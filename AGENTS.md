# AGENTS.md — SplashOS Agent Environment

This repository is **not a normal source tree**. It is an isolated working
environment that gives coding agents access to the individual SplashOS
repositories through symlinks. Read this file before making changes.

## How the environment works

- The four top-level directories — `BuildScripts`, `SourceStream`,
  `SplashBuilder` and `configuration` — are **symlinks** to independent git
  checkouts in `~/Documents/GitHub/` (e.g.
  `BuildScripts -> ~/Documents/GitHub/BuildScripts`).
- Each symlinked directory is its **own git repository** with its own history
  and remotes. This repo (`splashos_agent_enviroment`) only tracks
  `README.md`, `AGENTS.md` and `.gitattributes`.
- Consequence for agents: **commits and branches are per-repo.** A change made
  through `BuildScripts/...` must be committed inside
  `~/Documents/GitHub/BuildScripts`, not in this repo. Never `git add` the
  symlinks here.
- The symlinks are the mechanism that keeps agents sandboxed to exactly the
  repos they need; do not replace them with copies or move them.

## The toolchain and how the pieces fit

```
SourceStream  ──uses──▶  configuration/  ◀──uses──  SplashBuilder
     │                        │                         │
     ▼                        ▼                         ▼
 downloads & repacks     upstream-sources.yml,     builds the core system
 core package sources    LFS-mapping.json,         in a chroot and assembles
 (using BuildScripts)    edition-packages/         the final image
```

1. **SourceStream** (`python3 run.py`) downloads and repacks upstream package
   sources. It reads `SourceStream/config.yml` to decide which **edition** and
   **version** of the configuration to use, and fetches the matching files
   from `configuration/`.
2. **configuration** supplies the shared, versioned configuration:
   - `upstream-sources.yml` — download URL template per package.
   - `LFS-mapping.json` — maps Linux From Scratch book package names
     (Title Case, e.g. `Util-linux`) to the lowercase keys used everywhere
     else (e.g. `util_linux`).
   - `edition-packages/<version>/<edition>.yml` — per-edition package lists
     (pinned versions) plus the full build task list.
3. **BuildScripts** contains one build script per core package (glibc, gcc,
   bash, coreutils, systemd, linux, grub, …). SourceStream/SplashBuilder
   invoke these; they are written against the package versions pinned in the
   edition files.
4. **SplashBuilder** (`./run.sh`) prepares the build environment, builds the
   core system inside a chroot and assembles the final distribution (ISO by
   default).

## Key conventions and gotchas

- **Versions are not pinned in `upstream-sources.yml`.** URLs are templates
  with placeholders substituted at runtime:
  - `{VERSION}`, `{VERSION_MAJOR}`, `{VERSION_MINOR}`
  - `{VERSION_SEPARATE_UNDERSCORE}` (e.g. `2.8.3` → `2_8_3`, used by expat)
  - `{PACKAGE}` (used by expect)
  - `subdir: true` means "extract into the standard `<name>-<VERSION>` dir";
    otherwise it is an explicit subdir template or `false`.
- **The LFS baseline is currently split**: `upstream-sources.yml` URLs are
  aligned with the latest stable **LFS 13.1-systemd** book, while the pinned
  versions in `configuration/edition-packages/0.0.1-dev/molecule.yml` are
  from the **LFS 12.1-systemd** era (systemd 255, glibc 2.39, GCC 13.2,
  kernel 6.7.4). Do not bump pinned versions without also updating
  BuildScripts — e.g. Python ≥3.13 needs `mpdecimal` (no BuildScript exists),
  and OpenSSL 4.x / GCC 16 are breaking major bumps.
- Packages may exist in `upstream-sources.yml` without being in an edition
  file (e.g. `lz4`, `mpdecimal`, `pcre2`, `sqlite`, `sysklogd`, SplashOS
  extras like `yq` and `zed`). That is intentional; they have no build tasks.
- `SourceStream/config.yml`:
  - `update-sources: true` re-downloads `upstream-sources.yml` from the
    official source; a `.lock-sources` file in the SourceStream root disables
    this and freezes updates.
  - `update-edition: false` — edition files are not auto-updated.
  - `edition: custom` downloads nothing; the edition file must be created
    manually.
- `SplashBuilder/config.yml` controls the build: release metadata
  (`release_name/version/codename/cycle`), build location
  (`path_type: directory|partition`, `path_build`), output
  (`output_filetype: iso|vmdk|vdi|qcow2`), and `build_edition`
  (`molecule` = minimal base/IoT, `desktop` = GNOME for end users).
- Editions: `molecule` is the base for all other editions; `desktop` and
  `server` build on top of it.

## Validation

- YAML/JSON config changes: parse-check with
  `python3 -c "import yaml; yaml.safe_load(open('<file>'))"` (or `json.load`).
- URL changes: verify with
  `curl -s -o /dev/null -w "%{http_code}" -L "<url>"` (expect 200).
- Full builds require root and a dedicated partition/directory
  (`path_build`, default `/mnt/splashos`) — do not run casually.
