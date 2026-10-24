"""
Core execution and helper functions for Halmos verification tool integration.
"""
from pathlib import Path
import os
import signal
import subprocess
import re
import utils


def run_in_own_process_group(cmd, cwd, timeout_seconds):
    """
    Run cmd in a new process group and return (stdout, stderr, timed_out).
    On timeout, error or Ctrl-C the whole group is killed, so the solvers
    spawned by Halmos (yices) do not survive it.
    """
    proc = subprocess.Popen(
        cmd,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        start_new_session=True
    )
    timed_out = False
    try:
        stdout, stderr = proc.communicate(timeout=timeout_seconds)
    except subprocess.TimeoutExpired:
        timed_out = True
        os.killpg(proc.pid, signal.SIGKILL)
        stdout, stderr = proc.communicate()
    finally:
        # Halmos may exit leaving solvers behind; the group outlives its leader
        try:
            os.killpg(proc.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    return stdout or "", stderr or "", timed_out


def parse_timeout_to_seconds(timeout_str):
    """Convert timeout string (e.g., '10m', '600s') to seconds integer."""
    try:
        if timeout_str.endswith('m'):
            return int(timeout_str[:-1]) * 60
        elif timeout_str.endswith('s'):
            return int(timeout_str[:-1])
        return int(timeout_str)
    except ValueError:
        return 600


def extract_test_contract_name(file_path, clean_p):
    """Extract the specific contract name enclosing the test function."""
    try:
        content = Path(file_path).read_text(encoding="utf-8")
        # Ignore comments: e.g. "// ... contract target" is not a contract declaration
        content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
        content = re.sub(r'//[^\n]*', '', content)

        test_search = clean_p
        if test_search.startswith("check_"):
            test_search = test_search[6:]
        elif test_search.startswith("invariant_"):
            test_search = test_search[10:]

        contracts = re.findall(r'\bcontract\s+([a-zA-Z0-9_]+)', content)
        if not contracts:
            return None

        if len(contracts) == 1:
            return contracts[0]

        parts = content.split("contract ")
        for part in parts[1:]:
            lines = part.splitlines()
            c_name = lines[0].split()[0].split('{')[0].strip()
            if test_search.lower() in part.lower():
                return c_name

        return contracts[-1]

    except Exception:
        return None


VERSION_SPECIFIC_FILE = re.compile(r"^v\d+_|_v\d+\.t\.sol$")


def find_test_file(halmos_path, p, v):
    """
    Locate the .t.sol file for property p and version v. Supported layouts:
    - version-specific: '<v>_<p>.t.sol' (generated, e.g. contracts/bank) or
      '<Contract>_<p>_<v>.t.sol' (e.g. regression/call_verifier)
    - generic: '<p>.t.sol' or '<Contract>_<p>.t.sol' (e.g. regression/payable)
    The property name is matched both with '-' and with '_'.
    """
    names = {p, p.replace('-', '_')}

    def files(pattern):
        return sorted(f for f in halmos_path.rglob(pattern) if f.is_file())

    if v:
        for n in names:
            matches = files(f"{v}_{n}.t.sol") + files(f"*_{n}_{v}.t.sol")
            if matches:
                return matches[0]

    for n in names:
        matches = files(f"{n}.t.sol") + files(f"*_{n}.t.sol")
        matches = [f for f in matches if not VERSION_SPECIFIC_FILE.search(f.name)]
        if matches:
            return matches[0]

    test_fun = re.compile(rf"function\s+(check|invariant)_{re.escape(p.replace('-', '_'))}\s*\(")
    for f in files("*.t.sol"):
        if VERSION_SPECIFIC_FILE.search(f.name):
            continue
        try:
            if test_fun.search(f.read_text(encoding="utf-8")):
                return f
        except Exception:
            continue

    return None


def parse_outcome(output, test_match):
    """Map the Halmos output to an outcome: FAIL/counterexample -> N!, PASS -> P, else UNK."""
    # Strip ANSI colors from output
    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    clean_output = ansi_escape.sub('', output)

    fail_pattern = rf"\[FAIL\]\s+.*{re.escape(test_match)}"
    pass_pattern = rf"\[PASS\]\s+.*{re.escape(test_match)}"

    if re.search(fail_pattern, clean_output, re.IGNORECASE) or (
        re.search(rf"{re.escape(test_match)}", clean_output, re.IGNORECASE) and "Counterexample:" in clean_output
    ):
        return utils.STRONG_NEGATIVE

    elif re.search(pass_pattern, clean_output, re.IGNORECASE):
        return utils.WEAK_POSITIVE

    lines = [line for line in clean_output.split('\n') if test_match.lower() in line.lower()]
    for line in lines:
        if "[fail]" in line.lower():
            return utils.STRONG_NEGATIVE
        if "[pass]" in line.lower():
            return utils.WEAK_POSITIVE

    return utils.UNKNOWN


def run(p, v, halmos_dir, timeout_seconds):
    """
    Runs a single Halmos experiment for property p and version v.
    """
    clean_p = p.replace('-', '_')
    target_file_path = find_test_file(Path(halmos_dir), p, v)

    # Skip versions for which no version-specific test file was generated
    if not target_file_path:
        return utils.ERROR, None

    print(f"Running Halmos verification for property: '{p}', version: ({v})")

    try:
        test_match = clean_p
        if test_match.startswith("check_"):
            test_match = test_match[6:]
        elif test_match.startswith("invariant_"):
            test_match = test_match[10:]

        halmos_cmd = [
            "halmos",
            "--match-test", test_match,
            "--solver-timeout-assertion", str(timeout_seconds * 1000),
            "--early-exit"
        ]

        contract_name = extract_test_contract_name(target_file_path, clean_p)
        if contract_name:
            halmos_cmd.extend(["--contract", contract_name])

        stdout, stderr, timed_out = run_in_own_process_group(halmos_cmd, halmos_dir, timeout_seconds)
        output = stdout + "\n" + stderr

        if timed_out:
            output += f"\n[TIMEOUT] killed after {timeout_seconds}s (wall-clock timeout)\n"
            return utils.UNKNOWN, output

        return parse_outcome(output, test_match), output

    except Exception as e:
        msg = f"Error during Halmos execution for {p}: {e}"
        print(msg)
        return utils.ERROR, msg


def run_log(p, v, halmos_dir, timeout_seconds, logs_dir=None):
    """
    Calls run() and writes the log (also on timeout).
    Skipped tasks (no test file) are neither printed nor logged.
    """
    outcome, log = run(p, v, halmos_dir, timeout_seconds)
    if log is None:
        return outcome
    if logs_dir:
        log_filename = f"{v}_{p}.log" if v else f"{p}.log"
        utils.write_log(Path(logs_dir).joinpath(log_filename), log)
    else:
        print(log)
    print(f"{p} ({v}): {outcome}")
    return outcome


def run_all(tasks, timeout_seconds, logs_dir=None, halmos_dir="./halmos"):
    """
    Runs Halmos on all (property, version) tasks, one at a time: each run
    already spawns several solver processes and is bound by a wall-clock timeout.

    Returns:
        dict: {(property, version): outcome}
    """
    outcomes = {}
    for p, v in tasks:
        outcomes[(p, v)] = run_log(p, v, halmos_dir, timeout_seconds, logs_dir)
    return outcomes