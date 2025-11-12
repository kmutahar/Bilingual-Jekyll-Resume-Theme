# frozen_string_literal: true

require 'yaml'
require 'uri'
require 'date'

module ResumeValidator
  # Main validator class that hooks into Jekyll build process
  class Validator < Jekyll::Generator
    safe true
    priority :highest

    # ANSI color codes for better terminal output
    COLORS = {
      red: "\e[31m",
      yellow: "\e[33m",
      green: "\e[32m",
      blue: "\e[34m",
      reset: "\e[0m"
    }.freeze

    def generate(site)
      @site = site
      @errors = []
      @warnings = []
      @info = []

      Jekyll.logger.info "Resume Validator:", "Starting validation..."

      # Validate all data files
      validate_data_files

      # Report results
      report_results

      # Fail build if there are errors
      if @errors.any?
        raise "Resume validation failed with #{@errors.size} error(s). Fix the issues above and rebuild."
      end
    end

    private

    def validate_data_files
      return unless @site.data

      # Validate both language directories (en, ar) and root-level data files
      %w[en ar].each do |lang|
        next unless @site.data[lang]

        validate_section('header', @site.data[lang]['header'], lang)
        validate_section('experience', @site.data[lang]['experience'], lang)
        validate_section('education', @site.data[lang]['education'], lang)
        validate_section('skills', @site.data[lang]['skills'], lang)
        validate_section('projects', @site.data[lang]['projects'], lang)
        validate_section('certifications', @site.data[lang]['certifications'], lang)
        validate_section('courses', @site.data[lang]['courses'], lang)
        validate_section('associations', @site.data[lang]['associations'], lang)
        validate_section('volunteering', @site.data[lang]['volunteering'], lang)
        validate_section('recognitions', @site.data[lang]['recognitions'], lang)
        validate_section('interests', @site.data[lang]['interests'], lang)
        validate_section('languages', @site.data[lang]['languages'], lang)
        validate_section('links', @site.data[lang]['links'], lang)
      end
    end

    def validate_section(section_name, data, lang)
      return if data.nil?

      send("validate_#{section_name}", data, lang) if respond_to?("validate_#{section_name}", true)
    rescue StandardError => e
      add_error("Unexpected error validating #{section_name} (#{lang})", e.message)
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
      total_issues = @errors.size + @warnings.size

      if @errors.any?
        Jekyll.logger.error ""
        Jekyll.logger.error "#{COLORS[:red]}╔═══════════════════════════════════════════════════════════════════════╗#{COLORS[:reset]}"
        Jekyll.logger.error "#{COLORS[:red]}║                        VALIDATION ERRORS (#{@errors.size})                        ║#{COLORS[:reset]}"
        Jekyll.logger.error "#{COLORS[:red]}╚═══════════════════════════════════════════════════════════════════════╝#{COLORS[:reset]}"
        Jekyll.logger.error ""

        @errors.each do |error|
          Jekyll.logger.error "  #{COLORS[:red]}✗#{COLORS[:reset]} #{error[:context]}"
          Jekyll.logger.error "    → #{error[:message]}"
          Jekyll.logger.error ""
        end
      end

      if @warnings.any?
        Jekyll.logger.warn ""
        Jekyll.logger.warn "#{COLORS[:yellow]}╔═══════════════════════════════════════════════════════════════════════╗#{COLORS[:reset]}"
        Jekyll.logger.warn "#{COLORS[:yellow]}║                       VALIDATION WARNINGS (#{@warnings.size})                      ║#{COLORS[:reset]}"
        Jekyll.logger.warn "#{COLORS[:yellow]}╚═══════════════════════════════════════════════════════════════════════╝#{COLORS[:reset]}"
        Jekyll.logger.warn ""

        @warnings.each do |warning|
          Jekyll.logger.warn "  #{COLORS[:yellow]}⚠#{COLORS[:reset]} #{warning[:context]}"
          Jekyll.logger.warn "    → #{warning[:message]}"
          Jekyll.logger.warn ""
        end
      end

      if @info.any? && ENV['RESUME_VALIDATOR_VERBOSE']
        Jekyll.logger.info ""
        Jekyll.logger.info "#{COLORS[:blue]}╔═══════════════════════════════════════════════════════════════════════╗#{COLORS[:reset]}"
        Jekyll.logger.info "#{COLORS[:blue]}║                    VALIDATION SUGGESTIONS (#{@info.size})                      ║#{COLORS[:reset]}"
        Jekyll.logger.info "#{COLORS[:blue]}╚═══════════════════════════════════════════════════════════════════════╝#{COLORS[:reset]}"
        Jekyll.logger.info ""

        @info.each do |info|
          Jekyll.logger.info "  #{COLORS[:blue]}ℹ#{COLORS[:reset]} #{info[:context]}"
          Jekyll.logger.info "    → #{info[:message]}"
          Jekyll.logger.info ""
        end
      end

      # Final summary
      if @errors.empty? && @warnings.empty?
        Jekyll.logger.info ""
        Jekyll.logger.info "#{COLORS[:green]}╔═══════════════════════════════════════════════════════════════════════╗#{COLORS[:reset]}"
        Jekyll.logger.info "#{COLORS[:green]}║                     ✓ VALIDATION SUCCESSFUL                           ║#{COLORS[:reset]}"
        Jekyll.logger.info "#{COLORS[:green]}╚═══════════════════════════════════════════════════════════════════════╝#{COLORS[:reset]}"
        Jekyll.logger.info ""
      else
        Jekyll.logger.info ""
        Jekyll.logger.info "Resume Validator:", "Found #{@errors.size} error(s) and #{@warnings.size} warning(s)"
        Jekyll.logger.info ""
      end
    end
  end
end
