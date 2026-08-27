#!/bin/bash
# Horizon Linux - kiwi config.sh
# Runs inside the prepared image root during the "prepare" step.
# kiwi builds its own dracut/initrd afterwards in the "create" step,
# so do NOT call dracut manually here.

test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

set -uxo pipefail
# (not using -e globally: a failed Nvidia/kernel step below should not
#  abort the whole script - see the guarded calls further down)

echo "Configuring Horizon Linux..."

# --- Always-run, low-risk steps first ---
systemctl enable NetworkManager.service
systemctl enable firewalld.service
systemctl enable sddm.service

# Cosmetic rebrand only - keep ID=fedora intact so dnf/tooling still works.
sed -i 's/^NAME=.*/NAME="Horizon Linux"/' /etc/os-release
sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="Horizon Linux 44"/' /etc/os-release
sed -i 's/^LOGO=.*/LOGO=horizon-linux-logo/' /etc/os-release \
    || echo 'LOGO=horizon-linux-logo' >> /etc/os-release

systemctl disable sshd.service 2>/dev/null || true

# sudo package alone isn't enough - Fedora ships /etc/sudoers with the
# %wheel rule commented out by default, so horizon's wheel membership
# would do nothing without this.
sed -i 's/^# %wheel\s\+ALL=(ALL)\s\+ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers \
    || echo "WARNING: enabling %wheel sudo rule failed" >> /var/log/horizon-post.log

# CachyOS's own docs flag this as required: without it, SELinux in
# enforcing mode can block loading out-of-tree modules (Nvidia, and
# the CachyOS kernel's own modules).
if command -v setsebool >/dev/null 2>&1; then
    setsebool -P domain_kernel_load_modules on \
        || echo "WARNING: setsebool domain_kernel_load_modules failed" >> /var/log/horizon-post.log
fi

# --- Branding: files already placed by the root/ overlay, just point ---
# --- Plymouth and GRUB at them.

if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme spinner \
        || echo "WARNING: plymouth-set-default-theme failed" >> /var/log/horizon-post.log
fi

# --- Nvidia / kernel steps: log and continue on failure ---

if command -v akmods >/dev/null 2>&1; then
    akmods --force \
        || echo "WARNING: akmods build failed, rebuild manually after first boot" >> /var/log/horizon-post.log
fi

# The module is already built above, at image-creation time, against the
# exact kernel this live image ships. Since the kernel never changes
# between build and boot on a live medium, akmods.service re-running the
# same build on every single boot is pure waste - and on a VM/CPU-limited
# machine it's slow enough to look like a hang (this was the black-screen
# stall). Mask it so live boots go straight through.
if command -v systemctl >/dev/null 2>&1; then
    systemctl mask akmods.service 2>/dev/null || true
fi

for unit in nvidia-powerd.service nvidia-hibernate.service nvidia-resume.service nvidia-suspend.service; do
    if systemctl list-unit-files "$unit" >/dev/null 2>&1; then
        systemctl enable "$unit" 2>/dev/null || true
    fi
done

exit 0
