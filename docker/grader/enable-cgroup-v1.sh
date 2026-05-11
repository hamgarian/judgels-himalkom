#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root, for example: sudo $0" >&2
  exit 1
fi

if ! command -v update-grub >/dev/null 2>&1; then
  echo "update-grub was not found. This script supports Ubuntu/Debian GRUB hosts." >&2
  exit 1
fi

cat >/etc/default/grub.d/70-judgels-cgroup-v1.cfg <<'EOF'
JUDGELS_CGROUP_V1_ARGS="cgroup_enable=memory swapaccount=1 systemd.unified_cgroup_hierarchy=0 systemd.legacy_systemd_cgroup_controller=0"
GRUB_CMDLINE_LINUX="${GRUB_CMDLINE_LINUX} ${JUDGELS_CGROUP_V1_ARGS}"
GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} ${JUDGELS_CGROUP_V1_ARGS}"
EOF

update-grub

cat <<'EOF'

cgroup v1 boot flags have been installed.
Reboot the host, then verify:

  stat -fc %T /sys/fs/cgroup
  test -d /sys/fs/cgroup/memory && echo "cgroup v1 memory controller is available"

After that, recreate the grader container:

  docker compose up -d --force-recreate judgels-grader

EOF
