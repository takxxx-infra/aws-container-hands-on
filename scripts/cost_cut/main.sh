#!/bin/bash

set -euo pipefail

management_ec2_name="sbcntr-pseudo-cloud9"
ecs_cluster_name="sbcntr-app"
targets=(
    aws_vpc_endpoint.ecr_api
    aws_vpc_endpoint.ecr_dkr
    aws_vpc_endpoint.s3
    aws_vpc_endpoint.cw_logs
    aws_lb.ingress
    aws_lb_listener.ingress
  )

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

set_container_insights() {
  local value="$1"
  local cluster_found

  cluster_found="$(aws ecs describe-clusters \
    --clusters "${ecs_cluster_name}" \
    --query "length(clusters)" \
    --output text)"

  if [[ "${cluster_found}" == "0" || "${cluster_found}" == "None" ]]; then
    echo "ECS cluster (${ecs_cluster_name}) が見つからないため、containerInsights の変更をスキップします。"
    return 0
  fi

  aws ecs update-cluster-settings \
    --cluster "${ecs_cluster_name}" \
    --settings "name=containerInsights,value=${value}" >/dev/null
  echo "ECS cluster (${ecs_cluster_name}) の containerInsights を ${value} に設定しました。"
}

apply_targets() {
  local args=()

  for t in "${targets[@]}"; do
    args+=("-target=$t")
  done

  cd "$(dirname "$0")/../../terraform"
  terraform apply "${args[@]}"
}

destroy_targets() {
  local args=()

  for t in "${targets[@]}"; do
    args+=("-target=$t")
  done

  cd "$(dirname "$0")/../../terraform"
  terraform destroy "${args[@]}"
}

mode="${1:-down}"

case "${mode}" in
  up)
    set_container_insights "enhanced"
    start_pseudo_cloud9
    apply_targets
    ;;
  down)
    set_container_insights "disable"
    stop_pseudo_cloud9
    destroy_targets
    ;;
  *)
    usage
    exit 1
    ;;
esac
