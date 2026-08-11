#!/bin/bash

# Script to add MIT License headers to Swift files
# Usage: bash add_license_headers.sh [--dry-run]

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

# License header template
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
ERROR_FILES=0

# Array to store files with errors
ERROR_FILE_LIST=()

# Function to check if file already has license header
has_license_header() {
    local file="$1"
    if grep -q "Permission is hereby granted" "$file"; then
        return 0  # true - has license
    else
        return 1  # false - no license
    fi
}

# Function to add license header to a file
add_license_to_file() {
    local file="$1"
    local temp_file="${file}.tmp"
    
    # Check if file already has license
    if has_license_header "$file"; then
        echo -e "${YELLOW}⏭  Skipping (already has license): ${file}${NC}"
        ((SKIPPED_FILES++))
        return 0
    fi
    
    # Check if file has "Created by" line (existing header)
    if grep -q "^//  Created by" "$file"; then
        # File has existing header - preserve it and add license after line 6
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "${BLUE}📝 Would add license to: ${file}${NC}"
        else
            # Get first 6 lines (existing header)
            head -n 6 "$file" > "$temp_file"
            
            # Add license header
            echo "$LICENSE_HEADER" >> "$temp_file"
            
            # Add rest of the file (from line 7 onwards)
            tail -n +7 "$file" >> "$temp_file"
            
            # Replace original file
            mv "$temp_file" "$file"
            
            echo -e "${GREEN}✅ Added license to: ${file}${NC}"
        fi
        ((MODIFIED_FILES++))
        return 0
    else
        # File has no header - add complete header with license
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "${BLUE}📝 Would add complete header to: ${file}${NC}"
        else
            # Get filename
            filename=$(basename "$file")
            
            # Create complete header
            {
                echo "//"
                echo "//  ${filename}"
                echo "//  Whimo"
                echo "//"
                echo "$LICENSE_HEADER"
            } > "$temp_file"
            
            # Add original file content
            cat "$file" >> "$temp_file"
            
            # Replace original file
            mv "$temp_file" "$file"
            
            echo -e "${GREEN}✅ Added complete header to: ${file}${NC}"
        fi
        ((MODIFIED_FILES++))
        return 0
    fi
}

# Main execution
echo -e "${BLUE}🚀 Starting license header addition process...${NC}"
echo -e "${BLUE}📁 Project root: ${PROJECT_ROOT}${NC}\n"

# Find all Swift files in specified directories
echo -e "${BLUE}🔍 Finding Swift files...${NC}\n"

# Process files in Whimo/, NotificationService/, Packages/, and WhimoTests/
while IFS= read -r -d '' file; do
    ((TOTAL_FILES++))
    
    # Skip files in build directories
    if [[ "$file" == *"/build/"* ]] || [[ "$file" == *"/.build/"* ]]; then
        continue
    fi
    
    # Process the file
    if ! add_license_to_file "$file" 2>/dev/null; then
        echo -e "${RED}❌ Error processing: ${file}${NC}"
        ((ERROR_FILES++))
        ERROR_FILE_LIST+=("$file")
    fi
    
done < <(find "$PROJECT_ROOT/Whimo" "$PROJECT_ROOT/NotificationService" "$PROJECT_ROOT/Packages" "$PROJECT_ROOT/WhimoTests" -name "*.swift" -type f -print0 2>/dev/null)

# Print summary
echo -e "\n${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}📊 Summary:${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}Total files found:     ${TOTAL_FILES}${NC}"
echo -e "${GREEN}Files modified:        ${MODIFIED_FILES}${NC}"
echo -e "${YELLOW}Files skipped:         ${SKIPPED_FILES}${NC}"

if [[ $ERROR_FILES -gt 0 ]]; then
    echo -e "${RED}Files with errors:     ${ERROR_FILES}${NC}"
    echo -e "${RED}List of files with errors:${NC}"
    for error_file in "${ERROR_FILE_LIST[@]}"; do
        echo -e "${RED}  - ${error_file}${NC}"
    done
fi

if [[ "$DRY_RUN" == true ]]; then
    echo -e "\n${YELLOW}ℹ️  This was a DRY-RUN. No files were actually modified.${NC}"
    echo -e "${YELLOW}Run without --dry-run flag to apply changes.${NC}"
else
    echo -e "\n${GREEN}✅ License headers have been added successfully!${NC}"
fi

echo -e "${BLUE}═══════════════════════════════════════════════${NC}\n"

