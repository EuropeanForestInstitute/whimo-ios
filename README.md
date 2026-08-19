# WHIMO iOS

![Swift Version](https://img.shields.io/badge/swift-5-flat?style=flat&logo=Swift&logoColor=white&color=midgreen)
![Xcode Version](https://img.shields.io/badge/Xcode-16.3+-midgreen?logo=Xcode&logoColor=white)
![iOS Versions](https://img.shields.io/badge/iOS-16.4+-midgreen?logo=apple&logoColor=white&color=midgreen)
[![LICENSE](https://img.shields.io/badge/license-MIT-blue?logo=opensource)](LICENSE)

## 📝 Description

WHIMO is an iOS application for tracking commodities and managing transactions in supply chains. The platform enables farmers, suppliers, and buyers to record and monitor commodity transactions ensuring transparency and accountability throughout the supply chain.

## 📦 Tech Stack

| Dependency | Version | Purpose |
|------------|---------|---------|
| [Alamofire](https://github.com/Alamofire/Alamofire) | 5.10.2 | HTTP networking |
| [JWTDecode](https://github.com/auth0/JWTDecode.swift) | 3.3.0 | JWT token parsing |
| [SimpleKeychain](https://github.com/auth0/SimpleKeychain) | 1.3.0 | Keychain wrapper |
| [GRDB](https://github.com/groue/GRDB.swift) | 7.6.1 | SQLite database |
| [Factory](https://github.com/hmlongco/Factory) | 2.5.3 | Dependency injection |
| [SwiftGenPlugin](https://github.com/SwiftGen/SwiftGenPlugin) | 6.6.2 | Assets code generation |
| [PhoneNumberKit](https://github.com/marmelroy/PhoneNumberKit) | 4.1.3 | Phone number parsing and validation |
| [Firebase](https://github.com/firebase/firebase-ios-sdk) | 12.0.0 | Firebase SDK |
| [GoogleSignIn](https://github.com/google/GoogleSignIn-iOS) | 9.0.0 | Google Sign In SDK |
| [IdentifiedCollections](https://github.com/pointfreeco/swift-identified-collections) | 1.1.1 | Identifiable collections |
| [FlowStacks](https://github.com/slawaDnC/FlowStacks) | 0.1.0 | Coordinator-style navigation |
| [WindowOverlay](https://github.com/sunghyun-k/swiftui-window-overlay) | 1.0.2 | Window-level overlays |

## 🚀 Getting Started

### Requirements

- iOS 16.4+
- Xcode 16.3+ (last verified with Xcode 26.6)
- Swift 5

### Bootstrap

1. Clone the repository:
```bash
git clone https://gitlab.com/whimoapp1/whimo-ios.git
cd whimo-ios
```

2. Run the bootstrap script:
```bash
cd scripts
bash project_bootstrap.sh
```

This script installs Homebrew (if needed) and required tools like SwiftLint.

3. Open the project in Xcode:
```bash
open Whimo.xcodeproj
```

### Firebase Configuration Setup

Firebase configuration is managed through environment-specific `.plist` files located in `FirebaseSupportingFiles/`:

- `GoogleService-Info-Dev.plist` - Development environment
- `GoogleService-Info-Stage.plist` - Staging environment
- `GoogleService-Info-Prod.plist` - Production environment

The **"[Crashlitycs] Copy Plist"** build script automatically selects the appropriate configuration based on build configuration:

- **Debug** → `GoogleService-Info-Dev.plist`
- **Stage** → `GoogleService-Info-Stage.plist`
- **Release** → `GoogleService-Info-Prod.plist`

#### Setup Steps

1. Obtain Firebase configuration files from [Firebase Console](https://console.firebase.google.com/)
2. Place files in `FirebaseSupportingFiles/` directory
3. Verify each `.plist` has the correct `BUNDLE_ID` for its environment
4. Build script handles automatic configuration switching (no manual intervention needed)

## 🏗️ Architecture

The project follows **MVVM architecture** with SwiftUI.

### MVVM Module Structure

**View**:
- Uses `@StateObject` to observe ViewModel
- Uses `@EnvironmentObject` for navigation access
- Declarative UI focused on layout and presentation

**ViewModel**:
- Implements `ViewModelProtocol` (conforms to `ObservableObject`)
- Uses `@Published` properties for reactive state that View observes
- Uses Combine for reactive data binding
- Handles async/await operations and business logic

### Architecture Layers

The project uses a layered structure based on the ideas of **Clean Architecture**:

**Network Targets**:
- API endpoints definition layer
- Handles network requests through Alamofire

**Repositories**:
- Data access layer
- Abstracts data sources

**Interactors**:
- Business logic layer
- Orchestrates repository operations to execute business use cases

**Services**:
- Infrastructure services
- Platform-specific functionality

**AppState**:
- Centralized UI state management

## 🛠️ Development Tools

### Templates

Install custom Xcode templates:

```bash
bash scripts/install_templates.sh
```

**Usage**: In Xcode, navigate to **File** → **New** → **File from Template**:
- **Architecture Templates** - SwiftUI MVVM module template
- **Module Templates** - Network Target template

### SwiftGen

[SwiftGen](https://github.com/SwiftGen/SwiftGen) generates type-safe Swift code for resources. Configured in `Packages/Resources/swiftgen.yml` and runs automatically as a Swift Package Plugin.

**Generated Resources**:
- `AppAssets` - Image assets
- `AppColors` - Color assets
- `AppLocale` - Localization strings
- `AppFonts` - Custom fonts

**Example**:

```swift
// Type-safe access
let image = AppAssets.profileIcon.image
let color = AppColors.primaryColor.color
let text = AppLocale.welcomeMessage
```

Benefits: compile-time validation, better code completion, safer refactoring.

### SwiftLint

[SwiftLint](https://github.com/realm/SwiftLint) enforces Swift style conventions. Configured in `.swiftlint.yml` and runs automatically during build.

**Auto-fix**: Run `swiftlint --fix` to automatically correct many style violations.

**Disable Rules**: Use inline comments:

```swift
// swiftlint:disable:next force_unwrapping
let url = URL(string: urlString)!
```

### Shared Code

The app shares code with the **NotificationService** target using symbolic links:

```bash
ln -s <original_file_path> <alias_name>
```

## ⚙️ Runtime Configuration

Configuration files are located in `Whimo/Core/Utils/Utils+Configuration/`:

- `ApiConfiguration.swift` - Base API URL per build configuration
- `AppConstants.swift` - App-level constants (email, URLs, etc.)
- `BundleConfiguration.swift` - Bundle metadata helpers (bundle identifiers)

## 🌍 Localization

The application supports three languages:

- 🇬🇧 **English (en)**
- 🇪🇸 **Spanish (es)**
- 🇫🇷 **French (fr)**

### Automated Export and Audit

Use the automated script to export localizations and generate audit tables:

```bash
./scripts/export_and_audit_localizations.sh
```

This script:
1. Exports localizations from Xcode (en, fr, es)
2. Sets up Python environment (if needed)
3. Generates Excel audit files:
   - `localization_audit.xlsx` - Main localization audit with flow-based sheets
   - `permissions_localization.xlsx` - iOS permissions descriptions

#### Manual Process

For manual execution, see [localization_audit/README.md](localization_audit/README.md).

**Prerequisites**: Python 3.7+, Xcode Command Line Tools

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2025 EFI https://efi.int/
