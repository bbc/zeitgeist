require File.dirname(__FILE__) + '/spec_helper.rb'
require 'doodle/xml'

describe Doodle, 'XML' do
  temporary_constant :Base, :City, :Address, :Country do
    before :each do

      @country_example = %[<Address geo:where="home"><geo:City>London<Country>UK</Country></geo:City></Address>]

      class ::Base < Doodle
        include Doodle::XML
      end
      class ::Country < Base
        has :_text_
      end
      class ::City < Base
        has :_text_
        has Country, :default => "UK"
      end
      class ::Address < Base
        has :where, :default => "home", :namespace => "geo"
        has City, :namespace => "geo"
      end
    end

    it 'should output attributes with namespaces' do
      a = Address :where => 'home' do
        city "London", :country => "England" do
          country "UK"
        end
      end
      a.to_xml.should_be @country_example
    end
  end
end
