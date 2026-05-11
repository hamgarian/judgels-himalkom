#!/usr/bin/env bash
set -euo pipefail

echo "Host/container cgroup filesystem:"
stat -fc %T /sys/fs/cgroup

echo
echo "Kernel command line:"
cat /proc/cmdline

echo
echo "Cgroup mounts:"
grep cgroup /proc/mounts || true

echo
if [[ -d /sys/fs/cgroup/memory ]]; then
  echo "OK: /sys/fs/cgroup/memory exists."
else
  echo "MISSING: /sys/fs/cgroup/memory does not exist."
  echo "Judgels isolate 1.10.1 will fail until the Docker host boots with cgroup v1 memory enabled."
  exit 1
fi
