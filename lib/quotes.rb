## Quotes
module Quotes
  extend self

  ## escape_single_quotes(txt)
  def escape_single_quotes(txt)
    txt.gsub(/'/, "\\\\'")
  end

  ## escape_double_quotes(txt)
  def escape_double_quotes(txt)
    txt.gsub(/"/, '\"')
  end

  ## q(txt) - single quote a string
  def q(txt)
    "'#{escape_single_quotes(txt)}'"
  end

  ## qq(txt) - double quote a string
  def qq(txt)
    '"' + escape_double_quotes(txt) + '"'
  end
end

