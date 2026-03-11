#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR"

BASE_REF="${GITHUB_BASE_REF:-}"
HEAD_REF="${GITHUB_HEAD_REF:-HEAD}"

if [[ -z "$BASE_REF" ]]; then
  if git rev-parse HEAD~1 >/dev/null 2>&1; then
    BASE_REF="HEAD~1"
  else
    BASE_REF="HEAD"
  fi
fi

mapfile -t ALL_ROLES < <(find "${ROOT_DIR}/roles/" -type d -mindepth 1 -maxdepth 1 -exec basename {} \;)
declare -A ROLE_SCENARIOS
for role in "${ALL_ROLES[@]}"; do
  if [[ -z "${ROLE_SCENARIOS[$role]:-}" ]]; then
    ROLE_SCENARIOS["$role"]="$role"
  fi
done
declare -a OS_VARIANTS=("fedora42" "fedora43")

changed_roles=()
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  rel="${file#roles/}"
  role="${rel%%/*}"
  if [[ -n "${ROLE_SCENARIOS[$role]:-}" ]]; then
    if [[ ! " ${changed_roles[*]} " =~ " ""${role}"" " ]]; then
      changed_roles+=("$role")
    fi
  fi
done < <(git diff --name-only "$BASE_REF" "$HEAD_REF" -- 'roles/*' || true)

matrix_items=()
append_combos() {
  local role="$1"
  local scenario="${ROLE_SCENARIOS[$role]}"
  for os_variant in "${OS_VARIANTS[@]}"; do
    matrix_items+=("{\"os_variant\":\"${os_variant}\",\"scenario\":\"${scenario}\"}")
  done
}

if [[ ${#changed_roles[@]} -eq 0 ]]; then
  for role in "${ALL_ROLES[@]}"; do
    append_combos "$role"
  done
else
  for role in "${changed_roles[@]}"; do
    append_combos "$role"
  done
fi

if [[ ${#matrix_items[@]} -eq 0 ]]; then
  matrix_json='{"include":[]}'
else
  matrix_json="{\"include\":["
  delim=""
  for entry in "${matrix_items[@]}"; do
    matrix_json+="${delim}${entry}"
    delim=","
  done
  matrix_json+="]}"
fi
printf '%s\n' "$matrix_json"
