# WHIMO iOS

![Swift Version](https://img.shields.io/badge/swift-5-flat?style=flat&logo=Swift&logoColor=white&color=midgreen)
![Xcode Version](https://img.shields.io/badge/Xcode-16.0-midgreen?logo=Xcode&logoColor=white)
![iOS Versions](https://img.shields.io/badge/iOS-16.4+-midgreen?logo=apple&logoColor=white&color=midgreen)
[![LICENSE](https://img.shields.io/badge/license-MIT-blue?logo=opensource)](LICENSE)

## Table of Contents
- [Requirements](#requirements)
- [Dependencies](#dependencies)
- [Installation](#installation)
- [Templates](#templates)
- [Shared code](#shared-code)
- [SwiftGen](#swiftgen)
- [SwiftLint](#swiftlint)
- [Runtime Configuration](#runtime-configuration)
- [Firebase Configuration](#firebase-configuration)
- [GitFlow](#gitflow)
- [Localization](#localization)
- [License](#license)

## Requirements
- iOS 16.4+
- Xcode 16.0+
- Swift 5

## Dependencies

The project uses Swift Package Manager for dependency management. Key dependencies include:

### External Dependencies
- [Alamofire](https://github.com/Alamofire/Alamofire) (5.10.2) - HTTP networking
- [JWTDecode](https://github.com/auth0/JWTDecode.swift) (3.3.0) - JWT token parsing
- [SimpleKeychain](https://github.com/auth0/SimpleKeychain?tab=readme-ov-file) (1.3.0) - Keychain wrapper
- [GRDB](https://github.com/groue/GRDB.swift) (7.6.1) - SQLite database
- [Factory](https://github.com/hmlongco/Factory) (2.5.3) - Dependency injection
- [SwiftGenPlugin](https://github.com/SwiftGen/SwiftGenPlugin) (6.6.2) - Assets code generation
- [PhoneNumberKit](https://github.com/marmelroy/PhoneNumberKit) (4.1.3) - Parsing, formatting and validating international phone numbers
- [Firebase](https://github.com/firebase/firebase-ios-sdk) (12.0.0) - Firebase SDK
- [GoogleSignIn](https://github.com/google/GoogleSignIn-iOS) (9.0.0) - 
Google Sign In SDK
- [UTMConversion](https://github.com/wtw-software/UTMConversion) (1.4.0) - Convert between latitude/longitude and the UTM coordinate system
- [IdentifiedCollections](https://github.com/pointfreeco/swift-identified-collections) (1.1.1) - Data structures for identifiable collections
- [FlowStacks](https://github.com/slawaDnC/FlowStacks) (0.1.0) - Coordinator-style navigation for SwiftUI
- [WindowOverlay](https://github.com/sunghyun-k/swiftui-window-overlay) (1.0.2) - Window-level overlays for SwiftUI

### Internal Packages
- `CommonUI` - Reusable UI components
- `Persistence` - contains from:
    1. DatabaseKit - GRDB wrapper
    2. StorageKit - User preferences and local storage(Keychain/User Defaults)
- `Extensions` - Swift extensions
- `Networking` - API communication layer
- `Resources` - Shared assets and resources
- `Utility` - Helper functions, classes and utilities

## Installation

1. Clone the repository:
```bash
git clone https://gitlab.com/whimoapp1/whimo-ios.git
cd whimo-ios
```

2. Bootstrap the project:
```bash
cd scripts
bash project_bootstrap.sh
```

This script will:
- Install Homebrew if not already installed
- Install SwiftLint and other required tools

3. Open the Xcode project:
```bash
open Whimo.xcodeproj
```

## Templates

To install the custom Xcode templates:

```bash
cd scripts
bash install_templates.sh
```

Alternatively, run the `install_templates` file directly.

### Using Templates
1. Make sure templates are [installed](#templates)
2. In Xcode, navigate to **File** -> **New** -> **File from Template**
3. Select from the available template sections:
   - **Architecture Templates**. Contains SwiftUI MVVM module template.
   - **Module Templates**. Contains Network Target template.

These templates help maintain consistency across the codebase and speed up development.

## Shared code
The application shares a code base with the **NotificationService** target. To create an alias for a specific file, use the following command:
```
ln -s <original_file_path> <alias_name>
```
This command generates a symbolic link (alias) that points to the original file, allowing it to be accessed under a new name or location.

## SwiftGen

The project uses [SwiftGen](https://github.com/SwiftGen/SwiftGen) to generate type-safe Swift code for resources. This eliminates stringly-typed code and provides compile-time validation for assets.

### Generated Resources

SwiftGen is configured in `Packages/Resources/swiftgen.yml` and automatically generates the following:

- `AppAssets` - Type-safe access to image assets
- `AppColors` - Type-safe access to color assets
- `AppLocale` - Type-safe access to localization strings
- `AppFonts` - Type-safe access to custom fonts

### Usage Example

Instead of using string literals for assets:

```swift
// Without SwiftGen
let image = UIImage(named: "profileIcon")
let color = UIColor(named: "primaryColor")
let text = NSLocalizedString("welcome_message", comment: "")
```

You can use the generated type-safe APIs:

```swift
// With SwiftGen
let image = AppAssets.profileIcon.image
let color = AppColors.primaryColor.color
let text = AppLocale.welcomeMessage
```

This provides several benefits:
- Compile-time validation (typos are caught by the compiler)
- Better code completion
- Safer refactoring when assets are renamed

### Configuration

SwiftGen runs automatically during the build process as a Swift Package Plugin. The templates for code generation are located in `templates/swiftgen_templates/`.

## SwiftLint

The project uses [SwiftLint](https://github.com/realm/SwiftLint) to enforce Swift style and conventions. This helps maintain consistent code quality and style across the codebase.

### Configuration

SwiftLint is configured in the root `.swiftlint.yml` file, which defines:

- Disabled rules: Rules that are not enforced (e.g., `nesting`, `trailing_comma`, `type_body_length`)
- Opt-in rules: Additional rules that are enforced (e.g., `force_unwrapping`, `implicit_return`, `array_init`)
- Excluded paths: Directories that are excluded from linting
- Custom rules: Project-specific rules for consistent code style

### Integration

SwiftLint is automatically run during the build process through a **Run Script Phase** in Xcode:

```bash
if [ -z "$CI" ]; then
    if which swiftlint >/dev/null; then
        swiftlint lint --quiet --config ../.swiftlint.yml
    else
        echo "error: 😢 SwiftLint not installed, download from https://github.com/realm/SwiftLint"
    fi
fi
```

This ensures that all code adheres to the project's style guidelines.

### Auto-fixing Issues

SwiftLint can automatically fix many style violations using the `--fix` option:

```bash
# Fix all auto-fixable issues in the project
swiftlint --fix

# Fix issues in a specific file
swiftlint --fix --path path/to/file.swift

# Fix issues with specific config file
swiftlint --fix --config .swiftlint.yml
```

This command will automatically correct issues like:
- Trailing whitespace
- Missing final newlines
- Incorrect spacing around operators
- And many other formatting violations

**Note:** Always review the changes before committing, as auto-fix modifies your source files directly.

### Disabling Rules

For specific cases where SwiftLint rules need to be disabled, you can use inline comments:

```swift
// swiftlint:disable:next force_unwrapping
let url = URL(string: urlString)!

// Disable for a block of code
// swiftlint:disable force_unwrapping
let url1 = URL(string: urlString1)!
let url2 = URL(string: urlString2)!
// swiftlint:enable force_unwrapping
```

## Runtime Configuration

The app also uses lightweight config files under `Whimo/Core/Utils/Utils+Strings/`:

- `ApiUtils.swift` — base API URL per build configuration.
- `URLUtils.swift` — small helpers for building/sanitizing URLs used across the app.
- `BundleUtils.swift` — bundle metadata helpers (bundle identifiers).

## Firebase Configuration

The project uses Firebase for various services including authentication, push notifications, and analytics. Firebase configuration is managed through environment-specific `.plist` files.

### Configuration Files

Firebase configuration files are located in the `FirebaseSupportingFiles/` directory:

- `GoogleService-Info-Dev.plist` - Development environment configuration
- `GoogleService-Info-Stage.plist` - Staging environment configuration  
- `GoogleService-Info-Prod.plist` - Production environment configuration

### Automatic Configuration Selection

The project includes a build script that automatically selects the appropriate Firebase configuration based on the build configuration. This script is configured in **Build Phases** and called **"[Crashlitycs] Copy Plist"**:

- **Debug** → Uses `GoogleService-Info-Dev.plist`
- **Stage** → Uses `GoogleService-Info-Stage.plist`
- **Release** → Uses `GoogleService-Info-Prod.plist`

### Setup Instructions

1. **Obtain Firebase Configuration Files:**
   - Go to the [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Navigate to Project Settings → General
   - Download the `GoogleService-Info.plist` for each environment

2. **Add Configuration Files:**
   - Place the development config as `GoogleService-Info-Dev.plist`
   - Place the staging config as `GoogleService-Info-Stage.plist`
   - Place the production config as `GoogleService-Info-Prod.plist`
   - All files should be in the `FirebaseSupportingFiles/` directory

3. **Verify Bundle IDs:**
   - Ensure each `.plist` file has the correct `BUNDLE_ID` for its environment

4. **Build Phase Script:**
   - The **[Crashlitycs] Copy Plist** script in **Build Phases** handles automatic configuration switching
   - This script selects the appropriate `.plist` file based on the build configuration
   - No manual intervention needed - the script runs automatically during build

### Important Notes

- **Never commit production Firebase keys** to version control
- The **[Crashlitycs] Copy Plist** build phase script automatically copies the correct configuration file to the app bundle
- Each environment should have its own Firebase project or separate configurations
- Test Firebase functionality in each environment before deploying
- If you encounter Firebase initialization issues, verify that the build script is properly configured in Build Phases

## GitFlow

The project follows a GitFlow workflow to manage code changes and releases. This branching strategy helps maintain a clean and organized development process.

### Branch Structure

- **`main`** - Production-ready code, always stable
- **`develop`** - Integration branch for features, staging environment
- **`feature/*`** - Feature development branches (e.g., `feature/user-authentication`)
- **`bugfix/*`** - Bug fix branches (e.g., `bugfix/login-validation`)
- **`hotfix/*`** - Critical production fixes (e.g., `hotfix/security-patch`)

### Workflow Process

1. **Feature Development:**
   - Create feature branch from `develop`: `git checkout -b feature/feature-name develop`
   - Develop and commit changes
   - Push feature branch and create Pull Request to `develop`
   - After review and approval, merge to `develop`

2. **Bug Fixes:**
   - Create bugfix branch from `develop`: `git checkout -b bugfix/issue-description develop`
   - Fix the issue and commit changes
   - Push bugfix branch and create Pull Request to `develop`
   - After review and approval, merge to `develop`

3. **Release Process:**
   - Create release branch from `develop`: `git checkout -b release/version-number develop`
   - Final testing and bug fixes
   - Merge release branch to both `main` and `develop`
   - Tag the release: `git tag -a v1.0.0 -m "Release version 1.0.0"`

4. **Hotfixes:**
   - Create hotfix branch from `main`: `git checkout -b hotfix/critical-fix main`
   - Fix the critical issue
   - Merge hotfix to both `main` and `develop`
   - Tag the hotfix release

### Best Practices

- Always create Pull Requests for code review
- Write descriptive commit messages
- Keep feature branches focused and small
- Regularly sync with `develop` to avoid conflicts
- Delete merged branches after successful merge
- Use conventional commit format: `type(scope): description`

## Localization

### Supported Languages

The application is available in the following languages:

- 🇬🇧 **English (en)** - Base language
- 🇪🇸 **Spanish (es)** - Spanish translation
- 🇫🇷 **French (fr)** - French translation

UI elements, error messages, permissions descriptions, and user-facing text are localized for these languages.

### Localization Export and Audit Tools

The project includes automated tooling for localization export and auditing. This helps track translation coverage, identify missing translations, and maintain consistency across different app flows.

#### Automated Export and Audit (Recommended)

Use the automated bash script to export localizations from Xcode and generate audit tables:

```bash
# Run from project root
./scripts/export_and_audit_localizations.sh
```

This script automatically:
1. **Exports localizations** from Xcode project (en, fr, es) using xcodebuild CLI
2. **Sets up Python environment** (creates venv if needed, installs dependencies)
3. **Generates Excel audit files:**
   - `localization_audit.xlsx` - Main localization audit with flow-based sheets
   - `permissions_localization.xlsx` - iOS permissions descriptions

#### Manual Process

If you need to run the scripts individually:

1. Navigate to the localization audit directory:
```bash
cd localization_audit
```

2. Set up Python environment (first time only):
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

3. Export localizations from Xcode:
```bash
xcodebuild -exportLocalizations \
  -project Whimo.xcodeproj \
  -scheme "Whimo Dev" \
  -localizationPath "localization_audit/Resources Localizations" \
  -exportLanguage en -exportLanguage fr -exportLanguage es
```

4. Generate audit tables:
```bash
source venv/bin/activate
python3 create_localization_excel.py
python3 update_permissions_localization.py
deactivate
```

#### Generated Files

**localization_audit.xlsx**

Main localization audit file with the following sheets:

- **General** - Keys starting with "general." (general app strings)
- **AUTH_FLOW** - Authentication screens (Login, Register, Forgot Password, OTP)
- **NAVIGATION_BAR_FLOW** - Navigation and settings screens
- **MAIN_FLOW** - Main app screens (Home, Transactions, Transaction Details)
- **BALANCE_FLOW** - Balance related screens
- **ADD_TRANSACTION_FLOW** - Transaction creation screens (Forms, QR Scanning)
- **SETTINGS_FLOW** - Settings and account management screens

Each sheet contains:
- **key** - Localization key identifier
- **en** - English text (source language)
- **es** - Spanish translation
- **fr** - French translation

**permissions_localization.xlsx**

iOS permissions descriptions in all supported languages:
- Camera access
- Location access (always and when in use)
- User notifications

#### Prerequisites

- Python 3.7+
- Xcode Command Line Tools
- Required Python packages (installed automatically by script):
  - `pandas>=1.5.0`
  - `openpyxl>=3.0.0`

For more details, see the [localization_audit/README.md](localization_audit/README.md) file.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2025 EFI https://efi.int/