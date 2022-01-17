require 'ruby-spacy'
class NoStops
  def initialize
    en = Spacy::Language.new("en_core_web_lg")
    stopwords = en.Defaults.stop_words.to_s.gsub('\'','"').delete('{}" ').gsub('’','\'')
    @stopwords = stopwords.split(',')
    print @stopwords
  end

  def stopwordsclean()
    text = File.open("tokenization.txt", "r")
    text = File.read(text).downcase.delete('[]" ')
    text = text.split(',')

    shared = text & @stopwords
    textosw = text - shared
    File.write("NoStopwords.txt", textosw.join(', '))
  end

  def add_stopwords(newsw)
    @stopwords.insert(0, newsw)
  end

end


neu = NoStops.new
neu.add_stopwords("")
neu.stopwordsclean