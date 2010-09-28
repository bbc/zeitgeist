$:.unshift(File.expand_path(File.dirname(__FILE__)))
Dir["vendor/gems/*/lib"].each do |lib|
  $:.unshift(File.expand_path(lib))
end
