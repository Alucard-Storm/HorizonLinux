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
- NetworkManager, Firefox, firmware, Vulkan/Mesa utilities, and basic system diagnostics.

For image creation and QEMU testing, see the [build guide](build.md).

The image changes the displayed OS identity in `/etc/os-release` and `/etc/issue` to Horizon Linux. Fedora branding remains in places such as GRUB, Plymouth, and Anaconda.

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

The post-install stage adds `nvidia-drm.modeset=1`, attempts to build akmods, and regenerates initramfs images. Failures in the akmods or dracut steps are logged to `/root/horizon-linux-post.log` rather than aborting image creation. The default Hyprland configuration contains NVIDIA-oriented Wayland environment variables; hardware without NVIDIA may remove or adapt them.

## Package Sources and Support

This project consumes Fedora, RPM Fusion, and COPR repositories. Package availability, signing, update cadence, and licensing are governed by their respective maintainers. The CachyOS repositories and the optional upstream dotfiles reference are not an endorsement or support relationship with CachyOS.

Horizon Linux is an independent, community-maintained Fedora remix definition. It is not affiliated with or endorsed by the Fedora Project, Red Hat, RPM Fusion, CachyOS, Hyprland, Noctalia, or NVIDIA.

## License

The files authored in this repository are licensed under the [MIT License](LICENSE). Fedora and all included software retain their own licenses and trademarks.
