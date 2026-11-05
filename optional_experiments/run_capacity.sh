#!/usr/bin/env bash
# Extra experiment: battery capacity 6 / 8 / 10 on the single-drone large
# instance, A* with blind, h_max and LM-cut, both models. Same limits as
# run_experiments.sh. Output goes to optional_experiments/capacity/ so the
# main results are not touched.
# Usage (from the repo folder, in WSL):  bash optional_experiments/run_capacity.sh
set -u
cd "$(dirname "$0")/.."

FD=${FD:-$(command -v fast-downward.py || echo "$HOME/downward/fast-downward.py")}
VALIDATE=${VALIDATE:-$(command -v Validate || find "$HOME/VAL" -name Validate -type f | head -1)}
LIMITS="--overall-time-limit 5m --overall-memory-limit 4G"
OUT=optional_experiments/capacity
mkdir -p "$OUT"
CSV=$OUT/capacity.csv
echo "capacity,model,planner,solved,runtime_s,plan_length,plan_cost,recharges,expanded_states,h_init,val" > "$CSV"

for N in 6 8 10; do
  prob=optional_experiments/problem-large-1drone-b$N.pddl
  [ "$N" = 6 ] && prob=problem-large-1drone.pddl
  for model in A B; do
    for h in blind hmax lmcut; do
      id="b${N}_${model}_astar-$h"
      echo ">>> $id"
      "$FD" $LIMITS --plan-file "$OUT/$id.plan" "domain-$model.pddl" "$prob" \
        --search "astar($h())" > "$OUT/$id.log" 2>&1
      runtime=$(grep -oP 'Planner time: \K[0-9.]+' "$OUT/$id.log" | tail -1)
      expanded=$(grep -oP 'Expanded \K[0-9]+(?= state)' "$OUT/$id.log" | tail -1)
      hinit=$(grep -oP 'Initial heuristic value for \w+: \K[0-9]+' "$OUT/$id.log" | head -1)
      solved=no length="" cost="" rech="" val=""
      if [ -f "$OUT/$id.plan" ]; then
        solved=yes
        length=$(grep -vc '^;' "$OUT/$id.plan")
        rech=$(grep -c '^(recharge' "$OUT/$id.plan")
        "$VALIDATE" -v "domain-$model.pddl" "$prob" "$OUT/$id.plan" > "$OUT/$id.val.txt" 2>&1
        if grep -q "Plan valid" "$OUT/$id.val.txt"; then val=valid; else val=INVALID; fi
        cost=$(grep -oP 'Final value: \K[0-9.]+' "$OUT/$id.val.txt" | tail -1)
      fi
      echo "$N,$model,astar-$h,$solved,$runtime,$length,$cost,$rech,$expanded,$hinit,$val" >> "$CSV"
    done
  done
done

echo
column -s, -t < "$CSV"
