#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'uri'
require 'date'
require 'optparse'

# Standalone Resume Validator
# Can be run independently without Jekyll
class StandaloneResumeValidator
  # ANSI color codes for better terminal output
  COLORS = {
    red: "\e[31m",
    yellow: "\e[33m",
    green: "\e[32m",
    blue: "\e[34m",
    cyan: "\e[36m",
    bold: "\e[1m",
    reset: "\e[0m"
  }.freeze

  SECTIONS = %w[
    header experience education skills projects certifications
    courses associations volunteering recognitions interests languages links
  ].freeze

  def initialize(data_dir)
    @data_dir = data_dir
    @errors = []
    @warnings = []
    @info = []
    @verbose = false
  end

  def validate(languages: %w[en ar], verbose: false)
    @verbose = verbose

    puts "\n#{COLORS[:cyan]}#{COLORS[:bold]}Resume Validator#{COLORS[:reset]}"
    puts "#{COLORS[:cyan]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#{COLORS[:reset]}"
    puts "Validating data directory: #{@data_dir}"
    puts ""

    languages.each do |lang|
      lang_dir = File.join(@data_dir, lang)
      
      unless Dir.exist?(lang_dir)
        puts "#{COLORS[:yellow]}⚠#{COLORS[:reset]} Skipping #{lang}: directory not found"
        next
      end

      puts "#{COLORS[:blue]}▶#{COLORS[:reset]} Validating #{lang.upcase} files..."
      validate_language_files(lang_dir, lang)
    end

    report_results
    
    # Return exit code
    @errors.empty? ? 0 : 1
  end

  private

  def validate_language_files(lang_dir, lang)
    SECTIONS.each do |section|
      file_path = File.join(lang_dir, "#{section}.yml")
      next unless File.exist?(file_path)

      begin
        data = YAML.load_file(file_path)
        validate_section(section, data, lang, file_path)
      rescue Psych::SyntaxError => e
        add_error("#{lang}/#{section}.yml", "YAML syntax error: #{e.message}")
      rescue StandardError => e
        add_error("#{lang}/#{section}.yml", "Error loading file: #{e.message}")
      end
    end
  end

  def validate_section(section_name, data, lang, file_path)
    return if data.nil?

    method_name = "validate_#{section_name}"
    if respond_to?(method_name, true)
      send(method_name, data, lang)
    else
      add_info("#{lang}/#{section_name}.yml", "No validation rules defined for this section")
    end
  rescue StandardError => e
    add_error("#{lang}/#{section_name}.yml", "Validation error: #{e.message}")
  end

  # ============================================================================
  # SECTION VALIDATORS
  # ============================================================================

  def validate_header(data, lang)
    return unless data.is_a?(Hash)

    if data['intro'] && data['intro'].empty?
      add_warning("#{lang}/header.yml", "intro field is present but empty")
    end
  end

  def validate_experience(data, lang)
    return unless data.is_a?(Array)

    data.each_with_index do |entry, idx|
      next unless entry.is_a?(Hash)

      context = "#{lang}/experience.yml [entry #{idx + 1}]"

      # Required fields
      add_error(context, "Missing 'company' field") if entry['company'].nil? || entry['company'].to_s.strip.empty?
      add_error(context, "Missing 'position' field") if entry['position'].nil? || entry['position'].to_s.strip.empty?
      add_error(context, "Missing 'active' field") if entry['active'].nil?

      # Date validation
      if entry['startdate'] && entry['enddate']
        validate_date(entry['startdate'], context, 'startdate')
        validate_date_or_present(entry['enddate'], context, 'enddate')
        validate_date_range(entry['startdate'], entry['enddate'], context)
      elsif entry['durations']
        validate_durations(entry['durations'], context)
      else
        add_warning(context, "Missing both 'startdate/enddate' and 'durations' fields")
      end

      # Optional but recommended
      add_info(context, "Consider adding 'location' field") if entry['location'].nil? && entry['active']
    end
  end

  def validate_education(data, lang)
    return unless data.is_a?(Array)

    data.each_with_index do |entry, idx|
      next unless entry.is_a?(Hash)

      context = "#{lang}/education.yml [entry #{idx + 1}]"

      # Required fields
      add_error(context, "Missing 'degree' field") if entry['degree'].nil? || entry['degree'].to_s.strip.empty?
      add_error(context, "Missing 'uni' field") if entry['uni'].nil? || entry['uni'].to_s.strip.empty?
      add_error(context, "Missing 'year' field") if entry['year'].nil? || entry['year'].to_s.strip.empty?
      add_error(context, "Missing 'location' field") if entry['location'].nil? || entry['location'].to_s.strip.empty?
      add_error(context, "Missing 'active' field") if entry['active'].nil?

      # Check for both awards list and award field
      if entry['awards'] && entry['award']
        add_info(context, "Both 'awards' list and 'award' field are present - both will be displayed")
      end
    end
  end

  def validate_skills(data, lang)
    return unless data.is_a?(Array)

    data.each_with_index do |entry, idx|
      next unless entry.is_a?(Hash)

      context = "#{lang}/skills.yml [entry #{idx + 1}]"

      # Required fields
      add_error(context, "Missing 'skill' field") if entry['skill'].nil? || entry['skill'].to_s.strip.empty?
      add_error(context, "Missing 'description' field") if entry['description'].nil? || entry['description'].to_s.strip.empty?
      add_error(context, "Missing 'active' field") if entry['active'].nil?
    end
  end

  def validate_projects(data, lang)
    return unless data.is_a?(Array)

    data.each_with_index do |entry, idx|
      next unless entry.is_a?(Hash)

      context = "#{lang}/projects.yml [entry #{idx + 1}]"

      # Required fields
      add_error(context, "Missing 'project' field") if entry['project'].nil? || entry['project'].to_s.strip.empty?
      add_error(context, "Missing 'role' field") if entry['role'].nil? || entry['role'].to_s.strip.empty?
      add_error(context, "Missing 'duration' field") if entry['duration'].nil? || entry['duration'].to_s.strip.empty?
      add_error(context, "Missing 'description' field") if entry['description'].nil? || entry['description'].to_s.strip.empty?
      add_error(context, "Missing 'active' field") if entry['active'].nil?

      # URL validation
      if entry['url'] && !entry['url'].to_s.strip.empty?
        validate_url(entry['url'], context, 'url')
      end
    end
  end

  def validate_certifications(data, lang)
    return unless data.is_a?(Array)

    data.each_with_index do |entry, idx|
      next unless entry.is_a?(Hash)

      context = "#{lang}/certifications.yml [entry #{idx + 1}]"

      # Required fields
      add_error(context, "Missing 'name' field") if entry['name'].nil? || entry['name'].to_s.strip.empty?
      add_error(context, "Missing 'issuing_organization' field") if entry['issuing_organization'].nil? || entry['issuing_organization'].to_s.strip.empty?
      add_error(context, "Missing 'issue_date' field") if entry['issue_date'].nil?
      add_error(context, "Missing 'active' field") if entry['active'].nil?

      # Date validation
      if entry['issue_date']
        validate_date(entry['issue_date'], context, 'issue_date')
      end

      if entry['expiration']
        validate_date(entry['expiration'], context, 'expiration')
        validate_date_range(entry['issue_date'], entry['expiration'], context, 'issue_date', 'expiration')
      end

      # URL validation
      if entry['credential_url'] && !entry['credential_url'].to_s.strip.empty?
        validate_url(entry['credential_url'], context, 'credential_url')
      end

      # Nested courses validation
      if entry['courses'] && entry['courses'].is_a?(Array)
        entry['courses'].each_with_index do |course, course_idx|
          course_context = "#{context} > course #{course_idx + 1}"
          validate_course_entry(course, course_context)
        end
      end
    end
  end

  def validate_courses(data, lang)
    return unless data.is_a?(Array)

    data.each_with_index do |entry, idx|
      next unless entry.is_a?(Hash)

      context = "#{lang}/courses.yml [entry #{idx + 1}]"
      validate_course_entry(entry, context)
    end
  end

  def validate_course_entry(entry, context)
    # Required fields
    add_error(context, "Missing 'name' field") if entry['name'].nil? || entry['name'].to_s.strip.empty?
    add_error(context, "Missing 'issuing_organization' field") if entry['issuing_organization'].nil? || entry['issuing_organization'].to_s.strip.empty?
    add_error(context, "Missing 'startdate' field") if entry['startdate'].nil?
    add_error(context, "Missing 'active' field") if entry['active'].nil?

    # Date validation
    if entry['startdate']
      validate_date(entry['startdate'], context, 'startdate')
    end

    if entry['enddate']
      validate_date(entry['enddate'], context, 'enddate')
      validate_date_range(entry['startdate'], entry['enddate'], context, 'startdate', 'enddate')
    end

    if entry['expiration']
      validate_date(entry['expiration'], context, 'expiration')
    end

    # URL validation
    if entry['credential_url'] && !entry['credential_url'].to_s.strip.empty?
      validate_url(entry['credential_url'], context, 'credential_url')
    end
  end

  def validate_associations(data, lang)
    return unless data.is_a?(Array)

    data.each_with_index do |entry, idx|
      next unless entry.is_a?(Hash)

      context = "#{lang}/associations.yml [entry #{idx + 1}]"

      # Required fields
      add_error(context, "Missing 'organization' field") if entry['organization'].nil? || entry['organization'].to_s.strip.empty?
      add_error(context, "Missing 'role' field") if entry['role'].nil? || entry['role'].to_s.strip.empty?
      add_error(context, "Missing 'year' field") if entry['year'].nil? || entry['year'].to_s.strip.empty?
      add_error(context, "Missing 'active' field") if entry['active'].nil?

      # URL validation
      if entry['url'] && !entry['url'].to_s.strip.empty?
        validate_url(entry['url'], context, 'url')
      end
    end
  end

  def validate_volunteering(data, lang)
    # Volunteering has the same structure as experience
    return unless data.is_a?(Array)

    data.each_with_index do |entry, idx|
      next unless entry.is_a?(Hash)

      context = "#{lang}/volunteering.yml [entry #{idx + 1}]"

      # Required fields
      add_error(context, "Missing 'company' field") if entry['company'].nil? || entry['company'].to_s.strip.empty?
      add_error(context, "Missing 'position' field") if entry['position'].nil? || entry['position'].to_s.strip.empty?
      add_error(context, "Missing 'active' field") if entry['active'].nil?

      # Date validation
      if entry['startdate'] && entry['enddate']
        validate_date(entry['startdate'], context, 'startdate')
        validate_date_or_present(entry['enddate'], context, 'enddate')
        validate_date_range(entry['startdate'], entry['enddate'], context)
      elsif entry['durations']
        validate_durations(entry['durations'], context)
      else
        add_warning(context, "Missing both 'startdate/enddate' and 'durations' fields")
      end
    end
  end

  def validate_recognitions(data, lang)
    return unless data.is_a?(Array)

    data.each_with_index do |entry, idx|
      next unless entry.is_a?(Hash)

      context = "#{lang}/recognitions.yml [entry #{idx + 1}]"

      # Required fields
      add_error(context, "Missing 'award' field") if entry['award'].nil? || entry['award'].to_s.strip.empty?
      add_error(context, "Missing 'organization' field") if entry['organization'].nil? || entry['organization'].to_s.strip.empty?
      add_error(context, "Missing 'year' field") if entry['year'].nil? || entry['year'].to_s.strip.empty?
      add_error(context, "Missing 'summary' field") if entry['summary'].nil? || entry['summary'].to_s.strip.empty?
      add_error(context, "Missing 'active' field") if entry['active'].nil?
    end
  end

  def validate_interests(data, lang)
    return unless data.is_a?(Array)

    data.each_with_index do |entry, idx|
      next unless entry.is_a?(Hash)

      context = "#{lang}/interests.yml [entry #{idx + 1}]"

      # Required fields (interests have a simpler structure)
      add_error(context, "Missing 'description' field") if entry['description'].nil? || entry['description'].to_s.strip.empty?
    end
  end

  def validate_languages(data, lang)
    return unless data.is_a?(Array)

    data.each_with_index do |entry, idx|
      next unless entry.is_a?(Hash)

      context = "#{lang}/languages.yml [entry #{idx + 1}]"

      # Required fields
      add_error(context, "Missing 'language' field") if entry['language'].nil? || entry['language'].to_s.strip.empty?
      add_error(context, "Missing 'description' field") if entry['description'].nil? || entry['description'].to_s.strip.empty?
      add_error(context, "Missing 'descrp_short' field") if entry['descrp_short'].nil? || entry['descrp_short'].to_s.strip.empty?
      add_error(context, "Missing 'active' field") if entry['active'].nil?
    end
  end

  def validate_links(data, lang)
    return unless data.is_a?(Array)

    data.each_with_index do |entry, idx|
      next unless entry.is_a?(Hash)

      context = "#{lang}/links.yml [entry #{idx + 1}]"

      # Required fields
      add_error(context, "Missing 'description' field") if entry['description'].nil? || entry['description'].to_s.strip.empty?
      add_error(context, "Missing 'url' field") if entry['url'].nil? || entry['url'].to_s.strip.empty?
      add_error(context, "Missing 'active' field") if entry['active'].nil?

      # URL validation
      if entry['url']
        validate_url(entry['url'], context, 'url')
      end
    end
  end

  # ============================================================================
  # HELPER VALIDATION METHODS
  # ============================================================================

  def validate_date(date_value, context, field_name)
    return if date_value.nil?

    begin
      # Handle Date objects directly
      return if date_value.is_a?(Date)

      # Convert to string and parse
      date_str = date_value.to_s.strip
      Date.parse(date_str)

      # Check if it matches YYYY-MM-DD format
      unless date_str =~ /^\d{4}-\d{2}-\d{2}$/
        add_warning(context, "#{field_name} '#{date_str}' should be in YYYY-MM-DD format")
      end
    rescue ArgumentError
      add_error(context, "Invalid date format for '#{field_name}': #{date_value}")
    end
  end

  def validate_date_or_present(date_value, context, field_name)
    return if date_value.nil?

    date_str = date_value.to_s.strip
    return if date_str.downcase == 'present'

    validate_date(date_value, context, field_name)
  end

  def validate_date_range(start_date, end_date, context, start_field = 'startdate', end_field = 'enddate')
    return if start_date.nil? || end_date.nil?
    return if end_date.to_s.strip.downcase == 'present'

    begin
      start_d = start_date.is_a?(Date) ? start_date : Date.parse(start_date.to_s)
      end_d = end_date.is_a?(Date) ? end_date : Date.parse(end_date.to_s)

      if end_d < start_d
        add_error(context, "#{end_field} (#{end_d}) is before #{start_field} (#{start_d})")
      end
    rescue ArgumentError
      # Date parsing errors already handled by validate_date
    end
  end

  def validate_durations(durations, context)
    return unless durations.is_a?(Array)

    if durations.empty?
      add_warning(context, "durations array is empty")
    end

    durations.each_with_index do |duration_entry, idx|
      if duration_entry.is_a?(Hash) && duration_entry['duration']
        if duration_entry['duration'].to_s.strip.empty?
          add_warning(context, "duration[#{idx}] is empty")
        end
      else
        add_warning(context, "duration[#{idx}] has invalid structure")
      end
    end
  end

  def validate_url(url_value, context, field_name)
    return if url_value.nil? || url_value.to_s.strip.empty?

    url_str = url_value.to_s.strip

    begin
      uri = URI.parse(url_str)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        add_warning(context, "#{field_name} '#{url_str}' should start with http:// or https://")
      end
    rescue URI::InvalidURIError
      add_error(context, "Invalid URL format for '#{field_name}': #{url_str}")
    end
  end

  # ============================================================================
  # REPORTING METHODS
  # ============================================================================

  def add_error(context, message)
    @errors << { context: context, message: message }
  end

  def add_warning(context, message)
    @warnings << { context: context, message: message }
  end

  def add_info(context, message)
    @info << { context: context, message: message }
  end

  def report_results
    puts ""

    if @errors.any?
      puts "#{COLORS[:red]}╔═══════════════════════════════════════════════════════════════════════╗#{COLORS[:reset]}"
      puts "#{COLORS[:red]}║                        VALIDATION ERRORS (#{@errors.size.to_s.rjust(2)})                       ║#{COLORS[:reset]}"
      puts "#{COLORS[:red]}╚═══════════════════════════════════════════════════════════════════════╝#{COLORS[:reset]}"
      puts ""

      @errors.each do |error|
        puts "  #{COLORS[:red]}✗ #{error[:context]}#{COLORS[:reset]}"
        puts "    → #{error[:message]}"
        puts ""
      end
    end

    if @warnings.any?
      puts "#{COLORS[:yellow]}╔═══════════════════════════════════════════════════════════════════════╗#{COLORS[:reset]}"
      puts "#{COLORS[:yellow]}║                       VALIDATION WARNINGS (#{@warnings.size.to_s.rjust(2)})                    ║#{COLORS[:reset]}"
      puts "#{COLORS[:yellow]}╚═══════════════════════════════════════════════════════════════════════╝#{COLORS[:reset]}"
      puts ""

      @warnings.each do |warning|
        puts "  #{COLORS[:yellow]}⚠ #{warning[:context]}#{COLORS[:reset]}"
        puts "    → #{warning[:message]}"
        puts ""
      end
    end

    if @info.any? && @verbose
      puts "#{COLORS[:blue]}╔═══════════════════════════════════════════════════════════════════════╗#{COLORS[:reset]}"
      puts "#{COLORS[:blue]}║                    VALIDATION SUGGESTIONS (#{@info.size.to_s.rjust(2)})                     ║#{COLORS[:reset]}"
      puts "#{COLORS[:blue]}╚═══════════════════════════════════════════════════════════════════════╝#{COLORS[:reset]}"
      puts ""

      @info.each do |info|
        puts "  #{COLORS[:blue]}ℹ #{info[:context]}#{COLORS[:reset]}"
        puts "    → #{info[:message]}"
        puts ""
      end
    end

    # Final summary
    puts "#{COLORS[:cyan]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#{COLORS[:reset]}"
    
    if @errors.empty? && @warnings.empty?
      puts "#{COLORS[:green]}✓ VALIDATION SUCCESSFUL#{COLORS[:reset]}"
      puts "#{COLORS[:green]}All resume data files are valid!#{COLORS[:reset]}"
    else
      puts "#{COLORS[:yellow]}Summary: #{@errors.size} error(s), #{@warnings.size} warning(s)#{COLORS[:reset]}"
      if @errors.any?
        puts "#{COLORS[:red]}Build would fail with current errors.#{COLORS[:reset]}"
      end
    end
    
    puts "#{COLORS[:cyan]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#{COLORS[:reset]}"
    puts ""
  end
end

# ============================================================================
# CLI INTERFACE
# ============================================================================

if __FILE__ == $PROGRAM_NAME
  options = {
    data_dir: nil,
    languages: %w[en ar],
    verbose: false
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: ruby #{__FILE__} [options]"
    opts.separator ""
    opts.separator "Resume Validator - Validates YAML resume data files"
    opts.separator ""
    opts.separator "Options:"

    opts.on("-d", "--data-dir PATH", "Path to _data directory (required)") do |path|
      options[:data_dir] = path
    end

    opts.on("-l", "--languages LANGS", Array, "Comma-separated list of language codes (default: en,ar)") do |langs|
      options[:languages] = langs
    end

    opts.on("-v", "--verbose", "Show info-level suggestions") do
      options[:verbose] = true
    end

    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit 0
    end
  end.parse!

  # Validate required arguments
  unless options[:data_dir]
    puts "Error: --data-dir is required"
    puts "Usage: ruby #{__FILE__} --data-dir /path/to/_data"
    exit 1
  end

  unless Dir.exist?(options[:data_dir])
    puts "Error: Data directory not found: #{options[:data_dir]}"
    exit 1
  end

  # Run validation
  validator = StandaloneResumeValidator.new(options[:data_dir])
  exit_code = validator.validate(
    languages: options[:languages],
    verbose: options[:verbose]
  )

  exit exit_code
end
