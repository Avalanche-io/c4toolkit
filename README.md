# C4 Toolkit

Coordinated release infrastructure for the C4 ecosystem. Every component ships together under a single suite version.

## Suite Version 1.0.10

| Component | Version | Language | Install |
|-----------|---------|----------|---------|
| [c4](https://github.com/Avalanche-io/c4) | 1.0.10 | Go | `brew install mrjoshuak/tap/c4` or binary download |
| [c4sh](https://github.com/Avalanche-io/c4sh) | 1.0.10 | Go | included in Homebrew formula |
| [c4git](https://github.com/Avalanche-io/c4git) | 1.0.0 | Go | included in Homebrew formula |
| [c4py](https://github.com/Avalanche-io/c4py) | 1.0.0 | Python | `pip install c4py` |
| [c4ts](https://github.com/Avalanche-io/c4ts) | 1.0.10 | TypeScript | `npm install @avalanche-io/c4` |
| [c4-swift](https://github.com/Avalanche-io/c4-swift) | 1.0.10 | Swift | SPM: `from: "1.0.10"` |
| [libc4](https://github.com/Avalanche-io/libc4) | 0.1.0 | C | build from source |
| [c4-containers](https://github.com/Avalanche-io/c4-containers) | 1.0.10 | Docker | `ghcr.io/avalanche-io/c4` |

## How it works

Each component has its own version. A suite release bundles specific component versions that are tested together. The version matrix lives in `releases.json`.

```bash
# Validate all components are tagged and tests pass
./scripts/validate.sh 1.0.10

# Build Go binaries for all platforms
./scripts/build.sh 1.0.10

# Generate Homebrew formula
./scripts/homebrew.sh 1.0.10

# Full release: validate + build + publish + GitHub release
./scripts/release.sh 1.0.10
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

Individual tool archives also available (e.g., `c4_v1.0.10_darwin_arm64.tar.gz`).

### Package managers

```bash
pip install c4py                    # Python
npm install @avalanche-io/c4        # TypeScript (browser + Node)
npm install @avalanche-io/c4-node   # TypeScript (Node extensions)
```

```swift
// Swift Package Manager
.package(url: "https://github.com/Avalanche-io/c4-swift.git", from: "1.0.10")
```

### Containers

```bash
docker pull ghcr.io/avalanche-io/c4:1.0.10
docker pull ghcr.io/avalanche-io/c4-pipeline:1.0.10
docker pull ghcr.io/avalanche-io/c4-s3worker:1.0.10
```

## Adding a new suite release

1. Edit `releases.json` — add a new version entry with updated component versions
2. Ensure all component repos are tagged
3. Run `./scripts/validate.sh <version>` to verify
4. Run `./scripts/release.sh <version>` to build and publish

## License

Apache 2.0
