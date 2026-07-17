# Git
git_cleanup() {
    local has_main has_master

    git show-ref --verify --quiet refs/heads/main && has_main=1
    git show-ref --verify --quiet refs/heads/master && has_master=1

    if [[ -n "$has_main" && -n "$has_master" ]]; then
        echo "Error: Both 'main' and 'master' exist. Please specify the base branch." >&2
        return 1
    fi

    git fetch --prune || return 1

    local default_branch
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    if [[ -z "$default_branch" ]]; then
        echo "Error: Could not determine the default branch from origin/HEAD." >&2
        return 1
    fi

    git checkout "$default_branch" || return 1
    git pull origin "$default_branch" || return 1

    git branch --merged "$default_branch" \
        | grep -v "^\*" \
        | grep -v " $default_branch$" \
        | xargs -r git branch -d
}
