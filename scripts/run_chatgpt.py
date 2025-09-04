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


def sanitize_for_csv(text):
    """Raddoppia le virgolette e sostituisce newline reali con \n."""
    if not isinstance(text, str):
        return text
    #text = text.replace('"', '""')
    text = re.sub(r"\r?\n", r"\\n", text)
    return text

def load_api_key(path=API_KEY_FILE):
    if not os.path.exists(path):
        print(f"Errore: il file {path} non esiste.", file=sys.stderr)
        sys.exit(1)
    with open(path, "r", encoding="utf-8") as f:
        return f.read().strip()


def list_properties(contract_path):
    skeleton_path = os.path.join(contract_path, "skeleton.json")
    if not os.path.exists(skeleton_path):
        print(f"Errore: {skeleton_path} non trovato.", file=sys.stderr)
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
    return verification_tasks

def get_verification_tasks_from_csv(filepath,):
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

    # Normalizziamo il target da cercare
    target = f"{normalize_name(contract)}v{normalize_name(version)}"

    # Cerchiamo tra i file .sol quello che matcha
    for fname in os.listdir(version_folder):
        if fname.endswith(".sol"):
            candidate = normalize_name(fname.replace(".sol", ""))
            if candidate == target:
                filepath = os.path.join(version_folder, fname)
                break
    else:
        print(f"Errore: nessun file solidity trovato per {contract} v{version} in {version_folder}", file=sys.stderr)
        sys.exit(1)

    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    # Rimuove tutte le righe che iniziano con "/// @custom:"
    cleaned_lines = [line for line in lines if not line.strip().startswith("/// @custom:")]
    return "".join(cleaned_lines)



def load_property_description(contract, property_name):
    skeleton_path = os.path.join(CONTRACTS_DIR, contract, "skeleton.json")
    if not os.path.exists(skeleton_path):
        print(f"Errore: {skeleton_path} non trovato.", file=sys.stderr)
        sys.exit(1)

    with open(skeleton_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    props = data.get("properties", {})
    if property_name not in props:
        print(f"Errore: proprietà {property_name} non trovata in {skeleton_path}.", file=sys.stderr)
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
    return answer, explanation, counterexample

def run_experiment(contract, prop, version, prompt_file, token_limit, model):
    # Carica prompt
    prompt_path = os.path.join(SCRIPTS_DIR, f"prompt_templates/{prompt_file}")
    if not os.path.exists(prompt_path):
        print(f"Errore: prompt file {prompt_path} non trovato.", file=sys.stderr)
        sys.exit(1)
    with open(prompt_path, "r", encoding="utf-8") as f:
        prompt_template = f.read()

    # Carica codice Solidity e descrizione proprietà
    code = load_contract_code(contract, version)
    property_desc = load_property_description(contract, prop)

    # Sostituisci placeholders
    prompt_text = prompt_template.replace("{code}", code).replace("{property_desc}", property_desc)

    #with open(f"logs_prompt/prompt{str(datetime.datetime.now())}.txt", "w", encoding="utf-8") as f:
    #    f.write(prompt_text)

    start_time = time.time()
    # Inizializza client OpenAI
    client = openai.OpenAI(api_key=load_api_key())

    try:
        if model.startswith("gpt-4o") or model.startswith("gpt-3.5"):
            # Modelli chat classici
            response = client.chat.completions.create(
                model=model,
                messages=[{"role": "user", "content": prompt_text}],
                max_tokens=token_limit or 500
            )
            output_text = response.choices[0].message.content
        else:
            # Modelli nuovi (gpt-5, gpt-4.1, ecc.)
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
        print(f"Errore durante la chiamata API: {e}", file=sys.stderr)
        sys.exit(1)


def normalize_name(name: str) -> str:
    """Rende il nome uniforme: minuscolo, senza caratteri speciali."""
    return re.sub(r'[^a-z0-9]', '', name.lower())

def find_contract_folder(contract_arg: str) -> str:
    """Trova la cartella giusta in base al nome normalizzato."""
    target = normalize_name(contract_arg)
    for folder in os.listdir(CONTRACTS_DIR):
        if os.path.isdir(os.path.join(CONTRACTS_DIR, folder)):
            if normalize_name(folder) == target:
                return folder
    print(f"Errore: nessuna cartella trovata per '{contract_arg}' in {CONTRACTS_DIR}", file=sys.stderr)
    sys.exit(1)


def write_results_to_csv(results, output_file, temp=False):

    if not temp and os.path.exists(output_file):
        output_file_backup = output_file.replace("llms_results/","llms_results/backup/").replace(".csv", f"_backup_{str(datetime.datetime.now()).replace(' ','_').replace(':','-')}.csv")
        os.rename(output_file, output_file_backup)
        print(f"Backup of existing file saved as {output_file_backup}")

    text = "\"contract_id\",\"property_id\",\"ground_truth\",\"llm_answer\",\"llm_explanation\",\"llm_counterexample\",\"time\",\"tokens\",\"raw_output\"\n"

    for result in results:
        # Sanitizza i campi di testo
        result["llm_explanation"] = sanitize_for_csv(result["llm_explanation"])
        result["llm_counterexample"] = sanitize_for_csv(result["llm_counterexample"])
        result["raw_output"] = sanitize_for_csv(result["raw_output"])

        row = f"\"{result['contract_id']}\",\"{result['property_id']}\",\"{result['ground_truth']}\",\"{result['llm_answer']}\",\"{result['llm_explanation']}\",\"{result['llm_counterexample']}\",\"{result['time']}\",\"{result['tokens']}\",\"{result['raw_output']}\"\n"
        text = text + row        

    with open(output_file, "w", encoding="utf-8") as f: 
        f.write(text)


def get_results_from_csv(input_file):
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
            # Converti tipi appropriati
            #entry["ground_truth"] = entry["ground_truth"] == "True"
            #entry["time"] = float(entry["time"])
            results.append(entry)
        else:
            print(f"Warning: malformed line in {input_file}: {line}", file=sys.stderr)
    return results


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

    args = parser.parse_args()

    if args.use_csv_verification_tasks and args.no_sample:
        print("Warning: --no_sample has no effect when --use_csv_verification_tasks is enabled.")


    if args.version and not args.no_sample:
        args.no_sample = True
        print("Warning: --no_sample is automatically enabled when --version is specified.")


    # Find contract folder ignoring cases and special chars
    contract_folder = find_contract_folder(args.contract)

    base_path = os.path.join(CONTRACTS_DIR, contract_folder)

    # Se manca property → tutte
    properties = [args.property] if args.property else list_properties(base_path)
    if not properties:
        print(f"Nessuna proprietà trovata in {base_path}", file=sys.stderr)
        sys.exit(1)

    versions_path = os.path.join(base_path, "versions")

    ground_truths = get_ground_truths(base_path)

    verification_tasks = []
    for prop in properties:
        # Se manca version → tutte
        versions = [args.version] if args.version else list_versions(versions_path)
        if not versions:
            print(f"Nessuna versione trovata in {versions_path}", file=sys.stderr)

        verification_tasks_prop = choose_verification_tasks(prop, versions, ground_truths, args)
        #print(f"{verification_tasks_prop=}")
        verification_tasks.extend(verification_tasks_prop)  
    print(f"Verification tasks: {verification_tasks}")
    print(len(verification_tasks))
    #if args.use_csv_verification_tasks:
    #    verification_tasks = get_verification_tasks_from_csv(args.use_csv_verification_tasks)
    csv_ver_tasks_name = f"logs_verification_tasks/verification_tasks_{str(datetime.datetime.now())}.csv".replace(" ","")
    save_verification_tasks(verification_tasks, csv_ver_tasks_name)

    output_file = f"llms_results/results_{args.model}_{args.prompt}_{args.contract}_{args.tokens}tok.csv".replace(".txt","")
    print(f"Results will be saved to {output_file}")
            
    results = []

    starting_time = str(datetime.datetime.now())


    for verification_task in verification_tasks:
        prop, version = verification_task
        ground_truth = ground_truths[(prop,version)]
        output, total_time = run_experiment(contract_folder, prop, version, args.prompt, args.tokens, args.model)
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
        previous_results = get_results_from_csv(output_file)
        #for res in previous_results:
        #    print(res)

        results = merge_results(previous_results, results)

    write_results_to_csv(results, output_file)
    
    


if __name__ == "__main__":
    main()
