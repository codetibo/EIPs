#!/usr/bin/env bash
#
# sync-eips.sh — Sync EIP files from upstream ethereum/EIPs
#
# This script:
# 1. Adds the upstream repo and fetches the latest master
# 2. Compares EIP files between upstream and local
# 3. Downloads new/modified files from upstream
# 4. Removes files that were deleted upstream (safety check)
# 5. Runs the ERC metadata fetcher to patch ERC stubs with real data
#
# Designed to run in a GitHub Actions workflow (ubuntu-latest) or locally.
# Does NOT commit or push — that is handled by the calling workflow.
# Uses '|| true' on all non-critical steps so the script continues on error.

UPSTREAM_REPO="https://github.com/ethereum/EIPs.git"
UPSTREAM_BRANCH="master"
TARGET_BRANCH="personal-site"
EIPS_DIR="EIPS"
SCRIPT_DIR="scripts"

echo "=== EIP Sync Script ==="
echo "Target branch: $TARGET_BRANCH"
echo "Upstream: $UPSTREAM_REPO ($UPSTREAM_BRANCH)"
echo ""

# ---------------------------------------------------------------
# Step 1: Ensure we're on the right branch
# ---------------------------------------------------------------
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
if [ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]; then
    echo "WARNING: Currently on '$CURRENT_BRANCH', expected '$TARGET_BRANCH'."
    echo "Attempting to switch..."
    git checkout "$TARGET_BRANCH" 2>/dev/null || {
        echo "ERROR: Could not switch to $TARGET_BRANCH branch. Continuing anyway..."
    }
fi
echo "✓ On branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo $CURRENT_BRANCH)"

# ---------------------------------------------------------------
# Step 2: Add upstream remote and fetch
# ---------------------------------------------------------------
if git remote get-url upstream &>/dev/null; then
    echo "✓ Upstream remote already exists"
else
    git remote add upstream "$UPSTREAM_REPO" 2>/dev/null || {
        echo "✓ Upstream remote already exists (race condition)"
    }
fi

echo "Fetching upstream master..."
git fetch upstream "$UPSTREAM_BRANCH" --depth=50 2>&1 | tail -3 || {
    echo "ERROR: Failed to fetch upstream. Check network connectivity."
    echo "Will continue with existing data."
    exit 1
}
echo "✓ Upstream fetched"

UPSTREAM_SHA=$(git rev-parse upstream/$UPSTREAM_BRANCH 2>/dev/null || echo "unknown")
echo "   Upstream HEAD: ${UPSTREAM_SHA:0:12}"

# ---------------------------------------------------------------
# Step 3: Find new/modified EIP files
# ---------------------------------------------------------------
echo ""
echo "--- Checking for new/modified EIP files ---"

# Files that differ between upstream and local (in EIPS/ directory)
CHANGED_FILES=$(git diff --name-only "upstream/$UPSTREAM_BRANCH" -- "$EIPS_DIR/" 2>/dev/null || true)
NEW_COUNT=0
MODIFIED_COUNT=0

if [ -z "$CHANGED_FILES" ]; then
    echo "✓ No EIP files changed upstream."
else
    while IFS= read -r file; do
        [ -z "$file" ] && continue

        if [ ! -f "$file" ]; then
            # New file - checkout from upstream
            echo "  [+] NEW: $file"
            git checkout "upstream/$UPSTREAM_BRANCH" -- "$file" 2>/dev/null || {
                echo "  [!] SKIP: Could not checkout $file"
                continue
            }
            NEW_COUNT=$((NEW_COUNT + 1))
        else
            # Modified file - checkout from upstream
            echo "  [~] MODIFIED: $file"
            git checkout "upstream/$UPSTREAM_BRANCH" -- "$file" 2>/dev/null || {
                echo "  [!] SKIP: Could not checkout $file"
                continue
            }
            MODIFIED_COUNT=$((MODIFIED_COUNT + 1))
        fi
    done <<< "$CHANGED_FILES"
fi

echo ""
echo "Files synced: $NEW_COUNT new, $MODIFIED_COUNT modified"

# ---------------------------------------------------------------
# Step 4: Find files deleted upstream (no longer in EIPS/)
# ---------------------------------------------------------------
echo ""
echo "--- Checking for removed EIP files ---"

# Files that exist locally but not in upstream's EIPS directory
UPSTREAM_FILES=$(mktemp)
LOCAL_FILES=$(mktemp)

# Get list of files from upstream
git ls-tree --name-only "upstream/$UPSTREAM_BRANCH" "$EIPS_DIR/" | sort > "$UPSTREAM_FILES" 2>/dev/null || true

# Get list of files locally (tracked by git)
git ls-tree --name-only HEAD "$EIPS_DIR/" | sort > "$LOCAL_FILES" 2>/dev/null || true

# Find files that are local but not upstream
REMOVED_COUNT=0
while IFS= read -r file; do
    [ -z "$file" ] && continue
    echo "  [-] REMOVED: $file"
    git rm --cached "$file" 2>/dev/null || true
    rm -f "$file" 2>/dev/null || true
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
done < <(comm -23 "$LOCAL_FILES" "$UPSTREAM_FILES" 2>/dev/null || true)

rm -f "$UPSTREAM_FILES" "$LOCAL_FILES"

if [ "$REMOVED_COUNT" -eq 0 ]; then
    echo "✓ No files removed upstream."
else
    echo "Removed $REMOVED_COUNT file(s) that no longer exist upstream."
fi

# ---------------------------------------------------------------
# Step 5: Run ERC metadata fetcher to patch ERC stubs
# ---------------------------------------------------------------
echo ""
echo "--- Updating ERC metadata ---"
if [ -f "$SCRIPT_DIR/fetch-erc-metadata.py" ]; then
    python3 "$SCRIPT_DIR/fetch-erc-metadata.py" 2>&1 || {
        echo "⚠ WARNING: ERC metadata script failed, continuing..."
    }
else
    echo "⚠ WARNING: $SCRIPT_DIR/fetch-erc-metadata.py not found, skipping ERC patch."
fi

# ---------------------------------------------------------------
# Step 6: Check for any changes and summarize
# ---------------------------------------------------------------
echo ""
echo "--- Summary ---"
echo "  New EIP files:      $NEW_COUNT"
echo "  Modified EIP files: $MODIFIED_COUNT"
echo "  Removed EIP files:  $REMOVED_COUNT"

CHANGE_COUNT=$((NEW_COUNT + MODIFIED_COUNT + REMOVED_COUNT))
if [ "$CHANGE_COUNT" -gt 0 ]; then
    echo ""
    echo "✓ Changes detected. Ready to commit."
else
    echo ""
    echo "✓ No changes to commit. Everything is up to date."
fi