#!/bin/bash
# init.sh — Initialize this template as your own project
#
# Usage:
#   ./init.sh                           # Interactive mode
#   ./init.sh my-project                # Create new repo: github.com/<you>/my-project
#   ./init.sh git@github.com:user/repo  # Adopt existing repo
#   ./init.sh https://github.com/u/repo # Adopt existing repo (https)
#
# This will:
# 1. Replace template placeholders with your project info
# 2. Reset git history to a clean initial commit
# 3. Configure the remote and push

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}→${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }

# Check we're at the root of a git repo (handles worktrees/submodules where .git is a file)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || error "Not in a git repository."
if [ "$PWD" != "$REPO_ROOT" ]; then
    error "Not at repository root. Run this from: $REPO_ROOT"
fi

# Check gh CLI is available (needed for creating new repos)
check_gh() {
    if ! command -v gh &> /dev/null; then
        error "GitHub CLI (gh) not found. Install it: https://cli.github.com"
    fi
    if ! gh auth status &> /dev/null; then
        error "Not logged into GitHub CLI. Run: gh auth login"
    fi
}

# Detect if argument is a git URL
is_git_url() {
    local arg="$1"
    [[ "$arg" =~ ^git@ ]] || [[ "$arg" =~ ^https://github\.com ]] || [[ "$arg" =~ ^git://github\.com ]]
}

# Validate project slug (a-z, 0-9, hyphens only, min 2 chars)
validate_slug() {
    local slug="$1"
    if [[ ! "$slug" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]]; then
        error "Invalid project name '$slug'. Use only lowercase letters, numbers, and hyphens (min 2 characters)."
    fi
}

# Validate display name (allowlist: letters, numbers, spaces, hyphens, basic punctuation)
validate_display_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-zA-Z0-9\ \.\,\'\!\?\-]+$ ]]; then
        error "Display name can only contain letters, numbers, spaces, hyphens, and basic punctuation (. , ' ! ?)"
    fi
}

# Extract repo name from URL for display
repo_name_from_url() {
    local url="$1"
    basename "$url" .git
}

# Check if remote has existing commits
check_remote_empty() {
    local url="$1"
    if git ls-remote --heads "$url" 2>/dev/null | grep -q .; then
        warn "Remote already has commits!"
        echo ""
        echo "  This will push a new 'main' branch. If the remote has a main branch,"
        echo "  the push will fail (we don't force-push)."
        echo ""
        read -p "Continue anyway? [y/N]: " remote_confirm
        if [[ ! "$remote_confirm" =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 0
        fi
    fi
}

# Replace placeholders in template files
replace_placeholders() {
    local project_name="$1"
    local project_slug="$2"
    local date=$(date +%Y-%m-%d)

    info "Replacing template placeholders..."

    # Find and replace in all markdown files
    find . -type f -name "*.md" -not -path "./.git/*" | while read -r file; do
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/{{PROJECT_NAME}}/$project_name/g" "$file" 2>/dev/null || true
            sed -i '' "s/{{project_slug}}/$project_slug/g" "$file" 2>/dev/null || true
            sed -i '' "s/{{DATE}}/$date/g" "$file" 2>/dev/null || true
        else
            sed -i "s/{{PROJECT_NAME}}/$project_name/g" "$file" 2>/dev/null || true
            sed -i "s/{{project_slug}}/$project_slug/g" "$file" 2>/dev/null || true
            sed -i "s/{{DATE}}/$date/g" "$file" 2>/dev/null || true
        fi
    done
}

# Create README for the new project
create_readme() {
    local project_name="$1"

    cat > README.md << EOF
# $project_name

## Quick Start

1. Read \`spec/MASTER.md\` for project overview
2. Run \`/interrogate spec/architecture/overview\` to start speccing

## Structure

- \`spec/\` — Technical specifications (for agents)
- \`docs/\` — Human documentation
- \`.claude/\` — Agent commands and conventions

## Commands

- \`/interrogate <spec>\` — Deepen a specification through Q&A
- \`/ingest <notes>\` — Extract spec content from unstructured notes
- \`/human-docs <spec>\` — Generate human-readable documentation
EOF
}

# Reset git history and configure remote
setup_git() {
    local remote_url="$1"
    local project_name="$2"

    info "Resetting git history..."

    # Remove old git and start fresh
    rm -rf .git
    git init -q

    # Remove this init script from the new project
    rm -f init.sh

    # Stage everything
    git add .
    git commit -q -m "Initial commit: $project_name

Initialized from dream-machine template."

    # Configure remote
    info "Configuring remote: $remote_url"
    git remote add origin "$remote_url"

    # Rename branch to main if needed
    git branch -M main
}

# Push to remote
push_to_remote() {
    info "Pushing to remote..."
    git push -u origin main
}

# --- Main Logic ---

ARG="$1"
PROJECT_NAME=""
PROJECT_SLUG=""
REMOTE_URL=""

if [ -z "$ARG" ]; then
    # Interactive mode
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║     Dream Machine → Your Project       ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "How do you want to initialize?"
    echo ""
    echo "  1) Create a NEW GitHub repo"
    echo "  2) Use an EXISTING GitHub repo"
    echo ""
    read -p "Choose [1/2]: " choice
    echo ""

    case "$choice" in
        1)
            check_gh
            read -p "Project name (e.g., my-awesome-project): " PROJECT_SLUG
            [ -z "$PROJECT_SLUG" ] && error "Project name required"
            validate_slug "$PROJECT_SLUG"

            # Convert to title case for display name
            PROJECT_NAME=$(echo "$PROJECT_SLUG" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
            read -p "Display name [$PROJECT_NAME]: " custom_name
            [ -n "$custom_name" ] && PROJECT_NAME="$custom_name"

            # Ask about visibility
            read -p "Make repo public? [y/N]: " visibility_choice
            if [[ "$visibility_choice" =~ ^[Yy]$ ]]; then
                REPO_VISIBILITY="--public"
            else
                REPO_VISIBILITY="--private"
            fi

            # Create the repo
            info "Creating GitHub repo: $PROJECT_SLUG"
            gh repo create "$PROJECT_SLUG" $REPO_VISIBILITY --source=. --push=false
            REMOTE_URL=$(gh repo view "$PROJECT_SLUG" --json sshUrl -q .sshUrl)
            ;;
        2)
            read -p "Repo URL (git@github.com:user/repo.git): " REMOTE_URL
            [ -z "$REMOTE_URL" ] && error "Repo URL required"

            PROJECT_SLUG=$(repo_name_from_url "$REMOTE_URL")
            validate_slug "$PROJECT_SLUG"
            check_remote_empty "$REMOTE_URL"
            PROJECT_NAME=$(echo "$PROJECT_SLUG" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
            read -p "Display name [$PROJECT_NAME]: " custom_name
            [ -n "$custom_name" ] && PROJECT_NAME="$custom_name"
            ;;
        *)
            error "Invalid choice"
            ;;
    esac

elif is_git_url "$ARG"; then
    # Adopt existing repo
    REMOTE_URL="$ARG"
    PROJECT_SLUG=$(repo_name_from_url "$REMOTE_URL")
    validate_slug "$PROJECT_SLUG"
    check_remote_empty "$REMOTE_URL"
    PROJECT_NAME=$(echo "$PROJECT_SLUG" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

else
    # Create new repo with given name
    check_gh
    PROJECT_SLUG="$ARG"
    validate_slug "$PROJECT_SLUG"
    PROJECT_NAME=$(echo "$PROJECT_SLUG" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

    info "Creating GitHub repo: $PROJECT_SLUG"
    gh repo create "$PROJECT_SLUG" --private --source=. --push=false
    REMOTE_URL=$(gh repo view "$PROJECT_SLUG" --json sshUrl -q .sshUrl)
fi

# Validate display name before proceeding
validate_display_name "$PROJECT_NAME"

echo ""
info "Project: $PROJECT_NAME ($PROJECT_SLUG)"
info "Remote:  $REMOTE_URL"
echo ""

# Confirm before proceeding
read -p "Proceed? This will reset git history. [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""

# Do the work
replace_placeholders "$PROJECT_NAME" "$PROJECT_SLUG"
create_readme "$PROJECT_NAME"
setup_git "$REMOTE_URL" "$PROJECT_NAME"
push_to_remote

echo ""
echo -e "${GREEN}✓${NC} Done! Your project is ready."

# Check if directory name matches project slug
CURRENT_DIR=$(basename "$PWD")
if [ "$CURRENT_DIR" != "$PROJECT_SLUG" ]; then
    echo ""
    warn "Directory is still named '$CURRENT_DIR' but project is '$PROJECT_SLUG'"
    read -p "Rename directory to match? [Y/n]: " rename_confirm

    if [[ ! "$rename_confirm" =~ ^[Nn]$ ]]; then
        PARENT_DIR=$(dirname "$PWD")
        TARGET_PATH="$PARENT_DIR/$PROJECT_SLUG"

        if [ -e "$TARGET_PATH" ]; then
            error "Cannot rename: '$TARGET_PATH' already exists."
        fi

        cd "$PARENT_DIR"
        mv "$CURRENT_DIR" "$PROJECT_SLUG"
        echo ""
        echo -e "${GREEN}✓${NC} Renamed: $CURRENT_DIR → $PROJECT_SLUG"
        echo ""
        echo -e "${YELLOW}Your shell is now in a stale directory. Run:${NC}"
        echo ""
        echo "  cd $TARGET_PATH"
        echo ""
    fi
fi

echo ""
echo "Next steps:"
echo "  1. Edit spec/MASTER.md to define your project's domains"
echo "  2. Run /interrogate spec/architecture/overview to start speccing"
echo ""
