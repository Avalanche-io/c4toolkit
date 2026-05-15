# C4 Toolkit — the ONE place releases happen

**This repository is the authoritative release coordinator for the C4
ecosystem.** Every release of every component ships together as a
single suite version, driven by `releases.json` and the scripts in
`scripts/`. Do NOT release components individually — the suite ships
together, or it doesn't ship.

For coordination workflow + lessons learned across releases, see the
workspace-level `/Users/joshua/ws/active/c4/RELEASE.md`.

## Suite Version 1.0.13

| Component | Version | Language | Install |
|-----------|---------|----------|---------|
| [c4](https://github.com/Avalanche-io/c4) | 1.0.13 | Go | `brew install mrjoshuak/tap/c4` or binary download |
| [c4sh](https://github.com/Avalanche-io/c4sh) | 1.0.13 | Go | included in Homebrew formula |
| [c4git](https://github.com/Avalanche-io/c4git) | 1.0.13 | Go | included in Homebrew formula |
| [c4py](https://github.com/Avalanche-io/c4py) | 1.0.13 | Python | `pip install c4py` |
| [c4ts](https://github.com/Avalanche-io/c4ts) | 1.0.13 | TypeScript | `npm install @avalanche-io/c4` |
| [c4-swift](https://github.com/Avalanche-io/c4-swift) | 1.0.13 | Swift | SPM: `from: "1.0.13"` |
| [libc4](https://github.com/Avalanche-io/libc4) | 1.0.13 | C | build from source |
| [c4-containers](https://github.com/Avalanche-io/c4-containers) | 1.0.13 | Docker | `ghcr.io/avalanche-io/c4` |

## How it works

Each component has its own version. A suite release bundles specific component versions that are tested together. The version matrix lives in `releases.json`.

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

Installs c4, c4sh, and c4git. Updated each suite release.

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
.package(url: "https://github.com/Avalanche-io/c4-swift.git", from: "1.0.12")
```

### Containers

```bash
docker pull ghcr.io/avalanche-io/c4:1.0.12
docker pull ghcr.io/avalanche-io/c4-pipeline:1.0.12
docker pull ghcr.io/avalanche-io/c4-s3worker:1.0.12
```

## Adding a new suite release

The full process is documented at workspace-level
`/Users/joshua/ws/active/c4/RELEASE.md`. Summary:

1. Per-component bump + tag + push for all 8 repos (use the iTerm-tabs
   pattern at `/Users/joshua/ws/active/c4/docs/agent-team-iterm-pattern.md`
   for parallel execution).
2. Edit `releases.json` — add a new version entry with updated component
   versions; set `"latest"` to the new version.
3. `./scripts/validate.sh <version>` — verify tags exist + tests pass.
4. `./scripts/build.sh <version>` — produces archives in `dist/<version>/`.
5. `gh release create v<version> dist/<version>/*` — uploads to the
   c4toolkit GitHub releases page.
6. `./scripts/homebrew.sh <version>` — regenerates `homebrew/c4.rb`.
7. Copy that formula to `mrjoshuak/homebrew-tap/Formula/c4.rb`, commit
   `Update c4 formula to v<version>`, push.
8. Verify with the commands in workspace-level `RELEASE.md`.

PyPI (`c4py`) and npm (`@avalanche-io/c4`, `@avalanche-io/c4-node`)
publishes are done as part of step 1 (the per-component flow), not in
the c4toolkit run. c4-containers Docker images are built by that
repo's CI on tag.

## Per-release coordination homes

Each release keeps its working specs, module briefings, friction
reports, and iTerm-tab orchestration scripts at
`/Users/joshua/ws/active/c4/release-vX.Y.Z/`. Look at the most recent
one for the actual templates the next release will reuse.

## License

Apache 2.0
