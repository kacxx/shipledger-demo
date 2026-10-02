# shipledger-demo

Shipledger checks a release you wrote against local git. It does not generate the release notes, and it does not call GitHub.

This repository has two releases whose notes were typed, not generated:

- **v0.2.0** lists #1 and #2. Both commits are in `v0.1.0..v0.2.0`. The check passes.
- **v0.3.0** lists only #3. The tag also contains #4, which disables rate limiting on `/login`. The check fails with `unknown-reference`.
- **v0.3.0, amended** (`changesets/v0.3.0-amended.json`) lists #3 and #4. The check passes.

![Demo: the v0.3.0 notes claim only #3; shipledger check fails with an unknown-reference on commit feda538, "disable rate limiting on /login (#4)"; git show shows the change; the changelog lists it under unaccounted commits; the amended claim passes](docs/demo.gif)

_Recorded against this repository with the built CLI; `shipledger` in the recording is a shell function for `node ../shipledger/packages/cli/dist/cli/index.js`. To re-record, see [docs/record-demo.sh](docs/record-demo.sh)._

### With an agent

Shipledger never talks to your tracker. An agent gathers the claim, and the CLI decides. Here Claude Code, with the shipledger skill installed, builds the v0.3.0 claim from its GitHub release, runs `doctor` and `check`, and reports the unclaimed #4 without adding it to the claim.

![Demo: Claude Code loads the shipledger skill, reads the v0.3.0 GitHub release, writes changeset.json claiming only #3, runs shipledger doctor and check, and reports a fail with one unknown-reference on feda538, "disable rate limiting on /login (#4)"](docs/agent-demo.gif)

_Recorded with the real Claude Code CLI; Claude's work is live, so its steps and wording vary between runs. `claude` in the recording wraps `claude -p` with a formatter for its stream output, a tool allowlist (the CLI, read-only `git` and `gh`, and file edits in the scratch clone) with hooks disabled, and a short appended system prompt that names the `shipledger` binary, gives the skill's CLI range and asks for a compact report. To re-record, see [docs/record-agent-demo.sh](docs/record-agent-demo.sh)._

## Run it

Shipledger is not on npm yet. Build it, then point it at this clone.

```bash
git clone https://github.com/kacxx/shipledger.git
cd shipledger && npm ci && npm run build
cd ..

git clone https://github.com/kacxx/shipledger-demo.git
cd shipledger-demo

node ../shipledger/packages/cli/dist/cli/index.js check \
  --config shipledger.config.json \
  --changeset changesets/v0.2.0.json

node ../shipledger/packages/cli/dist/cli/index.js check \
  --config shipledger.config.json \
  --changeset changesets/v0.3.0.json
```
