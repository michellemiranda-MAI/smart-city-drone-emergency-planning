PAR Final Project - Autonomous Drone Planning
=============================================

Environment: Windows 11 + WSL 2 (Ubuntu 24.04), Fast Downward + VAL.
All commands are run from this folder, inside WSL/Linux.


Files
-----
domain-A.pddl                 First domain model
domain-B.pddl                 Alternative domain model
problem-small.pddl            Instance 1 (small)
problem-medium.pddl           Instance 2 (medium)
problem-large.pddl            Instance 3 (large, three drones)
problem-large-1drone.pddl     Single-drone variant of the large instance
optional_experiments/
  problem-large-clustered.pddl  Extra: large instance, all three drones start
                                at the port depot (not a required instance)
test-problem.pddl             Extra: tiny instance used to test the domains
run_experiments.sh            Runs every instance x model x configuration
validation/                   VAL output for every plan found (Validate -v)
plans/                        Plans found by Fast Downward
logs/                         Fast Downward output of every run
results/results.csv           One row per run (results table of the report)


1. Install the tools
--------------------
sudo apt update
sudo apt install -y git cmake g++ make python3 flex bison

Fast Downward:
cd ~
git clone https://github.com/aibasel/downward.git
cd downward
./build.py

VAL:
cd ~
git clone https://github.com/KCL-Planning/VAL.git
cd VAL
bash scripts/linux/build_linux64.sh all Release
(the Validate binary ends up in ~/VAL/build/linux64/Release/bin/;
 find it with: find ~/VAL -name Validate -type f)

Add both to PATH:
echo 'export PATH="$HOME/downward:$PATH"' >> ~/.bashrc
echo 'export PATH="$HOME/VAL/build/linux64/Release/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc


2. Run everything
-----------------
bash run_experiments.sh

Runs that already have a log are skipped. To re-run everything from scratch:
FORCE=1 bash run_experiments.sh

If the tools are not on PATH:
FD=/path/to/fast-downward.py VALIDATE=/path/to/Validate bash run_experiments.sh


3. Exact commands (what run_experiments.sh runs)
------------------------------------------------
Every run uses the same limits:
  --overall-time-limit 5m --overall-memory-limit 4G

Replace domain-A.pddl by domain-B.pddl and problem-small.pddl by any other
problem file to run the other combinations.

LAMA-first (required):
fast-downward.py --overall-time-limit 5m --overall-memory-limit 4G --plan-file sas_plan --alias lama-first domain-A.pddl problem-small.pddl

A* with LM-cut (required):
fast-downward.py --overall-time-limit 5m --overall-memory-limit 4G --plan-file sas_plan domain-A.pddl problem-small.pddl --search "astar(lmcut())"

Anytime LAMA (large, large-1drone and large-clustered only):
fast-downward.py --overall-time-limit 5m --overall-memory-limit 4G --plan-file sas_plan --alias lama domain-A.pddl problem-large.pddl
  It writes sas_plan.1, sas_plan.2, ... each cheaper than the last;
  the last one is the plan that is validated and reported.

Extra configurations:
fast-downward.py --overall-time-limit 5m --overall-memory-limit 4G --plan-file sas_plan domain-A.pddl problem-small.pddl --search "astar(blind())"
fast-downward.py --overall-time-limit 5m --overall-memory-limit 4G --plan-file sas_plan domain-A.pddl problem-small.pddl --search "astar(hmax())"
fast-downward.py --overall-time-limit 5m --overall-memory-limit 4G --plan-file sas_plan domain-A.pddl problem-small.pddl --search "eager_greedy([ff()])"

Validate a plan (same domain and problem files as the planner):
Validate -v domain-A.pddl problem-small.pddl sas_plan
  "Plan valid" and "Final value: <cost>" give the validation result and the
  plan cost reported in the results table.
