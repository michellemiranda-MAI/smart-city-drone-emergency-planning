#!/usr/bin/env bash
# Generate capacity variants of problem-large-1drone.pddl (extra experiment:
# how the number of battery levels affects search). Only the battery facts
# change: level objects, start level (full), battery_after, next_level,
# max_level. Map, costs, goals and locks are copied unchanged.
# Usage (from the repo folder):  bash optional_experiments/gen_capacity.sh 8 10
set -eu
cd "$(dirname "$0")/.."
SRC=problem-large-1drone.pddl

for N in "$@"; do
  out=optional_experiments/problem-large-1drone-b$N.pddl
  levels=$(for i in $(seq 0 "$N"); do printf 'b%d ' "$i"; done)
  after=$(for c in 1 2 3; do for b in $(seq "$N" -1 "$c"); do
            printf '    (battery_after b%d b%d b%d)\n' "$b" "$c" $((b - c)); done; done)
  next=$(for i in $(seq 0 $((N - 1))); do printf '(next_level b%d b%d) ' "$i" $((i + 1)); done)
  awk -v N="$N" -v levels="$levels" -v after="$after" -v nxt="$next" '
    /^\(define \(problem/      { print "(define (problem drone-large-1drone-b" N ")"; next }
    /- level?$/               { print "    " levels "- level"; next }
    /battery capacity 6/       { sub(/capacity 6 \(b0-b6\)/, "capacity " N " (b0-b" N ")") }
    /\(battery droneA b6\)/    { sub(/battery droneA b6/, "battery droneA b" N) }
    /battery arithmetic/       { print "    ;; ---- battery arithmetic (capacity " N ", costs 1, 2, 3) ----"
                                 print after; print "    " nxt; print "    (max_level b" N ")"
                                 skip = 1; next }
    skip && /max_level/        { skip = 0; next }
    skip                       { next }
                               { print }
  ' "$SRC" > "$out"
  echo "wrote $out"
done
