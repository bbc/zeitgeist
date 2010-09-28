require 'doodle/app'

class Filter < Doodle::App
  filename :input, :existing => true,
    :doc => "name of existing input file"
  filename :output, :doc => "name of output file"
  std_flags # help, verbose, debug

  def run
    puts "input: #{input} => output: #{output}"
  end
end

if  __FILE__ == $0
  Filter.run(ARGV)
end
