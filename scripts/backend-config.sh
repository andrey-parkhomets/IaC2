#!/usr/bin/env bash
# Writes backend.hcl for every state container created by bootstrap:
# "bootstrap" goes into bootstrap/, every environment into envs/<env>/.
# Usage: scripts/backend-config.sh
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
config=$(terraform -chdir="$repo_root/bootstrap" output -json backend_config)

for env in $(jq -r 'keys[]' <<<"$config"); do
  if [[ $env == bootstrap ]]; then
    target=$repo_root/bootstrap
  else
    target=$repo_root/envs/$env
  fi
  mkdir -p "$target"
  jq -r --arg env "$env" '.[$env] | to_entries[] | "\(.key) = \(.value | tojson)"' <<<"$config" >"$target/backend.hcl"
  echo "wrote $target/backend.hcl"
done
