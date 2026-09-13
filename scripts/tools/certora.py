'''
Operates on either a single file or every file within a directory.

Usage:
    python run_certora.py -c <file_or_dir> -s <spec_file> -o <output_dir>
'''

from string import Template
from multiprocessing import Pool
from pathlib import Path
import subprocess
import logging
import sys
import os
import re
import time
import random
random.seed(42)

import utils
from utils import (STRONG_POSITIVE,
                   STRONG_NEGATIVE,
                   WEAK_POSITIVE,
                   WEAK_NEGATIVE,
                   NONDEFINABLE,
                   ERROR)

THREADS = 6     # n of parallel executions


COMMAND_TEMPLATE = Template(
    'certoraRun.py --short_output $contract_path:$name --verify $name:$spec_path --msg "$msg" --wait_for_results --rule_sanity none'
)

CONF_FILE_COMMAND_TEMPLATE = Template(
    'certoraRun.py $conf_path --wait_for_results --rule_sanity none'
)

# Check if there is an error in the output (Deprec)
def has_property_error(output, property):
    pattern = rf'.*ERROR: \[rule\] {re.escape(property).upper()}.*'
    return re.search(pattern, output, re.DOTALL)


def no_errors_found(output):
    #pattern = r'.*No errors found by Prover!.*'
    pattern = r'.*Failures summary*'
    return not re.search(pattern, output, re.DOTALL)


def violations_found(output):
    pattern1 = r'.*Violations were found.*'
    pattern2 = r'.*Violated: *'
    return re.search(pattern1, output, re.DOTALL) or re.search(pattern2, output, re.DOTALL)

def property_violated(output, spec_path):
    property_name = str(spec_path).replace("certora/","").replace(".spec","").replace("-","_")
    return f"Violated: {property_name}" in output

# Checks if the property was verified at least for one method
def property_verified_at_least_one(output, spec_path):
    property_name = str(spec_path).replace("certora/","").replace(".spec","").replace("-","_")
    return f"Verified: {property_name}" in output

def has_critical_error(output):
    pattern1 = r'.*CRITICAL.*'
    pattern2 = r'.*solc had an error.*'
    return re.search(pattern1, output, re.DOTALL) or re.search(pattern2, output, re.DOTALL)

def no_permission(output):
    """ Parse the output looking for a no permission error. """
    pattern = r'.*You have no permission.*'
    return re.search(pattern, output, re.DOTALL)


def run(contract_path, spec_path):
    '''
    Runs a single certora experiment.

    Returns:
        tuple: (outcome, log)
    '''

    # Check if the contract to verify exists
    if not os.path.isfile(contract_path):
        msg = f'{contract_path} not found.'
        logging.error(msg)
        return ERROR, msg

    # Name of the Solidity contract to verify
    contract_name = utils.get_contract_name(contract_path)

    # Check the contract name
    if not contract_name:
        msg = f'Could not retrieve {contract_path} contract name.'
        logging.error(msg)
        return ERROR, msg

    # Process specs file
    negate = False
    has_satisfy = False
    has_assert = False
    has_invariant = False
    with open(spec_path, 'r') as file:
        spec_code = file.read()
        spec_no_comments = utils.remove_comments(spec_code)

        has_satisfy = re.search('satisfy', spec_no_comments)
        has_assert = re.search('assert', spec_no_comments)
        has_invariant = re.search('invariant', spec_no_comments)
        has_custom_run = re.search('/// @custom:run', spec_code)

        # Check if there are asserts or satisfy
        if not has_assert and not has_satisfy and not has_invariant:
            msg = f'Error in {spec_path}: No "assert" or "satisfy" found.'
            logging.error(msg)
            return ERROR, msg

        # Exit if both are used
        if has_assert and has_satisfy:
            msg = f'Error in {spec_path}: Combining both "satisfy" and "assert" is not allowed.'
            logging.error(msg)
            return ERROR, msg

        # Process tags
        # Tag Nondefinable
        nondef = re.search('/// @custom:nondef (.*)', spec_code)
        if nondef:
            print(f'{contract_path}: {NONDEFINABLE} (nondefinable)')
            return NONDEFINABLE, nondef.group(1)

        # Tag Negate
        negate = re.search('/// @custom:negate', spec_code)


    # Prepare to fill template command
    params = {}
    params['contract_path'] = contract_path
    params['name'] = contract_name
    params['spec_path'] = spec_path
    name, version_id = Path(contract_path).stem.split('_')
    property_id = Path(spec_path).stem.split('_')[0]
    params['msg'] = f'{name}_{property_id}_{version_id}'
    
    conf_params = {}
    conf_params['conf_path'] = f'certora/conf/{name}_{property_id}_{version_id}.conf'
    conf_command = CONF_FILE_COMMAND_TEMPLATE.substitute(conf_params)

    if os.path.isfile(conf_params['conf_path']):
        #print(conf_command)
        try:
            log = subprocess.run(conf_command.split(), capture_output=True, text=True)
        except FileNotFoundError as e:
            if 'certoraRun' in str(e):
                logging.error('Certora is not installed. Use:\npip install certora-cli.')
                return ERROR, str(e)
    else:
        if has_custom_run:
            command = utils.find_custom_run_line(spec_code)
            command = command.replace('certoraRun ', 'certoraRun.py --short_output --rule_sanity none ')
            command = command.replace('_v1.sol', f'_{version_id}.sol')
        else:
            command = COMMAND_TEMPLATE.substitute(params)

        # Random wait to avoid conflicting Certora runs
        wait_time = random.randint(1,1000)/1000
        time.sleep(wait_time)
        #print(command) #- substitute with a log that does not go to stdout
        try:
            log = subprocess.run(command.split(), capture_output=True, text=True)
        except FileNotFoundError as e:
            if 'certoraRun' in str(e):
                logging.error('Certora is not installed. Use:\npip install certora-cli.')
                return ERROR, str(e)
    is_violated = property_violated(log.stdout, spec_path)
    is_verified_once = property_verified_at_least_one(log.stdout, spec_path)

    # is_violated and is_verified must be mutually exclusive
    if (not is_violated) and (not is_verified_once):
        logging.error(log.stdout)
        return ERROR, log.stdout

    # Handle Certora errors
    if log.stderr:
        print(log.stderr, file=sys.stderr)

    if has_critical_error(log.stdout) and not is_violated:
        logging.error(log.stdout)
        return ERROR, log.stdout

    if no_permission(log.stdout) and not is_violated:
        logging.error(log.stdout)
        return ERROR, log.stdout

    # Save result
    if has_satisfy:
        is_positive = is_verified_once  # existential → disjunctive over instantiations
    else:
        is_positive = no_errors_found(log.stdout) and not is_violated

    # Negation
    is_positive = not is_positive if negate else is_positive

    res = STRONG_POSITIVE if has_assert or has_invariant else WEAK_POSITIVE
    if not is_positive:
        res = WEAK_NEGATIVE if has_assert or has_invariant else STRONG_NEGATIVE

    print(f'{contract_path}, {spec_path}: {res}')
    return res, f'{log.stdout}\n\n{log.stderr}'


def run_log(id, contract_path, spec_path, logs_dir=None):
    '''
    Calls run() and writes the log.
    '''
    outcome, log = run(contract_path, spec_path)
    if logs_dir:
        logs_dir.mkdir(parents=True, exist_ok=True)
        utils.write_log(Path(logs_dir).joinpath(id + '.log'), log)
    else:
        print(log)
        print(f'Result: {outcome}') 
    return id, outcome


def run_all(contracts_paths, specs_paths, only_ground_truth, logs_dir=None):
    '''
    Runs certora on all files of a directory.

    Args:
        contracts_paths (list): Contracts paths.
        specs_paths (list): CVL specs paths.
        log_dir (str): Log directory path.

    Returns:
        dict: {key_v*: outcome}
    '''
    outcomes = {}
    inputs = []     # inputs for run_log()

    for contract_path in contracts_paths:
        # Get list of properties to verify for this contract
        contract_properties_paths = utils.get_properties(contract_path, specs_paths)

        for property_path in contract_properties_paths:
            property_id = Path(property_path).stem.split('_')[0]    # split to eventually remove version
            version_id = Path(contract_path).stem.split('_')[1]
            id = f'{property_id}_{version_id}'
            if ((not only_ground_truth or utils.has_ground_truth(contract_path, property_path))
                    and utils.has_rule_or_invariant(property_path)):
                inputs.append((id, contract_path, property_path, logs_dir))

    with Pool(processes=THREADS) as pool:
        # [(id, outcome), ...]
        results = pool.starmap(run_log, inputs)
        for id, outcome in results:
            outcomes[id] = outcome

    return outcomes
