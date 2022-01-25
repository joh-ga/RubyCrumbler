require 'open-uri'
require 'nokogiri'
require 'fileutils'
require "ruby-spacy"
require 'glimmer-dsl-libui'
require 'csv'
require 'builder'
require 'tk'
#module RubyCrumbler
#
class Doctoclean #PipelineFeatures evtl als Name fuer die Klasse
  #initialize globally used variables
  def initialize()
    @input
    @text2process
    @projectname
    @filename
    @projectdir
    @en = Spacy::Language.new("en_core_web_lg")
    @stopwords = @en.Defaults.stop_words.to_s.gsub('\'','"').delete('{}" ').gsub('’','\'')
    @stopwords = @stopwords.split(',')
    @doc
  end

  #multidir function is automatically called, if a folder is used for input. For each file in the directory the chosen function will be applied.
  def multidir (directory)
    directory = @projectdir
    Dir.foreach(directory) do |filename|
      next if filename == '.' || filename == '..'
      puts "working on #{filename}"
      @filename=filename
      first = Nokogiri::HTML(File.open("#{@projectdir}/#{@filename}"))
      doc = first.search('p').map(&:text)
      File.write("#{@projectdir}/#{@filename}.txt", doc)
    end
  end

  #use newproject, for creating a new project directory. oldproject will continue an old project, no new folder is created
  #def start(input, projectname, new = false)
  #  @input = input
  #  @filename=File.basename(@input)
  #  @projectname = projectname
  #  if new == true
  #    newproject(input, projectname)
  #  else
  #    oldproject(input, projectname)
  #  end
  #end

  #create a new folder and copy chosen file to it OR copy all files in chosen directory to it OR write file from website into it
  #use txt-, xml- or html-files
  #created folder ist called by projectname. Written files will keep their names and are txts.
  def newproject (input, projectname)
    @input = input
    @projectname = projectname
    @filename=File.basename(@input)
    if !Dir.exists?("#{@projectname}")
      @projectdir = "#{@projectname}"
    else
      i = 1
      while Dir.exist?("#{@projectname}"+i.to_s)
        i = i+1
      end
      @projectdir = "#{@projectname}"+i.to_s
    end
    Dir.mkdir(@projectdir)
    if File.file?(@input)
      FileUtils.cp(@input, @projectdir)
      first = Nokogiri::HTML(File.open(@input))
      doc = first.search('p').map(&:text)
      File.write("#{@projectdir}/#{@filename}.txt", doc)
    else
      if File.directory?(@input)
        FileUtils.cp_r Dir.glob(@input+'/*.*'), @projectdir
        multidir(@projectdir)
      else
        first = Nokogiri::HTML(URI.open(@input))
        doc = first.search('p', 'text').map(&:text)
        File.write("#{@projectdir}/#{@filename}.txt", doc)
      end
    end
  end

  #Use old project folder to continue the data processing
  #def oldproject(input, projectname)
  #    @input = input
  #  @projectname = projectname
  #  @projectdir = "#{@projectname}"
  #  @filename=File.basename(@input)
  #end

  #clean raw text file from project folder from code, markup, special symbols (latin characters, currency symbols, emojis etc.), urls, digits and additional spaces
  #output is a txt file with additional _cl for "cleaned" in name
  def cleantext()
    @text2process = File.open("#{@projectdir}/#{@filename}.txt", 'r')
    @text2process = File.read( @text2process)
    @text2process =   @text2process.gsub('\n','').gsub('\r','').gsub(/\\u[a-f0-9]{4}/i,'').gsub(/https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,}/,'').gsub(/\d/, '').gsub(/[^\w\s\.\'´`]/,'').gsub(/[\.]{2,}/,' ').gsub(/[ ]{2,}/,' ')
    File.write("#{@projectdir}/#{@filename}_cl.txt", @text2process)
    p @text2process
  end

  #normalize text (from cleaned text file or raw text file) by choosing lowercasing and/or seperating contractions (both optional)
  def normalize(contractions=false, low=false)
    if File.exist?("#{@projectdir}/#{@filename}_cl.txt")
      @text2process = File.open("#{@projectdir}/#{@filename}_cl.txt", 'r')
    else @text2process = File.open("#{@projectdir}/#{@filename}.txt", 'r')
    end
    @text2process = File.read(@text2process)
    if low == true
      @text2process = @text2process.downcase
    end
    if contractions == true
      contractions()
    end
    File.write("#{@projectdir}/#{@filename}_cl_n.txt",@text2process)
    p @text2process
  end

  #ambigous contractions: the contraction dictionary will, when sth like "you'd" occure chose "you would" over "you had".
  def contractions()
    contractions = {
      "ain't"=> "are not",
      "aren't"=> "are not",
      "Ain't"=> "Are not",
      "Aren't"=> "Are not",
      "Can't"=> "Cannot",
      "Can't've"=> "Cannot have",
      "'Cause"=> "Because",
      "Could've"=> "Could have",
      "Couldn't"=> "Could not",
      "Couldn't've"=> "could not have",
      "can't"=> "cannot",
      "can't've"=> "cannot have",
      "'cause"=> "because",
      "could've"=> "could have",
      "couldn't"=> "could not",
      "couldn't've"=> "could not have",
      "didn't"=> "did not",
      "doesn't"=> "does not",
      "don't"=> "do not",
      "Didn't"=> "Did not",
      "Doesn't"=> "does not",
      "Don't"=> "Do not",
      "hadn't"=> "had not",
      "hadn't've"=> "had not have",
      "hasn't"=> "has not",
      "haven't"=> "have not",
      "he'd"=> "he would",
      "he'd've"=> "he would have",
      "he'll"=> "he will",
      "he'll've"=> "he will have",
      "he's"=> "he is",
      "how'd"=> "how did",
      "how'd'y"=> "how do you",
      "how'll"=> "how will",
      "how's"=> "how is",
      "Hadn't"=> "had not",
      "Hadn't've"=> "had not have",
      "Hasn't"=> "has not",
      "Haven't"=> "have not",
      "He'd"=> "He would",
      "He'd've"=> "He would have",
      "He'll"=> "He will",
      "He'll've"=> "He will have",
      "He's"=> "He is",
      "How'd"=> "How did",
      "How'd'y"=> "How do you",
      "How'll"=> "How will",
      "How's"=> "How is",
      "I'd"=> "I would",
      "I'd've"=> "I would have",
      "I'll"=> "I will",
      "I'll've"=> "I will have",
      "I'm"=> "I am",
      "I've"=> "I have",
      "i'd"=> "i would",
      "i'd've"=> "i would have",
      "i'll"=> "i will",
      "i'll've"=> "i will have",
      "i'm"=> "i am",
      "i've"=> "i have",
      "it's"=> "it is",
      "isn't"=> "is not",
      "it'd"=> "it would",
      "it'd've"=> "it would have",
      "it'll"=> "it will",
      "it'll've"=> "it will have",
      "It's"=> "It is",
      "Isn't"=> "Is not",
      "It'd"=> "It would",
      "It'd've"=> "It would have",
      "It'll"=> "It will",
      "It'll've"=> "It will have",
      "let's"=> "let us",
      "Let's"=> "Let us",
      "ma'am"=> "madam",
      "mayn't"=> "may not",
      "might've"=> "might have",
      "mightn't"=> "might not",
      "mightn't've"=> "might not have",
      "must've"=> "must have",
      "mustn't"=> "must not",
      "mustn't've"=> "must not have",
      "Ma'am"=> "Madam",
      "Mayn't"=> "May not",
      "Might've"=> "Might have",
      "Mightn't"=> "Might not",
      "Mightn't've"=> "Might not have",
      "Must've"=> "Must have",
      "Mustn't"=> "Must not",
      "Mustn't've"=> "Must not have",
      "needn't"=> "need not",
      "needn't've"=> "need not have",
      "Needn't"=> "Need not",
      "Needn't've"=> "Need not have",
      "o'clock"=> "of the clock",
      "oughtn't"=> "ought not",
      "oughtn't've"=> "ought not have",
      "O'clock"=> "Of the clock",
      "Oughtn't"=> "Ought not",
      "Oughtn't've"=> "Ought not have",
      "shan't"=> "shall not",
      "sha'n't"=> "shall not",
      "shan't've"=> "shall not have",
      "she'd"=> "he would",
      "she'd've"=> "she would have",
      "she'll"=> "she will",
      "she'll've"=> "she will have",
      "she's"=> "she is",
      "should've"=> "should have",
      "shouldn't"=> "should not",
      "shouldn't've"=> "should not have",
      "so've"=> "so have",
      "so's"=> "so is",
      "Shan't"=> "Shall not",
      "Sha'n't"=> "Shall not",
      "Shan't've"=> "Shall not have",
      "She'd"=> "She would",
      "She'd've"=> "She would have",
      "She'll"=> "She will",
      "She'll've"=> "She will have",
      "She's"=> "She is",
      "Should've"=> "Should have",
      "Shouldn't"=> "Should not",
      "Shouldn't've"=> "Should not have",
      "So've"=> "So have",
      "So's"=> "So is",
      "that'd"=> "that would",
      "that'd've"=> "that would have",
      "that's"=> "that is",
      "there'd"=> "there would",
      "there'd've"=> "there would have",
      "there's"=> "there is",
      "they'd"=> "they would",
      "they'd've"=> "they would have",
      "they'll"=> "they will",
      "they'll've"=> "they will have",
      "they're"=> "they are",
      "they've"=> "they have",
      "to've"=> "to have",
      "That'd"=> "That would",
      "That'd've"=> "that would have",
      "That's"=> "That is",
      "There'd"=> "There would",
      "There'd've"=> "There would have",
      "There's"=> "There is",
      "They'd"=> "They would",
      "They'd've"=> "they would have",
      "They'll"=> "They will",
      "They'll've"=> "They will have",
      "They're"=> "They are",
      "They've"=> "They have",
      "To've"=> "To have",
      "wasn't"=> "was not",
      "we'd"=> "we would",
      "we'd've"=> "we would have",
      "we'll"=> "we will",
      "we'll've"=> "we will have",
      "we're"=> "we are",
      "we've"=> "we have",
      "weren't"=> "were not",
      "what'll"=> "what will",
      "what'll've"=> "what will have",
      "what're"=> "what are",
      "what's"=> "what is",
      "what've"=> "what have",
      "when's"=> "when is",
      "when've"=> "when have",
      "where'd"=> "where did",
      "where's"=> "where is",
      "where've"=> "where have",
      "who'll"=> "who will",
      "who'll've"=> "who will have",
      "who's"=> "who is",
      "who've"=> "who have",
      "why's"=> "why is",
      "why've"=> "why have",
      "will've"=> "will have",
      "won't"=> "will not",
      "won't've"=> "will not have",
      "would've"=> "would have",
      "wouldn't"=> "would not",
      "wouldn't've"=> "would not have",
      "Wasn't"=> "Was not",
      "We'd"=> "We would",
      "We'd've"=> "We would have",
      "We'll"=> "We will",
      "We'll've"=> "We will have",
      "We're"=> "We are",
      "We've"=> "We have",
      "Weren't"=> "Were not",
      "What'll"=> "What will",
      "What'll've"=> "What will have",
      "What're"=> "What are",
      "What's"=> "What is",
      "What've"=> "What have",
      "When's"=> "When is",
      "When've"=> "When have",
      "Where'd"=> "Where did",
      "Where's"=> "Where is",
      "Where've"=> "Where have",
      "Who'll"=> "Who will",
      "Who'll've"=> "Who will have",
      "Who's"=> "Who is",
      "Who've"=> "Who have",
      "Why's"=> "Why is",
      "Why've"=> "Why have",
      "Will've"=> "Will have",
      "Won't"=> "Will not",
      "Won't've"=> "Will not have",
      "Would've"=> "Would have",
      "Wouldn't"=> "Would not",
      "Wouldn't've"=> "Would not have",
      "y'all"=> "you all",
      "y'all'd"=> "you all would",
      "y'all'd've"=> "you all would have",
      "y'all're"=> "you all are",
      "y'all've"=> "you all have",
      "you'd"=> "you would",
      "you'd've"=> "you would have",
      "you'll"=> "you will",
      "you'll've"=> "you will have",
      "you're"=> "you are",
      "you've"=> "you have",
      "Y'all"=> "You all",
      "Y'all'd"=> "You all would",
      "Y'all'd've"=> "You all would have",
      "Y'all're"=> "You all are",
      "Y'all've"=> "You all have",
      "You'd"=> "You would",
      "You'd've"=> "You would have",
      "You'll"=> "You will",
      "You'll've"=> "You will have",
      "You're"=> "You are",
      "You've"=> "You have"
    }
    @text2process = @text2process.gsub('’','\'')
    contractions.each { |k, v| @text2process.gsub! k, v }
  end

  def tokenizer()
    input = File.open("#{@projectname}/#{@filename}_cl_n.txt", "r")
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
    File.open("#{@projectdir}/#{@filename}_tok.txt", "w") do |f|
      f.write(row)
      f.write("\n")
      f.write("\n")
      f.write("Total number of tokens: #{count}")
    end
  end

  def stopwordsclean()
    text = File.open("#{@projectdir}/#{@filename}_tok.txt", "w")
    text = File.read(text).gsub(/Total number of tokens: \d+/, '')
    text = Kernel.eval(text)

    shared = text & @stopwords
    textosw = text - shared
    File.write("#{@projectdir}/#{@filename}_nost.txt", textosw)
  end

  def add_stopwords(newsw)
    @stopwords.insert(0, newsw)
  end

  def tagger()
    builder = Nokogiri::XML::Builder.new
    text = File.open("#{@projectdir}/#{@filename}_tok.txt")
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
    File.open("#{@projectdir}/pos.csv", "w") do |f|
      f.write(headings.inject([]) { |csv, row| csv << CSV.generate_line(row) }.join(""))
      f.write(@rows.inject([]) { |csv, row| csv << CSV.generate_line(row) }.join(""))
    end

    '''CSV.open("pos.csv", "w") do |csv|
    csv << headings
    csv << rows
    end'''
    #save to txt
    File.write("#{@projectdir}/pos.txt", output)
    #save to xml
    builder.new do |xml|
      xml.root {
        for r in @rows
          xml.tokens('token' => (r[0])) {
            xml.pos r[1]
            xml.tag r[2]
          }
        end
      }
    end
    pos_xml = builder.to_xml
    File.write("#{@projectdir}/pos.xml", pos_xml)
  end

  def ner()
    builder = Nokogiri::XML::Builder.new
    text = File.open("#{@projectdir}/#{@filename}_tok.txt", "r")
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
    File.open("#{@projectdir}/ner.csv", "w") do |f|
      f.write(headings.inject([]) { |csv, row| csv << CSV.generate_line(row) }.join(""))
      f.write(@rows.inject([]) { |csv, row| csv << CSV.generate_line(row) }.join(""))
    end
    #save to txt
    File.write("#{@projectdir}/ner.txt", output)
    #save to xml
    builder.new do |xml|
      xml.root {
        for r in @rows
          xml.tokens('token' => (r[0])) {
            xml.label r[1]
          }
        end
      }
    end
    ner_xml = builder.to_xml
    File.write("#{@projectdir}/ner.xml", ner_xml)
  end
  end


class OtherGUIWindows
  #this class contains all other GUI window except the main one
  include Glimmer

  def wabout
    window('About Ruby Crumbler', 700, 500) {
      margined true
      area {
        text {
          default_font family: 'Helvetica', size: 13, weight: :normal, italic: :normal, stretch: :normal

          string {
            font family: 'Helvetica', size: 14, weight: :bold, italic: :normal, stretch: :normal
            "Ruby Crumbler Version 0.0.1\n\n"
          }

          string(
            "Developed by Laura Bernardy, Nora Dirlam, Jakob Engel, and Johanna Garthe.\n" \
              "some-email@address.com\n" \
              "March 31, 2022\n\n" \
              "            This project is open source on "
          )
          string{
            underline :single
            # need to include a hyperlink with respective GitHub Repo
            #"https://github.com/joh-ga/GUI-Application-in-Ruby-NLP-Pipeline"
            "GitHub"
          }
        }
        image(File.expand_path('icons/github.png', __dir__), x: 0, y: 85, width: 45, height: 45)
      }
    }.show
  end

  def wdocumentation
    window('Documentation', 700, 500) {
      margined true
      area {
        text {
          default_font family: 'Helvetica', size: 13, weight: :normal, italic: :normal, stretch: :normal

          string {
            font family: 'Helvetica', size: 14, weight: :bold, italic: :normal, stretch: :normal
            "Description of features\n\n"
          }

          string(
            "Please find below all the necessary information about the individual features.\n\n"
          )
          string{
            font family: 'Helvetica', size: 13, weight: :bold, italic: :normal, stretch: :normal
            underline :single
            "Pre-Processing\n"
          }
          string{
            font family: 'Helvetica', size: 13, weight: :bold, italic: :normal, stretch: :normal
            "Data cleaning: "
          }
          string(
            "This includes ..\n"
          )
          string{
            font family: 'Helvetica', size: 13, weight: :bold, italic: :normal, stretch: :normal
            "Normalization: "
          }
          string(
            "This includes converting..\n\n"
          )
          string{
            font family: 'Helvetica', size: 13, weight: :bold, italic: :normal, stretch: :normal
            underline :single
            "Natural Language Processings – Tasks \n"
          }
          string{
            font family: 'Helvetica', size: 13, weight: :bold, italic: :normal, stretch: :normal
            "Tokenization: "
          }
          string(
            "This includes ..\n"
          )
          string{
            font family: 'Helvetica', size: 13, weight: :bold, italic: :normal, stretch: :normal
            "Stopword removal: "
          }
          string(
            "This includes ..\n"
          )
          string{
            font family: 'Helvetica', size: 13, weight: :bold, italic: :normal, stretch: :normal
            "Stemming: "
          }
          string(
            "This includes ..\n"
          )
          string{
            font family: 'Helvetica', size: 13, weight: :bold, italic: :normal, stretch: :normal
            "Lemmatization: "
          }
          string(
            "This includes ..\n"
          )
          string{
            font family: 'Helvetica', size: 13, weight: :bold, italic: :normal, stretch: :normal
            "Part-of-Speech Tagging: "
          }
          string(
            "This includes ..\n"
          )
          string{
            font family: 'Helvetica', size: 13, weight: :bold, italic: :normal, stretch: :normal
            "Named Entity Recognition: "
          }
          string(
            "This includes ..\n\n"
          )
          string{
            font family: 'Helvetica', size: 13, weight: :bold, italic: :normal, stretch: :normal
            "Notes\n"
          }
          string(
            "More information and the source code are available on "
          )
          string{
            underline :single
            "GitHub"
          }
        }
      }
    }.show
  end
  
  def wfileupload
    window('Upload Center', 700, 500) {
      margined true
      vertical_box{
        area {
          text {
            default_font family: 'Helvetica', size: 13, weight: :normal, italic: :normal, stretch: :normal

            string{
              font family: 'Helvetica', size: 14, weight: :bold, italic: :normal, stretch: :normal
              "Upload Center\n\n"
            }

            string(
              "Choose a file(s) or a directory, or specify a URL whose text content should be used to upload.\n" \
              "Note: Total file size may not exceed 50MB. File type must be TXT." \
          )
          }
        }
        group("File Upload"){
          button('Choose file(s)') {
            on_clicked do
              msg_box('Information', 'You clicked the button')
            end
          }
        }
        group("Directory Upload"){
          button('Choose directory') {
            on_clicked do
              msg_box('Information', 'You clicked the button')
            end
          }
        }
        group("URL Upload"){
        }
        horizontal_separator { stretchy false }
        button('Upload') {
          on_clicked do
            msg_box('Information', 'You clicked the button')
          end
        }

      }
    }.show
  end  
end


  class CrumblerGUI
    # this class contains the main GUI window
       include Glimmer


    def launch

      ### START of menu bar
      # menu bar number one
      menu('File') {
        menu_item('Upload Center') {
          on_clicked do
            OtherGUIWindows.new.wfileupload

            # code lines for loading file
            #file = open_file
            #@input = file
            #@projectname = File.basename(@input, ".*")
            #@doc = Doctoclean.new
            #puts @input unless file.nil?
            #@doc.newproject(@input, @projectname)
            #puts "ich funktioniere auch"

            # code lines for choosing directory
            # @input = dir
            # @projectname = File.basename(@input, ".*")
            # @projectname = "#{@projectname}_process"
            # @doc = Doctoclean.new
            # @doc.newproject(@input, @projectname)
          end
        }


        quit_menu_item {
          on_clicked do
            puts 'Goodbye'
          end
        }
      }

      # menu bar number two
      menu('Help') {
        menu_item('About'){
          on_clicked do
            OtherGUIWindows.new.wabout
          end
        }

        menu_item('Documentation'){
          on_clicked do
            OtherGUIWindows.new.wdocumentation
          end
        }
      }

      ### START of main window
      window('Ruby Crumbler',500, 400) {

        margined true

        on_closing do
          puts 'Bye Bye'
        end

        vertical_box {
          horizontal_box {

            vertical_box {
              group('Pre-Processing') {
                stretchy false

                vertical_box {
                  checkbox('Data cleaning') {
                    stretchy false

                    on_toggled do |c|
                      checked = c.checked?
                      # link to the respective pipeline feature
                    end
                  }

                  checkbox('Normalization') {
                    stretchy false

                    on_toggled do |c|
                      checked = c.checked?
                      # link to the respective pipeline feature
                    end
                  }

                  button('Choose all') {
                    stretchy false

                    on_clicked do
                      msg_box('Information', 'You clicked the button')
                    end
                  }

                  button('Reset') {
                    stretchy false

                    on_clicked do
                      msg_box('Information', 'You clicked the button')
                    end
                  }
                }
              }

              group('Natural Language Processing – Tasks') {
                stretchy false

                vertical_box {

                  checkbox('Tokenization') {
                    stretchy false

                    on_toggled do |c|
                      checked = c.checked?
                      # link to the respective pipeline feature
                    end
                  }

                  checkbox('Stopword removal') {
                    stretchy false

                    on_toggled do |c|
                      checked = c.checked?
                      # link to the respective pipeline feature
                    end
                  }

                  checkbox('Stemming') {
                    stretchy false

                    on_toggled do |c|
                      checked = c.checked?
                      # link to the respective pipeline feature
                    end
                  }

                  checkbox('Lemmatization') {
                    stretchy false

                    on_toggled do |c|
                      checked = c.checked?
                      # link to the respective pipeline feature
                    end
                  }

                  checkbox('Part-of-Speech Tagging') {
                    stretchy false

                    on_toggled do |c|
                      checked = c.checked?
                      # link to the respective pipeline feature
                    end
                  }

                  checkbox('Named Entity Recognition') {
                    stretchy false

                    on_toggled do |c|
                      checked = c.checked?
                      # link to the respective pipeline feature
                    end
                  }

                  button('Choose all') {
                    stretchy false

                    on_clicked do
                      msg_box('Information', 'You clicked the button')
                    end
                  }

                  button('Reset') {
                    stretchy false

                    on_clicked do
                      msg_box('Information', 'You clicked the button')
                    end
                  }

                }
              }
            }

            vertical_box {
              group('File Upload Overview') {
                stretchy false

                vertical_box {
                  label("Uploaded file(s):#{@input}") { stretchy false }
                  label('Uploaded file(s) from directory path') { stretchy false }
                  label('Uploaded text of the website: ') { stretchy false }

                }
              }

            }

          }

          horizontal_separator { stretchy false }

          vertical_box {
            group() {
              stretchy false

              vertical_box {
                button('Run') {
                  stretchy false

                  on_clicked do
                    msg_box('Information', 'You clicked the button')
                  end
                }
                button('Cancel') {
                  stretchy false

                  on_clicked do
                    msg_box('Information', 'You clicked the button')
                  end
                }

                label('Status – Progress bar') { stretchy false }
                @progressbar = progress_bar {
                  stretchy false
                }
              }
            }
          }
        }
      }.show
    end
end


CrumblerGUI.new.launch
# neu = Doctoclean.new()
# neu.newproject("C:/Users/Laura/Documents/GitHub/GUI-Application-in-Ruby-NLP-Pipeline/Pipeline/inputdir/tornados.txt", "testdir")
# neu.cleantext()
# neu.normalize(true, false)
# neu.tokenizer()
# neu.tagger()
# neu.ner()

