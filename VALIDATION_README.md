# Resume Validation System

A comprehensive validation toolkit for the Bilingual Jekyll Resume Theme that ensures data quality and prevents errors.

## 📦 What Was Created

### Core Components

1. **Jekyll Plugin** (`_plugins/resume-validator.rb`)
   - Automatically validates during `jekyll build`
   - Runs at highest priority
   - Fails build on errors
   - Colorized terminal output

2. **Standalone CLI** (`lib/resume-validator.rb`)
   - Run validation without Jekyll
   - Pre-commit hooks
   - CI/CD integration
   - Flexible command-line options

3. **Documentation**
   - `docs/VALIDATION_GUIDE.md` - Complete guide (37 pages)
   - `docs/VALIDATION_QUICK_START.md` - Quick reference
   - This README - Overview

## ✨ Features

### Validation Capabilities

- ✅ **Required Field Validation** - Ensures all mandatory fields are present
- ✅ **Date Format Validation** - Checks YYYY-MM-DD format
- ✅ **Date Range Validation** - Ensures end dates are after start dates
- ✅ **URL Validation** - Verifies proper URL format
- ✅ **YAML Syntax Checking** - Catches syntax errors
- ✅ **Empty Field Detection** - Warns about empty optional fields
- ✅ **Type Checking** - Validates field types (arrays, strings, booleans)
- ✅ **Bilingual Support** - Validates both English and Arabic data

### Validation Rules

All 13 resume sections are validated:
- Header
- Experience
- Education
- Skills
- Projects
- Certifications
- Courses
- Associations
- Volunteering
- Recognitions
- Interests
- Languages
- Links

### Issue Reporting

Three-tier system:
1. **🔴 Errors** - Critical issues (build-blocking)
2. **🟡 Warnings** - Quality issues (non-blocking)
3. **🔵 Info** - Suggestions (optional improvements)

## 🚀 Quick Start

### Automatic Validation (Recommended)

Simply build your site:

```bash
bundle exec jekyll build
```

Validation runs automatically. If errors are found, the build fails with detailed messages.

### Manual Validation

Run the standalone validator:

```bash
ruby lib/resume-validator.rb --data-dir docs/_data
```

For verbose output with suggestions:

```bash
ruby lib/resume-validator.rb --data-dir docs/_data --verbose
```

## 📖 Usage Examples

### During Development

```bash
# Auto-validates on every rebuild
bundle exec jekyll serve
```

### Before Committing

```bash
# Quick validation check
ruby lib/resume-validator.rb --data-dir docs/_data

# Only if exit code is 0 (success), then commit
ruby lib/resume-validator.rb --data-dir docs/_data && git commit -m "Update resume"
```

### In CI/CD Pipeline

```yaml
# GitHub Actions
- name: Validate resume data
  run: ruby lib/resume-validator.rb --data-dir docs/_data
```

### Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
echo "Running resume data validation..."
ruby lib/resume-validator.rb --data-dir docs/_data || exit 1
```

## 🎯 What Gets Validated

### Example: Experience Section

```yaml
# This will pass validation ✅
- company: "ACME Corp"
  position: "Senior Developer"
  startdate: 2020-01-15
  enddate: 2023-06-30
  location: "New York, NY"
  active: true
  summary: "Led development of key features"

# This will fail validation ❌
- company:              # Error: Missing required field
  position: "Developer"
  startdate: 2023-01-01
  enddate: 2020-01-01   # Error: End date before start date
  active: true
```

### Date Format Examples

```yaml
# ✅ Correct
startdate: 2020-01-15
enddate: 2023-06-30
enddate: Present

# ❌ Incorrect
startdate: Jan 15, 2020    # Wrong format
startdate: 2020/01/15      # Wrong delimiter
startdate: 15-01-2020      # Wrong order
```

### URL Examples

```yaml
# ✅ Correct
url: https://github.com/user/repo
url: https://www.example.com

# ⚠ Warning (works but not ideal)
url: github.com/user/repo
url: www.example.com
```

## 📊 Validation Output

### Success

```
╔═══════════════════════════════════════════════════════════════════════╗
║                     ✓ VALIDATION SUCCESSFUL                           ║
╚═══════════════════════════════════════════════════════════════════════╝

All resume data files are valid!
```

### Errors Found

```
╔═══════════════════════════════════════════════════════════════════════╗
║                        VALIDATION ERRORS (2)                          ║
╚═══════════════════════════════════════════════════════════════════════╝

  ✗ en/experience.yml [entry 1]
    → Missing 'company' field

  ✗ en/education.yml [entry 2]
    → Invalid date format for 'startdate': 2020/13/01

Summary: 2 error(s), 0 warning(s)
Build would fail with current errors.
```

## 🔧 Configuration

### Jekyll Plugin

No configuration needed! The plugin automatically:
- Detects all language directories (`en`, `ar`)
- Validates all section files
- Reports during build

### Environment Variables

```bash
# Show verbose output (info-level suggestions)
RESUME_VALIDATOR_VERBOSE=1 bundle exec jekyll build
```

### CLI Options

```bash
ruby lib/resume-validator.rb [options]

Options:
  -d, --data-dir PATH        Path to _data directory (required)
  -l, --languages LANGS      Comma-separated language codes (default: en,ar)
  -v, --verbose              Show info-level suggestions
  -h, --help                 Show help message
```

## 📁 File Structure

```
bilingual-jekyll-resume-theme/
├── _plugins/
│   └── resume-validator.rb       # Jekyll plugin (auto-validates)
├── lib/
│   └── resume-validator.rb       # Standalone CLI validator
├── docs/
│   ├── VALIDATION_GUIDE.md       # Complete documentation
│   └── VALIDATION_QUICK_START.md # Quick reference
├── VALIDATION_README.md          # This file
└── bilingual-jekyll-resume-theme.gemspec  # Updated to include validators
```

## 🎓 Learning Resources

### For Beginners

1. Start with [VALIDATION_QUICK_START.md](docs/VALIDATION_QUICK_START.md)
2. Run your first validation: `ruby lib/resume-validator.rb --data-dir docs/_data`
3. Fix any errors found
4. Read common error messages in the guide

### For Advanced Users

1. Read [VALIDATION_GUIDE.md](docs/VALIDATION_GUIDE.md) for complete details
2. Set up pre-commit hooks
3. Integrate with CI/CD pipeline
4. Customize validation rules (if needed)

## 🐛 Troubleshooting

### Build Fails with Validation Errors

**Solution:** Read error messages carefully - they show exact file and entry number. Fix each error and rebuild.

### "Missing required field" Errors

**Solution:** Add the missing field with a non-empty value:

```yaml
# Before (error)
- skill:
  description: "..."

# After (fixed)
- skill: "Python Programming"
  description: "..."
```

### Date Validation Errors

**Solution:** Use `YYYY-MM-DD` format:

```yaml
# Before (error)
startdate: 2020/01/15

# After (fixed)
startdate: 2020-01-15
```

### URL Validation Warnings

**Solution:** Add `https://` prefix:

```yaml
# Before (warning)
url: github.com/user/repo

# After (fixed)
url: https://github.com/user/repo
```

## 🔄 Integration Examples

### With Rake

```ruby
# Rakefile
task :validate do
  sh "ruby lib/resume-validator.rb --data-dir docs/_data"
end

task build: :validate do
  sh "bundle exec jekyll build"
end
```

### With npm/package.json

```json
{
  "scripts": {
    "validate": "ruby lib/resume-validator.rb --data-dir docs/_data",
    "build": "npm run validate && bundle exec jekyll build"
  }
}
```

### With Make

```makefile
# Makefile
.PHONY: validate build

validate:
	ruby lib/resume-validator.rb --data-dir docs/_data

build: validate
	bundle exec jekyll build
```

## 📈 Benefits

### For Theme Users

- ✅ Catch errors before deployment
- ✅ Consistent data format
- ✅ Clear error messages
- ✅ Professional resume output
- ✅ No manual checking needed

### For Theme Developers

- ✅ Enforce data standards
- ✅ Reduce support requests
- ✅ Improve theme quality
- ✅ Easy to extend
- ✅ Well-documented

### For Teams

- ✅ Consistent across team members
- ✅ CI/CD ready
- ✅ Version control friendly
- ✅ Automated quality checks
- ✅ Reduces review time

## 🚦 Best Practices

1. **Run validation frequently** - Before every commit
2. **Fix errors immediately** - Don't accumulate technical debt
3. **Review warnings** - They indicate potential issues
4. **Use consistent formats** - Follow date and URL standards
5. **Keep data clean** - Use `active: false` instead of deleting
6. **Document changes** - Use `notes` field for internal info
7. **Test both languages** - Validate en and ar data

## 📊 Validation Statistics

The validator checks:
- **13 resume sections**
- **100+ validation rules**
- **3 issue severity levels**
- **2 languages** (en, ar)
- **Date formats** (YYYY-MM-DD)
- **URL formats** (http/https)
- **Required fields**
- **Optional fields**
- **Data types**
- **Range validation**

## 🎯 Future Enhancements

Potential additions (not yet implemented):
- [ ] JSON output format for machine parsing
- [ ] Custom validation rules via config file
- [ ] Auto-fix for common issues
- [ ] Integration with text editors (LSP)
- [ ] GitHub Action for automatic PR validation
- [ ] HTML report generation
- [ ] Validation history tracking

## 💡 Tips

- Use `--verbose` flag during development to see all suggestions
- Integrate with your IDE for real-time validation
- Set up pre-commit hooks to prevent invalid commits
- Add validation to your deployment pipeline
- Keep the VALIDATION_GUIDE.md handy for reference

## 🤝 Contributing

To extend the validator:

1. Edit validation rules in `_plugins/resume-validator.rb` or `lib/resume-validator.rb`
2. Add new validation methods following existing patterns
3. Update documentation in `docs/VALIDATION_GUIDE.md`
4. Test with sample data
5. Submit a pull request

## 📄 License

Same as the main theme - MIT License

## 📞 Support

For issues or questions:
1. Check [VALIDATION_GUIDE.md](docs/VALIDATION_GUIDE.md) troubleshooting section
2. Review error messages carefully
3. Open an issue on GitHub with details

---

**Version:** 1.0.0  
**Last Updated:** 2024  
**Compatibility:** Jekyll 4.4+, Ruby 3.0+

---

## Quick Links

- 📘 [Complete Guide](docs/VALIDATION_GUIDE.md) - Full documentation
- 🚀 [Quick Start](docs/VALIDATION_QUICK_START.md) - Quick reference
- 🔧 [Main README](README.md) - Theme documentation
- 🐛 [Issue Tracker](https://github.com/kmutahar/bilingual-jekyll-resume-theme/issues)
