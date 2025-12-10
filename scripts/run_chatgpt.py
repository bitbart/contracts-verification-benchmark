#!/usr/bin/env python3
import argparse
import os
import sys
import json
import openai
import re
import datetime 
import random
random.seed(42)
import time
import pandas as pd
import csv

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # root del progetto
SCRIPTS_DIR = os.path.join(BASE_DIR, "scripts")
CONTRACTS_DIR = os.path.join(BASE_DIR, "contracts")
API_KEY_FILE = os.path.join(SCRIPTS_DIR, "openai_api_key.txt")

# Ensures text does not contain excessively long sequence of quotes
def remove_repeated_quotes(text):
    if not isinstance(text, str):
        return text
    while '""""""""""' in text:
        text = text.replace('""""""""""', '""')
    return text

def sanitize_for_csv(text):
    if not isinstance(text, str):
        return text
    text = text.replace('"', '""')
    text = re.sub(r"\r?\n", r"\\n", text)
    text = remove_repeated_quotes(text)
    return text

def load_api_key(path=API_KEY_FILE):
    if not os.path.exists(path):
        print(f"Error: file {path} does not exists.", file=sys.stderr)
        sys.exit(1)
    with open(path, "r", encoding="utf-8") as f:
        return f.read().strip()


def list_properties(contract_path):
    skeleton_path = os.path.join(contract_path, "skeleton.json")
    if not os.path.exists(skeleton_path):
        print(f"Error: {skeleton_path} not found.", file=sys.stderr)
        sys.exit(1)

    with open(skeleton_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    return sorted(list(data.get("properties", {}).keys()))

def get_ground_truths(contract_path):
    truth_path = os.path.join(contract_path, "ground-truth.csv")
    if not os.path.exists(truth_path):
        print(f"Error: {truth_path} not found.", file=sys.stderr)
        sys.exit(1)

    with open(truth_path, "r", encoding="utf-8") as f:
        ground_truths = {}
        for line in f:
            parts = line.strip().split(',')
            if parts[2] in ["0", "1"]:
                ground_truths[(parts[0],parts[1].replace("v",""))] = True if parts[2] == "1" else False
    return ground_truths

def choose_verification_tasks(prop, versions, ground_truths : dict, args):
    if args.use_csv_verification_tasks:
        verification_tasks = []
        verification_tasks_from_csv = get_verification_tasks_from_csv(args.use_csv_verification_tasks)
        for property, version in verification_tasks_from_csv:
            if property == prop and version in versions:
                if ground_truths.get((prop,version)) is None:
                    print(f"Warning: ground truth for ({prop}, {version}) not found. Skipping this version.")
                    continue
                verification_tasks.append((property, version))

    else:
        versions_positive = []
        versions_negative = []
        #print(ground_truths)
        for version in versions:
            #print(version,ground_truths[(prop,version)])
            if ground_truths.get((prop,version)) is None:
                print(f"Warning: ground truth for ({prop}, {version}) not found. Skipping this version.")
                continue
            if ground_truths[(prop,version)]:
                versions_positive.append(version)
            else:
                versions_negative.append(version)
        #print(versions_positive)
        #print(versions_negative)

        if args.no_sample:
            verification_tasks = [(prop, v) for v in versions_positive + versions_negative]
        else:
            k = min(len(versions_positive),len(versions_negative))
            print(prop)
            print(f"{k=}")
            sampled_versions_positive = random.sample(versions_positive, k)
            sampled_versions_negative = random.sample(versions_negative, k)
            #print(f"{sampled_versions_positive=}")
            #print(f"{sampled_versions_negative=}")
            verification_tasks = [(prop, v) for v in sampled_versions_positive + sampled_versions_negative]
            #print(f"{verification_tasks=}")
            if args.at_least_n_prop > 0:
                n = args.at_least_n_prop
                if len(verification_tasks) < n:
                    additional_needed = n - len(verification_tasks)
                    remaining_versions = list(set(versions_positive) | set(versions_negative) - set(v for _, v in verification_tasks))
                    if len(remaining_versions) < additional_needed:
                        additional_needed = len(remaining_versions)
                    if additional_needed > 0:
                        additional_versions = random.sample(remaining_versions, additional_needed)
                        verification_tasks.extend([(prop, v) for v in additional_versions])
                        print(f"Added {additional_needed} more tasks to reach at least {n} tasks for property {prop}.")
    return verification_tasks

def get_verification_tasks_from_csvOld(filepath,):
    verification_tasks = []
    if not os.path.exists(filepath):
        print(f"Error: the file {filepath} does not exist.", file=sys.stderr)
        sys.exit(1)
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            parts = line.strip().split(',')
            if len(parts) == 2:
                verification_tasks.append((parts[0], parts[1]))
            else:
                print(f"Warning: malformed line in {filepath}: {line}", file=sys.stderr)
    return verification_tasks

def get_verification_tasks_from_csv(filepath):
    verification_tasks = []
    if not os.path.exists(filepath):
        print(f"Error: the file {filepath} does not exist.", file=sys.stderr)
        sys.exit(1)
    with open(filepath, "r", encoding="utf-8") as f:
        reader = csv.reader(f)
        for row in reader:
            # Skip empty lines and header
            if not row or (row[0].lower() in {"property", "contract_id", "id"}):
                continue
            # Use the first two columns as property and version/task id
            if len(row) >= 2:
                verification_tasks.append((row[0].strip(), row[1].strip()))
            else:
                print(f"Warning: malformed line in {filepath}: {row}", file=sys.stderr)
    return verification_tasks

def save_verification_tasks(verification_tasks, filepath):
    with open(filepath, "a", encoding="utf-8") as f:
        for prop, version in verification_tasks:
            f.write(f"{prop},{version}\n")

def list_versions(versions_path):
    if not os.path.exists(versions_path):
        return []
    versions = []
    for fname in os.listdir(versions_path):
        if fname.endswith(".sol"):
            # estrae "v1", "v2" ecc.
            base = fname.replace(".sol", "")
            parts = base.split("_v")
            if len(parts) == 2:
                versions.append(parts[1])
    return sorted(versions, key=lambda x: int(re.sub(r'\D', '', x) or 0))



def load_contract_code(contract, version):
    version_folder = os.path.join(CONTRACTS_DIR, contract, "versions")

    target = f"{normalize_name(contract)}v{normalize_name(version)}"

    for fname in os.listdir(version_folder):
        if fname.endswith(".sol"):
            candidate = normalize_name(fname.replace(".sol", ""))
            if candidate == target:
                filepath = os.path.join(version_folder, fname)
                break
    else:
        print(f"Error: no solidity file found for {contract} v{version} in {version_folder}", file=sys.stderr)
        sys.exit(1)

    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    # Removes all lines which  start with "/// @custom:"
    cleaned_lines = [line for line in lines if not line.strip().startswith("/// @custom:")]
    return "".join(cleaned_lines)



def load_property_description(contract, property_name):
    skeleton_path = os.path.join(CONTRACTS_DIR, contract, "skeleton.json")
    if not os.path.exists(skeleton_path):
        print(f"Error: {skeleton_path} not found.", file=sys.stderr)
        sys.exit(1)

    with open(skeleton_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    props = data.get("properties", {})
    if property_name not in props:
        print(f"Error: property {property_name} not found in {skeleton_path}.", file=sys.stderr)
        sys.exit(1)

    return props[property_name]


def parse_llm_output(text):
    match = re.search(
        r"ANSWER:\s*(.*?)\s*EXPLANATION:\s*(.*?)\s*COUNTEREXAMPLE:\s*(.*)",
        text,
        re.DOTALL | re.IGNORECASE
    )
    if match:
        answer = match.group(1).strip().upper()
        explanation = match.group(2).strip()
        counterexample = match.group(3).strip()
    else:
        answer, explanation, counterexample = "PARSE_ERROR", text.strip(), "N/A"
    
    # Sometimes when the answer is True GPT does not include "COUNTEREXAMPLE: " in the output, hence in such cases parsing needs to be fixed
    if answer == "PARSE_ERROR" and "ANSWER: TRUE\nEXPLANATION: " in explanation:
        answer = "TRUE"
        explanation = explanation.replace("ANSWER: TRUE\nEXPLANATION: ","")

    return answer, explanation, counterexample

def run_experiment(contract, prop, version, prompt_file, token_limit, model, args, previous_result = None):
    # Load prompt
    if args.hardhat:
        prompt_file = args.prompt_poc
    prompt_path = os.path.join(SCRIPTS_DIR, f"prompt_templates/{prompt_file}")
    if not os.path.exists(prompt_path):
        print(f"Error: prompt file {prompt_path} non found.", file=sys.stderr)
        sys.exit(1)
    with open(prompt_path, "r", encoding="utf-8") as f:
        prompt_template = f.read()

    # Load  Solidity code and property description
    code = load_contract_code(contract, version)
    property_desc = load_property_description(contract, prop)

    # Replace placeholders
    if args.hardhat:
        llm_answer = previous_result["llm_answer"]
        if llm_answer != "FALSE":
            print(f"Error: the result for ({prop}, {version}) is not FALSE. Cannot produce hardhat PoC without a counterexample.", file=sys.stderr)
            sys.exit(1)
        explanation = previous_result["llm_explanation"] 
        counterexample = previous_result["llm_counterexample"] 
        prompt_text = prompt_template.replace("{code}", code).replace("{property_desc}", property_desc).replace("{explanation}", explanation).replace("{counterexample}", counterexample)
        with open(f"logs_pocs/poc_{contract}_{prop}_{version}.txt", "w", encoding="utf-8") as f: 
            f.write(prompt_text)
    elif args.skeleton:
        skeleton_path = os.path.join(CONTRACTS_DIR, contract, f"specs/{prop}.spec")
        if not os.path.exists(skeleton_path):
            print(f"Error: {skeleton_path} not found.", file=sys.stderr)
            sys.exit(1)

        violation_skeleton = open(skeleton_path, "r", encoding="utf-8").read()
        
        prompt_text = prompt_template.replace("{code}", code).replace("{property_desc}", property_desc).replace("{violation_skeleton}", violation_skeleton)

    else:
        prompt_text = prompt_template.replace("{code}", code).replace("{property_desc}", property_desc)

    start_time = time.time()
    # Inizialize client OpenAI
    client = openai.OpenAI(api_key=load_api_key())


    print(prompt_text)
    
    try:
        if model.startswith("gpt-4o") or model.startswith("gpt-3.5"):
            response = client.chat.completions.create(
                model=model,
                messages=[{"role": "user", "content": prompt_text}],
                max_tokens=token_limit or 500
            )
            output_text = response.choices[0].message.content
        else:
            # New models (gpt-5, gpt-4.1, ecc.)
            response = client.responses.create(
                model=model,
                input=[{"role": "user", "content": prompt_text}],
                max_output_tokens=token_limit or 500
            )
            output_text = response.output_text
        end_time = time.time()
        total_time = end_time - start_time
        return output_text, total_time
        #print(f"=== {contract} / {prop} / v{version} ===")
        #print(output_text)
        #print("\n")

    except Exception as e:
        print(f"Error during API call: {e}", file=sys.stderr)
        sys.exit(1)


def normalize_name(name: str) -> str:
    """Uniform name: lower case, no special characters."""
    return re.sub(r'[^a-z0-9]', '', name.lower())

def find_contract_folder(contract_arg: str) -> str:
    target = normalize_name(contract_arg)
    for folder in os.listdir(CONTRACTS_DIR):
        if os.path.isdir(os.path.join(CONTRACTS_DIR, folder)):
            if normalize_name(folder) == target:
                return folder
    print(f"Error: no folder found per '{contract_arg}' in {CONTRACTS_DIR}", file=sys.stderr)
    sys.exit(1)

def check_all_verification_tasks_have_ground_truth(verification_tasks, ground_truths):
    for prop, version in verification_tasks:
        if (prop, version) not in ground_truths:
            print(f"Error: ground truth for ({prop}, {version}) not found.", file=sys.stderr)
            sys.exit(1)

def write_results_to_csv(results, output_file, temp=False):

    if not temp and os.path.exists(output_file):
        output_file_backup = output_file.replace("llms_results/","llms_results/backup/").replace(".csv", f"_backup_{str(datetime.datetime.now()).replace(' ','_').replace(':','-')}.csv")
        os.rename(output_file, output_file_backup)
        print(f"Backup of existing file saved as {output_file_backup}")

    text = "\"contract_id\",\"property_id\",\"ground_truth\",\"llm_answer\",\"llm_explanation\",\"llm_counterexample\",\"time\",\"tokens\",\"raw_output\"\n"

    for result in results:
        # Sanitize text fields
        result["llm_explanation"] = sanitize_for_csv(result["llm_explanation"])
        result["llm_counterexample"] = sanitize_for_csv(result["llm_counterexample"])
        result["raw_output"] = sanitize_for_csv(result["raw_output"])

        row = f"\"{result['contract_id']}\",\"{result['property_id']}\",\"{result['ground_truth']}\",\"{result['llm_answer']}\",\"{result['llm_explanation']}\",\"{result['llm_counterexample']}\",\"{result['time']}\",\"{result['tokens']}\",\"{result['raw_output']}\"\n"
        text = text + row        

    with open(output_file, "w", encoding="utf-8") as f: 
        f.write(text)


def get_results_from_csvOld(input_file):
    if not os.path.exists(input_file):
        print(f"Error: the file {input_file} does not exist.", file=sys.stderr)
        sys.exit(1)
    with open(input_file, "r", encoding="utf-8") as f:
        lines = f.readlines()
    results = []
    header = lines[0].strip().split(',')
    for line in lines[1:]:
        parts = line.strip().split('","')
        if len(parts) == len(header):
            entry = {header[i].strip('"'): parts[i].strip('"') for i in range(len(header))}
            #entry["ground_truth"] = entry["ground_truth"] == "True"
            #entry["time"] = float(entry["time"])
            results.append(entry)
        else:
            print(f"Error: malformed line in {input_file}: {line}\nlen(parts) == len(header): {len(parts)}, {len(header)}", file=sys.stderr)
            sys.exit(1)
    return results

def get_results_from_csv(input_file):
    if not os.path.exists(input_file):
        print(f"Error: the file {input_file} does not exist.", file=sys.stderr)
        sys.exit(1)
    results = []
    with open(input_file, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            results.append(row)
    return results

def get_verification_task_result(results, contract_id, property_id):
    for res in results:
        if res['contract_id'] == contract_id and res['property_id'] == property_id:
            return res
    return None

def get_previous_verification_tasks(previous_results):
    previous_verification_tasks = set()
    for res in previous_results:
        key = (res['property_id'], res['contract_id'])
        previous_verification_tasks.add(key)
    return previous_verification_tasks

def merge_results(old_results, new_results):
    merged_results = []
    seen_keys = set()

    # Add old results
    for res in old_results:
        key = (res['contract_id'], res['property_id'])
        merged_results.append(res)
        seen_keys.add(key)

    # Add new results, overwriting if key already seen
    for res in new_results:
        key = (res['contract_id'], res['property_id'])
        if key in seen_keys:
            #  Overwrite existing entry
            for i, existing_res in enumerate(merged_results):
                if (existing_res['contract_id'], existing_res['property_id']) == key:
                    merged_results[i] = res
                    break
        else:
            merged_results.append(res)
            seen_keys.add(key)

    return merged_results

def main():
    parser = argparse.ArgumentParser(description="Run ChatGPT experiments on benchmark.")
    parser.add_argument("--contract", required=True, help="Contract name (i.e. name of folder in contracts/)")
    parser.add_argument("--property", help="Property name (optional)")
    parser.add_argument("--version", help="Version number (optional)")
    parser.add_argument("--prompt", required=True, help="Prompt file (must be in scripts/prompt_templates/)")
    parser.add_argument("--tokens", type=int, default=500, help="Token limit (optional)")
    parser.add_argument("--model", default="gpt-4o", help="Model (default gpt-4o)")
    parser.add_argument("--no_sample", action='store_true', required=False, default=False, help="Disable verification tasks sampling. ")
    parser.add_argument("--use_csv_verification_tasks", required=False, default=False, help="Use verification tasks from a CSV file. ")
    parser.add_argument("--at_least_n_prop", type=int, default=0, help="Force to pick at least N verification task per property.")
    parser.add_argument("--force_overwrite", action='store_true', required=False, default=False, help="Don't run verification tasks already present in the results file.")
    parser.add_argument("--hardhat", action='store_true', required=False, default=False, help="Return a textual query to ask to produce a hardhat PoC given a False result.")
    parser.add_argument("--prompt_poc", required=False, help="Prompt file for hardhat PoC (must be in scripts/prompt_templates/)")
    parser.add_argument("--model_poc", required=False, help="Model to run the PoC prompt")
    parser.add_argument("--skeleton", action='store_true', required=False, default=False, help="Accept as input a violation skeleton.")

    args = parser.parse_args()
    assert(not(args.hardhat and args.skeleton))


    if args.use_csv_verification_tasks and args.no_sample:
        print("Warning: --no_sample has no effect when --use_csv_verification_tasks is enabled.")

    if args.use_csv_verification_tasks and args.at_least_n_prop:
        args.at_least_n_prop = 0
        print("Warning: --at_least_n_prop is automatically disabled when --use_csv_verification_tasks is enabled.")

    if args.no_sample and args.at_least_n_prop:
        args.at_least_n_prop = 0
        print("Warning: --at_least_n_prop has no effect when --no_sample is enabled.")

    if args.version and not args.no_sample:
        args.no_sample = True
        print("Warning: --no_sample is automatically enabled when --version is specified.")


    # Find contract folder ignoring cases and special chars
    contract_folder = find_contract_folder(args.contract)

    base_path = os.path.join(CONTRACTS_DIR, contract_folder)

    # If `property` not specified → consider all properties
    properties = [args.property] if args.property else list_properties(base_path)
    print(properties)
    if not properties:
        print(f"No property found in {base_path}", file=sys.stderr)
        sys.exit(1)

    versions_path = os.path.join(base_path, "versions")

    ground_truths = get_ground_truths(base_path)

    output_file = f"llms_results/results_{args.model}_{args.prompt}_{args.contract}_{args.tokens}tok.csv".replace(".txt","")
    print(f"Output file: {output_file}")

    if os.path.exists(output_file):
        previous_results = get_results_from_csv(output_file)
    else:
        previous_results = []

    previous_verification_tasks = get_previous_verification_tasks(previous_results)

    verification_tasks = []
    for prop in properties:
        # If `version` not specified → consider all versions
        versions = [args.version] if args.version else list_versions(versions_path)
        if not versions:
            print(f"No versions found in {versions_path}", file=sys.stderr)

        verification_tasks_prop = choose_verification_tasks(prop, versions, ground_truths, args)
        #print(f"{verification_tasks_prop=}")
        verification_tasks.extend(verification_tasks_prop)  

    print(f"Verification tasks: {verification_tasks}")
    print(len(verification_tasks))

    if not args.force_overwrite and not args.hardhat:
        verification_tasks = [vt for vt in verification_tasks if vt not in previous_verification_tasks]
        print(f"After skipping already done tasks, {len(verification_tasks)} tasks remain.")

    if len(verification_tasks) < 10:
        print(f"Verification tasks: {verification_tasks}")

    #if args.use_csv_verification_tasks:
    #    verification_tasks = get_verification_tasks_from_csv(args.use_csv_verification_tasks)
    csv_ver_tasks_name = f"logs_verification_tasks/verification_tasks_{str(datetime.datetime.now())}.csv".replace(" ","")
    save_verification_tasks(verification_tasks, csv_ver_tasks_name)



    check_all_verification_tasks_have_ground_truth(verification_tasks, ground_truths)

    results = []

    starting_time = str(datetime.datetime.now())


    for verification_task in verification_tasks:
        prop, version = verification_task
        ground_truth = ground_truths[(prop,version)]

        if args.hardhat:
            print(f"{previous_results=}")
            previous_result = get_verification_task_result(previous_results, version, prop)
            if not previous_result:
                print(f"Error: no previous result found for ({prop}, {version}). Cannot produce hardhat PoC without a counterexample.", file=sys.stderr)
                continue
            output, total_time = run_experiment(contract_folder, prop, version, args.prompt, args.tokens, args.model_poc, args, previous_result)
            print(f"{output=}, {total_time=}")
            exit()
        else:
            output, total_time = run_experiment(contract_folder, prop, version, args.prompt, args.tokens, args.model, args)
            answer, explanation, counterexample = parse_llm_output(output)
            result_entry = {
                "contract_id": version,
                "property_id": prop,
                "ground_truth": ground_truth,
                "llm_answer": answer,
                "llm_explanation": explanation,
                "llm_counterexample": counterexample,
                "time": total_time,
                "tokens": args.tokens,
                "raw_output": output
            }
            results.append(result_entry)
            temp_file = f"logs_results/results_temp_{starting_time}.txt"
            write_results_to_csv(results, temp_file, temp=True)
        

    #print(results)
    results_df = pd.DataFrame(results)
    
    if os.path.exists(output_file):
        #previous_results = get_results_from_csv(output_file)
        #for res in previous_results:
        #    print(res)
        results = merge_results(previous_results, results)

    write_results_to_csv(results, output_file)
    
    


if __name__ == "__main__":
    main()
