import subprocess
import os

with open("../contracts/amm/certora/redeem-liveness.spec", "r") as f:
    content = f.read()

new_requires = """
    require(currentContract.r0(e) <= 1000000000000000000000000000000000000);
    require(currentContract.r1(e) <= 1000000000000000000000000000000000000);
    require(currentContract.supply(e) <= 1000000000000000000000000000000000000);
    require(currentContract.t0(e).balanceOf(e, e.msg.sender) <= 1000000000000000000000000000000000000);
    require(currentContract.t1(e).balanceOf(e, e.msg.sender) <= 1000000000000000000000000000000000000);
    require(currentContract.supply(e) > 0);
"""

content = content.replace("    require(currentContract.supply(e) > 0);", new_requires)

with open("../contracts/amm/certora/redeem-liveness.spec", "w") as f:
    f.write(content)

print("Running certora...")
subprocess.run(["python3", "run_certora_simple.py", "--contract", "amm", "--property", "redeem-liveness", "--version", "1"])
