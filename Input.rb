require 'open-uri'
require 'nokogiri'

class Doctoclean
def initialize(input, outputname)
  @output = outputname
  @input = input
  @text2clean
end

def datainput()
  if File.file?(@input)
    first = Nokogiri::HTML(File.open(@input))
    doc = first.search('p').map(&:text)
  else
    first = Nokogiri::HTML(URI.open(@input))
    doc = first.search('p', 'text').map(&:text)
  end
  #print doc
  File.write("#{@output}.txt", doc)
end

def cleantext()
  @text2clean = File.open("#{@output}.txt", 'r')
  @text2clean = File.read(@text2clean)
  @text2clean = @text2clean.gsub('\n','').gsub('\r','').gsub(/\\u[a-f0-9]{4}/i,'').gsub(/https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,}/,'').gsub(/\d/, '').gsub(/[^\w\s\.\'´`]/,'').gsub(/[\.]{2,}/,' ').gsub(/[ ]{2,}/,' ')
  p @text2clean
  File.write("#{@output}_clean.txt", @text2clean)
end
end

neu = Doctoclean.new('https://stackoverflow.com/questions/18492664/ruby-output-unicode-character', "outputdoc")
neu.datainput()
neu.cleantext()