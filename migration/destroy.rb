require 'pry'
require 'contentful/management'
require 'contentful'
require 'csv'

d_client = Contentful::Client.new(
  space: ENV['CONTENTFUL_SPACE_ID'],
  access_token: ENV['CONTENTFUL_ACCESS_TOKEN'],
  environment: ENV['CONTENTFUL_ENV']
)

m_client = Contentful::Management::Client.new(ENV['CONTENTFUL_MANAGEMENT_TOKEN'])
environment = m_client.environments(ENV['CONTENTFUL_SPACE_ID']).find(ENV['CONTENTFUL_ENV'])
page = environment.content_types.find('page')

CSV.foreach("migrated-pages.csv", :headers => true) do |line|
  d_entry = d_client.entries(content_type: 'page', 'fields.permalink' => line["permalink"])
  d_entry.each do |item|
    entry = environment.entries.find(item.id)
    entry.unpublish
    entry.destroy
    puts "removed #{line["permalink"]}"
  end
end


