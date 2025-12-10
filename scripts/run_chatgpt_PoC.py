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


def load_api_key(path=API_KEY_FILE):
    if not os.path.exists(path):
        print(f"Errore: il file {path} non esiste.", file=sys.stderr)
        sys.exit(1)
    with open(path, "r", encoding="utf-8") as f:
        return f.read().strip()

prompt_template="""You are an expert in Solidity smart contracts and formal verification. 

You will be given: 
1. A Solidity smart contract. 
2. A property on the contract expressed in natural language. 
3. An explanation of why the property is violated.
4. A counterexample written in natural language that consists in a trace that violates the property.

Your task: 
- Carefully analyze the contract and understand in depth why the given counterexample violates the property.
- Encode the counterexample to a JavaScript file (using HardHat 2.14.0, Mocha, and Chai) to produce a Proof of Concept that shows a concrete trace that violates the property.

Think step by step internally about how to translate the counterexample into an Hardhat Proof of Concept. Make sure that the code you produce works correctly. Do not include your reasoning in the output. 

Your answer must consist of ONLY the code of the Hardhat Proof of Concept.
---
Smart Contract:
{code}
Property:
{property_desc}
Explanation:
{explanation}
Counterexample:
{counterexample}"""

def run_experiment(contract, prop, explanation, counterexample):

    # Sostituisci placeholders
    prompt_text = prompt_template.replace("{code}", contract).replace("{property_desc}", prop).replace("{explanation}", explanation).replace("{counterexample}", counterexample)

    #with open(f"logs_prompt/prompt{str(datetime.datetime.now())}.txt", "w", encoding="utf-8") as f:
    #    f.write(prompt_text)

    start_time = time.time()
    # Inizializza client OpenAI
    client = openai.OpenAI(api_key=load_api_key())

    try:
        # Modelli nuovi (gpt-5, gpt-4.1, ecc.)
        response = client.responses.create(
            model="gpt-5",
            input=[{"role": "user", "content": prompt_text}],
            max_output_tokens=20000
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

contract = "../contracts/safe/versions/Safe_v1.sol"
prop = "The only method that can change the transaction guard is setGuard"
explanation = """While GuardManager.setGuard is the only function in the code that explicitly writes to GUARD_STORAGE_SLOT (see GuardManager.setGuard, sstore(GUARD_STORAGE_SLOT, guard)), the Safe can execute arbitrary delegatecalls (see Executor.execute: delegatecall when operation == Enum.Operation.DelegateCall, invoked by Safe.execTransaction). Any delegatecalled contract can directly write to the same GUARD_STORAGE_SLOT and thus change the transaction guard without calling setGuard. This can also occur during setup via setupModules(to, data), which delegatecalls arbitrary initializer code."""
counterexample = """1) Deploy Safe with owner Alice (threshold=1).
2) Deploy a helper contract:
 contract GuardChanger {
 function change(address newGuard) external {
 bytes32 slot = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8; // GUARD_STORAGE_SLOT
 assembly { sstore(slot, newGuard) }
 }
 }
3) Alice submits Safe.execTransaction pointing to GuardChanger with operation=DelegateCall and data encoding change(attackerGuard).
4) Executor.execute performs a delegatecall into GuardChanger, which sstores to GUARD_STORAGE_SLOT, changing the guard without calling setGuard.
"""

def read_csv_to_array(file_path):
    with open(file_path, newline='', encoding='utf-8') as csvfile:
        reader = csv.reader(csvfile)
        # Read the first row (assuming there's only one)
        row = next(reader)  
        return row
    
file_path = 'res.txt' 
entries = read_csv_to_array(file_path)


print(entries)

"""
output_text, total_time = run_experiment(contract, prop, explanation, counterexample)
print(output_text)
print(total_time)

with open(f"poc_{str(datetime.datetime.now())}.txt", "w", encoding="utf-8") as f:
    f.write(output_text)
"""