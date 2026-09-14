#!/bin/bash

# EOD Report Archive - Daily Update Script
# Usage: ./update-report.sh <path-to-report.html> [YYYY-MM-DD]
# If date is not provided, today's date is used.

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if report file is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Report file path required${NC}"
    echo "Usage: ./update-report.sh <path-to-report.html> [YYYY-MM-DD]"
    echo ""
    echo "Examples:"
    echo "  ./update-report.sh ./new-report.html"
    echo "  ./update-report.sh ./new-report.html 2026-09-15"
    exit 1
fi

REPORT_FILE="$1"
REPORT_DATE="${2:-$(date +%Y-%m-%d)}"

# Verify the report file exists and is readable
if [ ! -f "$REPORT_FILE" ]; then
    echo -e "${RED}Error: Report file not found: $REPORT_FILE${NC}"
    exit 1
fi

if [ ! -r "$REPORT_FILE" ]; then
    echo -e "${RED}Error: Report file is not readable: $REPORT_FILE${NC}"
    exit 1
fi

# Validate date format
if ! [[ "$REPORT_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo -e "${RED}Error: Invalid date format. Use YYYY-MM-DD${NC}"
    exit 1
fi

# Check if report for this date already exists
ARCHIVE_FILE="reports/${REPORT_DATE}.html"
if [ -f "$ARCHIVE_FILE" ]; then
    echo -e "${YELLOW}Warning: Report for ${REPORT_DATE} already exists: ${ARCHIVE_FILE}${NC}"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# Step 1: Update report.html with new content
echo -e "${BLUE}Step 1: Updating current report (report.html)...${NC}"
cp "$REPORT_FILE" report.html
echo -e "${GREEN}✓ Updated report.html${NC}"

# Step 2: Archive the report with date
echo -e "${BLUE}Step 2: Archiving report as ${ARCHIVE_FILE}...${NC}"
cp "$REPORT_FILE" "$ARCHIVE_FILE"
echo -e "${GREEN}✓ Created ${ARCHIVE_FILE}${NC}"

# Step 3: Update reports.json
echo -e "${BLUE}Step 3: Updating reports.json...${NC}"

# Get day of week
DOW=$(date -d "$REPORT_DATE" +%A 2>/dev/null || date -j -f "%Y-%m-%d" "$REPORT_DATE" +%A 2>/dev/null || echo "Report")
FORMATTED_DATE=$(date -d "$REPORT_DATE" "+%B %d, %Y" 2>/dev/null || date -j -f "%Y-%m-%d" "$REPORT_DATE" "+%B %d, %Y" 2>/dev/null || echo "$REPORT_DATE")

# Read current reports.json
if [ -f "reports.json" ]; then
    CURRENT_JSON=$(cat reports.json)
else
    CURRENT_JSON="[]"
fi

# Check if entry already exists and remove it
UPDATED_JSON=$(echo "$CURRENT_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
data = [r for r in data if r['date'] != '$REPORT_DATE']
print(json.dumps(data, indent=2))
" 2>/dev/null || echo "$CURRENT_JSON")

# Add new entry at the beginning (most recent first)
NEW_ENTRY="{
  \"date\": \"${REPORT_DATE}\",
  \"label\": \"${FORMATTED_DATE}\",
  \"dayOfWeek\": \"${DOW}\",
  \"file\": \"${ARCHIVE_FILE}\"
}"

FINAL_JSON=$(echo "[
${NEW_ENTRY},
$(echo "$UPDATED_JSON" | tail -n +2 | head -n -1)
]" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(json.dumps(data, indent=2))
except:
    print('[]')
")

echo "$FINAL_JSON" > reports.json
echo -e "${GREEN}✓ Updated reports.json${NC}"

# Step 4: Git operations
echo -e "${BLUE}Step 4: Committing changes to Git...${NC}"

git add report.html "$ARCHIVE_FILE" reports.json

COMMIT_MSG="Update: EOD Report ${REPORT_DATE}

- Updated current report (report.html)
- Archived report as reports/${REPORT_DATE}.html
- Updated reports.json index

Co-Authored-By: Rêve EOD Report System <reports@reverealtors.com>"

git commit -m "$COMMIT_MSG" || echo -e "${YELLOW}No changes to commit${NC}"

# Step 5: Push to GitHub
echo -e "${BLUE}Step 5: Pushing to GitHub...${NC}"
git push origin main || {
    echo -e "${RED}Error: Failed to push to GitHub${NC}"
    echo "Please check your network connection and try again."
    exit 1
}

echo -e "${GREEN}✓ Pushed to GitHub${NC}"

# Final summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Report Successfully Updated!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Summary:"
echo "  Date:           ${REPORT_DATE}"
echo "  Current Report: report.html"
echo "  Archive:        ${ARCHIVE_FILE}"
echo "  Index:          reports.json"
echo ""
echo "The report is now live on the production site."
echo "Vercel will deploy automatically in a few moments."
echo ""
