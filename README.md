# C4 Toolkit — the ONE place releases happen

**This repository is the authoritative release coordinator for the C4
ecosystem.** Every release of every component ships together as a
single suite version, driven by `releases.json` and the scripts in
`scripts/`. Do NOT release components individually — the suite ships
together, or it doesn't ship.

The maintainers' coordination runbook and the lessons learned across
releases are kept outside this repository.

## Suite Version 1.0.26

| Component | Version | Language | Install |
|-----------|---------|----------|---------|
| [c4](https://github.com/Avalanche-io/c4) | 1.0.26 | Go | `brew install mrjoshuak/tap/c4` or binary download |
| [c4sh](https://github.com/Avalanche-io/c4sh) | 1.0.26 | Go | included in Homebrew formula |
| [c4git](https://github.com/Avalanche-io/c4git) | 1.0.26 | Go | included in Homebrew formula |
| [c4py](https://github.com/Avalanche-io/c4py) | 1.0.26 | Python | `pip install c4py` |
| [c4ts](https://github.com/Avalanche-io/c4ts) | 1.0.26 | TypeScript | `npm install @avalanche-io/c4` |
| [c4-swift](https://github.com/Avalanche-io/c4-swift) | 1.0.26 | Swift | SPM: `from: "1.0.26"` |
| [libc4](https://github.com/Avalanche-io/libc4) | 1.0.26 | C | build from source |
| [c4-containers](https://github.com/Avalanche-io/c4-containers) | 1.0.26 | Docker | `ghcr.io/avalanche-io/c4` |

Three more components are built from [c4-operator](https://github.com/Avalanche-io/c4-operator)
at its pinned tag (v0.2.2 in suite 1.0.26) and ship in the suite archives:
`c4-farm` and `c4-unit` (all platforms) and `c4-agent` (macOS and Linux).
`c4 farm ...` runs `c4-farm`.

## How it works

Each component has its own version. A suite release bundles specific component versions that are tested together. The version matrix lives in `releases.json`.

## Versioning policy (permanent)

- **The major is frozen at 1 — there will be no v2.** Go's import
  rules make v2+ a repo-wide import-path migration (`/v2` suffix on
  the core module and every dependent). That cost is never paid.
  Consequently the Go module API must stay backward-compatible at all
  times.
- **Minor = the contract moved.** Under a frozen major, a minor
  release is this suite's major: anything that breaks the CLI machine
  contract, changes defaults, removes or repurposes flags or verbs,
  or changes what existing commands print ships ONLY in a minor,
  flagged in the changelog with migration notes.
- **Patch = compatible.** Fixes and strictly additive changes only.
  A patch must be safe to auto-upgrade blind (`brew upgrade`); it
  must never break a script.
- Version numbers are contract signals, not launch vehicles: product
  or marketing milestones are not reserved a number in advance — they
  take whatever minor is next when they land.

```bash
# Validate all components are tagged and tests pass
./scripts/validate.sh 1.0.12

# Build Go binaries for all platforms
./scripts/build.sh 1.0.12

# Generate Homebrew formula
./scripts/homebrew.sh 1.0.12

# Full release: validate + build + publish + GitHub release
./scripts/release.sh 1.0.12
```

## Distribution

### Homebrew (macOS / Linux)

```bash
brew install mrjoshuak/tap/c4
```

One formula: c4, c4sh and c4git from the suite bundle, plus c4-farm,
c4-agent and c4-unit as resources fetched from the c4-operator release
the suite pins, so `c4 farm` works after the one install. No in-tap
`depends_on`: Homebrew 6 trusts only the formula named on the command
line. Updated each suite release. The tap stays
`mrjoshuak/homebrew-tap` until Avalanche-io is tied into the service
offering (Joshua, 2026-10-21).

### Binary downloads

Platform archives on the [Releases](https://github.com/Avalanche-io/c4toolkit/releases) page:

| Platform | Archive |
|----------|---------|
| macOS arm64 | `c4-suite_vX.Y.Z_darwin_arm64.tar.gz` |
| macOS amd64 | `c4-suite_vX.Y.Z_darwin_amd64.tar.gz` |
| Linux arm64 | `c4-suite_vX.Y.Z_linux_arm64.tar.gz` |
| Linux amd64 | `c4-suite_vX.Y.Z_linux_amd64.tar.gz` |
| Windows amd64 | `c4-suite_vX.Y.Z_windows_amd64.zip` |
| Windows arm64 | `c4-suite_vX.Y.Z_windows_arm64.zip` |

Individual tool archives also available (e.g., `c4_v1.0.12_darwin_arm64.tar.gz`).

### Package managers

```bash
pip install c4py                    # Python
npm install @avalanche-io/c4        # TypeScript (browser + Node)
npm install @avalanche-io/c4-node   # TypeScript (Node extensions)
```

```swift
// Swift Package Manager
.package(url: "https://github.com/Avalanche-io/c4-swift.git", from: "1.0.26")
```

### Containers

```bash
docker pull ghcr.io/avalanche-io/c4:v1.0.26
docker pull ghcr.io/avalanche-io/c4-pipeline:v1.0.26
docker pull ghcr.io/avalanche-io/c4-s3worker:v1.0.26
```

## Adding a new suite release

The full process is in the maintainers' runbook, outside this repository.
Summary:

1. Per-component bump and push for all 8 repos, then
   `./scripts/gate.sh <component> <version> <checkout>` on the exact commit
   to be tagged, then the tag and its push. The gate checks that the tree is
   clean and pushed, CI is green for that commit (c4-containers'
   images build on the tag instead), every version site says the
   version, a Go tool's binary reports it, go.mod has no `replace`, no
   session names are in tracked text, and the tag is free. Nothing is tagged
   or published for a component until its gate passes.
2. Edit `releases.json` — add a new version entry with updated component
   versions; set `"latest"` to the new version.
   **Make the notes public text before anything else.** The `notes` become
   the GitHub release body word for word, so strip the draft's working
   notes: the "Held for Joshua" list, any "while Joshua rules" asides, any
   person named, what is "still to come", and the `"status": "draft…"`
   field. `./scripts/release.sh <version> --dry-run` refuses until they are
   gone (Step 0); run it even when publishing by hand with step 5.
3. `./scripts/validate.sh <version>` — verify tags exist + tests pass.
4. `./scripts/build.sh <version>` — produces archives in `dist/<version>/`.
5. `gh release create v<version> dist/<version>/*` — uploads to the
   c4toolkit GitHub releases page.
6. `./scripts/homebrew.sh <version>` — regenerates `homebrew/c4.rb`.
7. Copy that formula to `mrjoshuak/homebrew-tap/Formula/c4.rb`, commit
   `Update c4 formula to v<version>`, push. The c4 formula brings c4-farm,
   c4-agent and c4-unit itself. The tap's separate `c4-farm` and `c4-agent`
   formulas are deprecated (since 2026-10-26, pointing at
   `brew install mrjoshuak/tap/c4`) and stay at 0.2.1, so there is nothing
   to copy for them. `./scripts/farm-formulas.sh <operator-version>` still
   generates them, deprecated, should they need regenerating.
8. Verify the published release with the maintainers' runbook checks.

PyPI (`c4py`) and npm (`@avalanche-io/c4`, `@avalanche-io/c4-node`)
publishes are done as part of step 1 (the per-component flow), not in
the c4toolkit run. c4-containers Docker images are built by that
repo's CI on tag.

Two things learned releasing 1.0.24 right after a reboot (2026-11-07):

- **npm after a reboot: log in first.** The web-login token in
  `~/.npmrc` did not survive the restart: `npm whoami` returned 401 and
  `pnpm publish` failed with a misleading E404 ("could not be found or
  you do not have permission"). Run `npm login --auth-type=web`, open the
  link it prints, then publish; each publish still asks for one browser
  approval of its own.
- **Run publishes in the background and read their output afterwards.**
  A publish piped through `head` was killed by SIGPIPE while polling for
  its browser approval, and the attempt was lost. Start the publish as a
  background task, pick the authorization link out of its output file,
  and read the result when it exits; never put a filter on its pipe.

## Per-release coordination homes

Each release keeps its working specs, module briefings and friction
reports in the maintainers' workspace, outside this repository.

## License

Apache 2.0
