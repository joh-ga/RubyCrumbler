require 'ruby-spacy'
require 'csv'
require 'nokogiri'
require 'builder'

class PosTagging
  def initialize()
    @en = Spacy::Language.new("en_core_web_lg")
    @builder = Nokogiri::XML::Builder.new
  end

  def tagger(filename)
    text = File.open(filename, "r")
    text = File.read(text).gsub(/Total number of tokens: \d+/, '')
    text = Kernel.eval(text).join(" ")
    doc = @en.read(text)

    #pos: The simple UPOS part-of-speech tag
    #tag: The detailed part-of-speech tag
    headings = [["text", "pos", "tag"]]
    @rows = []
    output = []

    doc.each do |token|
      @rows << [token.text, token.pos, token.tag]
      output.append(token.text + ": pos:" + token.pos + ", tag:" + token.tag)
    end
    p @rows

    #save to csv
    File.open("pos.csv", "w") do |f|
      f.write(headings.inject([]) { |csv, row| csv << CSV.generate_line(row) }.join(""))
      f.write(@rows.inject([]) { |csv, row| csv << CSV.generate_line(row) }.join(""))
    end

    '''CSV.open("pos.csv", "w") do |csv|
    csv << headings
    csv << rows
    end'''

    #save to txt
    File.write("pos.txt", output)

    #save to xml
    @builder.new do |xml|
      xml.root {
        for r in @rows
          xml.tokens('token' => (r[0])) {
              xml.pos r[1]
              xml.tag r[2]
          }
        end
      }
    end
    pos_xml = @builder.to_xml
    File.write("pos_xml.txt", pos_xml)

  end
end

class NER
  def initialize()
    @en = Spacy::Language.new("en_core_web_lg")
    @builder = Nokogiri::XML::Builder.new
  end

  def ner(filename)
    text = File.open(filename, "r")
    text = File.read(text).gsub(/Total number of tokens: \d+/, '')
    text = Kernel.eval(text).join(" ")
    doc = @en.read(text)

    headings = [['text', 'label']]
    @rows = []
    output = []

    doc.ents.each do |ent|
      @rows << [ent.text, ent.label]
      output.append(ent.text + ": label:" + ent.label)
    end

    #save to csv
    File.open("ner.csv", "w") do |f|
      f.write(headings.inject([]) { |csv, row| csv << CSV.generate_line(row) }.join(""))
      f.write(@rows.inject([]) { |csv, row| csv << CSV.generate_line(row) }.join(""))
    end

    #save to txt
    File.write("ner.txt", output)

    #save to xml
    @builder.new do |xml|
      xml.root {
        for r in @rows
          xml.tokens('token' => (r[0])) {
            xml.label r[1]
          }
        end
      }
    end
    ner_xml = @builder.to_xml
    File.write("ner_xml.txt", ner_xml)
  end
end

fileobject = "tokenization.txt"
tagging = PosTagging.new
tagging.tagger(fileobject)

named_entities = NER.new
named_entities.ner(fileobject)

