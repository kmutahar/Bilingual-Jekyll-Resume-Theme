# Configuration Guide (_config.yml)

Make your site render correctly with this theme. This guide matches the shipped `_config.yml` template exactly, removes ambiguity, and adds clear examples.

---

## Table of contents

- [Quick start](#quick-start)
- [Required settings](#required-settings)
- [Recommended basics](#recommended-basics)
- [Data source (active_resume_path_en/_ar)](#data-source-active_resume_path_en_ar)
- [Header and contact](#header-and-contact)
- [Sections](#sections)
- [Language and RTL](#language-and-rtl)
- [Social links](#social-links)
- [Analytics](#analytics)
- [Design and authors](#design-and-authors)
- [Jekyll build settings](#jekyll-build-settings)
- [Full example config](#full-example-config)
- [FAQs](#faqs)

---

## Quick start

Copy, paste, and customize the ALL-CAPS values:

```yaml
# Required basics
theme: bilingual-jekyll-resume-theme
url: https://YOUR-DOMAIN.com
baseurl: ""        # leave empty unless deploying to a subpath

title: YOUR NAME
name:
  first: YOUR
  middle: M
  last: NAME
resume_title: YOUR JOB TITLE

description: Your short tagline (optional)

timezone: UTC

contact_info:
  email: you@example.com

# Resume sections to show and their order
resume_section:
  experience: true
  education: true
  projects: true
  skills: true
resume_section_order:
  - experience
  - education
  - projects
  - skills
```

That’s enough to render a working resume using data from `_data/`.

---

## Required settings

- theme: Must be `bilingual-jekyll-resume-theme`.
- url: Full site URL (protocol + host). Used for SEO and absolute links.
- title: Site title (footer and SEO).
- name.first, name.last: Appears in the header (`middle` is optional).
  - use `name_ar.` for arabic version of name
- resume_title: English job title shown in header.
- contact_info.email: Needed if `resume_looking_for_work: true` (for the contact button).

---

## Recommended basics

- description: Short site description/tagline (used by SEO tags).
- baseurl: Keep empty unless deploying under a subdirectory (e.g., `/resume`).
- timezone: Set to your region (e.g., `UTC`, `Etc/GMT`, `America/New_York`).
- resume_avatar: true/false to show/hide the profile image.
- display_header_contact_info: true/false to show/hide contact row in header.

---

## Data source (active_resume_path_en/_ar)

The layouts read resume data from a subtree of `_data/` using dot-separated paths.

- active_resume_path_en: Path for English pages.
- active_resume_path_ar: Path for Arabic pages.
- If the value is an empty string (`""`) or not set, the root of `_data/` is used.

Examples:

```yaml
active_resume_path_en: "en"          # -> uses _data/en/*
active_resume_path_ar: "ar"          # -> uses _data/ar/*
# Nested example:
active_resume_path_en: "2025-06.PM"   # -> uses _data/2025-06/PM/*
# Root example (use files directly under _data/ not suggested unless using one language only):
active_resume_path_en: ""
active_resume_path_ar: ""
```

Note: This theme uses the two keys above (there is no single `active_resume_path`).

---

## Header and contact

- resume_avatar (bool): Show/hide avatar in the header.
- resume_header_intro (HTML string): Short paragraph under your header; basic HTML supported.
- resume_looking_for_work (bool | omitted):
  - true → Shows “Contact me” button using `contact_info.email`.
  - false → Shows a neutral “I’m not looking for work” pill.
  - omitted → Shows nothing.
- display_header_contact_info (bool): Show/hide contact row (phone, email, address, DoB, compact languages).
- enable_live (bool): When true, uses `contact_info.email_live`/`phone_live` instead of `email`/`phone`.

contact_info fields:
- email (required for contact button), phone (optional), address (optional), address_ar (optional on Arabic page), dob (optional), email_live/phone_live (used when `enable_live: true`).

Language-specific titles:
- resume_title (EN), resume_title_ar (AR).

---

## Sections

Available sections: experience, education, certifications, courses, volunteering, projects, skills, recognition, associations, interests, languages, links

- resume_section.<name> (bool): Master toggle per section.
- resume_section.lang_header (bool): When true and `languages` data exists, shows a compact languages summary in the header instead of rendering the full Languages section.
- resume_section_order (array): Rendering order; disabled sections are skipped.

Helpful toggles:
- enable_summary (bool): If true, renders `summary` fields for roles/courses when present.
- resume_print_social_links (bool): If true, adds a text-only “Social Links” section on print/PDF.

---

## Language and RTL

- resume_title_ar: Arabic job title for the Arabic layout.
- address_ar: Arabic address line for the Arabic header contact row.
- Arabic dates: `_includes/ar-date.html` expects `site.data.ar.months` to map 1–12 to Arabic month names (define in `_data/ar.yml` or `_data/ar/months.yml`).
- Present text: English shows “Present”; Arabic shows “حتى الآن”.

---

## Social links

Only keys with values render. Add the ones you want; leave others out.

Supported keys (icons on page; text list for print when enabled):
- github, linkedin, telegram, twitter, medium, dribbble, facebook, instagram, website, whatsapp, devto, flickr, pinterest, youtube

Tip: For printing, set `resume_print_social_links: true`.

---

## Analytics

Choose one (do not enable both):

- Google Tag Manager (recommended):
  - analytics.gtm: GTM-XXXXXXX (adds head script + `<noscript>` body iframe)
- Google Analytics 4 (gtag.js):
  - analytics.ga: true
  - analytics.gtag: G-XXXXXXXXXX

---

## Design and authors

- resume_theme: Theme variant (currently `default`).
- authors: Optional list; not required by the theme but supported in config.

---

## Jekyll build settings

- plugins (required): jekyll-feed, jekyll-seo-tag, jekyll-sitemap, jekyll-redirect-from
- include: Files/dirs to include (e.g., `_redirects`, `.well-known/`, `_pages/`, `_posts/`).
- exclude: Files/dirs to ignore (e.g., README.md, Gemfile*, vendor/, node_modules/, scripts/).
- defaults: Optional front matter defaults.

---

## Full example config

```yaml
# Identity
theme: bilingual-jekyll-resume-theme
url: https://your-domain.com
baseurl: ""
title: Jane Doe
description: Product leader focused on outcomes

timezone: UTC

# Name & titles
name:
  first: Jane
  middle: Q.
  last: Doe
name_ar:
  first:
  middle:
  last:
resume_title: Senior Product Manager
resume_title_ar: مديرة منتج أولى

# Contact
contact_info:
  email: jane.doe@example.com
  phone: "+1 555 555 5555"
  address: "San Francisco, CA"
  address_ar: "سان فرانسيسكو، كاليفورنيا"
# Live-mode alternates
# enable_live: false
# contact_info:
#   email_live: live@example.com
#   phone_live: "+1 555 000 0000"

display_header_contact_info: true
resume_avatar: true
resume_header_intro: "<p>Building products customers love through clear strategy and measurable outcomes.</p>"
resume_looking_for_work: true

# Data paths
active_resume_path_en: "en"
active_resume_path_ar: "ar"

# Sections
resume_section:
  experience: true
  education: true
  certifications: true
  courses: true
  volunteering: true
  projects: true
  associations: true
  skills: false
  recognition: false
  languages: false
  lang_header: true
  interests: false
  links: false
resume_section_order:
  - experience
  - education
  - certifications
  - courses
  - volunteering
  - projects
  - associations
  - skills
  - recognition
  - languages
  - interests
  - links

# Behavior
enable_summary: false
resume_print_social_links: true

# Social
social_links:
  github: https://github.com/janedoe
  linkedin: https://www.linkedin.com/in/janedoe/
  website: https://janedoe.com
  twitter: https://twitter.com/janedoe

# Theme & analytics
authors: []
resume_theme: default
analytics:
  # gtm: GTM-XXXXXXX
  # ga: true
  # gtag: G-XXXXXXXXXX

# Jekyll
plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap
  - jekyll-redirect-from
include:
  - _redirects
  - .well-known/
  - _pages/
  - _posts/
exclude:
  - scratch.md
  - README.md
  - Gemfile*
  - vendor/
  - node_modules/
  - "*.gemspec"
  - netlify.toml
  - vercel.json
  - WARP.md
  - scripts/
```

---

## FAQs

- A section isn’t showing up.
  - Ensure `resume_section.<name>: true`, it appears in `resume_section_order`, and your data items have `active: true`.
- Contact button shows but nothing happens.
  - Set `contact_info.email` or set `resume_looking_for_work: false`.
- Arabic months appear as numbers.
  - Define Arabic month names under `site.data.ar.months` (e.g., `_data/ar/months.yml`).
- Data for EN/AR lives in different folders.
  - Point `active_resume_path_en` and `active_resume_path_ar` at the right subtrees (e.g., `en` and `ar`).
