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

if [ -f "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi

# cargo
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

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
