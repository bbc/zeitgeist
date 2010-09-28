require File.dirname(__FILE__) + '/spec_helper.rb'
require 'doodle/json'

def compare_json(data, json)
  JSON.parse(data.to_json, :create_additions => false).should_be JSON.parse(json, :create_additions => false)
end

describe Doodle, 'JSON serialization within a module' do
  temporary_constants :Container, :Base, :Slideshow, :Layout do
    before(:each) do
      @json_source = <<EOT
{
  "json_class":"Container::Slideshow",
  "data":{
    "name":"test",
    "layout":{
     "json_class":"Container::Layout",
     "data":{
       "template":"generic"
     }
    },
    "id":1
  }
}
EOT
      @json_data = JSON.parse(@json_source, :create_additions => false)

      module ::Container
        class Base < Doodle
          include Doodle::JSON
        end
        class Layout < Base
          has :template
        end
        class Slideshow < Base
          has :id, :kind => Integer
          has :name, :kind => String
          has Layout
        end
      end
    end
    it 'should serialize to json' do
      slideshow = Container::Slideshow.new do
        id 1
        name "test"
        layout "generic"
      end
      compare_json(slideshow, @json_source)
    end
    it 'should serialize from json' do
      slideshow = Container::Slideshow.new do
        id 1
        name "test"
        layout "generic"
      end
      ss2 = Doodle.from_json(@json_source)
      ss2.should_be slideshow
    end
  end
end

describe Doodle, 'JSON serialization at top level' do
  temporary_constants :Base, :Slideshow, :Layout do
    before(:each) do
      @json_source = <<EOT
{
  "json_class":"Slideshow",
  "data":{
    "name":"test",
    "layout":{
     "json_class":"Layout",
     "data":{
       "template":"generic"
     }
    },
    "id":1
  }
}
EOT
      class ::Base < Doodle
        include Doodle::JSON
      end
      class ::Layout < Base
        has :template
      end
      class ::Slideshow < Base
        has :id, :kind => Integer
        has :name, :kind => String
        has Layout
      end
    end
    it 'should serialize to json' do
      slideshow = ::Slideshow.new do
        id 1
        name "test"
        layout "generic"
      end
      compare_json(slideshow,  @json_source)
    end
    it 'should serialize from json' do
      slideshow = ::Slideshow.new do
        id 1
        name "test"
        layout "generic"
      end
      ss2 = Doodle.from_json(@json_source)
      ss2.should_be slideshow
    end
  end
end

describe Doodle, 'JSON' do
  temporary_constant :Address do
    before :each do
      class ::Address < Doodle
        include Doodle::JSON
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

    it 'should output non-doodle attributes as JSON attributes' do
      a = Address do
        city "London"
      end
      compare_json(a, <<EOT)
{
  "json_class":"Address",
  "data":{
    "city":"London"
  }
}
EOT
    end
  end
end

describe Doodle, 'JSON' do
  temporary_constant :Base, :City, :Address do
    before :each do
      class ::Base < Doodle
        include Doodle::JSON
      end
      class ::City < Base
        has :_text_
        has :country, :default => "UK"
      end
      class ::Address < Base
        has :where, :default => "home"
        has City
      end
    end

    it 'should output required tags in JSON' do
      a = Address do
        city "London"
      end
      compare_json(a, <<EOT)
{
  "json_class":"Address",
  "data":{
    "city":{
    "json_class":"City",
    "data":{"_text_":"London"}
    }
  }
}
EOT
    end

    it 'should output specified optional attributes as json attributes if kind not a doodle class' do
      a = Address :where => 'home' do
        city "London"
      end
      compare_json(a, <<EOT)
{
  "json_class":"Address",
  "data":{
    "city":{
    "json_class":"City",
    "data":{"_text_":"London"}
    },
    "where":"home"
  }
}
EOT
    end

    it 'should output specified optional attributes' do
      a = Address :where => 'home' do
        city "London", :country => "England" do
          country "UK"
        end
      end
      compare_json(a, <<EOT)
{
  "json_class":"Address",
  "data":{
    "city":{"json_class":"City", "data":{"_text_":"London", "country":"UK"}},
    "where":"home"
  }
}
EOT
    end

  end

end

