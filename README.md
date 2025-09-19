# Lumos On‑Premise Agent on AWS ECS (CloudFormation)

This repository contains an AWS CloudFormation template that deploys the **Lumos On‑Premise Agent** on **ECS Fargate (x86_64)** with logs to CloudWatch and the API key stored in **AWS Secrets Manager**.

> Why ECS/Fargate? The Lumos docs support running the agent as a container; ECS Fargate gives you a managed runtime with rollbacks via CloudFormation and repeatable deployments. ARM is not supported; we explicitly set **X86_64**. (See the Lumos installation guide for details.)

## What this stack creates

- ECS **cluster**, **task definition** and **service** (Fargate, `awsvpc`).
- **CloudWatch Logs** group with configurable retention.
- **IAM roles** for task execution and task runtime.
- **Secrets Manager** secret for `LUMOS_ON_PREMISE_AGENT_API_KEY` (either created by the stack or you can provide an existing secret).
- A **security group** that allows outbound traffic (needed for HTTPS to Lumos and any internal directories/DBs your connectors reach).
- Parameters for CPU/memory, ephemeral storage, desired count, proxy settings, and log level.

## Prerequisites

- AWS account + permissions to create IAM roles, ECS, Secrets Manager, CloudWatch Logs and Security Groups.
- A VPC with subnets that have **Internet egress** (public subnets with `AssignPublicIp=ENABLED`, or private subnets with a NAT Gateway).
- Lumos **On‑Prem Agent token** from your Lumos admin UI.

## Quick start

```bash
# 1) (Optional) create a secret for your agent API key
aws secretsmanager create-secret   --name LumosOnPremApiKey   --secret-string 'lsk_...your_agent_token...'   --description "Lumos On-Prem Agent API key"

# 2) Deploy the stack using an EXISTING secret
aws cloudformation deploy   --stack-name lumos-agent-ecs   --template-file templates/lumos-onprem-agent-ecs.yaml   --capabilities CAPABILITY_NAMED_IAM   --parameter-overrides       VpcId=vpc-0123456789abcdef0       SubnetIds='subnet-aaaabbbb,subnet-ccccdddd'       AssignPublicIp=DISABLED       ExistingSecretArn=arn:aws:secretsmanager:us-east-1:123456789012:secret:LumosOnPremApiKey-abc       DesiredCount=2 Cpu=2048 Memory=16384 EphemeralStorageGiB=64 ImageTag=latest       LUMOS_LOG_TO_STDOUT=true LUMOS_ON_PREMISE_AGENT_SEND_CRITICAL_LOGS_TO_LUMOS=false

# OR 2b) Let the stack CREATE the secret for you (pass the API key directly)
aws cloudformation deploy   --stack-name lumos-agent-ecs   --template-file templates/lumos-onprem-agent-ecs.yaml   --capabilities CAPABILITY_NAMED_IAM   --parameter-overrides       VpcId=vpc-0123456789abcdef0       SubnetIds='subnet-aaaabbbb,subnet-ccccdddd'       AssignPublicIp=ENABLED       LumosApiKey='lsk_...your_agent_token...'       DesiredCount=1 ImageTag=latest
```

## Parameters (highlights)

- `VpcId`, `SubnetIds`, `AssignPublicIp` – where the service runs. Ensure the subnets have outbound Internet.
- `ExistingSecretArn` **or** `LumosApiKey` – how to supply `LUMOS_ON_PREMISE_AGENT_API_KEY`.
- `Cpu`/`Memory` – Fargate sizes; defaults to **2 vCPU / 16 GiB** (per doc guidance).
- `EphemeralStorageGiB` – default **64 GiB** for `/onprem/agent` working space.
- `LUMOS_LOG_TO_STDOUT` – default **true** (sends agent & connector logs to stdout for CloudWatch).
- `ProxyUrl` – sets `HTTP_PROXY` and `HTTPS_PROXY` if you require an outbound proxy.
- `LUMOS_ON_PREMISE_AGENT_SEND_CRITICAL_LOGS_TO_LUMOS` – opt-in forwarding of **Error+** logs.

## Networking

The service does not expose inbound ports. It needs:
- Outbound **HTTPS (443)** to `integration-proxy.lumos.com`.
- Outbound access to your **internal directories/DBs** on their respective ports (e.g., **636** for AD). Use route/VPN/Direct Connect as appropriate and tighten the security group egress rules to your environment.

## Operations

- View logs in **CloudWatch Logs** (log group output by the stack).
- See agent status in Lumos UI (**Integrations → Agents**; should show *Connected*).
- For updates, change `ImageTag` or parameters and re‑deploy the stack. Use **Change Sets** for safe previews.

---

*Provenance:* This template follows the official Lumos On‑Premise Agent installation guidance (supported platforms, x86_64, environment variables, logging to stdout for ECS, and outbound HTTPS requirement).
