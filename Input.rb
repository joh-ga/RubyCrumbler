require 'open-uri'
require 'nokogiri'

input = 'https://en.wikipedia.org/wiki/Computational_linguistics'

if File.file?(input)
  first = Nokogiri::HTML(File.open(input))
  doc = first.search('p').map(&:text)
else
  first = Nokogiri::HTML(URI.open(input))
  doc = first.search('p', 'text').map(&:text)
end

doc = doc.join('').gsub(/\d/, '').gsub('[','').gsub(']','').gsub('(','').gsub(')','')

print doc
File.write("doc.txt", doc)

