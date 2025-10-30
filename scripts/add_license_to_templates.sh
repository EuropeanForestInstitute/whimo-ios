#!/bin/bash

# Script to add MIT License headers to Xcode templates
# Usage: bash add_license_to_templates.sh [--dry-run]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=false

# Parse arguments
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "${YELLOW}🔍 Running in DRY-RUN mode (no files will be modified)${NC}\n"
fi

# License header template for templates
read -r -d '' LICENSE_HEADER << 'EOF' || true
//  Copyright (c) 2025 EFI https://efi.int/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
EOF

# Counters
TOTAL_FILES=0
MODIFIED_FILES=0
SKIPPED_FILES=0

echo -e "${BLUE}🚀 Adding license headers to Xcode templates...${NC}"
echo -e "${BLUE}📁 Project root: ${PROJECT_ROOT}${NC}\n"

# Find all Swift template files
while IFS= read -r -d '' file; do
    ((TOTAL_FILES++))
    
    # Check if file already has license
    if grep -q "Permission is hereby granted" "$file"; then
        echo -e "${YELLOW}⏭  Skipping (already has license): ${file}${NC}"
        ((SKIPPED_FILES++))
        continue
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${BLUE}📝 Would add license to: ${file}${NC}"
        ((MODIFIED_FILES++))
    else
        # Create temp file
        temp_file="${file}.tmp"
        
        # Check if file has existing header
        if head -n 1 "$file" | grep -q "^//"; then
            # File has existing header - add license after it
            # Get existing header (lines starting with //)
            awk '/^\/\// {print; next} {exit}' "$file" > "$temp_file"
            echo "$LICENSE_HEADER" >> "$temp_file"
            # Add rest of the file
            awk '/^[^\/]/ {p=1} p' "$file" >> "$temp_file"
        else
            # No header - add complete header with license
            {
                echo "//"
                echo "//  ___FILENAME___"
                echo "//  ___PROJECTNAME___"
                echo "//"
                echo "$LICENSE_HEADER"
            } > "$temp_file"
            
            # Add original file content
            cat "$file" >> "$temp_file"
        fi
        
        # Replace original file
        mv "$temp_file" "$file"
        
        echo -e "${GREEN}✅ Added license to: ${file}${NC}"
        ((MODIFIED_FILES++))
    fi
    
done < <(find "$PROJECT_ROOT/templates" -name "*.swift" -type f -print0)

# Print summary
echo -e "\n${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}📊 Summary:${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}Total template files found: ${TOTAL_FILES}${NC}"
echo -e "${GREEN}Files modified:             ${MODIFIED_FILES}${NC}"
echo -e "${YELLOW}Files skipped:              ${SKIPPED_FILES}${NC}"

if [[ "$DRY_RUN" == true ]]; then
    echo -e "\n${YELLOW}ℹ️  This was a DRY-RUN. No files were actually modified.${NC}"
    echo -e "${YELLOW}Run without --dry-run flag to apply changes.${NC}"
else
    echo -e "\n${GREEN}✅ License headers have been added to templates!${NC}"
fi

echo -e "${BLUE}═══════════════════════════════════════════════${NC}\n"