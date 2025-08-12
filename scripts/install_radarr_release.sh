#!/usr/bin/env bash
set -euo pipefail
ROOTFS="${1:-out/rootfs}"
if [ ! -d "$ROOTFS" ]; then
  echo "Usage: $0 <rootfs_dir>" >&2
  exit 1
fi

API_URL="https://api.github.com/repos/Radarr/Radarr/releases/latest"
echo "Fetching latest Radarr arm64 release URL..."
URL=$(curl -fsSL "$API_URL" \
  | jq -r '.assets[]? | select(.name|test("(?i)linux.*arm64.*\\.tar\\.gz$")) | .browser_download_url' \
  | head -n1)

if [ -z "${URL:-}" ]; then
  echo "Could not find arm64 tarball in latest release" >&2
  exit 2
fi
echo "Latest URL: $URL"

# Users, dirs, permissions
chroot "$ROOTFS" /bin/bash -lc 'groupadd -r media || true; useradd -r -s /usr/sbin/nologin -g media -d /var/lib/radarr radarr || true'
mkdir -p "$ROOTFS/opt/radarr" "$ROOTFS/var/lib/radarr" "$ROOTFS/config" "$ROOTFS/srv"
chroot "$ROOTFS" /bin/bash -lc 'chown -R radarr:media /var/lib/radarr'
chown -R radarr:media "$ROOTFS/config" || true

# Download & install
TMP="$(mktemp -d)"
curl -fsSL "$URL" -o "$TMP/radarr.tar.gz"
tar -xzf "$TMP/radarr.tar.gz" -C "$ROOTFS/opt/radarr" --strip-components=1
rm -rf "$TMP"

# Defaults for service
echo "RADARR_DATA=/config" > "$ROOTFS/etc/default/radarr"

# Sensible timezone default (adjust if you want)
echo "Etc/UTC" > "$ROOTFS/etc/timezone"
ln -sf /usr/share/zoneinfo/Etc/UTC "$ROOTFS/etc/localtime"

