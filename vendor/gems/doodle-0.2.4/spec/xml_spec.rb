require File.dirname(__FILE__) + '/spec_helper.rb'
require 'doodle/xml'

describe Doodle, 'XML serialization within a module' do
  temporary_constants :Container, :Base, :Slideshow, :Layout do
    before(:each) do
      @xml_source = '<Slideshow id="1" name="test"><Layout template="generic" /></Slideshow>'
      module ::Container
        class Base < Doodle
          include Doodle::XML
        end
        class Layout < Base
          has :template
        end
        class Slideshow < Base
          has :id, :kind => Integer do
            from String do |s|
              s.to_i
            end
          end
          has :name, :kind => String
          has Layout
        end
      end
    end
    it 'should serialize to xml' do
      slideshow = Container::Slideshow.new do
        id 1
        name "test"
        layout "generic"
      end
      slideshow.to_xml.should_be @xml_source
    end
    it 'should serialize from xml' do
      slideshow = Container::Slideshow.new do
        id 1
        name "test"
        layout "generic"
      end
      ss2 = Doodle::XML.from_xml(Container, @xml_source)
      ss2.should_be slideshow
    end
  end
end

describe Doodle, 'XML serialization at top level' do
  temporary_constants :Base, :Slideshow, :Layout do
    before(:each) do
      @xml_source = '<Slideshow id="1" name="test"><Layout template="generic" /></Slideshow>'
      class ::Base < Doodle
        include Doodle::XML
      end
      class ::Layout < Base
        has :template
      end
      class ::Slideshow < Base
        has :id, :kind => Integer do
          from String do |s|
            s.to_i
          end
        end
        has :name, :kind => String
        has Layout
      end
    end
    it 'should serialize to xml' do
      slideshow = ::Slideshow.new do
        id 1
        name "test"
        layout "generic"
      end
      slideshow.to_xml.should_be @xml_source
    end
    it 'should serialize from xml' do
      slideshow = ::Slideshow.new do
        id 1
        name "test"
        layout "generic"
      end
      ss2 = Doodle::XML.from_xml(Object, @xml_source)
      ss2.should_be slideshow
    end
  end
end

describe Doodle, 'XML' do
  temporary_constant :Address do
    before :each do
      class Address < Doodle
        include Doodle::XML
        has :where, :default => "home"
        has :city
      end
    end

    it 'should not raise an error when supplying attribute values' do
      proc {
        Address do
          city "London"
        end
      }.should_not raise_error
    end

    it 'should accept attributes defined in block' do
      a = Address do
        city "London"
      end
      a.city.should_be "London"
    end

    it 'should output non-doodle attributes as XML attributes' do
      a = Address do
        city "London"
      end
      a.to_xml.should_be '<Address city="London" />'
    end
  end
end

describe Doodle, 'XML' do
  temporary_constant :Base, :City, :Address do
    before :each do
      class Base < Doodle
        include Doodle::XML
      end
      class City < Base
        has :_text_
        has :country, :default => "UK"
      end
      class Address < Base
        has :where, :default => "home"
        has City
      end
    end

    it 'should output required tags in XML' do
      a = Address do
        city "London"
      end
      a.to_xml.should_be '<Address><City>London</City></Address>'
    end

    it 'should output specified optional attributes as xml attributes if kind not a doodle class' do
      a = Address :where => 'home' do
        city "London"
      end
      a.to_xml.should_be %[<Address where="home"><City>London</City></Address>]
    end

    it 'should output specified optional attributes' do
      a = Address :where => 'home' do
        city "London", :country => "England" do
          country "UK"
        end
      end
      a.to_xml.should_be %[<Address where="home"><City country="UK">London</City></Address>]
    end

  end

end

describe Doodle, 'XML' do
  temporary_constant :Base, :City, :Address, :Country do
    before :each do

      @country_example = %[<Address where="home"><City>London<Country>UK</Country></City></Address>]

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
        has :where, :default => "home"
        has City
      end
    end

    it 'should output required tags in XML' do
      a = Address do
        city "London"
      end
      a.to_xml.should_be '<Address><City>London</City></Address>'
    end

    it 'should output specified optional attributes' do
      a = Address :where => 'home' do
        city "London"
      end
      a.to_xml.should_be %[<Address where="home"><City>London</City></Address>]
    end

    it 'should output specified optional attributes as tags if kind is a Doodle class' do
      a = Address :where => 'home' do
        city "London", :country => "England" do
          country "UK"
        end
      end
      a.to_xml.should_be @country_example
    end

    it 'should reconstruct object graph from xml source' do
      a = Address :where => 'home' do
        city "London", :country => "England" do
          country "UK"
        end
      end
      a.to_xml.should_be @country_example
      b = Doodle::XML.from_xml(Base, a.to_xml)
      b.should_be a
    end
  end
end
