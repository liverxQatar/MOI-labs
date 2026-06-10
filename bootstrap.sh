#!/usr/bin/env bash
###############################################################################
# MOI Training Academy - Bootstrap Script (Cloud Shell / Linux)
# Provisions all GCP resources (deploy only). State is kept LOCALLY
# (terraform.tfstate in this directory) — no remote GCS backend.
# Usage:
#   ./bootstrap.sh -p <project_id> -r <region>
###############################################################################

set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
INFO="\033[0;36m[INFO]  \033[0m"
OK="\033[0;32m[OK]    \033[0m"
ERR="\033[0;31m[ERROR] \033[0m"
WARN="\033[0;33m[WARN]  \033[0m"
SEP="\033[0;90m---------------------------------------------\033[0m"

info() { echo -e "${INFO}$1"; }
ok()   { echo -e "${OK}$1"; }
warn() { echo -e "${WARN}$1"; }
err()  { echo -e "${ERR}$1"; exit 1; }

# ─── Parse Arguments ──────────────────────────────────────────────────────────
PROJECT_ID=""
REGION=""

while getopts "p:r:" opt; do
  case $opt in
    p) PROJECT_ID="$OPTARG" ;;
    r) REGION="$OPTARG" ;;
    *) err "Invalid option. Usage: ./bootstrap.sh -p <project_id> -r <region>" ;;
  esac
done

# Validate required args
[[ -z "$PROJECT_ID" ]] && err "Project ID is required. Use -p <project_id>"
[[ -z "$REGION" ]]     && err "Region is required. Use -r <region>"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

###############################################################################
# APPLY
###############################################################################

# Step 1: Set active project
info "Step 1/3 - Setting active project..."
gcloud config set project "$PROJECT_ID"
ok "Active project: $PROJECT_ID"

# Step 2: terraform init (local state).
# Remove any stale backend record (e.g. a previously configured GCS backend) so
# switching to local state doesn't trigger a reinit/migration error.
info "Step 2/3 - Running terraform init..."
rm -f .terraform/terraform.tfstate
terraform init
ok "Terraform initialized (local state)."

# Step 3: terraform apply
info "Step 3/3 - Running terraform apply..."
terraform apply -auto-approve
ok "Bootstrap complete!"

echo ""
echo -e "$SEP"
echo -e "  Project : ${PROJECT_ID}"
echo -e "  Region  : ${REGION}"
echo -e "  State   : ${SCRIPT_DIR}/terraform.tfstate (local)"
echo -e "$SEP"
echo ""
info "Run 'terraform output' to see all created resource IDs."
warn "State is local — back up terraform.tfstate; you need it to manage/destroy later."
