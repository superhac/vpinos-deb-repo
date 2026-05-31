#!/usr/bin/env bash
set -euo pipefail

repo_url="${VPINBALL_REPO_URL:-https://github.com/vpinball/vpinball.git}"
ref="${VPINBALL_REF:-master}"
revision="${PACKAGE_REVISION:-1}"
workdir="${WORKDIR:-$PWD/.build/vpinball}"
outdir="${OUTDIR:-$PWD/pool/main/v/vpinball}"
arch="${DEB_ARCH:-$(dpkg --print-architecture)}"

rm -rf "$workdir"
mkdir -p "$workdir" "$outdir"

git clone --recursive "$repo_url" "$workdir/src"
cd "$workdir/src"
git checkout "$ref"
git submodule update --init --recursive

short_sha="$(git rev-parse --short=12 HEAD)"
tag="$(git describe --tags --exact-match 2>/dev/null || true)"
if [[ "$tag" =~ ^v?[0-9] ]]; then
  upstream_version="${tag#v}"
else
  upstream_version="0.0~git$(date -u +%Y%m%d).${short_sha}"
fi
upstream_version="$(printf '%s' "$upstream_version" | tr '_' '.' | sed -E 's/[^A-Za-z0-9.+:~]/./g')"
package_version="${upstream_version}-${revision}"

platforms/linux-x64/external.sh
cp make/CMakeLists_bgfx-linux-x64.txt CMakeLists.txt
cmake -DCMAKE_BUILD_TYPE=Release -B build
cmake --build build --parallel "$(nproc)"

pkgroot="$workdir/pkgroot"
rm -rf "$pkgroot"
install -d "$pkgroot/DEBIAN" "$pkgroot/opt/vpinball" "$pkgroot/usr/bin" "$pkgroot/usr/share/applications"
install -m 0755 build/VPinballX_BGFX "$pkgroot/opt/vpinball/VPinballX_BGFX"

if [[ -d build/assets ]]; then
  cp -a build/assets "$pkgroot/opt/vpinball/assets"
elif [[ -d src/assets ]]; then
  cp -a src/assets "$pkgroot/opt/vpinball/assets"
fi

cat > "$pkgroot/usr/bin/vpinball" <<'LAUNCHER'
#!/usr/bin/env bash
set -euo pipefail
cd /opt/vpinball
exec ./VPinballX_BGFX "$@"
LAUNCHER
chmod 0755 "$pkgroot/usr/bin/vpinball"

cat > "$pkgroot/usr/share/applications/vpinball.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Visual Pinball X
Comment=Standalone Visual Pinball player
Exec=vpinball
Terminal=false
Categories=Game;Emulator;
DESKTOP

installed_size="$(du -sk "$pkgroot" | awk '{print $1}')"
cat > "$pkgroot/DEBIAN/control" <<CONTROL
Package: vpinball
Version: ${package_version}
Architecture: ${arch}
Maintainer: VPINOS <repo@vpinos.local>
Installed-Size: ${installed_size}
Depends: libc6, libstdc++6, zlib1g, libdrm2, libgbm1, libglu1-mesa | libglu1, libegl1, libgl1, libwayland-client0, libwayland-egl1, libudev1, libx11-6, libxcursor1, libxi6, libxss1, libxtst6, libxkbcommon0, libxrandr2, libasound2, libpipewire-0.3-0
Section: games
Priority: optional
Homepage: https://github.com/vpinball/vpinball
Description: Visual Pinball X standalone player
 Visual Pinball X is an open source pinball table editor and simulator.
 This package installs the standalone Linux BGFX player build from upstream.
CONTROL

deb_path="$outdir/vpinball_${package_version}_${arch}.deb"
dpkg-deb --build --root-owner-group "$pkgroot" "$deb_path"
echo "$deb_path"
