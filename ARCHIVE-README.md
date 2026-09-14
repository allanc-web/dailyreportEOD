# EOD Report Historical Archive System

This repository includes a permanent archive system for daily EOD Transaction Coordination Reports.

## How It Works

### Current Setup

- **`index.html`** — Permanent landing page with two sections:
  1. **Current Report** — Displays today's report via dropdown
  2. **Report History** — Searchable archive with filters

- **`report.html`** — Always represents the CURRENT/LATEST report

- **`reports/` folder** — Contains historical reports archived by date
  - Example: `reports/2026-09-14.html`, `reports/2026-09-15.html`, etc.

- **`reports.json`** — Index of all historical reports
  - Used by the landing page to dynamically populate the history section
  - No hardcoded dates in `index.html`; everything is data-driven

### Architecture Benefits

✅ **Single source of truth** — `reports.json` is the only place dates are recorded  
✅ **No manual UI updates** — Landing page automatically reflects new reports  
✅ **Duplicate detection** — System warns before overwriting an existing date  
✅ **Historical preservation** — All reports permanently archived in `reports/` folder  
✅ **Easy to audit** — Git history tracks all report additions  
✅ **Simple workflow** — One command to add a daily report  

---

## Daily Workflow

### Option A: Using the Update Script (RECOMMENDED)

The simplest way to add a daily report:

```bash
./update-report.sh <path-to-new-report.html>
```

**Example:**
```bash
# Today's report
./update-report.sh ~/my-eod-report.html

# Specific date
./update-report.sh ~/my-eod-report.html 2026-09-15
```

**What the script does automatically:**
1. ✅ Validates the HTML file exists and is readable
2. ✅ Updates `report.html` with the new content
3. ✅ Creates an archive copy: `reports/YYYY-MM-DD.html`
4. ✅ Updates `reports.json` index with metadata
5. ✅ Commits all changes with a clear message
6. ✅ Pushes to GitHub (`main` branch)
7. ✅ Vercel deploys automatically
8. ✅ Detects duplicates and warns you before overwriting

**Output example:**
```
✓ Updated report.html
✓ Created reports/2026-09-15.html
✓ Updated reports.json
✓ Pushed to GitHub
========================================
✓ Report Successfully Updated!
========================================
```

### Option B: Manual Steps (If Script Fails)

If the script fails for any reason, you can do it manually:

1. **Update current report:**
   ```bash
   cp new-report.html report.html
   ```

2. **Archive with date:**
   ```bash
   cp new-report.html reports/2026-09-15.html
   ```

3. **Update reports.json:**
   Add a new entry at the top (most recent first):
   ```json
   {
     "date": "2026-09-15",
     "label": "September 15, 2026",
     "dayOfWeek": "Monday",
     "file": "reports/2026-09-15.html"
   }
   ```

4. **Commit and push:**
   ```bash
   git add report.html reports/2026-09-15.html reports.json
   git commit -m "Update: EOD Report 2026-09-15"
   git push origin main
   ```

---

## Landing Page Features

### Current Report Section
- Always shows today's (or latest) report
- Expandable dropdown: "View Today's Report"
- Displays inside an iframe; no navigation away

### Report History Section
- **Filters:**
  - All Reports
  - This Week
  - This Month
  - Previous Month

- **Report Grid:**
  - Shows all reports matching the selected filter
  - Most recent first
  - Click any report to view it in an iframe

- **Archive Viewer:**
  - Displays selected historical report
  - Shows date and day of week in header
  - Full-height iframe for comfortable reading

---

## File Structure

```
dailyreportEOD/
├── index.html                 # Landing page (DON'T EDIT MANUALLY)
├── report.html               # Current/latest report (updated daily)
├── reports.json             # Historical report index (auto-updated)
├── reports/                 # Archive folder
│   ├── 2026-09-14.html
│   ├── 2026-09-15.html
│   └── ...
├── update-report.sh         # Daily update workflow script
├── ARCHIVE-README.md        # This file
├── reve-logo-white.png      # Rêve branding
└── .git/                    # GitHub repository
```

---

## How reports.json Works

The `reports.json` file is the engine that powers the Report History section. It has this structure:

```json
[
  {
    "date": "2026-09-15",
    "label": "September 15, 2026",
    "dayOfWeek": "Monday",
    "file": "reports/2026-09-15.html"
  },
  {
    "date": "2026-09-14",
    "label": "September 14, 2026",
    "dayOfWeek": "Sunday",
    "file": "reports/2026-09-14.html"
  }
]
```

**Why this is important:**
- The landing page READS this file dynamically
- No dates are hardcoded in HTML
- Adding a new entry automatically makes it available in the UI
- Filters (This Week, This Month, etc.) work by parsing these dates

---

## Common Tasks

### Add Today's Report
```bash
./update-report.sh ~/new-report.html
```

### Add Yesterday's Report
```bash
./update-report.sh ~/yesterday-report.html 2026-09-14
```

### View Today's Report on the Site
1. Visit the production site (deployed via Vercel)
2. Click "View Today's Report" to expand the current report
3. Or scroll down to "Report History" and click today's date

### View an Historical Report
1. Scroll to "Report History" section
2. Use filters (All, This Week, This Month, Previous Month)
3. Click any report date to view it
4. The report loads in an iframe below the filter controls

### Check if a Report Already Exists
```bash
# Check if a report for 2026-09-15 exists
ls -la reports/2026-09-15.html
```

If it exists, the `update-report.sh` script will warn you before overwriting.

---

## Technical Details

### Date Filtering (in index.html)
The landing page implements four filters in JavaScript:

- **All Reports** — No date filtering
- **This Week** — Reports from Sunday to today
- **This Month** — Reports from day 1 to today
- **Previous Month** — Reports from previous month (all days)

All filters are calculated in JavaScript using `reports.json` dates. No backend needed.

### Duplicate Detection
The `update-report.sh` script checks if `reports/YYYY-MM-DD.html` already exists:
- If yes, it asks for confirmation before overwriting
- If no, it creates the new archive

This prevents accidental data loss.

### Responsive Design
- Desktop: 4-column grid for report dates
- Tablet: 2-3 column grid
- Mobile: 2-column grid, smaller font sizes
- Iframe heights adjust for screen size (800px desktop, 600px mobile)

---

## Troubleshooting

### Script Returns "Permission Denied"
```bash
# Make the script executable
chmod +x update-report.sh
```

### Git Push Fails
```bash
# Verify you have write access
git status

# Check remote
git remote -v

# Try again
git push origin main
```

### Report Not Appearing in History
1. Check `reports.json` was updated:
   ```bash
   cat reports.json
   ```

2. Refresh the landing page (Ctrl+Shift+R or Cmd+Shift+R for hard refresh)

3. Check browser console for errors (F12 → Console tab)

### Vercel Not Deploying
1. Check that your push to GitHub succeeded:
   ```bash
   git log --oneline -5
   ```

2. Visit Vercel dashboard and check deployment status

3. Usually deploys within 30-60 seconds of push

---

## Best Practices

✅ **Always use the script** — `./update-report.sh` handles everything correctly  
✅ **Test locally first** — Open `index.html` locally to verify before pushing  
✅ **Use today's date** — Reports should be dated the day they're generated  
✅ **Keep reports.json clean** — Don't manually edit it unless necessary  
✅ **Check Git logs** — Verify your commit went through: `git log -1`  
✅ **Hard refresh browser** — Use Ctrl+Shift+R after deploying to see changes  

---

## Support

If something goes wrong:

1. Check the error message carefully
2. Verify the HTML file is valid
3. Check Git status: `git status`
4. Review recent commits: `git log --oneline -10`
5. Check Vercel dashboard for deployment errors

For issues with the script itself, verify:
- The script is executable: `ls -la update-report.sh`
- Your report file exists and is readable
- Your date format is correct (YYYY-MM-DD)
- You have write access to the repository

---

## Future Enhancements

Possible future improvements (if needed):

- Search/keyword filter for reports
- Report comparison tool (view two dates side-by-side)
- Export to PDF functionality
- Analytics on report access patterns
- Email notifications for new reports
- Calendar view instead of list view

---

**Last Updated:** September 14, 2026  
**Archive System Version:** 1.0  
**Repository:** `allanc-web/dailyreportEOD`
