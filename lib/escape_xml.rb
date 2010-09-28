## EscapeXML
module EscapeXML
  ESCAPE = { '"' => '&quot;', '>' => '&gt;', '<' => '&lt;', "'" => "&apos;", '&' => '&amp;' }

  ## escape(s)
  def escape(s)
    s.to_s.gsub(/["><&]/) { |special| ESCAPE[special] }
  end

  def normalize(s)
    escape(unescape(s))
  end

  ## unescape(s)
  def unescape(s)
    s = s.to_s.
      # hex entities
      gsub(/\&#x[\dA-F]+?;/i) { |str| str[3..-1].to_i(16).chr }.
      # decimal entities
      gsub(/\&#[\d]+?;/i) { |str| str[3..-1].to_i(10).chr }

    ESCAPE.inject(s) do |str, (k, v)|
      # don't use gsub! here - don't want to modify argument
      str.gsub(v, k)
    end
  end

  # encode_attributes(attributes = {})
  def encode_attributes(attributes = { })
    # FIXME: not checking that key is valid identifier
    if attributes.size > 0
      " " + attributes.map{ |key, value| %[#{key}="#{escape(value)}"] }.sort.join(" ")
    else
      ""
    end
  end

  extend self
end

