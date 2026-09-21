# vpinos-deb-repo

This repository builds Debian packages for VPINOS-related projects and publishes
the `.deb` files as GitHub Release assets.

The current packages are:

- `vpinball`, built from [`vpinball/vpinball`](https://github.com/vpinball/vpinball)
- `vpinfe`, repackaged from [`superhac/vpinfe`](https://github.com/superhac/vpinfe)
  release assets
- `vpinconfig`, repackaged from [`superhac/vpxconfig`](https://github.com/superhac/vpxconfig)
  release assets (amd64 only)

GitHub rejects normal git files larger than 100 MB, while GitHub Release assets
can be much larger. The workflow therefore uploads `.deb` files to a release
instead of committing them to `pool/`.

## Installing with apt

End users should install through the signed apt repository published from these
builds, not by downloading `.deb` files from releases. See
[`superhac/vpinos-repo`](https://github.com/superhac/vpinos-repo) for the
instructions.

## Build Packages

Run the `Build Debian packages` workflow from the GitHub Actions tab. Each run
builds `vpinball`, `vpinfe` and `vpinconfig`.

## vpinball

The `vpinball` job:

1. checks out `https://github.com/vpinball/vpinball.git`,
2. builds the Linux x64 BGFX standalone player,
3. creates a `vpinball` Debian package,
4. writes it to `dist/`,
5. generates a `.sha256` checksum sidecar, and
6. uploads the `.deb` and checksum sidecar to the selected GitHub Release.

The workflow accepts a branch, tag, or commit SHA in `vpinball_ref`.

The package version is `<base>.<UTC commit date and time>-<revision>`, e.g.
`10.9.202609191430-1`. The base defaults to `10.9` and can be changed with
`VPINBALL_BASE_VERSION`. The timestamp is `YYYYMMDDHHMM` from the built commit,
so versions increase with upstream commits. Bump `package_revision` only to
repackage the same commit.

## vpinfe

The `vpinfe` job:

1. reads the selected release from `https://github.com/superhac/vpinfe`,
2. downloads the selected slim Linux release zip and `checksums.txt`,
3. verifies the zip SHA256,
4. creates a `vpinfe` Debian package,
5. writes it to `dist/`,
6. generates a `.sha256` checksum sidecar, and
7. uploads the `.deb` and checksum sidecar to the selected GitHub Release.

Only the slim VPinFE release assets are packaged. The default is
`linux-x64-slim`; `linux-arm64-slim` is available as a workflow input.

## vpinconfig

The `vpinconfig` job:

1. reads the selected release from `https://github.com/superhac/vpxconfig`
   (`vpinconfig_version`, default `latest`),
2. downloads the single-file `vpinconfig` executable and its `.sha256`,
3. verifies the checksum,
4. creates an amd64 `vpinconfig` Debian package that installs the executable
   to `/usr/bin/vpinconfig`,
5. writes it to `dist/`,
6. generates a `.sha256` checksum sidecar, and
7. uploads the `.deb` and checksum sidecar to the selected GitHub Release.

The package version is the upstream release tag, e.g. `0.5.2-1`.

## Releases

Each workflow run creates a brand-new GitHub Release, tagged
`<release_tag>-<run number>` (e.g. `vpinos-debs-42`), instead of reusing or
adding to a previous release. Override `release_tag` to change the base
name used for that run's release.

The uploaded checksum sidecars can be used to verify downloads:

```bash
sha256sum -c vpinball_*.deb.sha256
sha256sum -c vpinfe_*.deb.sha256
sha256sum -c vpinconfig_*.deb.sha256
```

## Local Builds

Build VPinball locally:

```bash
sudo apt-get install build-essential cmake git dpkg-dev
OUTDIR="$PWD/dist" scripts/build-vpinball-deb.sh
```

Build VPinFE locally:

```bash
sudo apt-get install curl dpkg-dev jq unzip
OUTDIR="$PWD/dist" scripts/build-vpinfe-deb.sh
```

Build VPinConfig locally:

```bash
sudo apt-get install curl dpkg-dev jq
OUTDIR="$PWD/dist" scripts/build-vpinconfig-deb.sh
```
