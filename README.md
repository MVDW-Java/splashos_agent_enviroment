# SplashOS Agent Environment

This repository is the working environment for building [SplashOS](https://github.com/MVDW-Java/SplashOS), a modern Linux distribution aimed at non-technical users. It ties together the individual SplashOS tooling repositories, which are checked out here as symlinks.

| Folder | Description |
| --- | --- |
| [`BuildScripts`](./BuildScripts) | Build scripts for [SourceStream](./SourceStream). Contains one script per core package (glibc, gcc, bash, coreutils, systemd, linux, grub, etc.) used to build the base system. |
| [`SourceStream`](./SourceStream) | A tool to repack core packages for SplashOS. Downloads and prepares upstream sources based on an edition/version defined in `config.yml`, and can push the resulting packages to an output directory or an SFTP server. Run with `python3 run.py`. |
| [`SplashBuilder`](./SplashBuilder) | The main build tool for SplashOS. Prepares the build environment, builds the core system inside a chroot, and assembles the final distribution. Run with `./run.sh`. |
| [`configuration`](./configuration) | The SplashOS configuration files, including `upstream-sources.yml` (upstream package sources), `LFS-mapping.json` (Linux From Scratch package mapping), and per-edition package lists under `edition-packages/`. |

> **Agents:** see [AGENTS.md](./AGENTS.md) for how this environment works, the per-repo commit rules, and toolchain conventions before making changes.
