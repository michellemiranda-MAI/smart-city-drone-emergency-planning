#!/usr/bin/env bash
# Run every instance x domain model x planner configuration, validate each
# plan with VAL, and collect the numbers for the results table.
#
# Usage (from the repo folder, in WSL/Linux):  bash run_experiments.sh
# Optional: FD=/path/to/fast-downward.py VALIDATE=/path/to/Validate bash run_experiments.sh
# Runs that already have a log are skipped, so the script can be re-run after
# adding instances. FORCE=1 bash run_experiments.sh re-runs everything.
#
# Output:
#   plans/       <instance>_<model>_<config>.plan   (lama: the last, cheapest plan)
#   validation/  <instance>_<model>_<config>.val.txt (output of Validate -v)
#   logs/        <instance>_<model>_<config>.log     (Fast Downward output)
#   results/results.csv  one row per run (columns of the statement's table 7.2)

set -u
cd "$(dirname "$0")"

FD=${FD:-$(command -v fast-downward.py || echo "$HOME/downward/fast-downward.py")}
VALIDATE=${VALIDATE:-$(command -v Validate || find "$HOME/VAL" -name Validate -type f | head -1)}
LIMITS="--overall-time-limit 5m --overall-memory-limit 4G"   # same for every run

INSTANCES="test-problem.pddl problem-small.pddl problem-medium.pddl
           problem-large.pddl problem-large-1drone.pddl
           optional_experiments/problem-large-clustered.pddl"
# --alias lama (anytime) only for the large variants, as the statement asks
LAMA_INSTANCES="problem-large problem-large-1drone problem-large-clustered"

mkdir -p plans validation logs results
CSV=results/results.csv
if [ "${FORCE:-0}" = 1 ] || [ ! -f "$CSV" ]; then
  rm -f logs/*.log plans/*.plan validation/*.val.txt
  echo "instance,model,planner,solved,runtime_s,plan_length,plan_cost,expanded_states,val" > "$CSV"
fi

run() {  # run <problem-file> <model> <config-name> <planner options...>
  local prob=$1 model=$2 cfg=$3; shift 3
  local inst; inst=$(basename "$prob" .pddl)
  local id="${inst}_${model}_${cfg}"
  local tmp="plans/.tmp_${id}"
  if [ -f "logs/$id.log" ]; then echo "--- $id (done, skipped)"; return; fi
  echo ">>> $id"
  rm -f "$tmp" "$tmp".*
  # --alias goes before the input files, --search after them
  if [ "$1" = "--alias" ]; then
    "$FD" $LIMITS --plan-file "$tmp" "$@" "domain-$model.pddl" "$prob" > "logs/$id.log" 2>&1
  else
    "$FD" $LIMITS --plan-file "$tmp" "domain-$model.pddl" "$prob" "$@" > "logs/$id.log" 2>&1
  fi

  # lama writes tmp.1, tmp.2, ... (each cheaper than the last): keep the last
  local plan=$tmp
  local last; last=$(ls "$tmp".* 2>/dev/null | sort -t. -k3 -n | tail -1)
  [ -n "$last" ] && plan=$last

  local solved=no runtime="" length="" cost="" expanded="" val=""
  runtime=$(grep -oP 'Planner time: \K[0-9.]+' "logs/$id.log" | tail -1)
  expanded=$(grep -oP 'Expanded \K[0-9]+(?= state)' "logs/$id.log" | tail -1)
  if [ -f "$plan" ]; then
    solved=yes
    mv "$plan" "plans/$id.plan"
    length=$(grep -vc '^;' "plans/$id.plan")
    "$VALIDATE" -v "domain-$model.pddl" "$prob" "plans/$id.plan" > "validation/$id.val.txt" 2>&1
    if grep -q "Plan valid" "validation/$id.val.txt"; then val=valid; else val=INVALID; fi
    cost=$(grep -oP 'Final value: \K[0-9.]+' "validation/$id.val.txt" | tail -1)
  else
    # unsolved: say whether the time or the memory limit was hit
    # (every log prints "search memory limit: ...", so match the exact messages)
    if grep -q "Time limit has been reached" "logs/$id.log"; then
      solved="no (time)"
    elif grep -qE "Memory limit has been reached|Failed to allocate memory" "logs/$id.log"; then
      solved="no (memory)"
    fi
  fi
  rm -f "$tmp" "$tmp".*
  echo "$inst,$model,$cfg,$solved,$runtime,$length,$cost,$expanded,$val" >> "$CSV"
}

for prob in $INSTANCES; do
  [ -f "$prob" ] || { echo "skip $prob (not written yet)"; continue; }
  inst=$(basename "$prob" .pddl)
  for model in A B; do
    # required (Section 7.1)
    run "$prob" "$model" lama-first  --alias lama-first
    run "$prob" "$model" astar-lmcut --search "astar(lmcut())"
    if [[ " $LAMA_INSTANCES " == *" $inst "* ]]; then
      run "$prob" "$model" lama --alias lama
    fi
    # extra configurations (Lecture 2: blind vs weak vs strong heuristic,
    # and greedy search with plain h_FF)
    run "$prob" "$model" astar-blind --search "astar(blind())"
    run "$prob" "$model" astar-hmax  --search "astar(hmax())"
    run "$prob" "$model" gbfs-ff     --search "eager_greedy([ff()])"
  done
done

echo
column -s, -t < "$CSV"
