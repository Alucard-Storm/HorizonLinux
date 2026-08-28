#!/bin/bash
# Horizon Linux - kiwi config.sh
# Runs inside the prepared image root during the kiwi "prepare" step.
# kiwi builds its own dracut/initrd afterwards in the "create" step,
# so do NOT call dracut manually here.

test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

set -uxo pipefail
# (not using -e globally: a failed Nvidia/kernel step below should not
#  abort the whole image build - those calls are guarded individually)

LOG=/var/log/horizon-linux-post.log
warn() { echo "WARNING: $*" >> "$LOG"; }

echo "Configuring Horizon Linux..."

# --- Always-run, low-risk steps first ---
systemctl enable NetworkManager.service
systemctl enable firewalld.service
systemctl enable sddm.service

# NetworkManager-wait-online orders itself before multi-user.target and
# blocks boot until a link is up - a pointless multi-second stall on every
# live boot. The desktop uses NetworkManager directly and does not need it.
systemctl mask NetworkManager-wait-online.service 2>/dev/null || true

# sshd is not installed by default; disable defensively in case it gets
# pulled in as a dependency later.
systemctl disable sshd.service 2>/dev/null || true

# Cosmetic rebrand only - keep ID=fedora intact so dnf/tooling still works.
sed -i 's/^NAME=.*/NAME="Horizon Linux"/' /etc/os-release
sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="Horizon Linux 44"/' /etc/os-release
sed -i 's/^LOGO=.*/LOGO=horizon-linux-logo/' /etc/os-release \
    || echo 'LOGO=horizon-linux-logo' >> /etc/os-release

# --- Machine-specific state must not be baked into the image ---
# Every booted copy (and every disk install made from it) has to generate
# its own identity on first boot.
rm -f /etc/machine-id
echo 'uninitialized' > /etc/machine-id
rm -f /var/lib/systemd/random-seed

# --- sudo for the wheel group ---
# Ship an explicit drop-in rather than sed-patching /etc/sudoers: it is
# idempotent and does not depend on which %wheel line the base sudoers
# happens to ship enabled. The "horizon" user is in wheel (see config.xml).
cat > /etc/sudoers.d/10-horizon-wheel << 'EOF'
## Horizon Linux: allow members of the wheel group to run any command
%wheel ALL=(ALL) ALL
EOF
chmod 0440 /etc/sudoers.d/10-horizon-wheel

# CachyOS's own docs flag this as required: without it, SELinux in enforcing
# mode can block loading the out-of-tree Nvidia module and some of the
# CachyOS kernel's own modules.
if command -v setsebool >/dev/null 2>&1; then
    setsebool -P domain_kernel_load_modules on \
        || warn "setsebool domain_kernel_load_modules failed"
fi

# --- Branding: assets are placed by the root/ overlay; just select them ---
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme spinner \
        || warn "plymouth-set-default-theme failed"
fi

# --- Desktop hardware services ---
# These have Fedora presets, but this image enables its services explicitly
# rather than trusting preset application inside the kiwi root (same reason
# NetworkManager/firewalld/sddm are enabled by hand above).
#   - bluetooth.service         : bluez backend for blueman / the Noctalia panel
#   - power-profiles-daemon     : balanced/performance/power-saver switching
#   - fwupd-refresh.timer       : periodic LVFS firmware-metadata refresh
#     (fwupd.service itself is D-Bus/socket activated - no enable needed)
# gnome-keyring needs no wiring here: Fedora's /etc/pam.d/sddm already loads
# pam_gnome_keyring on auth + session, so the login password unlocks it.
for unit in bluetooth.service power-profiles-daemon.service fwupd-refresh.timer; do
    systemctl enable "$unit" 2>/dev/null || warn "could not enable $unit"
done

# --- Nvidia / kernel: log and continue on failure ---
# In a chroot, akmods defaults to `uname -r`, i.e. the BUILD HOST kernel -
# not the CachyOS kernel this image ships. Build explicitly against the
# kernel that is actually installed here, then refresh modules.dep so the
# initrd kiwi generates in the "create" step can pick the module up.
if command -v akmods >/dev/null 2>&1; then
    kver=$(ls /lib/modules 2>/dev/null | grep cachyos | sort -V | tail -n1)
    if [ -n "${kver:-}" ]; then
        akmods --force --kernels "$kver" \
            || warn "akmods build failed for $kver; rebuild after first boot with: akmods --force"
        depmod -a "$kver" || warn "depmod failed for $kver"
    else
        warn "no *cachyos* tree under /lib/modules; skipped akmods build"
    fi
fi

# The Nvidia module is built above against the exact kernel this live image
# ships, and that kernel never changes between build and boot on live media,
# so akmods.service rebuilding it on every boot is pure waste - and on a
# CPU-limited VM it is slow enough to look like a hang (the old black-screen
# stall). Mask it for the live path; a disk install can re-enable it with
# `systemctl unmask akmods.service` to survive future kernel updates.
systemctl mask akmods.service 2>/dev/null || true

for unit in nvidia-powerd.service nvidia-hibernate.service nvidia-resume.service nvidia-suspend.service; do
    if systemctl list-unit-files "$unit" >/dev/null 2>&1; then
        systemctl enable "$unit" 2>/dev/null || true
    fi
done

exit 0
