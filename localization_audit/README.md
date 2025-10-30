# Localization Audit Excel File

This Excel file contains a comprehensive analysis of the WHIMO iOS app localization files.

## Structure

The Excel file contains the following sheets:

### 1. General
- Contains all localization keys with their translations in English, Spanish, and French
- Total: 45 keys

### 2. AUTH_FLOW
- Authentication related screens (Login, Register, Forgot Password, OTP, etc.)
- Total: 60 keys

### 3. NAVIGATION_BAR_FLOW
- Navigation and settings related screens (Change Password, More, Notifications List)
- Total: 22 keys

### 4. MAIN_FLOW
- Main app screens (Home, Transactions, Transaction Details, Suppliers History)
- Total: 72 keys

### 5. BALANCE_FLOW
- Balance related screens
- Total: 4 keys

### 6. ADD_TRANSACTION_FLOW
- Transaction creation screens (Select Type, Forms, QR Scanning, etc.)
- Total: 90 keys

### 7. SETTINGS_FLOW
- Settings and account management screens
- Total: 38 keys

## Columns

Each sheet contains the following columns:
- **key**: The localization key identifier
- **en**: English text (source language)
- **es**: Spanish translation
- **fr**: French translation

## Files Analyzed

- **English**: `Resources Localizations/en.xcloc/Source Contents/Sources/Resources/Localization/en.lproj/Localizable.strings`
- **Spanish**: `Resources Localizations/es.xcloc/Localized Contents/es.xliff`
- **French**: `Resources Localizations/fr.xcloc/Localized Contents/fr.xliff`

## Generation

### Automated Script (Recommended)

Use the automated bash script to export localizations from Xcode and generate all audit files:

```bash
# Run from project root
./scripts/export_and_audit_localizations.sh
```

This script:
1. Exports localizations from Xcode using xcodebuild CLI
2. Sets up Python virtual environment
3. Generates both localization_audit.xlsx and permissions_localization.xlsx

### Manual Generation

This Excel file can also be generated manually using the `create_localization_excel.py` script, which:
1. Parses the English Localizable.strings file
2. Extracts translations from Spanish and French XLIFF files
3. Categorizes keys by FLOW based on MARK comments
4. Creates separate Excel sheets for each flow
5. Includes a general sheet with all keys

## Usage

Use this file to:
- Review translation coverage across languages
- Identify missing translations
- Analyze localization by app flow
- Plan localization improvements
- Track translation quality and consistency

---

# Permissions Localization

## permissions_localization.xlsx

This Excel file contains all iOS permission descriptions (InfoPlist.strings) with translations in all supported languages.

### Structure

The file contains one sheet:

#### Permissions
- Contains all permission keys with their descriptions in English, Spanish, and French
- Includes permissions for:
  - Camera access (`NSCameraUsageDescription`)
  - Location access (`NSLocationAlwaysAndWhenInUseUsageDescription`, `NSLocationWhenInUseUsageDescription`)
  - Notifications (`NSUserNotificationsUsageDescription`)

### Columns

- **Permission Key**: The iOS permission key identifier
- **English (en)**: English description
- **Spanish (es)**: Spanish description
- **French (fr)**: French description

### Files Analyzed

- **English**: `../Whimo/Resources/en.lproj/InfoPlist.strings`
- **Spanish**: `../Whimo/Resources/es.lproj/InfoPlist.strings`
- **French**: `../Whimo/Resources/fr.lproj/InfoPlist.strings`

### Generation

This Excel file can be regenerated using the `update_permissions_localization.py` script:

```bash
# Activate virtual environment
source venv/bin/activate

# Run the script
python3 update_permissions_localization.py
```

The script:
1. Parses all InfoPlist.strings files for each language
2. Extracts permission key-value pairs
3. Creates a single Excel sheet with all permissions
4. Auto-adjusts column widths for readability

### Usage

Use this file to:
- Review permission descriptions across languages
- Ensure all permission texts are properly translated
- Maintain consistency in permission messaging
- Prepare for App Store submission reviews
