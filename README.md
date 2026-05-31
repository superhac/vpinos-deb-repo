# vpinos-deb-repo

This repository builds Debian packages for VPINOS-related projects and publishes
the `.deb` files as GitHub Release assets.

The current packages are:

- `vpinball`, built from [`vpinball/vpinball`](https://github.com/vpinball/vpinball)
- `vpinfe`, repackaged from [`superhac/vpinfe`](https://github.com/superhac/vpinfe)
  release assets

GitHub rejects normal git files larger than 100 MB, while GitHub Release assets
can be much larger. The workflow therefore uploads `.deb` files to a release
instead of committing them to `pool/`.

## Build Packages

Run the `Build Debian packages` workflow from the GitHub Actions tab. Each run
builds both `vpinball` and `vpinfe`.

## vpinball

The `vpinball` job:

1. checks out `https://github.com/vpinball/vpinball.git`,
2. builds the Linux x64 BGFX standalone player,
3. creates a `vpinball` Debian package,
4. writes it to `dist/`,
5. generates a `.sha256` checksum sidecar, and
6. uploads the `.deb` and checksum sidecar to the selected GitHub Release.

The workflow accepts a branch, tag, or commit SHA in `vpinball_ref`.

## vpinfe

The `vpinfe` job:

1. reads the selected release from `https://github.com/superhac/vpinfe`,
2. downloads the selected Linux release zip and `checksums.txt`,
3. verifies the zip SHA256,
4. creates a `vpinfe` Debian package,
5. writes it to `dist/`,
6. generates a `.sha256` checksum sidecar, and
7. uploads the `.deb` and checksum sidecar to the selected GitHub Release.

The default package uses the full `linux-x64` VPinFE release asset. Slim and
ARM64 release assets are also available as workflow inputs.

## Releases

The workflow uploads to the `vpinos-debs` GitHub Release by default. You can
override the release tag when manually starting it.

The uploaded checksum sidecars can be used to verify downloads:

```bash
sha256sum -c vpinball_*.deb.sha256
sha256sum -c vpinfe_*.deb.sha256
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
