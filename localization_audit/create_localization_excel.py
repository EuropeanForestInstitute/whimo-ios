#!/usr/bin/env python3
"""
Script to create Excel localization table from XLIFF files
Creates separate sheets for each FLOW found in the localization files
"""

import xml.etree.ElementTree as ET
import pandas as pd
import re
from pathlib import Path

def parse_xliff_file(xliff_path):
    """Parse XLIFF file and return dictionary of translations"""
    translations = {}
    
    try:
        tree = ET.parse(xliff_path)
        root = tree.getroot()
        
        # Define namespace
        ns = {'xliff': 'urn:oasis:names:tc:xliff:document:1.2'}
        
        for trans_unit in root.findall('.//xliff:trans-unit', ns):
            trans_id = trans_unit.get('id')
            source = trans_unit.find('xliff:source', ns)
            target = trans_unit.find('xliff:target', ns)
            
            if trans_id and source is not None and target is not None:
                source_text = source.text or ""
                target_text = target.text or ""
                translations[trans_id] = {
                    'source': source_text,
                    'target': target_text
                }
    
    except Exception as e:
        print(f"Error parsing {xliff_path}: {e}")
    
    return translations

def parse_english_strings(english_path):
    """Parse English Localizable.strings file and return dictionary"""
    english_strings = {}
    
    try:
        with open(english_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Extract key-value pairs
        pattern = r'"([^"]+)"\s*=\s*"([^"]*)"'
        matches = re.findall(pattern, content)
        
        for key, value in matches:
            english_strings[key] = value
            
    except Exception as e:
        print(f"Error parsing {english_path}: {e}")
    
    return english_strings

def categorize_keys_by_flow(english_strings):
    """Categorize localization keys by FLOW based on comments in the file"""
    
    # Read the file to analyze the structure
    english_file_path = "Resources Localizations/en.xcloc/Source Contents/Packages/Resources/Sources/Resources/Localization/en.lproj/Localizable.strings"
    
    try:
        with open(english_file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except:
        # Fallback to other possible locations
        try:
            with open("Resources Localizations/fr.xcloc/Source Contents/Packages/Resources/Sources/Resources/Localization/en.lproj/Localizable.strings", 'r', encoding='utf-8') as f:
                content = f.read()
        except:
            with open("Resources Localizations/es.xcloc/Source Contents/Packages/Resources/Sources/Resources/Localization/en.lproj/Localizable.strings", 'r', encoding='utf-8') as f:
                content = f.read()
    
    # Define flow patterns
    flows = {
        'AUTH FLOW': [],
        'NAVIGATION BAR FLOW': [],
        'MAIN FLOW': [],
        'BALANCE FLOW': [],
        'ADD TRANSACTION FLOW': [],
        'SETTINGS FLOW': []
    }
    
    current_flow = None
    lines = content.split('\n')
    
    for line in lines:
        line = line.strip()
        
        # Check for flow markers
        if '// MARK: - ---' in line and 'FLOW ---' in line:
            for flow_name in flows.keys():
                if flow_name in line:
                    current_flow = flow_name
                    break
        
        # Check for key-value pairs
        if '"' in line and '=' in line and current_flow:
            match = re.search(r'"([^"]+)"', line)
            if match:
                key = match.group(1)
                if key in english_strings and not key.startswith('general.'):
                    flows[current_flow].append(key)
    
    return flows

def create_excel_file(english_strings, spanish_translations, french_translations, flows):
    """Create Excel file with separate sheets for each flow"""
    
    # Create Excel writer
    output_path = "localization_audit.xlsx"
    with pd.ExcelWriter(output_path, engine='openpyxl') as writer:
        
        # Create General sheet with only "general." keys
        general_data = []
        for key in sorted(english_strings.keys()):
            if key.startswith('general.'):
                general_data.append({
                    'key': key,
                    'en': english_strings.get(key, ''),
                    'es': spanish_translations.get(key, {}).get('target', ''),
                    'fr': french_translations.get(key, {}).get('target', '')
                })
        
        general_df = pd.DataFrame(general_data)
        general_df.to_excel(writer, sheet_name='General', index=False)
        
        # Create separate sheets for each flow
        for flow_name, keys in flows.items():
            if keys:  # Only create sheet if there are keys
                flow_data = []
                for key in sorted(keys):
                    if key in english_strings:
                        flow_data.append({
                            'key': key,
                            'en': english_strings.get(key, ''),
                            'es': spanish_translations.get(key, {}).get('target', ''),
                            'fr': french_translations.get(key, {}).get('target', '')
                        })
                
                flow_df = pd.DataFrame(flow_data)
                # Clean sheet name for Excel (remove special characters)
                sheet_name = flow_name.replace(' ', '_').replace('-', '_')
                flow_df.to_excel(writer, sheet_name=sheet_name, index=False)
    
    print(f"Excel file created: {output_path}")
    return output_path

def main():
    """Main function to process localization files"""
    
    base_path = Path("Resources Localizations")
    
    # Parse English strings
    english_path = base_path / "en.xcloc/Source Contents/Packages/Resources/Sources/Resources/Localization/en.lproj/Localizable.strings"
    english_strings = parse_english_strings(english_path)
    print(f"Parsed {len(english_strings)} English strings")
    
    # Parse Spanish translations
    spanish_xliff = base_path / "es.xcloc/Localized Contents/es.xliff"
    spanish_translations = parse_xliff_file(spanish_xliff)
    print(f"Parsed {len(spanish_translations)} Spanish translations")
    
    # Parse French translations
    french_xliff = base_path / "fr.xcloc/Localized Contents/fr.xliff"
    french_translations = parse_xliff_file(french_xliff)
    print(f"Parsed {len(french_translations)} French translations")
    
    # Categorize keys by flow
    flows = categorize_keys_by_flow(english_strings)
    
    # Print flow statistics
    for flow_name, keys in flows.items():
        print(f"{flow_name}: {len(keys)} keys")
    
    # Create Excel file
    output_path = create_excel_file(english_strings, spanish_translations, french_translations, flows)
    
    print(f"\nLocalization audit completed successfully!")
    print(f"Output file: {output_path}")

if __name__ == "__main__":
    main()
