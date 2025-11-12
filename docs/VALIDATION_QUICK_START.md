# Resume Validator Quick Start

Quick reference for using the resume validation system.

## 🚀 Usage

### Automatic Validation (During Build)

```bash
bundle exec jekyll build
# or
bundle exec jekyll serve
```

The validation runs automatically. Build fails if errors are found.

### Manual Validation (Standalone)

```bash
# Basic usage
ruby lib/resume-validator.rb --data-dir docs/_data

# With suggestions
ruby lib/resume-validator.rb --data-dir docs/_data --verbose

# English only
ruby lib/resume-validator.rb --data-dir docs/_data --languages en
```

## 📊 Issue Types

| Type | Symbol | Description | Blocks Build? |
|------|--------|-------------|---------------|
| Error | 🔴 ✗ | Critical issues | ✅ Yes |
| Warning | 🟡 ⚠ | Quality issues | ❌ No |
| Info | 🔵 ℹ | Suggestions | ❌ No |

## 🔧 Quick Fixes

### Missing Required Field

```yaml
# ❌ Error
- company:
  position: "Developer"

# ✅ Fix
- company: "ACME Corp"
  position: "Developer"
```

### Invalid Date Format

```yaml
# ❌ Error
startdate: 2020/01/15

# ✅ Fix
startdate: 2020-01-15
```

### Invalid URL

```yaml
# ❌ Warning
url: github.com/user/repo

# ✅ Fix
url: https://github.com/user/repo
```

### Date Range Error

```yaml
# ❌ Error
startdate: 2022-01-01
enddate: 2021-12-31

# ✅ Fix
startdate: 2021-12-31
enddate: 2022-01-01
```

## 📋 Required Fields by Section

### Experience & Volunteering
- `company` ✅
- `position` ✅
- `active` ✅
- `startdate` + `enddate` OR `durations` ✅

### Education
- `degree` ✅
- `uni` ✅
- `year` ✅
- `location` ✅
- `active` ✅

### Skills
- `skill` ✅
- `description` ✅
- `active` ✅

### Projects
- `project` ✅
- `role` ✅
- `duration` ✅
- `description` ✅
- `active` ✅

### Certifications
- `name` ✅
- `issuing_organization` ✅
- `issue_date` ✅
- `active` ✅

### Courses
- `name` ✅
- `issuing_organization` ✅
- `startdate` ✅
- `active` ✅

### Languages
- `language` ✅
- `description` ✅
- `descrp_short` ✅
- `active` ✅

### Links
- `description` ✅
- `url` ✅
- `active` ✅

### Recognitions
- `award` ✅
- `organization` ✅
- `year` ✅
- `summary` ✅
- `active` ✅

### Associations
- `organization` ✅
- `role` ✅
- `year` ✅
- `active` ✅

### Interests
- `description` ✅

## 🛠️ Common Commands

```bash
# Validate before committing
ruby lib/resume-validator.rb --data-dir docs/_data

# Validate with full output
ruby lib/resume-validator.rb --data-dir docs/_data --verbose

# Check exit code
ruby lib/resume-validator.rb --data-dir docs/_data
echo $?  # 0 = success, 1 = errors found

# CI/CD usage
ruby lib/resume-validator.rb --data-dir docs/_data || exit 1
```

## 📚 Full Documentation

For complete details, see [VALIDATION_GUIDE.md](VALIDATION_GUIDE.md)

---

**Tip:** Run validation before each commit to catch errors early!
