# ls / grep color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Git
_git_default_branch() {
    local has_main has_master

    git show-ref --verify --quiet refs/heads/main && has_main=1
    git show-ref --verify --quiet refs/heads/master && has_master=1

    if [[ -n "$has_main" && -n "$has_master" ]]; then
        echo "Error: Both 'main' and 'master' exist. Please specify the base branch." >&2
        return 1
    fi

    local default_branch
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    if [[ -z "$default_branch" ]]; then
        echo "Error: Could not determine the default branch from origin/HEAD." >&2
        return 1
    fi

    echo "$default_branch"
}

git_cleanup() {
    git fetch --prune || return 1

    local default_branch
    default_branch=$(_git_default_branch) || return 1

    git checkout "$default_branch" || return 1
    git pull origin "$default_branch" || return 1

    git branch --merged "$default_branch" \
        | grep -v "^\*" \
        | grep -v " $default_branch$" \
        | xargs -r git branch -d
}

git_cleanup_all() {
    git fetch --prune || return 1

    local default_branch
    default_branch=$(_git_default_branch) || return 1

    git checkout "$default_branch" || return 1
    git pull origin "$default_branch" || return 1

    git branch \
        | grep -v "^\*" \
        | grep -v " $default_branch$" \
        | xargs -r git branch -D
}

git_rebase_default() {
    local default_branch
    default_branch=$(_git_default_branch) || return 1

    local current_branch
    current_branch=$(git branch --show-current)

    if [[ -z "$current_branch" ]]; then
        echo "Error: Not on a branch (detached HEAD)." >&2
        return 1
    fi

    if [[ "$current_branch" == "$default_branch" ]]; then
        echo "Already on the default branch '$default_branch'." >&2
        return 0
    fi

    git checkout "$default_branch" || return 1
    git pull origin "$default_branch" || return 1
    git checkout - || return 1
    git rebase "$default_branch"
}

alias alias_gc='git_cleanup'
alias alias_gca='git_cleanup_all'
alias alias_grd='git_rebase_default'
