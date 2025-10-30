#!/bin/bash

set -e

# Trap handlers
trap 'echo "‼️ The script terminated with an error on line $LINENO. Error code: $?" >&2' ERR
trap 'catch_exit $?' EXIT

# Process exit
catch_exit() {
    if [ "$1" -eq 0 ]; then
        echo "✅ Project bootstrap finished."
    else
        echo "‼️ The script terminated with an error. Error code: $1" >&2
    fi
}

projectBootstrapArtText="$(base64 -D <<< "X19fX19fICAgICAgICAgIF8gICAgICAgICAgIF8gICAKfCBfX18gXCAgICAgICAgKF8pICAgICAgICAgfCB8ICAKfCB8Xy8gLyBfXyBfX18gIF8gIF9fXyAgX19ffCB8XyAKfCAgX18vICdfXy8gXyBcfCB8LyBfIFwvIF9ffCBfX3wKfCB8ICB8IHwgfCAoXykgfCB8ICBfXy8gKF9ffCB8XyAKXF98ICB8X3wgIFxfX18vfCB8XF9fX3xcX19ffFxfX3wKICAgICAgICAgICAgICBfLyB8ICAgICAgICAgICAgICAKICAgICAgICAgICAgIHxfXy8gICAgICAgICAgICAgICAKIF9fX19fICAgICAgXyAgICAgICAgICAgICAgICAgICAKLyAgX19ffCAgICB8IHwgICAgICAgICAgICAgICAgICAKXCBgLS0uICBfX198IHxfIF8gICBfIF8gX18gICAgICAKIGAtLS4gXC8gXyBcIF9ffCB8IHwgfCAnXyBcICAgICAKL1xfXy8gLyAgX18vIHxffCB8X3wgfCB8XykgfCAgICAKXF9fX18vIFxfX198XF9ffFxfXyxffCAuX18vICAgICAKICAgICAgICAgICAgICAgICAgICAgfCB8ICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgfF98ICAgICAgICA=")"
echo "$projectBootstrapArtText"
echo ""
echo "Bootstrapping WHIMO iOS project."

# Check if Homebrew is already installed
if command -v brew &> /dev/null; then
    echo "✅ Homebrew is already installed at: $(which brew)"
    brew --version
else
    echo "📦 Installing Homebrew..."
    
    # Modern Homebrew installation (works for both Intel and Apple Silicon)
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Configure PATH for Apple Silicon
    if [[ $(arch) == 'arm64' ]]; then
        echo "🍎 Detected Apple Silicon - configuring PATH for /opt/homebrew"
        
        # Add Homebrew to PATH for this session
        eval "$(/opt/homebrew/bin/brew shellenv)"
        
        # Add to shell profile if not already present
        SHELL_PROFILE="${HOME}/.zprofile"
        if ! grep -q "/opt/homebrew/bin/brew shellenv" "$SHELL_PROFILE" 2>/dev/null; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$SHELL_PROFILE"
            echo "✅ Added Homebrew to $SHELL_PROFILE"
        fi
    else
        echo "💻 Detected Intel chip"
        # Intel Macs use /usr/local which is usually already in PATH
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# Install SwiftLint
echo "📦 Installing SwiftLint..."
if brew list swiftlint &> /dev/null; then
    echo "✅ SwiftLint is already installed"
    brew upgrade swiftlint || true
else
    brew install swiftlint
fi

echo "✅ SwiftLint version: $(swiftlint version)"