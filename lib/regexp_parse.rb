module RegexpParse
  extend self

  # OR together list of words into one Regexp
  def words_to_regex(*words)
    # p [:words_to_regex, words]
    Regexp.union(*words.flatten.map{ |w| word_to_regex(w)})
  end

  REGEXP_OPTIONS = {
    "m" => Regexp::MULTILINE,
    "i" => Regexp::IGNORECASE,
    "x" => Regexp::EXTENDED,
  }

  # convert a word or regular expression in string to Regexp
  def word_to_regex(word)
    # p [:word_to_regex, word]
    # allow literal regular expressions of form /.../
    if word =~ %r{/(.*)/([mixensu]*)}
      # save results before doing any more matching
      body = $1
      flags = $2.split(//).compact
      options = flags & REGEXP_OPTIONS.keys
      lang = (flags & ["n", "e", "s", "u"]).first
      options = options.inject(0){ |acc, opt|
        acc | (REGEXP_OPTIONS[opt] || 0)
      }
      word = Regexp.new(body, options, lang)
    else
      # \b = word boundary
      # i = ignore case
      # m = match across line boundaries
      # u = unicode
      /\b(#{Regexp.quote(word)})\b/miu
    end
  end
end

