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
printf '%sshipledger%s — checks the release you wrote against what git actually shipped\n' "$B" "$R"
sleep 1.5

say "The v0.3.0 release notes claim one change:"
run "jq -r '.items[] | .id + \"  \" + .title' changesets/v0.3.0.json" 1.2
say "Check that claim against the v0.3.0 tag:"
run 'shipledger check --changeset changesets/v0.3.0.json; echo "exit $?"' 3
say "Nobody announced #4. Here is what it changed:"
run "git show --format='%h %s' feda538" 3
say "The changelog won't let it slip through quietly either:"
run "shipledger render changelog" 3.5
say "Once the notes own up to it, the release checks clean:"
run 'shipledger check --changeset changesets/v0.3.0-amended.json; echo "exit $?"' 4

rm -f verified-changeset.json
