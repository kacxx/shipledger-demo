#!/usr/bin/env bash
# Drives the agent demo recording: Claude Code, with the shipledger skill
# installed, verifies v0.3.0 from its GitHub release. Claude's work is live, so
# its wording varies between runs; only the typing of the prompt is simulated.
# Runs in a scratch clone with the hand-written v0.3.0 claims removed, so the
# claim has to come from the release. Expects a built shipledger checkout next
# to this repo (override with SHIPLEDGER_CLI).
#
#   asciinema rec --window-size 102x30 -c docs/record-agent-demo.sh docs/agent-demo.cast
#   agg --theme monokai --font-size 16 --idle-time-limit 2 \
#     --last-frame-duration 12 docs/agent-demo.cast docs/agent-demo.gif
set -u
here=$(cd "$(dirname "$0")" && pwd)
repo=$(dirname "$here")
cli=${SHIPLEDGER_CLI:-$(dirname "$repo")/shipledger/packages/cli/dist/cli/index.js}

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/bin"
printf '#!/bin/sh\nexec node "%s" "$@"\n' "$cli" > "$scratch/bin/shipledger"
chmod +x "$scratch/bin/shipledger"
export PATH="$scratch/bin:$PATH" GIT_PAGER=cat PAGER=cat TERM=xterm-256color

cat > "$scratch/settings.json" <<'JSON'
{
  "disableAllHooks": true,
  "permissions": {
    "allow": [
      "Skill", "Read", "Write", "Edit", "Glob", "Grep",
      "Bash(shipledger:*)", "Bash(gh release view:*)",
      "Bash(git log:*)", "Bash(git rev-parse:*)", "Bash(git show:*)",
      "Bash(git status:*)", "Bash(git tag:*)",
      "Bash(date:*)", "Bash(echo:*)", "Bash(ls:*)", "Bash(cat:*)", "Bash(jq:*)"
    ],
    "deny": ["Bash(npx:*)"]
  }
}
JSON

git clone -q "$repo" "$scratch/shipledger-demo"
cd "$scratch/shipledger-demo" || exit 1
git remote set-url origin https://github.com/kacxx/shipledger-demo.git
rm -f changesets/v0.3.0*.json

system='The shipledger CLI is on PATH as `shipledger`; never use npx. Keep the final report to about ten lines.'
claude() {
  command claude "$@" --output-format stream-json --verbose \
    --settings "$scratch/settings.json" --append-system-prompt "$system" \
    < /dev/null | python3 "$here/agent-stream.py"
}

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
printf '%sshipledger%s + Claude Code — the agent gathers the claim, the CLI decides\n' "$B" "$R"
sleep 1.5

say "Ask Claude to verify v0.3.0. The only claim is the GitHub release:"
run 'claude -p "Verify the v0.3.0 release with shipledger. Build the claim from the GitHub release; the range is v0.2.0..v0.3.0."' 6
