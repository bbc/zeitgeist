# Robert Klemme, (ruby-talk 205150), (ruby-talk 205950)

module Kernel
private
  def calling_method(level = 1)
    caller[level] =~ /`([^']*)'/ and $1
  end
  
  def this_method
    calling_method
  end

end

if __FILE__ == $0
  def hello
    p this_method
    p calling_method
  end
  def greet
    hello
  end
  puts "hello:"
  hello
  puts "greet:"
  greet
end
  

