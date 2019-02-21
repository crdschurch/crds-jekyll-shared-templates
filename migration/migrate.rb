require 'pry'
require 'contentful/management'
require 'csv'

def extract_value(line)
  line[line.index(" ") + 1,line.index("\n")].chomp
end

if File.exist?("migrated-pages.csv")
  File.delete("migrated-pages.csv")
end

csv = CSV.open("migrated-pages.csv", "wb")
csv << ["title","permalink","layout","requires_auth", "entry_id"] #header

client = Contentful::Management::Client.new(ENV['CONTENTFUL_MANAGEMENT_TOKEN'])
environment = client.environments(ENV['CONTENTFUL_SPACE_ID']).find(ENV['CONTENTFUL_ENV'])
page = environment.content_types.find('page')

file_list = Dir["./../*.html"]
file_list.each do |file|
  frontmatter = true
  layout = nil
  title = nil
  permalink = nil
  file_content = '';
  loaded_page = File.open(file)
  requires_auth = false
  monetate_page_type = ''
  
  loaded_page.each do |line|
    if line.chomp == "---" && !title.nil?
      frontmatter = false
    end

    if frontmatter == true
      if line.include? "layout: "
        layout = extract_value(line)
      elsif line.include? "title: "
        title = extract_value(line)
      elsif line.include? "permalink: "
        permalink = extract_value(line)
      elsif line.include? "latitude: "
        file_content << "{% assign latitude = \"" + extract_value(line) + "\" %}\n"
      elsif line.include? "longitude: "
        file_content << "{% assign longitude = \"" + extract_value(line) + "\" %}\n"
      elsif line.include? "trip_location: "
        file_content << "{% assign trip_location = \"" + extract_value(line) + "\" %}\n"
      elsif line.include? "legacy_styles: "
        file_content << "<link rel=\"stylesheet\" href=\"/assets/static/legacy.min.css\">"
      elsif line.include? "requires_auth: "
        requires_auth = true
      elsif line.include? "masonry_js: "
        file_content << "{% assign masonry_js = " + extract_value(line) + " %}\n"
      elsif line.include? "monetate_page_type: "
        monetate_page_type = extract_value(line)
      elsif line.include? "zoom: "
        file_content << "{% assign zoom = \"" + extract_value(line) + "\" %}\n"
      end
    elsif line.chomp != "---"
      file_content << line
    end
  end

  file_content << "<!-- migrated from crds-net-shared -->"

  unless layout.nil? || title.nil? || permalink.nil?
    begin
      entry = page.entries.create(
        title: title,
        permalink: permalink,
        body: file_content,
        layout: layout,
        requires_auth: requires_auth,
        search_excluded: false,
        monetate_page_type: monetate_page_type
      )
      entry.save
      entry.publish
      csv << [title, permalink, layout, requires_auth, entry.id]
    rescue => exception
      puts "Had an issue creating title: #{title} permalink: #{permalink}"
      next
    end

  end

  puts "created #{title}"
end




