# shipledger-demo

Shipledger checks a release you wrote against local git. It walks the commit
range between two tags and reconciles what it finds against the items you
claimed in a changeset file. It does not call GitHub — everything runs locally
against the repository on disk.

This repository has two releases whose notes were typed by a human, not
generated:

- **v0.2.0** lists #1 (Add widget) and #2 (Handle empty input). Both commits
  appear in the `v0.1.0..v0.2.0` range, so the check passes.

- **v0.3.0** lists only #3 (Export a report). The tag also contains #4 (retry
  on timeout), which the notes do not mention. The check fails with an
  `unknown-reference` finding for the unlisted commit.

## Running the checks

```bash
npx shipledger check --config shipledger.config.json --changeset changesets/v0.2.0.json --out verified-v0.2.0.json
# exit 0 — pass

npx shipledger check --config shipledger.config.json --changeset changesets/v0.3.0.json --out verified-v0.3.0.json
# exit 1 — fail (unknown-reference: #4)
```
