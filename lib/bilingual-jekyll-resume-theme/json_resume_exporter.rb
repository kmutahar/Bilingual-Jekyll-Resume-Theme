# frozen_string_literal: true

require 'date'
require 'json'
require 'uri'
require 'fileutils'
require 'jekyll'

module BilingualJekyllResumeTheme
module Jekyll
  # Generator plugin to export resume data to JSON Resume format
  class JsonResumeExporter < ::Jekyll::Generator
    safe true
    priority :lowest

    def generate(site)
      # Determine which language to export (default to English)
      # Users can configure this via _config.yml if needed
      export_language = site.config['json_resume_export_language'] || 'en'
      
      # Get the appropriate data path (empty string means root _data/)
      if export_language == 'ar'
        export_path = site.config['active_resume_path_ar']
      else
        export_path = site.config['active_resume_path_en']
      end
      
      # Default to 'en' or 'ar' only if path is nil (not if it's empty string)
      export_path = export_language if export_path.nil?

      # Get resume data using the same path resolution logic as layouts
      resume_data = resolve_resume_data(site, export_path)
      
      unless resume_data
        ::Jekyll.logger.warn "JSON Resume:", "No resume data found at path: #{export_path || 'root'}"
        return
      end

      # Convert to JSON Resume format
      json_resume = convert_to_json_resume(site, resume_data, export_language)
      
      # Store JSON content in site data for later writing
      site.data['json_resume_content'] = json_resume
      
      # Register hook to write file after site is written
      ::Jekyll::Hooks.register(:site, :post_write) do |site_instance|
        write_json_file(site_instance)
      end
    end

    def write_json_file(site)
      json_resume = site.data['json_resume_content']
      return unless json_resume
      
      begin
        # Write JSON file directly to destination
        dest_path = File.join(site.dest, 'resume.json')
        FileUtils.mkdir_p(File.dirname(dest_path))
        File.write(dest_path, JSON.pretty_generate(json_resume))
        
        ::Jekyll.logger.info "JSON Resume:", "Generated resume.json at #{dest_path}"
      rescue => e
        ::Jekyll.logger.error "JSON Resume Error:", e.message
        ::Jekyll.logger.error "JSON Resume Error:", e.backtrace.join("\n") if ::Jekyll.logger.debug?
      end
    end

    private

    # Resolve resume data path similar to how layouts do it
    def resolve_resume_data(site, path_string)
      return site.data if path_string.nil? || path_string.empty?

      path_parts = path_string.split('.')
      data_object = site.data

      path_parts.each do |part|
        return nil unless data_object.is_a?(Hash)
        data_object = data_object[part]
        return nil if data_object.nil?
      end

      data_object
    end

    # Convert YAML resume data to JSON Resume schema
    def convert_to_json_resume(site, resume_data, language)
      json_resume = {
        '$schema' => 'https://raw.githubusercontent.com/jsonresume/resume-schema/v1.0.0/schema.json',
        'basics' => extract_basics(site, resume_data, language),
        'work' => extract_work(resume_data),
        'volunteer' => extract_volunteer(resume_data),
        'education' => extract_education(resume_data),
        'awards' => extract_awards(resume_data),
        'certificates' => extract_certificates(resume_data),
        'publications' => [],
        'skills' => extract_skills(resume_data),
        'languages' => extract_languages(resume_data),
        'interests' => extract_interests(resume_data),
        'references' => [],
        'projects' => extract_projects(resume_data)
      }

      # Remove empty arrays
      json_resume.reject { |_k, v| v.is_a?(Array) && v.empty? }
    end

    # Extract basics (contact info, name, summary)
    def extract_basics(site, resume_data, language)
      name_obj = language == 'ar' ? site.config['name_ar'] : site.config['name']
      name_parts = []
      name_parts << name_obj['first'] if name_obj && name_obj['first']
      name_parts << name_obj['middle'] if name_obj && name_obj['middle']
      name_parts << name_obj['last'] if name_obj && name_obj['last']
      full_name = name_parts.join(' ')

      contact = site.config['contact_info'] || {}
      enable_live = site.config['enable_live'] == true
      
      email = enable_live && contact['email_live'] ? contact['email_live'] : contact['email']
      phone = enable_live && contact['phone_live'] ? contact['phone_live'] : contact['phone']
      address = language == 'ar' && contact['address_ar'] ? contact['address_ar'] : contact['address']

      basics = {
        'name' => full_name,
        'label' => language == 'ar' ? site.config['resume_title_ar'] : site.config['resume_title'],
        'email' => email,
        'phone' => phone,
        'url' => site.config['url'],
        'summary' => extract_summary(resume_data, language),
        'location' => address ? { 'address' => address } : nil,
        'profiles' => extract_profiles(site.config['social_links'] || {})
      }

      # Remove nil values
      basics.compact
    end

    # Extract summary from header intro
    def extract_summary(resume_data, language)
      header = resume_data['header']
      return nil unless header && header['intro']
      header['intro']
    end

    # Extract social profiles
    def extract_profiles(social_links)
      profiles = []
      
      profile_mapping = {
        'github' => 'GitHub',
        'linkedin' => 'LinkedIn',
        'twitter' => 'Twitter',
        'x' => 'Twitter',
        'medium' => 'Medium',
        'website' => 'Website',
        'devto' => 'Dev.to',
        'dribbble' => 'Dribbble',
        'youtube' => 'YouTube',
        'instagram' => 'Instagram',
        'facebook' => 'Facebook',
        'telegram' => 'Telegram',
        'mastodon' => 'Mastodon'
      }

      social_links.each do |network, url|
        next unless url && !url.empty?
        network_name = profile_mapping[network.to_s] || network.to_s.capitalize
        profiles << {
          'network' => network_name,
          'username' => extract_username_from_url(url),
          'url' => url
        }
      end

      profiles
    end

    # Extract username from URL (basic implementation)
    def extract_username_from_url(url)
      # Try to extract username from common URL patterns
      # This is a simple implementation - can be enhanced
      uri = URI.parse(url) rescue nil
      return nil unless uri
      
      path = uri.path.chomp('/')
      path.split('/').last || nil
    end

    # Extract work experience
    def extract_work(resume_data)
      experience = resume_data['experience'] || []
      work = []

      # Group by company (as the theme does)
      grouped_by_company = {}
      experience.each do |entry|
        next unless entry['active'] == true
        company = entry['company'] || 'Unknown'
        grouped_by_company[company] ||= []
        grouped_by_company[company] << entry
      end

      grouped_by_company.each do |company, entries|
        entries.each do |entry|
          work_item = {
            'name' => company,
            'position' => entry['position'],
            'url' => nil, # Not in YAML structure
            'startDate' => format_date(entry['startdate']),
            'endDate' => format_date(entry['enddate']),
            'summary' => entry['summary'],
            'highlights' => entry['summary'] ? [entry['summary']] : [],
            'location' => entry['location']
          }

          # Handle durations field (alternative format)
          if entry['durations'] && entry['durations'].is_a?(Array)
            # For durations, we'll use the first duration as startDate
            # and create separate entries if needed
            entry['durations'].each do |duration_entry|
              work_item['startDate'] = nil # Can't parse from display text
              work_item['endDate'] = nil
              work_item['summary'] = "Duration: #{duration_entry['duration']}"
            end
          end

          work << work_item.compact
        end
      end

      work
    end

    # Extract volunteer work
    def extract_volunteer(resume_data)
      volunteering = resume_data['volunteering'] || []
      volunteer = []

      # Group by company/organization
      grouped_by_org = {}
      volunteering.each do |entry|
        next unless entry['active'] == true
        org = entry['company'] || 'Unknown'
        grouped_by_org[org] ||= []
        grouped_by_org[org] << entry
      end

      grouped_by_org.each do |org, entries|
        entries.each do |entry|
          volunteer_item = {
            'organization' => org,
            'position' => entry['position'],
            'url' => nil,
            'startDate' => format_date(entry['startdate']),
            'endDate' => format_date(entry['enddate']),
            'summary' => entry['summary'],
            'highlights' => entry['summary'] ? [entry['summary']] : []
          }

          # Handle durations field
          if entry['durations'] && entry['durations'].is_a?(Array)
            entry['durations'].each do |duration_entry|
              volunteer_item['startDate'] = nil
              volunteer_item['endDate'] = nil
              volunteer_item['summary'] = "Duration: #{duration_entry['duration']}"
            end
          end

          volunteer << volunteer_item.compact
        end
      end

      volunteer
    end

    # Extract education
    def extract_education(resume_data)
      education = resume_data['education'] || []
      edu_list = []

      education.each do |entry|
        next unless entry['active'] == true

        # Extract awards
        awards = []
        if entry['awards'] && entry['awards'].is_a?(Array)
          entry['awards'].each do |award_entry|
            awards << award_entry['award'] if award_entry['award']
          end
        end
        awards << entry['award'] if entry['award'] && !entry['award'].empty?

        edu_item = {
          'institution' => entry['uni'],
          'url' => nil,
          'area' => entry['degree'],
          'studyType' => extract_study_type(entry['degree']),
          'startDate' => extract_start_date_from_year(entry['year']),
          'endDate' => extract_end_date_from_year(entry['year']),
          'score' => nil,
          'courses' => [],
          'location' => entry['location']
        }

        # Add awards as highlights or notes
        edu_item['summary'] = entry['summary'] if entry['summary']
        if awards.any?
          highlights = [entry['summary']].compact
          highlights.concat(awards)
          edu_item['highlights'] = highlights
        end

        edu_list << edu_item.compact
      end

      edu_list
    end

    # Extract study type from degree string (basic heuristic)
    def extract_study_type(degree)
      return nil unless degree
      degree_lower = degree.downcase
      
      if degree_lower.include?('bachelor') || degree_lower.include?('b.s.') || degree_lower.include?('b.a.')
        'Bachelor'
      elsif degree_lower.include?('master') || degree_lower.include?('m.s.') || degree_lower.include?('m.a.')
        'Master'
      elsif degree_lower.include?('phd') || degree_lower.include?('doctorate') || degree_lower.include?('ph.d.')
        'PhD'
      elsif degree_lower.include?('associate')
        'Associate'
      else
        nil
      end
    end

    # Extract awards/recognitions
    def extract_awards(resume_data)
      recognitions = resume_data['recognitions'] || []
      awards = []

      recognitions.each do |entry|
        next unless entry['active'] == true
        awards << {
          'title' => entry['award'],
          'date' => extract_start_date_from_year(entry['year']),
          'awarder' => entry['organization'],
          'summary' => entry['summary']
        }.compact
      end

      awards
    end

    # Extract certificates
    def extract_certificates(resume_data)
      certifications = resume_data['certifications'] || []
      certificates = []

      certifications.each do |entry|
        next unless entry['active'] == true
        certificates << {
          'name' => entry['name'],
          'date' => format_date(entry['issue_date']),
          'issuer' => entry['issuing_organization'],
          'url' => entry['credential_url']
        }.compact
      end

      certificates
    end

    # Extract skills
    def extract_skills(resume_data)
      skills = resume_data['skills'] || []
      skills_list = []

      skills.each do |entry|
        next unless entry['active'] == true
        skills_list << {
          'name' => entry['skill'],
          'level' => nil, # Not in YAML structure
          'keywords' => entry['description'] ? [entry['description']] : []
        }
      end

      skills_list
    end

    # Extract languages
    def extract_languages(resume_data)
      languages = resume_data['languages'] || []
      languages_list = []

      languages.each do |entry|
        next unless entry['active'] == true
        languages_list << {
          'language' => entry['language'],
          'fluency' => entry['description'] || entry['descrp_short']
        }
      end

      languages_list
    end

    # Extract interests
    def extract_interests(resume_data)
      interests = resume_data['interests'] || []
      interests_list = []

      interests.each do |entry|
        # Interests don't have active flag in the structure
        next unless entry['description']
        
        interests_list << {
          'name' => entry['description'],
          'keywords' => [entry['description']]
        }
      end

      interests_list
    end

    # Extract projects
    def extract_projects(resume_data)
      projects = resume_data['projects'] || []
      projects_list = []

      projects.each do |entry|
        next unless entry['active'] == true
        projects_list << {
          'name' => entry['project'],
          'description' => entry['description'],
          'highlights' => [],
          'keywords' => [],
          'startDate' => extract_start_date_from_year(entry['duration']),
          'endDate' => extract_end_date_from_year(entry['duration']),
          'url' => entry['url'],
          'type' => entry['role'] # Using role as type
        }.compact
      end

      projects_list
    end

    #
    # --- START OF FIXED CODE ---
    #

    # Format date from YYYY-MM-DD to YYYY-MM-DD (JSON Resume uses ISO format)
    def format_date(date_input)
      return nil unless date_input

      # Handle 'Present' or other non-date strings
      if date_input.to_s.downcase == 'present'
        return nil 
      end

      # If it's already a Date object (which is causing the error)
      if date_input.is_a?(Date)
        return date_input.strftime('%Y-%m-%d')
      end

      # If it's a string, try to parse it
      begin
        Date.parse(date_input.to_s).strftime('%Y-%m-%d')
      rescue
        nil # Could not parse the string
      end
    end

    # Extract start date from year/duration display text (heuristic)
    def extract_start_date_from_year(year_str)
      return nil unless year_str
      
      # Try to extract year from patterns like "2020 — 2024" or "Sep 2020 — June 2024"
      match = year_str.to_s.match(/(\d{4})/)
      return "#{match[1]}-01-01" if match
      
      nil
    end

    # Extract end date from year/duration display text (heuristic)
    def extract_end_date_from_year(year_str)
      return nil unless year_str
      
      # Try to extract second year from patterns like "2020 — 2024"
      matches = year_str.to_s.scan(/(\d{4})/)
      
      # Use matches[1][0] to get the string from the capture group
      return "#{matches[1][0]}-12-31" if matches && matches.length > 1 && matches[1]
      
      nil
    end

    #
    # --- END OF FIXED CODE ---
    #

  end
end
end
