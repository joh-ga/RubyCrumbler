require "ruby-spacy"

class Tokenization
  def initialize()
    @en = Spacy::Language.new("en_core_web_lg")
  end

  def tokenizer(filename)
    input = File.open(filename, "r")
    file = input.read()
    input.close()

    # tokenization
    doc = @en.read(file)
    row = []
    count = 0
    doc.each do |token|
      count += 1
      row << token.text
    end

    # write tokenized content into new output file
    # name = filename.sub(/(?<=.)\..*/, '')
    File.open("tokenization.txt", "w") do |f|
      f.write(row)
    f.write("\n")
    f.write("\n")
    f.write("Total number of tokens: #{count}")
    end
  end
end

fileobject = "doc.txt"
neu = Tokenization.new
neu.tokenizer(fileobject)
