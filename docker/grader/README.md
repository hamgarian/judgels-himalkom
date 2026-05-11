# Judgels Grader Cgroups

`judgels-grader` runs submissions with `isolate`. The current grader image builds
`isolate` 1.10.1, which uses cgroup v1. On Ubuntu 24.04 and many modern Docker
hosts, cgroup v2 is enabled by default. In that mode the container does not have
`/sys/fs/cgroup/memory`, so grading fails during `isolate --cg --init` with:

```text
Failed to create control group /sys/fs/cgroup/memory/box-0/: No such file or directory
```

The compose file runs the grader as privileged, uses the host cgroup namespace,
and bind-mounts `/sys/fs/cgroup`. The host still has to boot with cgroup v1
enabled.

## Check the Host

Run this on the Linux machine that runs Docker:

```bash
test -d /sys/fs/cgroup/memory && echo "cgroup v1 memory controller is available"
stat -fc %T /sys/fs/cgroup
```

If the second command prints `cgroup2fs` and `/sys/fs/cgroup/memory` is missing,
enable cgroup v1 and reboot.

## Enable Cgroup V1 on Ubuntu

```bash
sudo bash docker/grader/enable-cgroup-v1.sh
sudo reboot
```

After reboot, recreate the grader container:

```bash
docker compose up -d --force-recreate judgels-grader
```

This is a host-level kernel setting. Docker Desktop, WSL, and shared container
hosts may not allow this change; use a dedicated Linux VM/server for reliable
grading.
