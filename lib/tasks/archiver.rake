require 'open-uri'
require 'uri'

namespace :archiver do
    urls_prefix = 'urls/'
    txt_ext = '.txt'

    desc "Crawl a website and output list of URLs to feed into 'pdfs_from_list' task"
    task :find_urls, [:url] => :environment do |t, args|
      url = args[:url]
      Rails.logger.info "Crawling root URL: #{url}"

      # Clean up filename for cross-platform compatibility.
      filename = url.dup
      filename.sub!(/https?(\:)?(\/)?(\/)?(www\.)?/, '') if filename.include?("http")
      filename.sub!(/(www\.)?/, '') if filename.include?("www")
      filename = filename.tr('.', '_').tr('/', '_').gsub(/[^a-z0-9]_\-/i, '') + txt_ext
      full_path = Rails.root.join('urls', filename).to_s
      log_path = urls_prefix + filename

      # Output files generated from previous runs will NOT be overwritten.
      if File.exist?(full_path)
        Rails.logger.info "Skipping existing file: '#{log_path}'"
      else
        ignore_regex = /
          \.css|\.js|\.json|\.jar|\.xml|\.csv|\.zip|\.7z|\.ico|\.png|\.jpg|
          \.jpeg|\.gif|\.bmp|\.tif|\.ppt|\.pptx|\.otf|\.ttf|\.woff|\.mp3|
          \.wav|\.mp4|\.mpeg|\.tar|\.rar|\.bin|\?print=|\/wp-json\/|\/rss
        /x
        urls_file = File.open(full_path, 'a')
        # Intentional delay between URLs to reduce server resource spikes.
        # https://github.com/postmodern/spidr
        # https://www.rubydoc.info/gems/spidr_epg/
        Spidr.site(
          url,
          :delay => 1,
          :ignore_links => [ignore_regex]
        ) do |spider|
          # Each URL will have comma and newline delimiter.
          spider.every_url { |url| urls_file.write("#{url},\r\n") }
        end
        urls_file.close
        Rails.logger.info "Crawling complete, output saved to: '#{log_path}'."
      end
    end

    # Convert a URL to PDF saved locally.
    def generate_pdf(url)
      Rails.logger.info "Archiving URL: #{url}"
      uri = URI.parse(url)

      # Replace periods with underscores in host to use as parent folder name.
      host_folder = uri.host.tr('.', '_')
      directory = Rails.root.join('pdfs', host_folder).to_s + '/'

      # Root pages without a path will be called 'index'.
      last_path = 'index'
      folder_path = ''
      full_path = uri.path
      pdf_ext = '.pdf'
      is_pdf = url.end_with? pdf_ext

      unless full_path.to_s.strip.empty?
        # Get path up to last period or end of string.
        end_pos = full_path.rindex('.') unless is_pdf ? full_path.rindex('.')-1 : -1
        # Get path between first and last slashes and clean up.
        folder_path = full_path[full_path.index('/') + 1..full_path.rindex('/')]
          .gsub(/[^a-z0-9]_\-/i, '')
        unless uri.path[-1] == '/'
          last_path = full_path[full_path.rindex('/') + 1..end_pos]
          # Clean up path for cross-platform compatible file name, keep PDF name as is.
          last_path.gsub(/[^a-z0-9_-]/i, '') unless is_pdf
        end
      end
      directory << folder_path
      last_path << pdf_ext unless is_pdf

      # If it doesn't exist, create subfolder structure mirroring slashes in URL.
      FileUtils.mkdir_p(directory) unless File.exist?(directory)
      file_path = directory + last_path
      log_path = "#{host_folder}/#{folder_path}#{last_path}"
  
      # PDFs generated from previous runs will NOT be overwritten.
      if File.exist?(file_path)
        Rails.logger.info "Skipping existing file: '#{log_path}'"
      else
        Rails.logger.info "Creating file: '#{log_path}'"
        if is_pdf
          # Download PDFs directly.
          IO.copy_stream(URI.open(url), file_path)
        else
          # https://github.com/mileszs/wicked_pdf
          pdf = WickedPdf.new.pdf_from_url(url)
          File.open(file_path, 'wb') { |file| file << pdf }
        end
      end
    end

    desc "Convert a single web URL to PDF"
    task :pdf_from_url, [:url] => :environment do |t, args|
      generate_pdf(args[:url])
    end

    desc "Convert a comma-delimited list of URLs in '.txt' file to PDFs"
    task :pdfs_from_list, [:filename] => :environment do |t, args|
      filename = args[:filename]
      # Check if input has valid filename extension.
      if filename.include? txt_ext
        # Handle filename inputs with and without leading 'urls/'.
        filename = filename[urls_prefix.length..-1] if filename.start_with?(urls_prefix)
        file_path = Rails.root.join('urls', filename)
        if File.exist?(file_path)
          urls_array = File.read(file_path).split(",")
          urls_array.each do |url|
            generate_pdf(url.strip) unless url.strip.empty?
            # Intentional delay between URLs to reduce server resource spikes.
            sleep(0.5)
          end
        else
          Rails.logger.info "File not found, ensure '#{filename}' is in '#{urls_prefix}'."
        end
      else
        Rails.logger.info "Invalid filename: '#{filename}', must have '#{txt_ext}' extension."
      end
    end
  end
