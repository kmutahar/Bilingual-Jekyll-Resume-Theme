# Resume Validation Guide

This guide covers the resume validation system that helps you maintain high-quality, error-free resume data.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Validation Types](#validation-types)
- [Using the Jekyll Plugin](#using-the-jekyll-plugin)
- [Using the Standalone CLI](#using-the-standalone-cli)
- [Validation Rules](#validation-rules)
- [Error Messages](#error-messages)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

The validation system provides two complementary tools:

1. **Jekyll Plugin** (`_plugins/resume-validator.rb`) - Automatically validates during `jekyll build`
2. **Standalone CLI** (`lib/resume-validator.rb`) - Run validation independently without building

### Benefits

- ✅ **Prevents errors** - Catch mistakes before building
- ✅ **Improves data quality** - Ensures consistent formatting
- ✅ **Better debugging** - Clear, actionable error messages
- ✅ **Professional tooling** - Industry-standard validation
- ✅ **CI/CD ready** - Integrate into your deployment pipeline

## Quick Start

### Method 1: Automatic (Jekyll Plugin)

The Jekyll plugin runs automatically during build:

```bash
bundle exec jekyll build
# or
bundle exec jekyll serve
```

If validation errors are found, the build will fail with detailed error messages.

### Method 2: Manual (Standalone CLI)

Run validation without building:

```bash
# From project root
ruby lib/resume-validator.rb --data-dir docs/_data

# With verbose output (shows suggestions)
ruby lib/resume-validator.rb --data-dir docs/_data --verbose

# Validate specific languages only
ruby lib/resume-validator.rb --data-dir docs/_data --languages en
```

## Validation Types

The validator checks for three types of issues:

### 🔴 Errors (Build-Blocking)

Critical issues that will prevent your site from building correctly:
- Missing required fields
- Invalid date formats
- Malformed URLs
- Date range inconsistencies (end date before start date)
- YAML syntax errors

**Action Required:** Must be fixed before building

### 🟡 Warnings (Non-Blocking)

Potential issues that won't block the build but should be reviewed:
- Date formats that don't match YYYY-MM-DD standard
- Empty optional fields
- Missing recommended fields
- URLs without http/https scheme

**Action Recommended:** Review and fix when possible

### 🔵 Info (Suggestions)

Helpful suggestions for improving your resume data:
- Optional fields you might want to add
- Best practices recommendations

**Action Optional:** Consider implementing for better results

## Using the Jekyll Plugin

### Automatic Validation

The plugin is automatically loaded by Jekyll if placed in the `_plugins` directory. It runs during the `:highest` priority phase of the build.

### Configuration

No configuration needed! The plugin automatically validates all language directories (`en`, `ar`) in your `_data` folder.

### Verbose Mode

To see info-level suggestions during Jekyll build, set the environment variable:

```bash
RESUME_VALIDATOR_VERBOSE=1 bundle exec jekyll build
```

### Output Example

```
Resume Validator: Starting validation...

╔═══════════════════════════════════════════════════════════════════════╗
║                        VALIDATION ERRORS (2)                          ║
╚═══════════════════════════════════════════════════════════════════════╝

  ✗ en/experience.yml [entry 1]
    → Missing 'company' field

  ✗ en/education.yml [entry 2]
    → Invalid date format for 'year': 2020-13-01

╔═══════════════════════════════════════════════════════════════════════╗
║                       VALIDATION WARNINGS (1)                         ║
╚═══════════════════════════════════════════════════════════════════════╝

  ⚠ en/projects.yml [entry 3]
    → url 'github.com/user/repo' should start with http:// or https://

Resume Validator: Found 2 error(s) and 1 warning(s)
```

### Disabling Validation

If you need to temporarily disable validation:

1. **Rename the plugin file:**
   ```bash
   mv _plugins/resume-validator.rb _plugins/resume-validator.rb.disabled
   ```

2. **Or move it outside _plugins:**
   ```bash
   mv _plugins/resume-validator.rb lib/
   ```

## Using the Standalone CLI

### Basic Usage

```bash
ruby lib/resume-validator.rb --data-dir /path/to/_data
```

### Command-Line Options

| Option | Description | Example |
|--------|-------------|---------|
| `-d`, `--data-dir PATH` | Path to `_data` directory (required) | `--data-dir docs/_data` |
| `-l`, `--languages LANGS` | Comma-separated language codes | `--languages en,ar` |
| `-v`, `--verbose` | Show info-level suggestions | `--verbose` |
| `-h`, `--help` | Show help message | `--help` |

### Exit Codes

- `0` - Validation passed (no errors)
- `1` - Validation failed (errors found)

### Integration with CI/CD

#### GitHub Actions Example

```yaml
name: Validate Resume Data

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.1
      
      - name: Validate resume data
        run: ruby lib/resume-validator.rb --data-dir docs/_data
```

#### Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash

echo "Running resume data validation..."
ruby lib/resume-validator.rb --data-dir docs/_data

if [ $? -ne 0 ]; then
    echo "Validation failed. Commit aborted."
    exit 1
fi

echo "Validation passed!"
exit 0
```

Make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

## Validation Rules

### All Sections

#### Common Fields

- `active` - **Required** for most sections (boolean: `true` or `false`)
  - Exception: `interests` section doesn't use active field

### Header Section

**File:** `_data/{lang}/header.yml`

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `intro` | String | Optional | Warning if present but empty |

### Experience Section

**File:** `_data/{lang}/experience.yml`

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `company` | String | ✅ Required | Non-empty |
| `position` | String | ✅ Required | Non-empty |
| `active` | Boolean | ✅ Required | Must be present |
| `startdate` | Date | Conditional* | YYYY-MM-DD format |
| `enddate` | Date/String | Conditional* | YYYY-MM-DD or "Present" |
| `durations` | Array | Conditional* | Array of duration objects |
| `location` | String | Optional | Recommended if active |
| `summary` | String | Optional | - |
| `notes` | String | Optional | - |

*Must have either (`startdate` + `enddate`) OR `durations`

**Date Range Validation:**
- End date cannot be before start date
- "Present" is accepted as a valid end date

### Education Section

**File:** `_data/{lang}/education.yml`

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `degree` | String | ✅ Required | Non-empty |
| `uni` | String | ✅ Required | Non-empty |
| `year` | String | ✅ Required | Non-empty |
| `location` | String | ✅ Required | Non-empty |
| `active` | Boolean | ✅ Required | Must be present |
| `awards` | Array | Optional | List of award objects |
| `award` | String | Optional | Single award string |
| `summary` | String | Optional | - |

### Skills Section

**File:** `_data/{lang}/skills.yml`

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `skill` | String | ✅ Required | Non-empty |
| `description` | String | ✅ Required | Non-empty |
| `active` | Boolean | ✅ Required | Must be present |

### Projects Section

**File:** `_data/{lang}/projects.yml`

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `project` | String | ✅ Required | Non-empty |
| `role` | String | ✅ Required | Non-empty |
| `duration` | String | ✅ Required | Non-empty |
| `description` | String | ✅ Required | Non-empty |
| `active` | Boolean | ✅ Required | Must be present |
| `url` | URL | Optional | Valid URL format |

### Certifications Section

**File:** `_data/{lang}/certifications.yml`

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `name` | String | ✅ Required | Non-empty |
| `issuing_organization` | String | ✅ Required | Non-empty |
| `issue_date` | Date | ✅ Required | YYYY-MM-DD format |
| `active` | Boolean | ✅ Required | Must be present |
| `expiration` | Date | Optional | YYYY-MM-DD format |
| `credential_id` | String | Optional | - |
| `credential_url` | URL | Optional | Valid URL format |
| `courses` | Array | Optional | Nested course validation |

**Date Validation:**
- Expiration date cannot be before issue date

### Courses Section

**File:** `_data/{lang}/courses.yml`

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `name` | String | ✅ Required | Non-empty |
| `issuing_organization` | String | ✅ Required | Non-empty |
| `startdate` | Date | ✅ Required | YYYY-MM-DD format |
| `active` | Boolean | ✅ Required | Must be present |
| `enddate` | Date | Optional | YYYY-MM-DD format |
| `expiration` | Date | Optional | YYYY-MM-DD format |
| `credential_id` | String | Optional | - |
| `credential_url` | URL | Optional | Valid URL format |
| `notes` | String | Optional | - |
| `summary` | String | Optional | - |

### Associations Section

**File:** `_data/{lang}/associations.yml`

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `organization` | String | ✅ Required | Non-empty |
| `role` | String | ✅ Required | Non-empty |
| `year` | String | ✅ Required | Non-empty |
| `active` | Boolean | ✅ Required | Must be present |
| `url` | URL | Optional | Valid URL format |
| `summary` | String | Optional | - |

### Volunteering Section

**File:** `_data/{lang}/volunteering.yml`

Same structure and validation as [Experience Section](#experience-section).

### Recognitions Section

**File:** `_data/{lang}/recognitions.yml`

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `award` | String | ✅ Required | Non-empty |
| `organization` | String | ✅ Required | Non-empty |
| `year` | String | ✅ Required | Non-empty |
| `summary` | String | ✅ Required | Non-empty |
| `active` | Boolean | ✅ Required | Must be present |

### Interests Section

**File:** `_data/{lang}/interests.yml`

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `description` | String | ✅ Required | Non-empty |

Note: This section doesn't use the `active` field.

### Languages Section

**File:** `_data/{lang}/languages.yml`

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `language` | String | ✅ Required | Non-empty |
| `description` | String | ✅ Required | Non-empty |
| `descrp_short` | String | ✅ Required | Non-empty |
| `active` | Boolean | ✅ Required | Must be present |

### Links Section

**File:** `_data/{lang}/links.yml`

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `description` | String | ✅ Required | Non-empty |
| `url` | URL | ✅ Required | Non-empty, valid URL |
| `active` | Boolean | ✅ Required | Must be present |

## Error Messages

### Common Error Messages

#### "Missing 'fieldname' field"

**Cause:** A required field is either completely absent or empty.

**Fix:** Add the required field with a non-empty value:

```yaml
# ❌ Wrong
- company:
  position: "Developer"

# ✅ Correct
- company: "ACME Corp"
  position: "Developer"
```

#### "Invalid date format for 'fieldname'"

**Cause:** Date is not in the expected YYYY-MM-DD format.

**Fix:** Use the proper date format:

```yaml
# ❌ Wrong
startdate: 2020/01/15
startdate: January 15, 2020

# ✅ Correct
startdate: 2020-01-15
```

#### "enddate is before startdate"

**Cause:** The end date comes before the start date.

**Fix:** Ensure dates are in chronological order:

```yaml
# ❌ Wrong
startdate: 2022-01-01
enddate: 2021-12-31

# ✅ Correct
startdate: 2021-12-31
enddate: 2022-01-01
```

#### "Invalid URL format"

**Cause:** URL is malformed or doesn't include the protocol.

**Fix:** Use complete URLs with http:// or https://:

```yaml
# ❌ Wrong
url: github.com/user/repo
url: www.example.com

# ✅ Correct
url: https://github.com/user/repo
url: https://www.example.com
```

#### "YAML syntax error"

**Cause:** The YAML file has syntax errors (indentation, missing quotes, etc.).

**Fix:** Check YAML syntax:

```yaml
# ❌ Wrong - inconsistent indentation
- name: Test
   description: Wrong indentation

# ❌ Wrong - unquoted special characters
description: Use: proper syntax

# ✅ Correct
- name: "Test"
  description: "Use: proper syntax"
```

## Best Practices

### 1. Run Validation Early and Often

```bash
# Before committing
ruby lib/resume-validator.rb --data-dir docs/_data

# During development
bundle exec jekyll serve  # Auto-validates on build
```

### 2. Use Consistent Date Formats

Always use `YYYY-MM-DD` format:

```yaml
✅ Good:
startdate: 2020-01-15
enddate: 2023-06-30

❌ Avoid:
startdate: Jan 15, 2020
enddate: 2023/06/30
```

### 3. Keep URLs Complete

Always include the protocol:

```yaml
✅ Good:
url: https://github.com/username
credential_url: https://verify.example.com/cert/123

❌ Avoid:
url: github.com/username
credential_url: verify.example.com/cert/123
```

### 4. Use the `active` Field

Control visibility without deleting data:

```yaml
# Hide an entry without losing the data
- skill: "Outdated Technology"
  description: "No longer relevant"
  active: false  # Won't appear on resume
```

### 5. Write Descriptive Notes

Use the `notes` field for internal reminders:

```yaml
- company: "ACME Corp"
  position: "Developer"
  notes: "Remember to update achievements when project completes"
  active: true
```

### 6. Validate Both Languages

If you maintain bilingual content, validate both:

```bash
ruby lib/resume-validator.rb --data-dir docs/_data --languages en,ar
```

### 7. Fix Errors Before Warnings

Prioritize fixing errors (🔴) before addressing warnings (🟡):

1. Fix all errors first (build-blocking)
2. Address warnings next (quality issues)
3. Consider info suggestions (improvements)

## Troubleshooting

### Build Fails With Validation Errors

**Problem:** `jekyll build` fails with validation errors.

**Solution:**
1. Read the error messages carefully - they show the exact file and entry
2. Fix each error listed
3. Run standalone validator to verify: `ruby lib/resume-validator.rb --data-dir docs/_data`
4. Rebuild

### Validation Shows Errors I Don't See

**Problem:** Validator reports issues in entries that look correct.

**Solution:**
1. Check for invisible characters (tabs vs spaces)
2. Verify YAML syntax with an online YAML validator
3. Look for trailing spaces or incorrect indentation
4. Ensure field names are spelled exactly as required

### Too Many Warnings

**Problem:** Getting overwhelmed by warnings.

**Solution:**
1. Focus on errors first
2. Address warnings in batches
3. Use `--verbose` flag only when you want suggestions
4. Some warnings are informational - they don't prevent building

### Plugin Not Running

**Problem:** Jekyll builds without validation running.

**Solution:**
1. Verify plugin is in `_plugins/resume-validator.rb`
2. Check file permissions: `ls -l _plugins/resume-validator.rb`
3. Ensure you're running Jekyll from project root
4. Check Jekyll version: `bundle exec jekyll -v` (needs Jekyll 4.4+)

### Date Validation Issues

**Problem:** Dates are valid but validator complains.

**Solution:**
1. Use `YYYY-MM-DD` format exactly: `2023-01-15`
2. For current positions, use `"Present"` (quoted)
3. Ensure dates are not in the future (unless intentional)
4. Check for typos in month/day (e.g., month 13 doesn't exist)

### URL Validation Issues

**Problem:** URLs are correct but validator warns about them.

**Solution:**
1. Add protocol: `https://example.com` not `example.com`
2. Use `https://` instead of `http://` when possible
3. Ensure no spaces in URLs
4. Check for missing closing quotes in YAML

## Advanced Usage

### Custom Validation Rules

To add custom validation rules, edit `_plugins/resume-validator.rb` or `lib/resume-validator.rb`:

```ruby
# Add a new validation method
def validate_custom_field(value, context)
  if value && value.length > 200
    add_warning(context, "Field is very long (#{value.length} chars)")
  end
end
```

### Integrating with Other Tools

#### With Rake

Create a `Rakefile`:

```ruby
task :validate do
  sh "ruby lib/resume-validator.rb --data-dir docs/_data"
end

task build: :validate do
  sh "bundle exec jekyll build"
end
```

#### With Make

Create a `Makefile`:

```makefile
.PHONY: validate build

validate:
	ruby lib/resume-validator.rb --data-dir docs/_data

build: validate
	bundle exec jekyll build
```

### Continuous Validation

Watch for changes and auto-validate:

```bash
# Using entr (install with: brew install entr)
find docs/_data -name "*.yml" | entr -c ruby lib/resume-validator.rb --data-dir docs/_data
```

## Support

If you encounter issues:

1. Check this guide's [Troubleshooting](#troubleshooting) section
2. Review the [Validation Rules](#validation-rules) for your section
3. Run with `--verbose` flag for more details
4. Open an issue on GitHub with:
   - The error message
   - The relevant YAML content (sanitized)
   - Steps to reproduce

## Changelog

### Version 1.0.0 (Initial Release)

- ✅ Jekyll plugin with automatic build-time validation
- ✅ Standalone CLI validator
- ✅ Comprehensive validation rules for all resume sections
- ✅ Date format validation
- ✅ URL format validation
- ✅ Date range consistency checks
- ✅ Colorized terminal output
- ✅ Three-tier issue reporting (errors, warnings, info)
- ✅ Bilingual support (en, ar)
- ✅ CI/CD ready with proper exit codes

---

**Last Updated:** 2024
**Version:** 1.0.0
