# Horizon Linux

<p align="center">
	<img src="horizon.png" alt="Horizon Linux logo" width="280">
</p>

Horizon Linux is a Fedora 44 live-spin definition for a Hyprland desktop. It combines the Fedora base with the CachyOS kernel and settings, RPM Fusion NVIDIA support, and the Noctalia shell.

## Included

- Fedora 44 live environment with SELinux enforcing and `firewalld` enabled.
- Hyprland, SDDM, Noctalia, Foot, PipeWire, and the required Wayland portals.
- CachyOS kernel, matched development package, and userspace settings from COPR.
- RPM Fusion NVIDIA packages, CUDA support, DRM modesetting, and available NVIDIA power-management services.
- The Anaconda installer, for installing Horizon to disk from the live session.
- GParted for partitioning, with NTFS/exFAT filesystem tools and `smartctl` for disk health.
- NetworkManager, Firefox, the PCManFM-Qt file manager, firmware, Vulkan/Mesa utilities, and basic system diagnostics.

For image creation and QEMU testing, see the [build guide](build.md).

The image changes the displayed OS identity in `/etc/os-release` to Horizon Linux. Fedora branding remains in places such as Plymouth and Anaconda; GRUB uses the bundled Horizon theme.

## Default Session

SDDM defaults to Hyprland without enabling autologin. New accounts receive a minimal Hyprland configuration from `/etc/skel` which starts Noctalia and provides these key bindings:

| Binding | Action |
| --- | --- |
| `Super+Return` | Open Foot |
| `Super+Space` | Toggle the Noctalia launcher |
| `Super+S` | Toggle the Noctalia control center |
| `Super+,` | Toggle Noctalia settings |
| `Super+Q` | Close the active window |
| `Super+M` | Exit Hyprland |
| `Super+F` | Toggle fullscreen |

## NVIDIA Notes

`nvidia-drm.modeset=1` is set on the kernel command line (`config.xml`) and the "Nvidia" GRUB entry; the "Legacy" entry overrides it and blacklists the driver. During image creation `config.sh` builds the NVIDIA akmod against the CachyOS kernel the image ships (not the build host's kernel), and `/etc/dracut.conf.d/10-horizon-nvidia.conf` pulls the resulting modules into the initramfs that kiwi generates. Any failure in the akmod build is written to `/var/log/horizon-linux-post.log` rather than aborting the build. `akmods.service` is masked on the live image because the kernel never changes between build and boot; a disk install can `systemctl unmask akmods.service` to keep the driver rebuilding across kernel updates. The default Hyprland configuration sets NVIDIA-oriented Wayland environment variables only when the `nvidia` module is actually loaded, so non-NVIDIA hardware and the Legacy boot path are unaffected.

## Package Sources and Support

This project consumes Fedora, RPM Fusion, and COPR repositories. Package availability, signing, update cadence, and licensing are governed by their respective maintainers. The CachyOS repositories and the optional upstream dotfiles reference are not an endorsement or support relationship with CachyOS.

Horizon Linux is an independent, community-maintained Fedora remix definition. It is not affiliated with or endorsed by the Fedora Project, Red Hat, RPM Fusion, CachyOS, Hyprland, Noctalia, or NVIDIA.

## License

The files authored in this repository are licensed under the [MIT License](LICENSE.txt). Fedora and all included software retain their own licenses and trademarks.
