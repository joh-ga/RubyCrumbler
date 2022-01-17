# script task: tokenization

require "ruby-spacy"

# source file
input = File.open("doc.txt", "r") # probably better to work with file path later
file = input.read()
input.close()

# tokenization
nlp = Spacy::Language.new("en_core_web_lg")
doc = nlp.read(file)
row = []
count = 0
doc.each do |token|
  count += 1
  row << token.text
end

# write tokenized content into new output file
File.open("tokenization.txt", "w") do |f|
  f.write(row)
  f.write("\n")
  f.write("\n")
  f.write("Total number of tokens: #{count}")
end



