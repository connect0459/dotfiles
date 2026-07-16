export BASH_SILENCE_DEPRECATION_WARNING=1

. "$HOME/.local/bin/env"
. "$HOME/.cargo/env"

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Automatic Startup and Management of SSH Agent
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

# Set up the SSH agent
ssh_agent_setup

# Starting Colima
if command -v colima &> /dev/null; then
    if ! colima status &> /dev/null; then
        colima start
    fi
fi

[[ -f ~/.bashrc ]] && . ~/.bashrc

export PATH="$HOME/bin:$PATH"

# AWS
export AWS_SESSION_TOKEN_TTL=12h

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# JDK
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"

# Android SDK tools
export PATH="/opt/homebrew/share/android-commandlinetools/emulator:/opt/homebrew/share/android-commandlinetools/platform-tools:$PATH"
