require 'pry'
require 'contentful/management'
require 'csv'

m_client = Contentful::Management::Client.new(ENV['CONTENTFUL_MANAGEMENT_TOKEN'])
environment = m_client.environments(ENV['CONTENTFUL_SPACE_ID']).find(ENV['CONTENTFUL_ENV'])

CSV.foreach("migrated-pages.csv", :headers => true) do |line|
  entry = environment.entries.find(line["entry_id"])
  entry.unpublish
  entry.destroy
  puts "removed #{line["permalink"]}"
end
