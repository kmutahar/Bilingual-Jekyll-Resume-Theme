# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Overview

This is a Jekyll theme gem for creating bilingual (English and Arabic) resume/CV websites. The theme supports data-driven resume content with dynamic section rendering and RTL support for Arabic.

## Common Commands

### Development
```bash
# Install dependencies
bundle install

# Run local development server
bundle exec jekyll serve
# Server runs at http://localhost:4000

# Build the gem
gem build bilingual-jekyll-resume-theme.gemspec

# Install the gem locally
gem install bilingual-jekyll-resume-theme-0.2.0.gem
```

### Testing in a consuming site
When testing theme changes in a site that uses this theme, the site should reference the theme via Gemfile and include `theme: bilingual-jekyll-resume-theme` in `_config.yml`.

## High-Level Architecture

### Dual-Language Layout System

The theme has **two primary resume layouts** that share identical structure but differ in language and text direction:

- `_layouts/resume-en.html` - English version (LTR)
- `_layouts/resume-ar.html` - Arabic version (RTL, `dir="rtl"`)

Both layouts:
1. Load resume data from `_data/` directory via Jekyll's `site.data` object
2. Support configurable data paths via `site.active_resume_path_en` and `site.active_resume_path_ar`
3. Dynamically render sections based on `site.resume_section_order` array in `_config.yml`

### Dynamic Section Rendering

Sections are **not hardcoded** in the layout files. Instead:
- The layout loops through `site.resume_section_order` (defined in `_config.yml`)
- For each section name, it includes either:
  - `_includes/resume-section-en.html` (English)
  - `_includes/resume-section-ar.html` (Arabic)
- The include file uses a large conditional block to render the appropriate section based on `section_name` parameter

**Available sections**: `experience`, `education`, `certifications`, `courses`, `volunteering`, `projects`, `skills`, `recognition`, `associations`, `interests`, `languages`, `links`

Each section can be toggled on/off via `site.resume_section.*` boolean flags in `_config.yml`.

### Data Structure

Resume content is stored in the `_data/` directory as YAML or JSON files. The theme expects structured data for each section type:

- **Experience/Volunteering**: Grouped by company, supports multiple roles per company, date ranges
- **Education**: University, degree, year, awards
- **Certifications/Courses**: Issuing organization, dates, credential IDs/URLs
- **Projects**: Name, role, duration, description, optional URL
- **Skills**: Skill name and description
- **Languages**: Language name, proficiency description
- All sections support an `active: true/false` flag to control visibility

### Styling Architecture

Styles are organized using SCSS with modular imports:

- `assets/css/cv.scss` - English resume styles (LTR)
- `assets/css/cv-ar.scss` - Arabic resume styles (includes RTL overrides from `_sass/_resume-rtl.scss`)
- `assets/css/main.scss` - Profile/landing page styles

Core SCSS modules in `_sass/`:
- `_variables.scss` - Colors, fonts, sizing
- `_base.scss` - Typography and base element styles
- `_layout.scss` - Grid and container layout
- `_resume.scss` - Resume-specific component styles
- `_resume-rtl.scss` - RTL-specific overrides for Arabic
- `_normalize.scss` - CSS reset
- `_mixins.scss` - Reusable SCSS mixins

### Configuration-Driven Features

The theme is highly configurable via `_config.yml` (in consuming sites):

- Section visibility toggles (`resume_section.*`)
- Section rendering order (`resume_section_order`)
- Contact info display (`display_header_contact_info`)
- Avatar display (`resume_avatar`)
- Social links configuration (`social_links`)
- Theme variants (`resume_theme`)
- Analytics integration (`enable_live`, analytics configs)
- Data path overrides (`active_resume_path_en`, `active_resume_path_ar`)

### Plugin Dependencies

The theme requires these Jekyll plugins (defined in gemspec):
- `jekyll-feed` - RSS feed generation
- `jekyll-seo-tag` - SEO meta tags
- `jekyll-sitemap` - Sitemap generation
- `jekyll-redirect-from` - URL redirection support

### Arabic-Specific Features

The Arabic layout (`resume-ar.html`) includes:
- Custom date formatting via `_includes/ar-date.html`
- RTL text direction (`dir="rtl"`)
- Reversed icon placement in header
- Arabic section titles and UI text
- "حتى الآن" (Present) for ongoing roles

### Gem Distribution

Files included in the gem (per gemspec `spec.files`):
- `assets/` - CSS and favicons
- `_data/` - Example data files
- `_layouts/` - Layout templates
- `_includes/` - Reusable components and SVG icons
- `_sass/` - SCSS source files
- Documentation files (LICENSE, README, CHANGELOG, CODE_OF_CONDUCT)

Git-tracked files only are included via `git ls-files -z` in the gemspec.
