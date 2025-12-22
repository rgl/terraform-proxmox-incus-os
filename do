#!/bin/bash
set -euo pipefail

# see https://github.com/lxc/incus-os/tags
# renovate: datasource=github-tags depName=lxc/incus-os
incus_os_version="202512210053"

export CHECKPOINT_DISABLE='1'
export TF_LOG='DEBUG' # TRACE, DEBUG, INFO, WARN or ERROR.
export TF_LOG_PATH='terraform.log'

function step {
  echo "### $* ###"
}

function build_incus_os_image {
  # see https://github.com/lxc/incus-os/tree/202512210053/doc
  # see https://images.linuxcontainers.org/os/
  local img_archive_url="https://images.linuxcontainers.org/os/$incus_os_version/x86_64/IncusOS_$incus_os_version.img.gz"
  local img_archive_path="tmp/incus-os/incus-os-$incus_os_version.img"
  local img_path="tmp/incus-os/incus-os-$incus_os_version.qcow2"
  if [ -r "$img_path" ]; then
    return
  fi
  step "downloading image $img_archive_url"
  rm -rf tmp/incus-os
  install -d tmp/incus-os
  wget -qO- "$img_archive_url" | gunzip >"$img_archive_path"
  local tmp_img_path="$img_path.tmp"
  qemu-img convert -O qcow2 "$img_archive_path" "$tmp_img_path"
  qemu-img info "$tmp_img_path"
  mv "$tmp_img_path" "$img_path"
  cat >terraform.tfvars <<EOF
incus_os_version         = "$incus_os_version"
incus_client_certificate = "$(incus remote get-client-certificate | sed -z 's/\n/\\n/g')"
EOF
}

function init {
  step 'build incus-os image'
  build_incus_os_image
  step 'terraform init'
  terraform init -lockfile=readonly
}

function plan {
  step 'terraform plan'
  terraform plan -out=tfplan
}

function apply {
  step 'terraform apply'
  terraform apply tfplan
  step 'wait for ready'
  local ip_address="$(terraform output -raw nodes)"
  incus remote remove incus-os-example &>/dev/null || true
  while ! incus remote add incus-os-example "$ip_address" --accept-certificate; do sleep 5; done
  echo 'incus os is ready!'
  info
}

function info {
  step 'incus info'
  incus query incus-os-example:/os/1.0
}

function destroy {
  terraform destroy -auto-approve
}

case $1 in
  init)
    init
    ;;
  plan)
    plan
    ;;
  apply)
    apply
    ;;
  plan-apply)
    plan
    apply
    ;;
  health)
    health
    ;;
  info)
    info
    ;;
  destroy)
    destroy
    ;;
  *)
    echo $"Usage: $0 {init|plan|apply|plan-apply|health|info}"
    exit 1
    ;;
esac
