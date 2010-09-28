require 'escape_xml'

## HashTags
module HashTags

  ## Excluded words
  excluded_words = %w[
I
a
all
also
and
are
aren
be
been
bst
but
call
calls
can
did
didn
do
don
does
doesn
even
few
for
from
get
got
has
hasn
have
her
here
his
how
in
is
isn
it
its
it's
just
less
made
make
makes
many
me
mine
more
much
my
no
not
of
oh
on
out
really
says
some
such
that
the
their
there
these
they
this
those
to
too
utc
via
was
wasn
we
what
when
where
which
who
why
will
with
you
your
yours
]

  RX_IGNORE = /^(@|http|\b#{excluded_words.join("\\b|\\b")}\b)|^(\d+)$/io

  ## normalize_word(word)
  def normalize_word(word)
    # word.gsub(/[:punct:]$/, '')
    if word =~ /(^@)|(\.\.\.$)/
      nil
    else
      word = word.gsub(/(^\W+)|(\W+$)|('s$)/, '').strip.downcase
      if word.empty?
        word = nil
      end
      word
    end
  end

  def words_from_text(hash, text)
    tokens = EscapeXML.unescape(text).split(/[\s+]+/)
    tokens.each do |word|
      # don't include hash tags here
      next if word =~ /^#[\w]+/
      if word = normalize_word(word)
        if word.size > 2 && !word.match(RX_IGNORE)
          hash[word] += 1
        end
      end
    end
    hash
  end

  ## collate_words_for_link(link)
  def collate_words_for_link(link)
    h = Hash.new{|h,k| h[k] = 0}
    result = link.
      tweets.inject(h) {|hash, tweet|
      words_from_text(hash, tweet.text)
    }
  end

  ## collate_hashtags_for_link(link)
  def collate_hashtags_for_link(link)
    h = Hash.new{|h,k| h[k] = 0}
    result = link.
      tweets.inject(h) {|hash, tweet|
      tokens = tweet.text.scan(/(#[\w]+)/)
      tokens.each do |word|
        hash[word] += 1
      end
      hash
    }
  end

  ## sort_result(result)
  def sort_result(result, threshold = 4)
    result.
      reject{|key, value|
      value < threshold
    }.sort_by{|key, value| value}
  end

  ## words_for_link(link, threshold)
  def words_for_link(link, threshold = 4)
    sort_result(collate_words_for_link(link), threshold).reverse
  end

  ## hashtags_for_link(link, threshold)
  def hashtags_for_link(link, threshold = 1)
    sort_result(collate_hashtags_for_link(link), threshold).reverse
  end

  extend self
end
