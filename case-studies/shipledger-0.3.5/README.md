# Case study: shipledger on its own 0.3.5 release

This runs shipledger 0.3.5 on its own release, `v0.3.4..v0.3.5` in
[kacxx/shipledger](https://github.com/kacxx/shipledger). The claim comes from
the [v0.3.5 GitHub release](https://github.com/kacxx/shipledger/releases/tag/v0.3.5),
which release-please generated.

## First run: the notes alone

The release notes list two PRs, #53 and #49. `changeset.notes-only.json` claims
those two.

```
FAIL  v0.3.5 release notes  unknown-reference=2; items linked 2/2, commits 5, ignored 1
  unknown-reference  shipledger 2eb8da4  ci: list build commits in the release changelog (#51)
  unknown-reference  shipledger bfe111a  docs: explain forcing a release with Release-As (#50)
```

Both claimed PRs link to their commits, and `github-oss@3` ignores the release
commit (#52). But #50 and #51 were merged in the range and aren't in the notes.

## Why they're missing

shipledger's `release-please-config.json` marks the `docs` and `ci` sections
`"hidden": true`, so release-please left #50 and #51 out of the notes on purpose.
The finding is correct: the claim was incomplete, not the release.

Ignoring `docs:` and `ci:` commits would make the failure go away, but a subject
can't show that a PR changes no output. The skill instead checks each PR:

- #50 (`docs`) changes only `AGENTS.md`.
- #51 (`ci`) changes `AGENTS.md` and `release-please-config.json`.

Neither touches `packages/cli`, so both are claim hygiene, not missing work.

## Second run: notes plus hidden sections

`changeset.json` adds #50 and #51 as items.

```
PASS  v0.3.5 release notes + hidden sections  items linked 4/4, commits 5, ignored 1
```

`render report --verify-against-repos` re-derives the artifact from git and
passes too.

This run led to the skill's guidance on claims built from generated release
notes ([kacxx/shipledger#54](https://github.com/kacxx/shipledger/pull/54)).

## Run it

Clone shipledger with full history next to this repository. A shallow clone
can't walk the range, and `check` exits 3 and says so.

```bash
git clone https://github.com/kacxx/shipledger.git
cd shipledger-demo/case-studies/shipledger-0.3.5

npx shipledger@0.3.5 check --config shipledger.config.json --changeset changeset.notes-only.json
npx shipledger@0.3.5 check --config shipledger.config.json --changeset changeset.json
```

Use 0.3.5: the config fingerprint includes the CLI version, so this pins the
output shown above.
