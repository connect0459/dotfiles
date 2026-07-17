# Load bash_aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# cargo
. "$HOME/.cargo/env"

# ecnavi-enquete-app-android
export PATH="${PATH}:${HOME}/Library/Android/sdk/emulator"
export PATH="${PATH}:${HOME}/Library/Android/sdk/platform-tools"

# Haskell
[ -f "/Users/akira/.ghcup/env" ] && . "/Users/akira/.ghcup/env" # ghcup-env

# mise
export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate bash)"

# moonbit
export PATH="$HOME/.moon/bin:$PATH"
