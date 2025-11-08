# JSON Resume Export Documentation

This document explains how the bilingual Jekyll resume theme exports resume data to the [JSON Resume](https://jsonresume.org/) standard format, enabling compatibility with tools like jsonresume.org, resume builders, and ATS systems.

## Overview

The theme includes a Jekyll plugin (`lib/bilingual-jekyll-resume-theme/json-resume-exporter.rb`) that automatically generates a `resume.json` file in JSON Resume format when you build your Jekyll site. This file will be available at `/resume.json` on your site.

## Features

- ✅ Automatic generation during Jekyll build
- ✅ Full JSON Resume schema v1.0.0 compliance
- ✅ Supports both English and Arabic data
- ✅ Respects `active` flags (only exports active entries)
- ✅ Handles dynamic data paths (same as layouts)
- ✅ Maps all resume sections to JSON Resume format

## Installation

### For Theme Development (Fork/Clone)

If you're using the theme by cloning or forking the repository, the plugin is already in place at `lib/bilingual-jekyll-resume-theme/json-resume-exporter.rb` and will work automatically.

### For Gem Installation

If you're using the theme as a Jekyll gem, it should work automatically make sure that in `_config.yml` to add plugin `bilingual-jekyll-resume-theme`

## Configuration

### Basic Setup

The plugin works automatically with no configuration required. By default, it exports English resume data.

**Important:** Make sure Jekyll plugins are enabled in your `_config.yml`:

```yaml
plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap
  - jekyll-redirect-from
  - bilingual-jekyll-resume-theme
```

The plugin will run automatically during Jekyll build.

### Language Selection

To export Arabic data instead, add this to your `_config.yml`:

```yaml
json_resume_export_language: "ar"
```

The plugin will use the same data path configuration as your layouts:
- English: Uses `active_resume_path_en` (default: `"en"`)
- Arabic: Uses `active_resume_path_ar` (default: `"ar"`)

## Data Mapping

The following sections detail how your YAML data structure maps to the JSON Resume schema.

### Basics (Contact Information)

**Source:** `_config.yml` and `_data/{lang}/header.yml`

| JSON Resume Field | YAML Source | Notes |
|------------------|-------------|-------|
| `name` | `name.first` + `name.middle` + `name.last` | Combined from config |
| `label` | `resume_title` or `resume_title_ar` | Job title |
| `email` | `contact_info.email` or `contact_info.email_live` | Uses live email if `enable_live: true` |
| `phone` | `contact_info.phone` or `contact_info.phone_live` | Uses live phone if `enable_live: true` |
| `url` | `url` | Site URL from config |
| `summary` | `header.intro` | Executive summary/intro paragraph |
| `location.address` | `contact_info.address` or `contact_info.address_ar` | Uses Arabic address if exporting Arabic |
| `profiles` | `social_links` | Social media profiles (see below) |

**Social Profiles Mapping:**

The plugin maps common social links to JSON Resume profile format:

- `github` → GitHub
- `linkedin` → LinkedIn
- `twitter` or `x` → Twitter
- `medium` → Medium
- `website` → Website
- `devto` → Dev.to
- `dribbble` → Dribbble
- `youtube` → YouTube
- `instagram` → Instagram
- `facebook` → Facebook
- `telegram` → Telegram
- `mastodon` → Mastodon

### Work Experience

**Source:** `_data/{lang}/experience.yml`

| JSON Resume Field | YAML Field | Notes |
|------------------|------------|-------|
| `name` | `company` | Company/organization name |
| `position` | `position` | Job title |
| `startDate` | `startdate` | ISO format (YYYY-MM-DD) |
| `endDate` | `enddate` | ISO format, `null` if "Present" |
| `summary` | `summary` | Job description (if `enable_summary: true`) |
| `highlights` | `summary` | Array with summary text |
| `location` | `location` | Job location |

**Special Cases:**
- If `durations` field is used instead of `startdate`/`enddate`, dates will be `null` and duration text will be included in `summary`
- Only entries with `active: true` are exported

### Volunteer Work

**Source:** `_data/{lang}/volunteering.yml`

| JSON Resume Field | YAML Field | Notes |
|------------------|------------|-------|
| `organization` | `company` | Organization name |
| `position` | `position` | Volunteer role |
| `startDate` | `startdate` | ISO format (YYYY-MM-DD) |
| `endDate` | `enddate` | ISO format, `null` if "Present" |
| `summary` | `summary` | Description (if `enable_summary: true`) |
| `highlights` | `summary` | Array with summary text |

**Special Cases:**
- Same duration handling as work experience
- Only entries with `active: true` are exported

### Education

**Source:** `_data/{lang}/education.yml`

| JSON Resume Field | YAML Field | Notes |
|------------------|------------|-------|
| `institution` | `uni` | University/institution name |
| `area` | `degree` | Degree name |
| `studyType` | `degree` | Auto-detected (Bachelor/Master/PhD/Associate) |
| `startDate` | `year` | Extracted from year string (heuristic) |
| `endDate` | `year` | Extracted from year string (heuristic) |
| `location` | `location` | Institution location |
| `summary` | `summary` | Additional description |
| `highlights` | `awards` + `summary` | Awards and summary combined |

**Study Type Detection:**
The plugin attempts to detect study type from degree name:
- Contains "bachelor", "b.s.", "b.a." → Bachelor
- Contains "master", "m.s.", "m.a." → Master
- Contains "phd", "doctorate", "ph.d." → PhD
- Contains "associate" → Associate

**Awards:**
- Both `awards` (array) and `award` (single) fields are included in `highlights`
- Only entries with `active: true` are exported

### Awards

**Source:** `_data/{lang}/recognitions.yml`

| JSON Resume Field | YAML Field | Notes |
|------------------|------------|-------|
| `title` | `award` | Award name |
| `date` | `year` | Extracted from year string (heuristic) |
| `awarder` | `organization` | Awarding organization |
| `summary` | `summary` | Award description |

**Note:** Only entries with `active: true` are exported

### Certificates

**Source:** `_data/{lang}/certifications.yml`

| JSON Resume Field | YAML Field | Notes |
|------------------|------------|-------|
| `name` | `name` | Certification name |
| `date` | `issue_date` | ISO format (YYYY-MM-DD) |
| `issuer` | `issuing_organization` | Issuing organization |
| `url` | `credential_url` | Verification URL (if available) |

**Note:** 
- Only entries with `active: true` are exported
- Nested `courses` are not exported (they're for personal record-keeping only)

### Skills

**Source:** `_data/{lang}/skills.yml`

| JSON Resume Field | YAML Field | Notes |
|------------------|------------|-------|
| `name` | `skill` | Skill name |
| `keywords` | `description` | Array with skill description |

**Note:** Only entries with `active: true` are exported

### Languages

**Source:** `_data/{lang}/languages.yml`

| JSON Resume Field | YAML Field | Notes |
|------------------|------------|-------|
| `language` | `language` | Language name |
| `fluency` | `description` or `descrp_short` | Proficiency level |

**Note:** Only entries with `active: true` are exported

### Interests

**Source:** `_data/{lang}/interests.yml`

| JSON Resume Field | YAML Field | Notes |
|------------------|------------|-------|
| `name` | `description` | Interest description |
| `keywords` | `description` | Array with description |

**Note:** All entries are exported (no active flag in interests structure)

### Projects

**Source:** `_data/{lang}/projects.yml`

| JSON Resume Field | YAML Field | Notes |
|------------------|------------|-------|
| `name` | `project` | Project name |
| `description` | `description` | Project description |
| `startDate` | `duration` | Extracted from duration string (heuristic) |
| `endDate` | `duration` | Extracted from duration string (heuristic) |
| `url` | `url` | Project URL (if available) |
| `type` | `role` | Your role in the project |

**Note:** Only entries with `active: true` are exported

## Date Format Handling

### ISO Dates (YYYY-MM-DD)

Fields that use ISO date format are preserved as-is:
- `startdate`, `enddate` in experience/volunteering
- `issue_date`, `expiration` in certifications

### Display Text Dates

Fields that use display text are parsed heuristically:
- `year` in education → Attempts to extract years from strings like "2020 — 2024"
- `year` in recognitions → Attempts to extract year from strings
- `duration` in projects → Attempts to extract dates from duration strings

**Limitations:**
- Date extraction from display text is heuristic and may not always work perfectly
- For best results, use ISO format dates where possible

## Usage Examples

### Accessing the JSON Resume

After building your Jekyll site, the JSON Resume will be available at:

```
https://your-site.com/resume.json
```

### Using with jsonresume.org

1. Build your Jekyll site
2. Copy the contents of `_site/resume.json`
3. Paste into [jsonresume.org](https://jsonresume.org/) editor
4. Use their themes to generate styled resumes

### Using with Resume Builders

Many resume builders and ATS systems accept JSON Resume format:

- **Resume.io**: Import JSON Resume format
- **Reactive Resume**: Native JSON Resume support
- **FlowCV**: Supports JSON Resume import
- **ATS Systems**: Many modern ATS systems can parse JSON Resume

### API Integration

You can use the JSON Resume endpoint for API integrations:

```javascript
// Fetch resume data
fetch('https://your-site.com/resume.json')
  .then(response => response.json())
  .then(data => {
    console.log(data.basics.name);
    console.log(data.work);
  });
```

## Limitations and Notes

1. **Date Parsing**: Display text dates (like `year` and `duration` fields) are parsed heuristically and may not always extract correctly. For best results, consider using ISO format dates.

2. **Missing Fields**: Some JSON Resume fields are not populated because they don't exist in the YAML structure:
   - `work[].url` - Company URLs not in YAML
   - `education[].url` - Institution URLs not in YAML
   - `education[].score` - GPA/scores not in YAML
   - `skills[].level` - Skill levels not in YAML
   - `references` - References section not implemented

3. **Durations Field**: When using the `durations` field (alternative format for non-continuous periods), dates will be `null` and duration text will be included in the summary.

4. **Bilingual Support**: The plugin exports one language at a time. To export both languages, you would need to build the site twice with different `json_resume_export_language` settings, or modify the plugin to generate separate files.

5. **Active Flags**: Only entries with `active: true` are exported (except interests, which don't have active flags).

## Troubleshooting

### JSON file not generated

1. **Check that `lib/bilingual-jekyll-resume-theme/json-resume-exporter.rb` exists**
   - The plugin file must be in your site's `lib/` directory (not the theme's `_plugins/` if using as a gem)

2. **Ensure Jekyll plugins are enabled in `_config.yml`:**
   ```yaml
   plugins:
     - jekyll-feed
     - jekyll-seo-tag
     - jekyll-sitemap
     - jekyll-redirect-from
     - bilingual-jekyll-resume-theme
   ```

3. **Check Jekyll build output for messages:**
   ```bash
   bundle exec jekyll build
   ```
   Look for: `JSON Resume: Generated resume.json at /path/to/_site/resume.json`
   
   If you see: `JSON Resume: No resume data found at path: ...`
   - Check your `active_resume_path_en` or `active_resume_path_ar` settings
   - Verify your data files exist in the expected location

4. **Verify the file was created:**
   ```bash
   ls -la _site/resume.json
   ```
   The file should exist in your `_site/` directory after building

5. **Check for errors:**
   ```bash
   bundle exec jekyll build --trace
   ```
   This will show detailed error messages if something goes wrong

6. **Test with a simple build:**
   - Make sure you have at least some resume data files (e.g., `_data/en/header.yml`)
   - Try building with minimal configuration first

### Missing data in JSON

1. Verify your data files exist in the correct path
2. Check that `active_resume_path_en` or `active_resume_path_ar` is set correctly
3. Ensure entries have `active: true` (where applicable)
4. Check that data files are valid YAML

### Date parsing issues

- Use ISO format (YYYY-MM-DD) for `startdate`, `enddate`, and `issue_date` fields
- For `year` and `duration` fields, the plugin attempts to extract dates but may not always succeed

## Contributing

If you find issues with the mapping or want to improve date parsing, please contribute to the plugin at `_plugins/json-resume-exporter.rb`.

## References

- [JSON Resume Schema](https://jsonresume.org/schema/)
- [JSON Resume Website](https://jsonresume.org/)
- [JSON Resume GitHub](https://github.com/jsonresume/resume-schema)

