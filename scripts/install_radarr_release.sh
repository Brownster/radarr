#!/usr/bin/env bash
set -euo pipefail
ROOTFS="${1:-out/rootfs}"
if [ ! -d "$ROOTFS" ]; then
  echo "Usage: $0 <rootfs_dir>" >&2
  exit 1
fi

# Determine latest arm64 tarball from GitHub API
echo "Fetching latest Radarr arm64 release URL..."
API_URL="https://api.github.com/repos/Radarr/Radarr/releases/latest"
URL=$(curl -fsSL "$API_URL" | jq -r '.assets[] | select(.name | test("linux-arm64.*\.tar\.gz$")) | .browser_download_url' | head -n1)
if [ -z "$URL" ]; then
  echo "Could not find arm64 tarball in latest release" >&2
  exit 2
fi
echo "Latest URL: $URL"

# Create radarr user/group and directories
chroot "$ROOTFS" /bin/bash -lc 'groupadd -r media || true; useradd -r -s /usr/sbin/nologin -g media -d /var/lib/radarr radarr || true'
mkdir -p "$ROOTFS/opt/radarr" "$ROOTFS/var/lib/radarr" "$ROOTFS/config" "$ROOTFS/srv/media"
chroot "$ROOTFS" /bin/bash -lc 'chown -R radarr:media /var/lib/radarr'
chown -R radarr:media "$ROOTFS/config" "$ROOTFS/srv/media" || true

# Download and install
TMP="$(mktemp -d)"
curl -fsSL "$URL" -o "$TMP/radarr.tar.gz"
tar -xzf "$TMP/radarr.tar.gz" -C "$ROOTFS/opt/radarr" --strip-components=1
rm -rf "$TMP"

# Default data dir
echo "RADARR_DATA=/config" > "$ROOTFS/etc/default/radarr"
