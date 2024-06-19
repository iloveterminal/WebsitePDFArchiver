require 'uri'

namespace :archiver do
    desc "Convert a website to PDFs for archiving"
    task :generate_pdfs, [:url] => :environment do |t, args|
      url = args[:url]
      Rails.logger.info "Archiving URL: #{url}"

      uri = URI.parse(url)
      # Replace periods with underscores in host to use as parent folder name.
      host_folder = uri.host.tr('.', '_')
      directory = Rails.root.join('pdfs', host_folder).to_s + '/'

      # Root pages without a path will be called 'index'.
      last_path = 'index'
      folder_path = ''
      full_path = uri.path

      unless full_path.to_s.strip.empty?
        # Get path up to last period or end of string.
        end_pos = full_path.rindex('.') ? full_path.rindex('.')-1 : -1
        # Get path between first and last slashes and clean up.
        folder_path = full_path[full_path.index('/')+1..full_path.rindex('/')].gsub(/[^a-z0-9]_\-/i, '')
        unless uri.path[-1] == '/'
          # Clean up path for most compatible file name.
          last_path = full_path[full_path.rindex('/')+1..end_pos].gsub(/[^a-z0-9_-]/i, '')
        end
      end
      directory << folder_path
      path = last_path + '.pdf'

      # If it doesn't already exist, create a subfolder structure mirroring slashes in URL.
      FileUtils.mkdir_p(directory) unless File.exists?(directory)
      file_path = directory + path
      log_path = "#{host_folder}/#{folder_path}#{path}"
  
      # PDFs generated from previous runs will NOT be overwritten.
      if File.exists?(file_path)
        Rails.logger.info "Skipping existing file: #{log_path}"
      else
        Rails.logger.info "Creating file: #{log_path}"
        pdf = WickedPdf.new.pdf_from_url(url)
        File.open(file_path, 'wb') do |file|
          file << pdf
        end
      end
  
      Rails.logger.info "Archiving complete."
    end
  end