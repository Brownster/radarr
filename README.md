# Radarr Incus Image Pipeline (ARM64, Debian 12)

Build **Incus/LXD system container images** for **Radarr** on every push and on a schedule.  
Two tracks:
- **release** – downloads the **latest upstream Radarr release** (arm64 tarball) from GitHub.
- **main** – builds a daily snapshot from Radarr's `develop` branch using .NET SDK.

Outputs are **image tarballs** you can import into Incus:
```
incus image import radarr-<track>-metadata.tar.gz radarr-<track>-rootfs.tar.gz --alias radarr-<track>
incus launch radarr-<track> radarr --profile base --profile media
```

> Default base: **Debian 12 (bookworm)**, **aarch64** (Pi 5 friendly).

## Repo layout
- `.github/workflows/build.yml` – CI that builds both tracks and uploads artifacts.
- `distrobuilder/debian-bookworm.yaml` – base OS image definition.
- `scripts/install_radarr_release.sh` – installs latest release into the rootfs.
- `scripts/build_radarr_from_source.sh` – builds from `develop` and installs into rootfs.
- `service/radarr.service` – systemd unit installed to the image.

## Requirements (CI handled for you)
- distrobuilder, debootstrap, squashfs-tools, xz-utils, uidmap.
- .NET 8 SDK (only for the `main` build track).

## Consume the image (on your Pi/Incus host)
1. Download artifacts from the workflow run (`radarr-release-*.tar.gz` or `radarr-main-*.tar.gz`).
2. Import & launch:
```bash
incus image import radarr-release-metadata.tar.gz radarr-release-rootfs.tar.gz --alias radarr-release
incus launch radarr-release radarr -p base -p media
# Then browse: http://<container-ip>:7878
```

## Notes
- Radarr listens on **7878** by default.
- The image creates user **radarr** and group **media**; Radarr runs as `radarr:media` and will expect your library and downloads to be readable/writeable by the `media` group.
- Mount your media and config via Incus profiles/devices (your Terraform project already sets `/srv/media` and `/config`).

