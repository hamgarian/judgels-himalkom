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

Run this on the Linux machine that runs Docker. For Coolify, this means SSH into
the server that runs Coolify, not the web terminal inside the application
container.

```bash
sudo bash docker/grader/check-cgroups.sh
```

Or run the minimal checks manually:

```bash
stat -fc %T /sys/fs/cgroup
test -d /sys/fs/cgroup/memory && echo "cgroup v1 memory controller is available"
```

If the second command prints `cgroup2fs` and `/sys/fs/cgroup/memory` is missing,
enable cgroup v1 and reboot.

## Coolify

Coolify deploys your compose file, but it cannot change the host kernel cgroup
version from inside the app deployment. The fix must happen on the Coolify
server itself:

```bash
ssh root@YOUR_COOLIFY_SERVER
cd /path/to/this/repo
sudo bash docker/grader/enable-cgroup-v1.sh
sudo reboot
```

If this repository is not present on the server, run the equivalent host command:

```bash
sudo tee /etc/default/grub.d/70-judgels-cgroup-v1.cfg >/dev/null <<'EOF'
JUDGELS_CGROUP_V1_ARGS="cgroup_enable=memory swapaccount=1 systemd.unified_cgroup_hierarchy=0 systemd.legacy_systemd_cgroup_controller=0"
GRUB_CMDLINE_LINUX="${GRUB_CMDLINE_LINUX} ${JUDGELS_CGROUP_V1_ARGS}"
GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} ${JUDGELS_CGROUP_V1_ARGS}"
EOF
sudo update-grub
sudo reboot
```

After reboot, verify the host:

```bash
stat -fc %T /sys/fs/cgroup
test -d /sys/fs/cgroup/memory && echo "cgroup v1 memory controller is available"
```

Then redeploy the Coolify application or force-recreate the `judgels-grader`
container.

If Coolify is not using raw Docker Compose deployment, switch the app to Raw
Docker Compose Deployment so Coolify does not rewrite or omit the grader's
`privileged`, `cgroup`, and `/sys/fs/cgroup` bind mount settings.

You can also inspect the running grader container from the host:

```bash
docker inspect judgels-grader --format '{{.HostConfig.Privileged}} {{.HostConfig.CgroupnsMode}}'
docker exec judgels-grader sh -lc 'stat -fc %T /sys/fs/cgroup; ls -ld /sys/fs/cgroup/memory || true'
```

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
