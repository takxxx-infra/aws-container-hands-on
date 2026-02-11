#!/bin/bash

set -euo pipefail

management_ec2_name="sbcntr-pseudo-cloud9"
ecs_cluster_name="sbcntr-app"
ecs_services=(
  "sbcntr-frontend-app"
  "sbcntr-backend-app"
)
targets=(
    aws_vpc_endpoint.ecr_api
    aws_vpc_endpoint.ecr_dkr
    aws_vpc_endpoint.cw_logs
  )

usage() {
  cat <<EOF
Usage: $0 [up|down]

  up   : ECS desired_count を 1、pseudo-cloud9 EC2 を起動し、指定リソースを terraform apply
  down : ECS desired_count を 0、pseudo-cloud9 EC2 を停止し、指定リソースを terraform destroy
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

set_ecs_services_desired_count() {
  local desired_count="$1"
  local cluster_found

  cluster_found="$(aws ecs describe-clusters \
    --clusters "${ecs_cluster_name}" \
    --query "length(clusters)" \
    --output text)"

  if [[ "${cluster_found}" == "0" || "${cluster_found}" == "None" ]]; then
    echo "ECS cluster (${ecs_cluster_name}) が見つからないため、desired_count 変更をスキップします。"
    return 0
  fi

  for service_name in "${ecs_services[@]}"; do
    local service_status
    service_status="$(aws ecs describe-services \
      --cluster "${ecs_cluster_name}" \
      --services "${service_name}" \
      --query "services[0].status" \
      --output text)"

    if [[ "${service_status}" == "None" || "${service_status}" == "INACTIVE" ]]; then
      echo "ECS service (${service_name}) が見つからないため、desired_count 変更をスキップします。"
      continue
    fi

    aws ecs update-service \
      --cluster "${ecs_cluster_name}" \
      --service "${service_name}" \
      --desired-count "${desired_count}" >/dev/null
    echo "ECS service (${service_name}) の desired_count を ${desired_count} に設定しました。"
  done
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
    set_ecs_services_desired_count "1"
    ;;
  down)
    set_container_insights "disabled"
    set_ecs_services_desired_count "0"
    stop_pseudo_cloud9
    destroy_targets
    ;;
  *)
    usage
    exit 1
    ;;
esac
