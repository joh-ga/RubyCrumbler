#PROBLEME
# 1) teilweise wird das Lemma nicht richtig erkannt (e.g. "rotating" -> lemma = "rotating" (anstatt ("rotate"))
# 2) Textinput (NoStopwords.txt) muss bereinigt werden (folgende Zeichen(ketten): [   "   ,   ]   (   )   [1", "])

require "ruby-spacy"
require "terminal-table"

class Lemmatization
  def initialize()
    @en = Spacy::Language.new("en_core_web_lg")
  end

  #Methode für Bereinigung des Input-Texts fehlt noch


  def lemmatizer(filename)
    input = File.open(filename, "r")
    file = input.read()
    input.close()

    # lemmatization
    doc = @en.read(file)
    rows = []
    output = []
    headings = ["text", "lemma"]

    doc.each do |token|
      rows << [token.text, token.lemma]
      output.append(token.text + ": lemma:" + token.lemma)
    end

    #output in Terminal:
    table = Terminal::Table.new rows: rows, headings: headings
    puts table

    #  save to txt
    File.write("lemmatized.txt", output)
  end
end

#fileobject = "NoStopwords.txt"
fileobject = "C:/Users/eng-j/RubymineProjects/NLPproject/GUI-Application-in-Ruby-NLP-Pipeline/Pipeline/NoStopwords.txt"
neu = Lemmatization.new
neu.lemmatizer(fileobject)
