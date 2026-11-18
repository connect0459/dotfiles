# for Android SDK
export PATH="${PATH}:${HOME}/Library/Android/sdk/emulator"
export PATH="${PATH}:${HOME}/Library/Android/sdk/platform-tools"

# rancher desktop
if [ -d "$HOME/.rd/bin" ]; then
    export PATH="$HOME/.rd/bin:$PATH"
fi
