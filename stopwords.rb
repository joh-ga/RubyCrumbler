require 'ruby-spacy'
class NoStops
  def initialize
    en = Spacy::Language.new("en_core_web_lg")
    stopwords = en.Defaults.stop_words.to_s.gsub('\'','"').delete('{}" ').gsub('’','\'')
    @stopwords = stopwords.split(',')
  end

  def stopwordsclean()
    text = File.open("tokenization.txt", "r")
    text = File.read(text).gsub(/Total number of tokens: \d+/, '')
    text = Kernel.eval(text)

    shared = text & @stopwords
    textosw = text - shared
    File.write("NoStopwords.txt", textosw)
  end

  def add_stopwords(newsw)
    @stopwords.insert(0, newsw)
  end

end


neu = NoStops.new
neu.stopwordsclean