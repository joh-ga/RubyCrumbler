require 'open-uri'
require 'nokogiri'
require 'fileutils'
require 'ruby-spacy'
require 'glimmer-dsl-libui'
require 'csv'
require 'builder'
require 'tk'
require 'terminal-table'

module RubyCrumbler

  class PipelineFeatures
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
      @filenumber
      @lang
    end

    #multidir function is automatically called, if a folder is used for input. For each file in the directory the chosen function will be applied.
    def multidir (directory)
      directory = @projectdir
      @filenumber = Dir.glob(File.join(directory, '**', '*')).select { |file| File.file?(file) }.count
      #filenumber is later important for opening the x recent files in the methods
      print @filenumber
      Dir.foreach(directory) do |filename|
        next if filename == '.' || filename == '..'
        puts "working on #{filename}"
        @filenamein=filename
        @filename=File.basename(filename, ".*")
        first = Nokogiri::HTML(File.open("#{@projectdir}/#{@filenamein}"))
        doc = first.search('p').map(&:text)
        #encode doc to correct encoding for german special characters
        doc = doc.join("").encode("iso-8859-1").force_encoding("utf-8")
        doc = doc.gsub(/\n/, '')
        File.write("#{@projectdir}/#{@filename}", doc)
      end
    end


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
        @filenumber = 1
        #encode doc to correct encoding for german special characters
        doc = doc.join("").encode("iso-8859-1").force_encoding("utf-8")
        doc = doc.gsub(/\n/, '')
        File.write("#{@projectdir}/#{@filename}", doc)
      else
        if File.directory?(@input)
          FileUtils.cp_r Dir.glob(@input+'/*.*'), @projectdir
          multidir(@projectdir)
        else
          first = Nokogiri::HTML(URI.open(@input))
          doc = first.search('p', 'text').map(&:text)
          @filenumber = 1
          #encode doc to correct encoding for german special characters
          doc = doc.join("").encode("iso-8859-1").force_encoding("utf-8")
          doc = doc.gsub(/\n/, '')
          File.write("#{@projectdir}/#{@filename}.txt", doc)
        end
      end
    end


    #clean raw text file from project folder from code, markup, special symbols (latin characters, currency symbols, emojis etc.), urls, digits and additional spaces
    #output is a txt file with additional _cl for "cleaned" in name
    #
    # The file.open line is universal for using the newest (last processed) file in directory
    def cleantext()
      Dir.foreach(@projectdir) do |filename|
        next if filename == '.' or filename == '..'
        puts "working on #{filename}"
        @filename = File.basename(filename, ".*")
        @text2process = File.open(Dir.glob(@projectdir+"/#{@filename}.*").max_by {|f| File.mtime(f)}, 'r')
        #@text2process = File.open(Dir.glob(@projectdir+'/*.*').max_by {|f| File.mtime(f)}, 'r')
        @text2process = File.read(@text2process, :encoding => 'iso-8859-1')
        @text2process.force_encoding("utf-8")
        @text2process = @text2process.gsub('\n','').gsub('\r','').gsub(/\\u[a-f0-9]{4}/i,'').gsub(/https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,}/,'').gsub(/\d/, '').gsub(/[^\w\s\.\'´`]/,'').gsub(/[\.]{2,}/,' ').gsub(/[ ]{2,}/,' ')
        File.write("#{@projectdir}/#{@filename}_cl.txt", @text2process)
        p @text2process

      end
    end


    #normalize text (from cleaned text file or raw text file) by choosing lowercasing and/or seperating contractions (both optional)
    #The 5 first lines of the methods open the last processed files (cleantext or just input) and normalize them
    # it's only important, if you process more than 1 file at a time, otherwise it would just normalize the most recent file or every file in the processdir
    def normalize(contractions=false, language='EN', low=false)
      Dir.glob(@projectdir+"/*.*").max_by(@filenumber) {|f| File.mtime(f)}.each do |file|
        @filename = File.basename(file, ".*")
        puts "working on #{@filename}"
        @file2process = file
        @text2process = File.open(@file2process)
        @text2process = File.read(@text2process, :encoding => 'iso-8859-1')
        @text2process.force_encoding("utf-8")
        @text2process = @text2process.gsub('.','').gsub(',','').gsub('!','').gsub('?','').gsub(':','').gsub(';','').gsub('(','').gsub(')','').gsub('[','').gsub(']','').gsub('"','').gsub('„','').gsub('»','').gsub('«','').gsub('›','').gsub('‹','').gsub('–','')
        puts @text2process
        lc=''
          cons=''
        if low == true
          lc ='l'
          @text2process = @text2process.downcase
        end
        if contractions == true
          cons = 'c'
          contractions(language)
        end
        File.write("#{@projectdir}/#{@filename}_n#{lc}#{cons}.txt",@text2process)
        p @text2process
      end
    end


    # ambigous contractions: the contraction dictionary will, when sth like "you'd" occure chose "you would" over "you had".
    def contractions(language)

      # Contractions of English language
      @contractions_en = {
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
      # Contractions of German language
      @contractions_de = {
        "ausm"=> "aus dem",
        "aus'm"=> "aus dem",
        "durchs"=> "durch das",
        "fürs"=> "für das",
        "unterm"=> "unter dem",
        "so'n"=> "so ein",
      }
      @text2process = @text2process.gsub('’','\'')
      if language == "EN"
        @contractions_en.each { |k, v| @text2process=@text2process.gsub k, v }
      else
        @contractions_de.each { |k, v| @text2process=@text2process.gsub k, v }
      end
    end

    def tokenizer()
      Dir.glob(@projectdir+"/*.*").max_by(@filenumber) {|f| File.mtime(f)}.each do |file|
        @filename = File.basename(file, ".*")
        puts "working on #{@filename}"
        @file2process = file
        @text2process = File.open(@file2process)
        @text2process = File.read(@text2process, :encoding => 'iso-8859-1')
        @text2process.force_encoding("utf-8")
        #input = File.open(Dir.glob(@projectdir+'/*.*').max_by {|f| File.mtime(f)}, 'r')
        #file = input.read
        #input.close

        # tokenization
        doc = @en.read(@text2process)
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
          #f.write("\n")
          #f.write("\n")
          #f.write("Total number of tokens: #{count}")
          puts ("Total number of tokens: #{count}")
        end
      end
    end

    def stopwordsclean()
      Dir.glob(@projectdir+"/*.*").max_by(@filenumber) {|f| File.mtime(f)}.each do |file|
        @filename = File.basename(file, ".*")
        puts "working on #{@filename}"
        @file2process = file
        @text2process = File.open(@file2process)
        @text2process = File.read(@text2process, :encoding => 'iso-8859-1')
        @text2process.force_encoding("utf-8")
        #.gsub(/Total number of tokens: \d+/, '')
        @text2process = Kernel.eval(@text2process)


        shared = @text2process & @stopwords
        textosw = @text2process - shared
        File.write("#{@projectdir}/#{@filename}_nost.txt", textosw)
      end
    end

    def add_stopwords(newsw)
      @stopwords.insert(0, newsw)
    end

    def lemmatizer()
      Dir.glob(@projectdir+"/*.*").max_by(@filenumber) {|f| File.mtime(f)}.each do |file|
        @filename = File.basename(file, ".*")
        puts "working on #{@filename}"
        @file2process = file
        @text2process = File.open(@file2process)
        @text2process = File.read(@text2process, :encoding => 'iso-8859-1')
        @text2process.force_encoding("utf-8")
        @text2process = Kernel.eval(@text2process)
        @text2process = @text2process.join(', ').gsub(',','')

        # lemmatization
        doc = @en.read(@text2process)
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
        File.write("#{@projectdir}/#{@filename}_lem.txt", output)
      end
    end


    def tagger()
      Dir.glob(@projectdir+"/*.*").reject{|file| file.end_with?("lem.txt")}.max_by(@filenumber){|f| File.mtime(f)}.each do |file|
        @filename = File.basename(file, ".*")
        puts "working on POS #{file}"
        @file2process = file
        @text2process = File.open(@file2process)
        @text2process = File.read(@text2process, :encoding => 'iso-8859-1')
        @text2process.force_encoding("utf-8")
        @text2process = Kernel.eval(@text2process)
        @text2process = @text2process.join(' ').gsub(',','')#.gsub(/Total number of tokens: \d+/, '')
        doc = @en.read(@text2process)
        #pos: The simple UPOS part-of-speech tag
        #tag: The detailed part-of-speech tag
        builder = Nokogiri::XML::Builder.new
        headings = [["text", "pos", "tag"]]
        @rows = []
        output = []

        doc.each do |token|
          @rows << [token.text, token.pos, token.tag]
          output.append(token.text + ": pos:" + token.pos + ", tag:" + token.tag)
        end
        p @rows

        #save to csv
        File.open("#{@projectdir}/#{@filename}_pos.csv", "w") do |f|
          f.write(headings.inject([]) { |csv, row| csv << CSV.generate_line(row) }.join(""))
          f.write(@rows.inject([]) { |csv, row| csv << CSV.generate_line(row) }.join(""))
        end
        #save to txt
        File.write("#{@projectdir}/#{@filename}_pos.txt", output)
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
        File.write("#{@projectdir}/#{@filename}_pos.xml", pos_xml)
      end
    end

    def ner()
      Dir.glob(@projectdir+"/*.*").reject{|file| file.end_with?("lem.txt") ||file.end_with?("pos.txt")||file.end_with?("pos.csv") ||file.end_with?("pos.xml")}.max_by(@filenumber){|f| File.mtime(f)}.each do |file|
        @filename = File.basename(file, ".*")
        puts "working on NER #{file}"
        @file2process = file
        @text2process = File.open(@file2process)
        @text2process = File.read(@text2process, :encoding => 'iso-8859-1')
        @text2process.force_encoding("utf-8")
        @text2process = @text2process
        @text2process = Kernel.eval(@text2process).join(' ')#.gsub(/Total number of tokens: \d+/, '')
        doc = @en.read(@text2process)
        builder = Nokogiri::XML::Builder.new
        #text = File.open(Dir.glob(@projectdir+'/*tok.*').max_by {|f| File.mtime(f)}, 'r')
        #text = File.read(text)#.gsub(/Total number of tokens: \d+/, '')
        #text = Kernel.eval(text).join(' ')

        headings = [['text', 'label']]
        @rows = []
        output = []

        doc.ents.each do |ent|
          @rows << [ent.text, ent.label]
          output.append(ent.text + ": label:" + ent.label)
        end

        #save to csv
        File.open("#{@projectdir}/#{@filename}_ner.csv", "w") do |f|
          f.write(headings.inject([]) { |csv, row| csv << CSV.generate_line(row) }.join(""))
          f.write(@rows.inject([]) { |csv, row| csv << CSV.generate_line(row) }.join(""))
        end
        #save to txt
        File.write("#{@projectdir}/#{@filename}_ner.txt", output)
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
        File.write("#{@projectdir}/#{@filename}_ner.xml", ner_xml)
      end
    end
  end
end

class CrumblerGUI
  include RubyCrumbler
  include Glimmer
  require 'ruby-progressbar'
  progress_bar = ProgressBar.create()
  def launch

    ### START of menu bar
    menu('Help') {
      menu_item('About'){
        on_clicked do
          window('About RubyCrumbler', 700, 500, has_menubar = false) {
            on_closing do
              window.destroy
              1
            end
            margined true
            vertical_box {
              area {
                text {
                  default_font family: 'Helvetica', size: 13, weight: :normal, italic: :normal, stretch: :normal
                  string { font family: 'Helvetica', size: 14, weight: :bold, italic: :normal, stretch: :normal; "RubyCrumbler Version 0.0.1\n\n" }
                  string("Developed by Laura Bernardy, Nora Dirlam, Jakob Engel, and Johanna Garthe.\nsome-email@address.com\nMarch 31, 2022\n\nThis project is open source on GitHub.")
                }
                # image(File.expand_path('img/github.png', __dir__), x: 0, y: 85, width: 45, height: 45)
              }
              button('Go to GitHub Repository') {
                stretchy true
                on_clicked do
                  system("open","https://github.com/joh-ga/RubyCrumbler")
                end
              }
            }
          }.show
        end
      }

      menu_item('Documentation'){
        on_clicked do
          window('Documentation', 400, 600, has_menubar = false) {
            on_closing do
              window.destroy
              1
            end
            margined true
            vertical_box {
              area {
                text {
                  default_font family: 'Helvetica', size: 12, weight: :normal, italic: :normal, stretch: :normal
                  string { font family: 'Helvetica', size: 13, weight: :bold, italic: :normal, stretch: :normal; "Description of Features\n\n"}
                  string("Please find below all the necessary information about the individual features.\n\n")
                  string{ font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal; underline :single; "Pre-Processing\n" }
                  string{ font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal; "Data cleaning: " }
                  string("This includes removing redundant whitespaces, punctuation (redundant dots), special symbols (e.g., line break, new line), hash tags, HTML tags, and URLs.\n")
                  string{ font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal; "Normalization: " }
                  string("This includes removing punctuation symbols (dot, colon, comma, semicolon, exclamation and question mark).\n")
                  string{ font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal; "Normalization (lowercase): " }
                  string("This includes removing punctuation symbols (dot, colon, comma, semicolon, exclamation and question mark) as well as converting the text into lowercase.\n")
                  string{ font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal; "Normalization (contractions): " }
                  string("This includes removing punctuation symbols (dot, colon, comma, semicolon, exclamation and question mark) as well as converting contractions (abbreviation for a sequence of words like “don’t”) into their original form (e.g., do not).\n\n")
                  string{ font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal; underline :single; "Natural Language Processings – Tasks \n" }
                  string{ font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal; "Tokenization: " }
                  string("This includes splitting the pre-processed data into individual characters or tokens.\n")
                  string{ font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal; "Stopword removal: " }
                  string("Stopwords are words that do not carry much meaning but are important grammatically as, for example, “to” or “but”. This feature includes the removal of stopwords.\n")
                  string{ font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal; "Stemming: " }
                  string("This includes the reduction of a word to its stem (a character sequence shared by related words) by clipping inflectional and partially derivational suffixes. A word’s stem therefore does not necessarily have to be a semantically meaningful word. Word stems and lemmatized base forms may overlap. Examples: computing - compute, sung - sung, obviously - obvious.\n")
                  string{ font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal; "Lemmatization: " }
                  string("This includes reduction of a word to its semantic base form according to POS classification. Lemmatized base forms and word stems may overlap. Examples: computing - compute, sung - sing, obviously - obviously.\n")
                  string{ font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal; "Part-of-Speech Tagging: " }
                  string("This includes identifying and labeling the parts of speech of text data.\n")
                  string{ font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal; "Named Entity Recognition: " }
                  string("This includes labeling the so-called named entities in the data such as persons, organizations, and places.\n\n\n")
                  string{ font family: 'Helvetica', size: 13, weight: :bold, italic: :normal, stretch: :normal; "Information about the File Naming Convention\n\n"}
                  string("To enable a quick identification and location of your converted document depending on the feature applied, the following file naming convention is used in RubyCrumbler.\nAbbreviations are added to the source file name to indicate the features that have been applied to the document. The suffix of the new file name indicates the ouput file for the corresponding feature. For example, the file named “myfirsttext_cl_nlc_tok.txt” is the output file of the tokenization step.\n\nAbbreviations of the features:\n • Data cleaning = cl\n • Normalization = n \n • Normalization (lowercase) = l\n • Normalization (contractions) = c\n • Tokenization = tok\n • Stopword Removal = sw\n • Stemming = stem\n • Lemmatization = lem\n • Part-of-Speech Tagging = pos\n • Named Entity Recognition = ner\n\nFor each feature step the output format is TXT. POS tagging and NER are additionally saved in CSV and XML output format.\n\n\n")
                  string{ font family: 'Helvetica', size: 13, weight: :bold, italic: :normal, stretch: :normal; "Notes\n\n" }

                  string("More information and the source code are available on GitHub.")
                }
              }
              button('Go to GitHub Repository') {
                stretchy false
                on_clicked do
                  system("open","https://github.com/joh-ga/RubyCrumbler")
                end
              }
            }
          }.show
        end
      }
    }
    @count=0
    @fincount = 0

    ### START of main window
    window('RubyCrumbler', 300, 800) {

      margined(true)
      #fullscreen(true)

      vertical_box {
        horizontal_box {
          stretchy false

          vertical_box {

            group('Language of Text Input') {
              stretchy false
              vertical_box {
                label("Please specify the language in which your input text data is written.\n" \
                "Note: This information is mandatory to run the program.\n") { stretchy false }

                combobox {
                  stretchy false
                  items 'English', 'German'
                  selected 'English' #default

                  on_selected do |c|
                    @lang = if c.selected_item == 'English'
                              'EN' #English
                            else
                              'DE' #German
                            end
                  end
                }
                label
              }
            }

            group('Upload Center') {
              stretchy false

              vertical_box {
                label("Choose a file(s) or a directory, or specify a URL whose text content should be used to upload.\n" \
                "Note: Total file size may not exceed 50MB. File type must be TXT.\n") { stretchy false }
                button("Upload from file(s)") {
                  stretchy false

                  on_clicked do
                    file = open_file
                    if file == nil
                      msg_box('ERROR: No File selected.')
                    else
                      @input = file
                      @projectname = File.basename(@input, ".*")
                      @doc = PipelineFeatures.new
                      puts @input unless file.nil?
                      @doc.newproject(@input, @projectname)
                      msg_box('Notification', 'Upload successfully completed.')
                    end
                  end
                }

                button("Upload file(s) from directory") {
                  stretchy false

                  on_clicked do
                    dir = Tk.chooseDirectory
                    @input = dir
                    @projectname = File.basename(@input, ".*")
                    @projectname = "#{@projectname}_process"
                    if @projectname == "_process"
                      msg_box('ERROR: No Folder selected.')
                    else
                      @doc = PipelineFeatures.new
                      @doc.newproject(@input, @projectname)
                      msg_box('Notification', 'Upload successfully completed.')
                    end
                  end
                }

                label("\nEnter URL:") { stretchy false }
                @entry = entry {
                  stretchy false
                  on_changed do
                    @url = @entry.text
                  end
                }
                @button = button('Upload text from website'){
                  stretchy false

                  on_clicked do
                    @input = @url
                    if @input == nil
                      msg_box('ERROR: No URL selected.')
                    else
                      @projectname = File.basename(@input, ".*")
                      @doc = PipelineFeatures.new
                      puts @input unless @input.nil?
                      @doc.newproject(@input, @projectname)
                      msg_box('Notification', 'Upload successfully completed.')
                    end
                  end
                  }
                }
              }
            }

          vertical_box{
            group('Pre-Processing') {
              stretchy false

              # Den checkboxen muss man wohl individuelle Namen geben, damit man
              # die einzelnen methods aufrufen kann
              vertical_box {

                label("Select all or respective features.\n" \
                "Note: See the documentation for more information about each feature.") { stretchy false}

                @clcb = checkbox('Data cleaning') {
                  stretchy false

                  on_toggled do |c|
                    @clcbchecked = @clcb.checked?
                    if @clcb.checked == true
                      @count +=1
                    end
                  end
                }
                # muss noch die nur norm funktion eingetragen werden
                @norm = checkbox('Normalization') {
                  stretchy false

                  on_toggled do |c|
                    @normchecked = @norm.checked?
                    if @norm.checked == true
                      @count +=1
                    end
                  end
                }

                @normlow = checkbox('Normalization (lowercase)') {
                  stretchy false

                  on_toggled do |c|
                    @normlowchecked = @normlow.checked?
                    if @normlow.checked == true
                      @count +=1
                    end
                  end
                }

                @normcont = checkbox('Normalization (contractions)') {
                  stretchy false

                  on_toggled do |c|
                    @normcontchecked = @normcont.checked?
                    if @normcont.checked == true
                      @count +=1
                    end
                  end
                }
              }
            }

            group('Natural Language Processing – Tasks') {
              stretchy false

              vertical_box {
                label("Select all or respective features.\n" \
                "Note: See the documentation for more information about each feature.") { stretchy false}

                @tok = checkbox('Tokenization') {
                  stretchy false

                  on_toggled do |c|
                    @tokchecked = @tok.checked?
                    if @tok.checked? == true
                      @count +=1
                    end
                  end
                }

                @sr = checkbox('Stopword removal') {
                  stretchy false

                  on_toggled do |c|
                    @srchecked = @sr.checked?
                    if @sr.checked == true
                      @count +=1
                    end
                  end
                }

                @stem = checkbox('Stemming') {
                  stretchy false

                  on_toggled do |c|
                    @stemchecked = @stem.checked?
                    if @stem.checked == true
                      @count +=1
                    end
                  end
                }

                @lem = checkbox('Lemmatization') {
                  stretchy false

                  on_toggled do |c|
                    @lemchecked = @lem.checked?
                    if @lem.checked == true
                      @count +=1
                    end
                  end
                }

                @pos = checkbox('Part-of-Speech Tagging') {
                  stretchy false

                  on_toggled do |c|
                    @poschecked = @pos.checked?
                    if @pos.checked == true
                      @count +=1
                    end
                  end
                }

                @ner = checkbox('Named Entity Recognition') {
                  stretchy false

                  on_toggled do |c|
                    @nerchecked = @ner.checked?
                    if @ner.checked == true
                      @count +=1
                    end
                  end
                }
              }
            }
          }
        }

        horizontal_separator { stretchy false }

        horizontal_box {
          stretchy false
          group() {
            #stretchy false

            vertical_box {
              button('Run') {
                stretchy false

                #hier geht die action ab
                # if entsprechende checkbox
                # dann @doc und passende methode aufrufen

                on_clicked do
                  #pre-processing
                  if @clcbchecked == true
                    @doc.cleantext()
                    @fincount += 1
                    @progressbar.value = (@fincount*100/@count)
                    if @progressbar.value == 100
                      @label.text = "Text processing finished!"
                    end
                  end

                  if @normchecked == true && !@normlowchecked && !@normcontchecked
                    @doc.normalize(false, @lang, false)
                    @fincount += 1
                    @progressbar.value = (@fincount*100/@count)
                    if @progressbar.value == 100
                      @label.text = "Text processing finished!"
                    end
                  end
                  if (@normchecked == true && @normlowchecked == true && !@normcontchecked) || (@normchecked == true && @normcontchecked == true && !@normlowchecked)
                    @doc.normalize(@normcontchecked, @lang, @normlowchecked)
                    @fincount += 2
                    @progressbar.value = (@fincount*100/@count)
                    if @progressbar.value == 100
                      @label.text = "Text processing finished!"
                    end
                  end
                  if @normchecked == true && @normlowchecked == true && @normcontchecked == true
                    @doc.normalize(@normcontchecked, @lang, @normlowchecked)
                    @fincount += 3
                    @progressbar.value = (@fincount*100/@count)
                    if @progressbar.value == 100
                      @label.text = "Text processing finished!"
                    end
                  end
                  if !@normchecked && @normlowchecked == true && @normcontchecked == true
                    @norm.checked = true
                    @doc.normalize(@normcontchecked, @lang, @normlowchecked)
                    @count += 1
                    @fincount += 3
                    @progressbar.value = (@fincount*100/@count)
                    if @progressbar.value == 100
                      @label.text = "Text processing finished!"
                    end
                  end
                  if (!@normchecked && @normlowchecked == true && !@normcontchecked) || (!@normchecked && !@normlowchecked && @normcontchecked == true)
                    @norm.checked = true
                    @doc.normalize(@normcontchecked, @lang, @normlowchecked)
                    @count += 1
                    @fincount += 2
                    @progressbar.value = (@fincount*100/@count)
                    if @progressbar.value == 100
                      @label.text = "Text processing finished!"
                    end
                  end

                  #nlp-pipeline
                  if @tokchecked == true
                    @doc.tokenizer()
                    @fincount += 1
                    @progressbar.value = (@fincount*100/@count)
                    if @progressbar.value == 100
                      @label.text = "Text processing finished!"
                    end
                  end

                  @autotokchecked = false #variable for automatically checking tokenization
                  if @srchecked == true
                    if !@tokchecked && !@autotokchecked
                      @autotokchecked = (@tok.checked = true)
                      @doc.tokenizer()
                      @count += 1
                      @fincount += 1
                    end
                    @doc.stopwordsclean()
                    @fincount += 1
                    @progressbar.value = (@fincount*100/@count)
                    if @progressbar.value == 100
                      @label.text = "Text processing finished!"
                    end
                  end

                  #if @stemchecked == true
                  #  @doc.()
                  #  @processbar.value += 2520/@count
                  #                if @progressbar.value == 2520
                  #                   @label.text = "Text processing finished!"
                  #                 end
                  #end
                  #
                  if @lemchecked == true
                    if !@tokchecked && !@autotokchecked
                      @autotokchecked = (@tok.checked = true)
                      @doc.tokenizer()
                      @count += 1
                      @fincount += 1
                    end
                    @doc.lemmatizer()
                    @fincount += 1
                    @progressbar.value = (@fincount*100/@count)
                    if @progressbar.value == 100
                      @label.text = "Text processing finished!"
                    end
                  end

                  if @poschecked == true
                    if !@tokchecked && !@autotokchecked
                      @autotokchecked = (@tok.checked = true)
                      @doc.tokenizer()
                      @count += 1
                      @fincount += 1
                    end
                    @doc.tagger()
                    @fincount += 1
                    @progressbar.value = (@fincount*100/@count)
                    if @progressbar.value == 100
                      @label.text = "Text processing finished!"
                    end
                  end

                  if @nerchecked == true
                    if !@tokchecked && !@autotokchecked
                      @autotokchecked = (@tok.checked = true)
                      @doc.tokenizer()
                      @count += 1
                      @fincount += 1
                    end
                    @doc.ner()
                    @fincount += 1
                    @progressbar.value = (@fincount*100/@count)
                    if @progressbar.value == 100
                      @label.text = "Text processing finished!"
                    end
                  end
                end
              }
              # button('Cancel') {
              #   stretchy false
              #
              #   on_clicked do
              #     msg_box('Information', 'You clicked the button')
              #   end
              # }

              label('Status – Progress bar') { stretchy false }
              @progressbar = progress_bar {
                stretchy false

              }
              @label = label("") {
                stretchy false
              }

              button('New Project') {
                stretchy false

                on_clicked do
                  window.destroy
                  Kernel.exec("ruby rubycrumbler_macOS_EN-DE.rb")
                end
              }
            }
          }
        }
      }
    }.show
  end
end

CrumblerGUI.new.launch
