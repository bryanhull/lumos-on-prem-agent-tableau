#!/usr/bin/env bash
set -euo pipefail

# Simple wrapper to deploy the stack with common parameters.
# Usage:
#   ./scripts/deploy.sh #     --stack-name lumos-agent-ecs #     --vpc-id vpc-0123456789abcdef0 #     --subnet-ids subnet-aaaabbbb,subnet-ccccdddd #     --assign-public-ip DISABLED #     --desired-count 2 #     --cpu 2048 #     --memory 16384 #     --ephemeral-storage 64 #     --image-tag latest #     [--existing-secret-arn arn:aws:secretsmanager:...:secret:...] #     [--lumos-api-key lsk_xxx] #     [--log-to-stdout true] #     [--send-critical-logs false] #     [--log-level DEBUG] #     [--proxy-url http://proxy:8080]

STACK_NAME=""
VPC_ID=""
SUBNET_IDS=""
ASSIGN_PUBLIC_IP="DISABLED"
DESIRED_COUNT="1"
CPU="2048"
MEMORY="16384"
EPHEMERAL="64"
IMAGE_TAG="latest"
EXISTING_SECRET_ARN=""
LUMOS_API_KEY=""
LOG_TO_STDOUT="true"
SEND_CRITICAL_LOGS="false"
LOG_LEVEL=""
PROXY_URL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stack-name) STACK_NAME="$2"; shift 2;;
    --vpc-id) VPC_ID="$2"; shift 2;;
    --subnet-ids) SUBNET_IDS="$2"; shift 2;;
    --assign-public-ip) ASSIGN_PUBLIC_IP="$2"; shift 2;;
    --desired-count) DESIRED_COUNT="$2"; shift 2;;
    --cpu) CPU="$2"; shift 2;;
    --memory) MEMORY="$2"; shift 2;;
    --ephemeral-storage) EPHEMERAL="$2"; shift 2;;
    --image-tag) IMAGE_TAG="$2"; shift 2;;
    --existing-secret-arn) EXISTING_SECRET_ARN="$2"; shift 2;;
    --lumos-api-key) LUMOS_API_KEY="$2"; shift 2;;
    --log-to-stdout) LOG_TO_STDOUT="$2"; shift 2;;
    --send-critical-logs) SEND_CRITICAL_LOGS="$2"; shift 2;;
    --log-level) LOG_LEVEL="$2"; shift 2;;
    --proxy-url) PROXY_URL="$2"; shift 2;;
    *) echo "Unknown flag: $1"; exit 1;;
  esac
done

if [[ -z "$STACK_NAME" || -z "$VPC_ID" || -z "$SUBNET_IDS" ]]; then
  echo "Required: --stack-name, --vpc-id, --subnet-ids"
  exit 1
fi

PARAMS=(   VpcId="$VPC_ID"   SubnetIds="$SUBNET_IDS"   AssignPublicIp="$ASSIGN_PUBLIC_IP"   DesiredCount="$DESIRED_COUNT"   Cpu="$CPU"   Memory="$MEMORY"   EphemeralStorageGiB="$EPHEMERAL"   ImageTag="$IMAGE_TAG"   LUMOS_LOG_TO_STDOUT="$LOG_TO_STDOUT"   LUMOS_ON_PREMISE_AGENT_SEND_CRITICAL_LOGS_TO_LUMOS="$SEND_CRITICAL_LOGS" )

if [[ -n "$LOG_LEVEL" ]]; then
  PARAMS+=( LUMOS_ON_PREMISE_AGENT_LOG_LEVEL="$LOG_LEVEL" )
fi

if [[ -n "$PROXY_URL" ]]; then
  PARAMS+=( ProxyUrl="$PROXY_URL" )
fi

if [[ -n "$EXISTING_SECRET_ARN" ]]; then
  PARAMS+=( ExistingSecretArn="$EXISTING_SECRET_ARN" )
elif [[ -n "$LUMOS_API_KEY" ]]; then
  PARAMS+=( LumosApiKey="$LUMOS_API_KEY" )
else
  echo "Either --existing-secret-arn or --lumos-api-key must be provided."
  exit 1
fi

aws cloudformation deploy   --stack-name "$STACK_NAME"   --template-file templates/lumos-onprem-agent-ecs.yaml   --capabilities CAPABILITY_NAMED_IAM   --parameter-overrides "${PARAMS[@]}"
