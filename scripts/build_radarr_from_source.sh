#!/usr/bin/env bash
set -euo pipefail
ROOTFS="${1:-out/rootfs}"
if [ ! -d "$ROOTFS" ]; then
  echo "Usage: $0 <rootfs_dir>" >&2
  exit 1
fi

# Install .NET SDK and build tools inside a temporary build container (runner host)
# Then copy into rootfs. We use a containerized build to avoid polluting the host rootfs.
# For simplicity in CI, we chroot into rootfs and install dotnet to build in-place.
# Note: this increases CI time but keeps the image content correct.

# Add Microsoft apt repo for dotnet 8
chroot "$ROOTFS" /bin/bash -lc '  apt-get update && apt-get install -y ca-certificates curl gnupg &&   install -m 0755 -d /etc/apt/keyrings &&   curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg &&   chmod a+r /etc/apt/keyrings/microsoft.gpg &&   echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" > /etc/apt/sources.list.d/microsoft-dotnet.list &&   apt-get update && apt-get install -y dotnet-sdk-8.0 git'

# Create radarr user/group and directories
chroot "$ROOTFS" /bin/bash -lc 'groupadd -r media || true; useradd -r -s /usr/sbin/nologin -g media -d /var/lib/radarr radarr || true'
mkdir -p "$ROOTFS/opt/radarr" "$ROOTFS/var/lib/radarr" "$ROOTFS/config" "$ROOTFS/srv/media"
chroot "$ROOTFS" /bin/bash -lc 'chown -R radarr:media /var/lib/radarr'
chown -R radarr:media "$ROOTFS/config" "$ROOTFS/srv/media" || true

# Build from develop branch
chroot "$ROOTFS" /bin/bash -lc '  cd /tmp && git clone --depth=1 --branch develop https://github.com/Radarr/Radarr.git &&   cd Radarr &&   ./build.sh --platform linux-arm64 --runtime linux-arm64 --release &&   mkdir -p /opt/radarr && cp -r _output/linux-arm64/publish/* /opt/radarr &&   rm -rf /tmp/Radarr && apt-get purge -y dotnet-sdk-8.0 git && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*'
