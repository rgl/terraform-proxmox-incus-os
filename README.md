# About

[![Lint](https://github.com/rgl/terraform-proxmox-incus-os/actions/workflows/lint.yml/badge.svg)](https://github.com/rgl/terraform-proxmox-incus-os/actions/workflows/lint.yml)

An example [Incus OS](https://github.com/lxc/incus-os) cluster running in Proxmox QEMU/KVM Virtual Machines using terraform.

# Usage (Ubuntu 24.04 host)

Install the [incus cli](https://github.com/lxc/incus/releases).

Install the [xorriso cli](https://packages.ubuntu.com/jammy/xorriso).

Set your Proxmox details:

```bash
# see https://registry.terraform.io/providers/bpg/proxmox/latest/docs#argument-reference
# see environment variables at https://github.com/bpg/terraform-provider-proxmox/blob/v0.91.0/proxmoxtf/provider/provider.go#L52-L61
cat >secrets-proxmox.sh <<EOF
unset HTTPS_PROXY
#export HTTPS_PROXY='http://localhost:8080'
export TF_VAR_proxmox_pve_node_address='192.168.8.21'
export PROXMOX_VE_INSECURE='1'
export PROXMOX_VE_ENDPOINT="https://$TF_VAR_proxmox_pve_node_address:8006"
export PROXMOX_VE_USERNAME='root@pam'
export PROXMOX_VE_PASSWORD='vagrant'
EOF
source secrets-proxmox.sh
```

Build the incus os image, and initialize terraform:

```bash
./do init
```

Create the infrastructure:

```bash
time ./do plan-apply
```

In another shell, start the local incus web ui proxy, and open the incus web ui:

```bash
incus webui incus-os-example:
```

Go back to the original shell.

Get information about incus os and incus:

```bash
# see https://linuxcontainers.org/incus-os/docs/main/reference/api/
# see https://github.com/lxc/incus-os/blob/202601080126/doc/rest-api.yaml
# see https://github.com/lxc/incus-os/tree/202601080126/incus-osd/internal/rest
# see https://github.com/lxc/incus-os/blob/202601080126/incus-osd/internal/rest/server.go
incus admin os show incus-os-example:
incus query incus-os-example:/os/1.0
incus admin os system security show incus-os-example:
incus query incus-os-example:/os/1.0/system/security
incus query incus-os-example:/os/1.0/system/network
incus query incus-os-example:/os/1.0/system/storage
incus query incus-os-example:/os/1.0/system/update
incus query incus-os-example:/os/1.0/system/provider
incus admin os system resources show incus-os-example:
incus query incus-os-example:/os/1.0/system/resources
incus query incus-os-example:/os/1.0/system/resources | jq .storage.disks
incus query incus-os-example:/os/1.0/system/resources | jq .network.cards
incus admin os service list incus-os-example:
incus query incus-os-example:/os/1.0/services
incus query incus-os-example:/os/1.0/services/ovn
incus admin os application list incus-os-example:
incus query incus-os-example:/os/1.0/applications
incus query incus-os-example:/os/1.0/applications/incus
incus query incus-os-example:/os/1.0/debug
incus query incus-os-example:/os/1.0/debug/log
incus info incus-os-example:
```

Execute an example container:

```bash
incus launch images:debian/trixie incus-os-example:debian-ct
incus list incus-os-example:
incus config show incus-os-example:debian-ct --expanded
incus info incus-os-example:debian-ct --show-log
incus console incus-os-example:debian-ct --show-log
incus exec incus-os-example:debian-ct -- cat /etc/os-release
incus exec incus-os-example:debian-ct -- ip addr
incus exec incus-os-example:debian-ct -- mount
incus exec incus-os-example:debian-ct -- df -h
incus exec incus-os-example:debian-ct -- ps -efww --forest
incus stop incus-os-example:debian-ct
incus delete incus-os-example:debian-ct
```

Execute an example vm:

```bash
incus launch images:debian/trixie incus-os-example:debian-vm --vm
incus list incus-os-example:
incus config show incus-os-example:debian-vm --expanded
incus info incus-os-example:debian-vm --show-log
incus console incus-os-example:debian-vm --show-log
incus exec incus-os-example:debian-vm -- cat /etc/os-release
incus exec incus-os-example:debian-vm -- ip addr
incus exec incus-os-example:debian-vm -- mount
incus exec incus-os-example:debian-vm -- df -h
incus exec incus-os-example:debian-vm -- ps -efww --forest
incus stop incus-os-example:debian-vm
incus delete incus-os-example:debian-vm
```

Reboot or poweroff incus os:

```bash
# see https://linuxcontainers.org/incus-os/docs/main/reference/api/
# see https://github.com/lxc/incus-os/blob/202601080126/doc/rest-api.yaml
# see https://github.com/lxc/incus-os/blob/202601080126/incus-osd/internal/rest/api_system.go
incus query -X POST incus-os-example:/os/1.0/system/:reboot
incus query -X POST incus-os-example:/os/1.0/system/:poweroff
# NB there is also a incus admin sub-command for these actions, but those ask
#    for confirmation and do not have a flag to automatically confirm the
#    action, so we have to workaround that with the `yes` command.
yes | incus admin os system reboot incus-os-example:
yes | incus admin os system poweroff incus-os-example:
```

Destroy the infrastructure:

```bash
time ./do destroy
```

List this repository dependencies (and which have newer versions):

```bash
GITHUB_COM_TOKEN='YOUR_GITHUB_PERSONAL_TOKEN' ./renovate.sh
```
