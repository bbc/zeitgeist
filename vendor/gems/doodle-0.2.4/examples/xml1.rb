# RUBYLIB=lib xmpfilter
#: requires
require 'doodle'
require 'doodle/xml'

#: source
xml_source = %[<Address where="home"><City>London<Country>UK</Country></City></Address>]

#: include
class Base < Doodle
  include Doodle::XML
end

#: definition
class Country < Base
  has :_text_
end
class City < Base
  has :_text_
  has Country, :default => "UK"
end
class Address < Base
  has :where, :default => "home"
  has City
end

#: use
a = Address :where => 'home' do
  city "London", :country => "England" do
    country "UK"
  end
end

#: output
a                               # => #<Address:0x114c534 @city=#<City:0x1148830 @country=#<Country:0x113fa00 @_text_="UK">, @_text_="London">, @where="home">
a.to_xml == xml_source          # => true
#: load
b = Doodle::XML.from_xml(Base, xml_source)
b                               # => #<Address:0x113152c @city=#<City:0x112e304 @country=#<Country:0x112b8e8 @_text_="UK">, @_text_="London">, @where="home">
#: equality
b == a                          # => true
