#!/usr/bin/env bash
set -euo pipefail

repo="${VPXCONFIG_REPO:-superhac/vpxconfig}"
version="${VPXCONFIG_VERSION:-latest}"
revision="${PACKAGE_REVISION:-1}"
workdir="${WORKDIR:-$PWD/.build/vpxconfig}"
outdir="${OUTDIR:-$PWD/dist}"
arch="amd64"
asset_name="vpxconfig"

command -v curl >/dev/null || { echo "curl is required." >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required." >&2; exit 1; }

rm -rf "$workdir"
mkdir -p "$workdir" "$outdir"

api_base="https://api.github.com/repos/$repo"
curl_args=(-fsSL)
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  curl_args+=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

release_json="$workdir/release.json"
if [[ "$version" == "latest" ]]; then
  curl "${curl_args[@]}" "$api_base/releases/latest" > "$release_json"
  version="$(jq -r '.tag_name' "$release_json")"
else
  curl "${curl_args[@]}" "$api_base/releases/tags/$version" > "$release_json"
fi

asset_url() {
  jq -r --arg name "$1" '.assets[] | select(.name == $name) | .browser_download_url' "$release_json"
}

bin_url="$(asset_url "$asset_name")"
sum_url="$(asset_url "$asset_name.sha256")"
if [[ -z "$bin_url" || -z "$sum_url" ]]; then
  echo "Release $version of $repo is missing $asset_name or $asset_name.sha256." >&2
  exit 1
fi

curl "${curl_args[@]}" -o "$workdir/$asset_name" "$bin_url"
curl "${curl_args[@]}" -o "$workdir/$asset_name.sha256" "$sum_url"
(cd "$workdir" && sha256sum --check "$asset_name.sha256")

upstream_version="${version#v}"
upstream_version="$(printf '%s' "$upstream_version" | tr '_' '.' | sed -E 's/[^A-Za-z0-9.+:~]/./g')"
package_version="${upstream_version}-${revision}"

pkgroot="$workdir/pkgroot"
rm -rf "$pkgroot"
install -d "$pkgroot/DEBIAN" "$pkgroot/usr/bin"
install -m 0755 "$workdir/$asset_name" "$pkgroot/usr/bin/vpxconfig"

installed_size="$(du -sk "$pkgroot" | awk '{print $1}')"
cat > "$pkgroot/DEBIAN/control" <<CONTROL
Package: vpxconfig
Version: ${package_version}
Architecture: ${arch}
Maintainer: Superhac <superhac007@gmail.com>
Installed-Size: ${installed_size}
Depends: libc6, zlib1g
Section: utils
Priority: optional
Homepage: https://github.com/superhac/vpxconfig
Description: VPXConfig configuration tool for Visual Pinball
 VPXConfig is a configuration tool for Visual Pinball setups. It listens
 on 127.0.0.1:1111 by default (see --host and --port).
 This package installs the upstream single-file release executable.
CONTROL

deb_path="$outdir/vpxconfig_${package_version}_${arch}.deb"
dpkg-deb --build --root-owner-group "$pkgroot" "$deb_path"
echo "$deb_path"
