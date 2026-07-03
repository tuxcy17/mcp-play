#!/usr/bin/env bash
# Delete GHCR image versions that are not from the main branch.
#
# Kept:   versions tagged 'main', 'latest', or a semver (v?x.y.z)
# Deleted: everything else (PR images, feature branches, untagged layers)
#
# Usage:
#   DRY_RUN=true bash .ops/scripts/ghcr-cleanup.sh   # preview without deleting
#   bash .ops/scripts/ghcr-cleanup.sh                 # delete for real
#
# Requirements: gh CLI authenticated with packages:read+write scope.
# In GitHub Actions, GITHUB_TOKEN with 'packages: write' permission is enough.

set -euo pipefail

# ── resolve owner / package ───────────────────────────────────────────────────
OWNER="${GITHUB_REPOSITORY_OWNER:-$(gh api /user --jq '.login')}"
# Package name on GHCR matches the repo name (lowercased)
PACKAGE="${GITHUB_REPOSITORY##*/}"
PACKAGE="${PACKAGE,,}"

# ── org vs user API base ──────────────────────────────────────────────────────
if gh api "/orgs/${OWNER}" --silent 2>/dev/null; then
  API_BASE="orgs/${OWNER}"
else
  API_BASE="user"
fi

ENDPOINT="/${API_BASE}/packages/container/${PACKAGE}/versions"

echo "Registry : ghcr.io/${OWNER}/${PACKAGE}"
echo "Keeping  : main · latest · semver (v?x.y.z)"
echo "Endpoint : ${ENDPOINT}"
echo

# ── fetch all versions and select candidates for deletion ─────────────────────
ALL=$(gh api --paginate "$ENDPOINT")

TO_DELETE=$(echo "$ALL" | jq '[
  .[] |
  select(
    (.metadata.container.tags // [] |
      map(test("^(main|latest|v?[0-9]+\\.[0-9]+\\.[0-9]+)")) |
      any
    ) | not
  ) |
  {id: .id, tags: (.metadata.container.tags // [])}
]')

COUNT=$(echo "$TO_DELETE" | jq 'length')

if [[ "$COUNT" -eq 0 ]]; then
  echo "Nothing to delete — all versions are from main or are releases."
  exit 0
fi

echo "Versions to delete: ${COUNT}"
echo "$TO_DELETE" | jq -r '.[] | "  id=\(.id)  tags=[\(.tags | join(", "))]"'
echo

# ── dry-run guard ─────────────────────────────────────────────────────────────
if [[ "${DRY_RUN:-false}" == "true" ]]; then
  echo "DRY_RUN=true — no deletions performed."
  exit 0
fi

# ── delete ────────────────────────────────────────────────────────────────────
FAILED=0
while read -r vid; do
  if gh api --method DELETE "${ENDPOINT}/${vid}" 2>/dev/null; then
    echo "Deleted  ${vid}"
  else
    echo "Failed   ${vid} (still referenced by a multi-arch manifest?)"
    FAILED=$((FAILED + 1))
  fi
done < <(echo "$TO_DELETE" | jq -r '.[].id')

echo
echo "Done. Deleted: $((COUNT - FAILED))  Failed: ${FAILED}"
[[ "$FAILED" -eq 0 ]]
