#!/usr/bin/env bash
set -euo pipefail

suite="${SUITE:-trixie}"
component="${COMPONENT:-main}"
origin="${ORIGIN:-VPINOS}"
label="${LABEL:-VPINOS Debian Repository}"
description="${DESCRIPTION:-VPINOS Debian package repository}"
repo_root="${REPO_ROOT:-repo}"
pool_root="${POOL_ROOT:-pool}"

command -v apt-ftparchive >/dev/null || {
  echo "apt-ftparchive is required. Install apt-utils." >&2
  exit 1
}
command -v dpkg-scanpackages >/dev/null || {
  echo "dpkg-scanpackages is required. Install dpkg-dev." >&2
  exit 1
}

mapfile -t architectures < <(
  find "$pool_root" -type f -name '*.deb' -print0 |
    xargs -0 -r dpkg-deb -f 2>/dev/null |
    awk '/^Architecture: / {print $2}' |
    sort -u
)

if [[ "${#architectures[@]}" -eq 0 ]]; then
  architectures=(amd64)
fi

dist_dir="$repo_root/dists/$suite"
mkdir -p "$dist_dir/$component"

for arch in "${architectures[@]}"; do
  binary_dir="$dist_dir/$component/binary-$arch"
  mkdir -p "$binary_dir"
  dpkg-scanpackages --arch "$arch" "$pool_root" /dev/null > "$binary_dir/Packages"
  gzip -9fk "$binary_dir/Packages"
done

arch_list="$(printf '%s ' "${architectures[@]}" | sed 's/ $//')"
release_conf="$(mktemp)"
cat > "$release_conf" <<CONF
APT::FTPArchive::Release::Origin "$origin";
APT::FTPArchive::Release::Label "$label";
APT::FTPArchive::Release::Suite "$suite";
APT::FTPArchive::Release::Codename "$suite";
APT::FTPArchive::Release::Architectures "$arch_list";
APT::FTPArchive::Release::Components "$component";
APT::FTPArchive::Release::Description "$description";
CONF

apt-ftparchive -c "$release_conf" release "$dist_dir" > "$dist_dir/Release"
rm -f "$release_conf"

if [[ -n "${GPG_KEY_ID:-}" ]]; then
  gpg --batch --yes --pinentry-mode loopback --default-key "$GPG_KEY_ID" \
    --output "$dist_dir/InRelease" \
    --clearsign "$dist_dir/Release"
  gpg --batch --yes --pinentry-mode loopback --default-key "$GPG_KEY_ID" \
    --output "$dist_dir/Release.gpg" \
    --detach-sign "$dist_dir/Release"
elif [[ "${SIGN_REPO:-}" == "1" ]]; then
  gpg --batch --yes --pinentry-mode loopback \
    --output "$dist_dir/InRelease" \
    --clearsign "$dist_dir/Release"
  gpg --batch --yes --pinentry-mode loopback \
    --output "$dist_dir/Release.gpg" \
    --detach-sign "$dist_dir/Release"
else
  rm -f "$dist_dir/InRelease" "$dist_dir/Release.gpg"
fi

echo "Updated $dist_dir for architectures: $arch_list"
