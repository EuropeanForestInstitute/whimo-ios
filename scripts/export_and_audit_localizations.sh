#!/bin/bash

set -e

# Trap handlers
trap 'echo "‼️ The script terminated with an error on line $LINENO. Error code: $?" >&2' ERR
trap 'catch_exit $?' EXIT

# Process exit
catch_exit() {
    if [ "$1" -eq 0 ]; then
        echo "✅ Localization export and audit finished successfully."
    else
        echo "‼️ The script terminated with an error. Error code: $1" >&2
    fi
}

echo "=================================================="
echo "🌍 Localization Export and Audit"
echo "=================================================="
echo ""

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
XCODE_PROJECT="$PROJECT_ROOT/Whimo.xcodeproj"
SCHEME_NAME="Whimo Dev"
EXPORT_DIR="$PROJECT_ROOT/localization_audit/Resources Localizations"
PYTHON_SCRIPTS_DIR="$PROJECT_ROOT/localization_audit"

echo "📂 Project root: $PROJECT_ROOT"
echo "📦 Xcode project: $XCODE_PROJECT"
echo "🎯 Scheme: $SCHEME_NAME"
echo "📤 Export directory: $EXPORT_DIR"
echo ""

# Step 1: Clean previous exports
echo "🧹 Cleaning previous localization exports..."
if [ -d "$EXPORT_DIR" ]; then
    rm -rf "$EXPORT_DIR"
    echo "   Removed existing exports"
fi
mkdir -p "$EXPORT_DIR"
echo ""

# Step 2: Export localizations using xcodebuild
echo "📥 Exporting localizations from Xcode..."
cd "$PROJECT_ROOT"
xcodebuild -exportLocalizations \
    -project "$XCODE_PROJECT" \
    -scheme "$SCHEME_NAME" \
    -localizationPath "$EXPORT_DIR" \
    -exportLanguage en \
    -exportLanguage fr \
    -exportLanguage es

echo "✅ Localizations exported successfully"
echo ""

# Step 3: Setup Python environment
echo "🐍 Setting up Python environment..."
cd "$PYTHON_SCRIPTS_DIR"

if [ ! -d "venv" ]; then
    echo "   Creating virtual environment..."
    python3 -m venv venv
    echo "   ✅ Virtual environment created"
else
    echo "   ✅ Virtual environment already exists"
fi

echo "   Activating virtual environment..."
source venv/bin/activate

echo "   Installing/updating dependencies..."
pip install -q --upgrade pip
pip install -q -r requirements.txt
echo "   ✅ Dependencies installed"
echo ""

# Step 4: Run Python scripts
echo "📊 Generating localization audit tables..."
echo ""

echo "1️⃣  Running create_localization_excel.py..."
python3 create_localization_excel.py
echo ""

echo "2️⃣  Running update_permissions_localization.py..."
python3 update_permissions_localization.py
echo ""

# Step 5: Cleanup
deactivate

# Summary
echo "=================================================="
echo "✅ All tasks completed successfully!"
echo "=================================================="
echo ""
echo "Generated files:"
echo "  📄 $PYTHON_SCRIPTS_DIR/localization_audit.xlsx"
echo "  📄 $PYTHON_SCRIPTS_DIR/permissions_localization.xlsx"
echo ""
echo "Exported localizations:"
echo "  📁 $EXPORT_DIR"
echo ""

