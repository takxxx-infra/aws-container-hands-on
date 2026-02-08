#!/bin/bash

set -euo pipefail

management_ec2_name="sbcntr-pseudo-cloud9"

usage() {
  cat <<EOF
Usage: $0 [up|down]

  up   : pseudo-cloud9 EC2 を起動（terraform destroy は実行しない）
  down : pseudo-cloud9 EC2 を停止し、指定リソースを terraform destroy
EOF
}

find_instance_ids_by_state() {
  local state="$1"
  aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${management_ec2_name}" "Name=instance-state-name,Values=${state}" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text
}

start_pseudo_cloud9() {
  local ids
  ids="$(find_instance_ids_by_state "stopped")"

  if [[ -z "${ids}" || "${ids}" == "None" ]]; then
    echo "${management_ec2_name} (stopped) が見つからないため、起動はスキップします。"
    return 0
  fi

  aws ec2 start-instances --instance-ids ${ids} >/dev/null
  echo "${management_ec2_name} を起動しました: ${ids}"
}

stop_pseudo_cloud9() {
  local ids
  ids="$(find_instance_ids_by_state "running")"

  if [[ -z "${ids}" || "${ids}" == "None" ]]; then
    echo "${management_ec2_name} (running) が見つからないため、停止はスキップします。"
    return 0
  fi

  aws ec2 stop-instances --instance-ids ${ids} >/dev/null
  echo "${management_ec2_name} を停止しました: ${ids}"
}

destroy_targets() {
  # 削除対象リソースを定義
  local targets=(
    aws_vpc_endpoint.ecr_api
    aws_vpc_endpoint.ecr_dkr
    aws_vpc_endpoint.s3
  )
  local args=()

  for t in "${targets[@]}"; do
    args+=("-target=$t")
  done

  cd "$(dirname "$0")/../../terraform"
  terraform destroy -auto-approve "${args[@]}"
}

mode="${1:-down}"

case "${mode}" in
  up)
    start_pseudo_cloud9
    ;;
  down)
    stop_pseudo_cloud9
    destroy_targets
    ;;
  *)
    usage
    exit 1
    ;;
esac
