export BASH_SILENCE_DEPRECATION_WARNING=1

# Homebrew (must run before loading bashrc, which initializes rbenv/mise/etc.
# that rely on Homebrew-installed binaries being on PATH)
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Load bashrc
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

. "$HOME/.local/bin/env"

# cargo
. "$HOME/.cargo/env"

# Starting Colima
if command -v colima &> /dev/null; then
    if ! colima status &> /dev/null; then
        colima start
    fi
fi

export PATH="$HOME/bin:$PATH"

# AWS
export AWS_SESSION_TOKEN_TTL=12h

# Android SDK tools
if [ -d /opt/homebrew/share/android-commandlinetools ]; then
    export PATH="/opt/homebrew/share/android-commandlinetools/emulator:/opt/homebrew/share/android-commandlinetools/platform-tools:$PATH"
fi
