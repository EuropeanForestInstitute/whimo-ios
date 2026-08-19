#!/usr/bin/env python3
"""
Script to update permissions_localization.xlsx from InfoPlist.strings files
"""

import pandas as pd
import re
from pathlib import Path

def parse_infoplist_strings(file_path):
    """Parse InfoPlist.strings file and return dictionary of permissions"""
    permissions = {}
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Extract key-value pairs
        # Pattern matches: "KEY" = "VALUE";
        pattern = r'"([^"]+)"\s*=\s*"([^"]*)"'
        matches = re.findall(pattern, content)
        
        for key, value in matches:
            permissions[key] = value
            
    except Exception as e:
        print(f"Error parsing {file_path}: {e}")
    
    return permissions

def create_permissions_excel():
    """Create permissions_localization.xlsx file from InfoPlist.strings files"""
    
    # Base path to resources
    base_path = Path("../Whimo/Resources")
    
    # Parse all three language files
    english_perms = parse_infoplist_strings(base_path / "en.lproj/InfoPlist.strings")
    spanish_perms = parse_infoplist_strings(base_path / "es.lproj/InfoPlist.strings")
    french_perms = parse_infoplist_strings(base_path / "fr.lproj/InfoPlist.strings")
    
    print(f"Parsed {len(english_perms)} English permissions")
    print(f"Parsed {len(spanish_perms)} Spanish permissions")
    print(f"Parsed {len(french_perms)} French permissions")
    
    # Create data for Excel
    data = []
    
    # Get all unique permission keys
    all_keys = set(english_perms.keys()) | set(spanish_perms.keys()) | set(french_perms.keys())
    
    for key in sorted(all_keys):
        data.append({
            'Permission Key': key,
            'English (en)': english_perms.get(key, ''),
            'Spanish (es)': spanish_perms.get(key, ''),
            'French (fr)': french_perms.get(key, '')
        })
    
    # Create DataFrame
    df = pd.DataFrame(data)
    
    # Write to Excel
    output_path = "permissions_localization.xlsx"
    with pd.ExcelWriter(output_path, engine='openpyxl') as writer:
        df.to_excel(writer, sheet_name='Permissions', index=False)
        
        # Auto-adjust column widths
        worksheet = writer.sheets['Permissions']
        for idx, col in enumerate(df.columns):
            max_length = max(
                df[col].astype(str).map(len).max(),
                len(col)
            )
            # Set column width with some padding
            worksheet.column_dimensions[chr(65 + idx)].width = min(max_length + 2, 80)
    
    print(f"\nPermissions localization file created: {output_path}")
    print(f"Total permissions: {len(data)}")
    
    return output_path

def main():
    """Main function"""
    print("=" * 60)
    print("Updating permissions_localization.xlsx")
    print("=" * 60)
    
    output_path = create_permissions_excel()
    
    print("\n" + "=" * 60)
    print("Permissions localization update completed successfully!")
    print(f"Output file: {output_path}")
    print("=" * 60)

if __name__ == "__main__":
    main()

