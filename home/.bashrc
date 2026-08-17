# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# history
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

shopt -s checkwinsize

# less: friendlier output for non-text files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# debian_chroot (used in prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# prompt
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# Load bash_aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# bash completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# ssh-agent
ssh_agent_setup() {
  if [ -S "$SSH_AUTH_SOCK" ]; then
    ssh-add -l &>/dev/null
    if [ $? -eq 2 ]; then
      eval "$(ssh-agent -s)" >/dev/null
      echo "SSH agent started"
    fi
  else
    eval "$(ssh-agent -s)" >/dev/null
    echo "SSH agent started"
  fi

  ssh-add -l &>/dev/null
  if [ $? -eq 1 ]; then
    ssh-add 2>/dev/null && echo "SSH key added"
  fi
}
ssh_agent_setup

# cargo
. "$HOME/.cargo/env"

# ecnavi-enquete-app-android
export PATH="${PATH}:${HOME}/Library/Android/sdk/emulator"
export PATH="${PATH}:${HOME}/Library/Android/sdk/platform-tools"

# Haskell
[ -f "/Users/akira/.ghcup/env" ] && . "/Users/akira/.ghcup/env" # ghcup-env

# mise
export PATH="$HOME/.local/bin:$PATH"
command -v mise &> /dev/null && eval "$(mise activate bash)"

# moonbit
export PATH="$HOME/.moon/bin:$PATH"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - bash)"
