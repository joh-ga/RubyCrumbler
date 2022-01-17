require 'readability'
require 'open-uri'
require 'nokogiri'

def datainput (input, outputname)

  if File.file?(input)
    first = Nokogiri::HTML(File.open(input))
    doc = first.search('p').map(&:text)
  else
    first = Nokogiri::HTML(URI.open(input))
    doc = first.search('p', 'text').map(&:text)
  end

  doc = doc.join('').gsub(/\d/, '').gsub('[','').gsub(']','').gsub('(','').gsub(')','')
  print doc
  File.write("#{outputname}.txt", doc)
end


#neu = datainput('https://en.wikipedia.org/wiki/Computational_linguistics', 'output')
#p neu
