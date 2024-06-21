# Website PDF Archiver

A Ruby on Rails tool to convert a website to PDFs for offline archiving.

# Compatibility

Tested to work with:
* Ruby 3.3.3
* Rails 7.1.3.4

# Dependencies

* wicked_pdf (https://github.com/mileszs/wicked_pdf)
* wkhtmltopdf-binary (https://github.com/wkhtmltopdf/wkhtmltopdf)
* spidr (https://github.com/postmodern/spidr)

# How to use

Most of the code resides in [lib/tasks/archiver.rake](lib/tasks/archiver.rake), which contains the following 3 tasks:

## find_urls

Crawls a website and outputs a comma delimited text file list of URLs to later feed into the 'pdfs_from_list' task. The intention is that once this list is generated, you should filter it down (delete unneeded lines) to only keep the URLs you actually need converted to PDFs.

**Input:** 1 argument, the root URL from which to begin crawling.

**How to run:** 
```
rails archiver:find_urls['https://mywebsite.com']
```

**Output:** 1 text file per unique input URL, saved to `urls/mywebsite_com.txt`

## pdf_from_url

Converts a single URL to PDF, great for testing before running a large list of URLs. Auto creates a folder structure mirroring slashes in the URL.

**Input:** 1 argument, the URL to convert to PDF.

**How to run:** 
```
rails archiver:pdf_from_url['https://mywebsite.com/sub-folder/awesome-page']
```

**Output:** 1 PDF file per unique path, saved to `pdfs/mywebsite_com/sub-folder/awesome-page.pdf`

## pdfs_from_list

Converts a comma delimited text file list of URLs to PDFs. Auto creates a folder structure mirroring slashes in the URL.

**Input:** 1 argument, the relative path of the comma delimited `.txt` file in the `urls/` folder.

**How to run:** 
```
rails archiver:pdfs_from_list['urls/mywebsite_com.txt']
```

**Output:** 1 PDF file per unique URL in text file, saved to `pdfs/mywebsite_com/sub-folder/awesome-page.pdf`

# Notes

* Any URLs that end in `.pdf` will simply be downloaded into the corresponding folder.
* Existing ouput PDFs or urls text files will NOT be overwritten, you must delete the existing file to generate a new one.
* Keep an eye on `log/development.log` to see progress or any messages.
* Some websites may not work without further code tweaks due to popups or other reasons.
* Use at your own risk only for lawful uses, understand all consequences of using this tool before executing.
