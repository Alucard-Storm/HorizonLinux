# Horizon Linux Build Guide

This guide covers building and testing the Horizon Linux live image with kiwi-ng. The distro overview and included desktop features are documented in the [README](README.md).

## Prerequisites

Install kiwi-ng and its Fedora system dependencies:

```bash
sudo dnf install kiwi kiwi-systemdeps distribution-gpg-keys
```

`distribution-gpg-keys` is required, not optional: `config.xml` verifies the
Fedora repositories against the keys it installs under
`/usr/share/distribution-gpg-keys/`.

## Build

Run the build from the repository root:

```bash
sudo kiwi-ng system build --description . --target-dir /var/tmp/horizon-linux-build
```

The resulting ISO is written to `/var/tmp/horizon-linux-build/`.

## Test

The image is UEFI-only, so QEMU needs OVMF firmware (`sudo dnf install edk2-ovmf`):

```bash
sudo qemu-system-x86_64 -enable-kvm -m 4096 -serial stdio \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/ovmf/OVMF_CODE.fd \
  -cdrom /var/tmp/horizon-linux-build/horizon-linux.x86_64-1.0.0.iso
```

## Install to disk

The live session ships Anaconda. Launch it from the Noctalia app launcher
(`Super+Space`) or run `liveinst` from a terminal - it escalates itself via
pkexec, so do not prefix it with `sudo` (that breaks the Web UI's handoff to
the graphical session).

## Notes

- kiwi runs `config.sh` inside the prepared root, then builds its own initrd/dracut image during the create step. A separate dracut invocation is not required.
- The bootstrap package list in `config.xml` is a starting point, not a guarantee. If the build fails while resolving base packages, compare it with an [official Fedora kiwi description](https://github.com/OSInside/kiwi-descriptions).
- NVIDIA driver setup failures are logged to `/var/log/horizon-linux-post.log` rather than aborting image creation. After first boot, rebuild the driver and initramfs when necessary:

  ```bash
  sudo akmods --force
  sudo dracut --force --regenerate-all
  ```
