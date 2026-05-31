# vpinos-deb-repo

This repository is laid out as a small APT repository for VPINOS packages.
The first packages are `vpinball`, built from the upstream
[`vpinball/vpinball`](https://github.com/vpinball/vpinball) repository, and
`vpinfe`, repackaged from upstream
[`superhac/vpinfe`](https://github.com/superhac/vpinfe) release assets.

## Repository layout

```text
pool/main/v/vpinball/                 Built vpinball .deb packages
pool/main/v/vpinfe/                   Built vpinfe .deb packages
repo/dists/trixie/main/binary-amd64/  APT Packages indexes
repo/dists/trixie/Release             APT Release metadata
repo/vpinos-archive-keyring.asc       Public signing key after generation
```

## Build vpinball

Run the `Build vpinball package` workflow from the GitHub Actions tab. The
workflow:

1. checks out `https://github.com/vpinball/vpinball.git`,
2. builds the Linux x64 BGFX standalone player,
3. creates a `vpinball` Debian package,
4. writes it to `pool/main/v/vpinball`,
5. regenerates the APT metadata under `repo/dists/trixie`,
6. signs the repository metadata with `APT_SIGNING_KEY`, and
7. commits the package and metadata back to this repository.

The workflow accepts a branch, tag, or commit SHA in `vpinball_ref`.

## Build vpinfe

Run the `Build vpinfe package` workflow from the GitHub Actions tab. The
workflow:

1. reads the latest release from `https://github.com/superhac/vpinfe`,
2. downloads the selected Linux release zip and `checksums.txt`,
3. verifies the zip SHA256,
4. creates a `vpinfe` Debian package,
5. writes it to `pool/main/v/vpinfe`,
6. regenerates the APT metadata under `repo/dists/trixie`,
7. signs the repository metadata with `APT_SIGNING_KEY`, and
8. commits the package and metadata back to this repository.

The default package uses the full `linux-x64` release asset. The workflow also
supports `linux-x64-slim`, `linux-arm64`, and `linux-arm64-slim`.

## Generate the repository signing key

Create a repository signing key locally:

```bash
scripts/generate-repo-key.sh
```

This writes:

```text
repo/vpinos-archive-keyring.asc
.secrets/vpinos-archive-signing-key.asc
```

Commit the public key at `repo/vpinos-archive-keyring.asc`. Add the private key
file contents to the GitHub repository secret named `APT_SIGNING_KEY`.

The generated key is intentionally unencrypted so the GitHub workflow can sign
non-interactively. Keep `.secrets/vpinos-archive-signing-key.asc` private.

## Update metadata locally

After adding or removing packages in `pool`, regenerate the APT metadata with:

```bash
sudo apt-get install apt-utils dpkg-dev gnupg
scripts/update-apt-repo.sh
```

To sign with a local key:

```bash
GPG_KEY_ID=<fingerprint-or-key-id> scripts/update-apt-repo.sh
```

## Client usage

After the repository is published, clients can install the public key and add an
APT source that points at the `repo` directory as served by GitHub Pages or your
web server.

For example, if this repository is served at
`https://superhac.github.io/vpinos-deb-repo/repo`:

```bash
curl -fsSL https://superhac.github.io/vpinos-deb-repo/repo/vpinos-archive-keyring.asc |
  sudo tee /etc/apt/keyrings/vpinos-archive-keyring.asc >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/vpinos-archive-keyring.asc] https://superhac.github.io/vpinos-deb-repo/repo trixie main" |
  sudo tee /etc/apt/sources.list.d/vpinos.list
sudo apt update
sudo apt install vpinball
```
