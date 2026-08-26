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

# NOTE: GRUB_THEME expects a full theme directory with a theme.txt file.
# We only shipped a background image, so use GRUB_BACKGROUND instead -
# it's the simple "just show this image" option and needs no theme.txt.
cat >> /etc/default/grub << 'GRUB_EOF'
GRUB_BACKGROUND="/usr/share/grub2/themes/horizon/background.png"
GRUB_EOF

if command -v grub2-mkconfig >/dev/null 2>&1; then
    grub2-mkconfig -o /boot/grub2/grub.cfg \
        || echo "WARNING: grub2-mkconfig failed" >> /var/log/horizon-post.log
fi

# --- Nvidia / kernel steps: log and continue on failure ---

if command -v akmods >/dev/null 2>&1; then
    akmods --force \
        || echo "WARNING: akmods build failed, rebuild manually after first boot" >> /var/log/horizon-post.log
fi

if command -v grubby >/dev/null 2>&1; then
    grubby --update-kernel=ALL --args="nvidia-drm.modeset=1" \
        || echo "WARNING: grubby nvidia-drm.modeset update failed" >> /var/log/horizon-post.log
fi

for unit in nvidia-powerd.service nvidia-hibernate.service nvidia-resume.service nvidia-suspend.service; do
    if systemctl list-unit-files "$unit" >/dev/null 2>&1; then
        systemctl enable "$unit" 2>/dev/null || true
    fi
done

exit 0
