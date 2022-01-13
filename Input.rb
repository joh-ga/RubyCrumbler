require 'readability'
require 'open-uri'
require 'nokogiri'

input = 'https://de.wikipedia.org/wiki/Computerlinguistik'

if File.file?(input)
  first = Nokogiri::HTML(File.open(input))
  doc = first.search('p').map(&:text)
else
  first = Nokogiri::HTML(URI.open(input))
  doc = first.search('p', 'text').map(&:text)
end

print doc
File.write("doc.txt", doc)

