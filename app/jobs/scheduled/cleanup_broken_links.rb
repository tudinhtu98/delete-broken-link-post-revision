# frozen_string_literal: true
require 'uri'
require 'net/http'

module Jobs
  class CleanupBrokenLinks < ::Jobs::Scheduled
    daily at: 7.hours # Runs daily at 7 AM GMT, meaning 1 AM CST timezone

    BATCH_SIZE = 100  # Number of posts per batch to optimize performance
    HTTP_TIMEOUT = 5  # Timeout in seconds for checking links

    def execute(args)
      Rails.logger.info("[CleanupBrokenLinks] Starting broken link check...")

      # 🔹 First-time run: Check all PostRevisions
      is_first_run = !File.exist?("tmp/cleanup_broken_links.lock")

      if is_first_run
        Rails.logger.info("[CleanupBrokenLinks] First-time run - Checking all PostRevisions...")
        check_revisions(PostRevision.all)
      else
        # 🔹 Daily check: Only scan PostRevisions from the previous day
        yesterday = 1.day.ago.beginning_of_day..1.day.ago.end_of_day
        revisions = PostRevision.where(created_at: yesterday)
        check_revisions(revisions)
      end

      Rails.logger.info("[CleanupBrokenLinks] Finished checking broken links.")

      File.write("tmp/cleanup_broken_links.lock", Time.now.to_s) if is_first_run
    end

    private

    def check_revisions(revisions)
        revisions.find_in_batches(batch_size: BATCH_SIZE) do |batch|
          batch.each do |revision|
            begin
              modifications = parse_modifications(revision.modifications)
              text_content = modifications.values.flatten.join(" ")
      
              links = extract_links(text_content)
              next if links.empty?
      
              Rails.logger.info("[CleanupBrokenLinks] Checking PostRevision ID: #{revision.id}")
      
              broken_found = false
              links.each do |link|
                status = check_broken_link(link)
                Rails.logger.info("   - #{link} → Status: #{status}")
      
                if [404, 500].include?(status)
                  broken_found = true
                  break
                end
              end
      
              if broken_found
                Rails.logger.warn("[CleanupBrokenLinks] Deleting PostRevision ID: #{revision.id}")
                
                topic_id = revision.post&.topic_id
                if topic_id
                    revision.destroy
                    # 🔄 Reindex the topic
                    Jobs.enqueue(:reindex_search, topic_id: topic_id)
                end
              end
            rescue => e
              Rails.logger.error("[CleanupBrokenLinks] Error processing PostRevision ID #{revision.id} - #{e.message}")
            end
          end
        end
    end

    # 🌐 Check if a URL is broken
    def check_broken_link(url)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = HTTP_TIMEOUT
      http.read_timeout = HTTP_TIMEOUT

      begin
        response = http.request_head(uri.path)
        return response.code.to_i
      rescue => e
        Rails.logger.error("[CleanupBrokenLinks] Error checking link: #{url} (#{e.message})")
        return 500
      end
    end

    # 🔍 Extract valid URLs from text content
    def extract_links(text)
      return [] if text.nil?
      text.scan(%r{https?://[^\s"'<>\]]+})
    end

    # 📝 Parse YAML modifications field (if stored as a string)
    def parse_modifications(modifications)
      return {} if modifications.blank?
      modifications.is_a?(String) ? (YAML.safe_load(modifications) rescue {}) : modifications
    end
  end
end
