#!/usr/bin/env bash
# Drives the demo recording. Every command really runs against this clone;
# only the typing is simulated. Expects a built shipledger checkout next to
# this repo (override with SHIPLEDGER_CLI).
#
#   asciinema rec --window-size 102x30 -c docs/record-demo.sh docs/demo.cast
#   agg --theme monokai --font-size 16 --idle-time-limit 2.5 \
#     --last-frame-duration 4 docs/demo.cast docs/demo.gif
set -u
cd "$(dirname "$0")/.." || exit 1
cli=$(cd .. && pwd)/shipledger/packages/cli/dist/cli/index.js
cli=${SHIPLEDGER_CLI:-$cli}
rm -f verified-changeset.json
export GIT_PAGER=cat PAGER=cat TERM=xterm-256color
shipledger() { node "$cli" "$@"; }

B=$'\e[1m'; Y=$'\e[1;33m'; C=$'\e[36m'; M=$'\e[35m'; G=$'\e[32m'; R=$'\e[0m'
prompt() { printf '%sshipledger-demo%s %s(main)%s %s❯%s ' "$C" "$R" "$M" "$R" "$G" "$R"; }
say() { printf '\n%s# %s%s\n' "$Y" "$1" "$R"; sleep 1.2; }
run() {
  prompt; sleep 0.4
  local s=$1 i
  for ((i = 0; i < ${#s}; i++)); do printf '%s' "${s:i:1}"; sleep 0.025; done
  sleep 0.4; printf '\n'
  eval "$s"
  sleep "${2:-1.8}"
}

clear
printf '%sshipledger%s — checks a release you wrote against local git\n' "$B" "$R"
sleep 1.5

say "v0.2.0's release notes claim two PRs:"
run "jq -r '.items[] | .id + \"  \" + .title' changesets/v0.2.0.json" 1.2
run "git log --oneline v0.1.0..v0.2.0"
say "Every commit in the tag is claimed, so the check passes:"
run 'shipledger check --config shipledger.config.json --changeset changesets/v0.2.0.json; echo "exit $?"'
run "jq -c '{verdict, violations}' verified-changeset.json" 2.5

say "v0.3.0's notes claim only #3:"
run "jq -r '.items[] | .id + \"  \" + .title' changesets/v0.3.0.json" 1.2
run "git log --oneline v0.2.0..v0.3.0"
say "But the tag also contains #4, so the check fails:"
run 'shipledger check --config shipledger.config.json --changeset changesets/v0.3.0.json; echo "exit $?"'
run "jq -c '{verdict, violations}' verified-changeset.json" 1.2
say "The artifact names the commit nobody claimed:"
run "jq -r '.commits[] | select(.findings != []) | \"\\(.sha[:7]) \\(.subject)  ->  \\(.findings[0])\"' verified-changeset.json" 4

rm -f verified-changeset.json
