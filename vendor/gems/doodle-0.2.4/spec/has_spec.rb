require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'has Class' do
  temporary_constant :Foo, :Bar, :AudioClip do
    it "should convert 'has \"foo\"' into 'has :foo" do
      class Bar < Doodle
        has "foo"
      end
      Bar.doodle.attributes.keys.include?(:foo).should_be true
    end
    it "should convert 'has Bar' into 'has :bar, :kind => Bar'" do
      class Bar
      end
      class Foo < Doodle
        has Bar
      end
      att = Foo.doodle.attributes.values.first
      att.name.should_be :bar
      att.kind.should_be [Bar]
    end
    it "should allow overriding name of attribute when using 'has Bar'" do
      class Bar
      end
      class Foo < Doodle
        has Bar, :name => :baz
      end
      att = Foo.doodle.attributes.values.first
      att.name.should_be :baz
      att.kind.should_be [Bar]
    end
    it "should convert class name to snakecase when using CamelCase class constant" do
      class AudioClip
      end
      class Foo < Doodle
        has AudioClip
      end
      att = Foo.doodle.attributes.values.first
      att.name.should_be :audio_clip
      att.kind.should_be [AudioClip]
    end
    it "should apply validations for 'has Bar' as if 'has :bar, :kind => Bar' was used" do
      class Bar
      end
      class Foo < Doodle
        has Bar
      end
      proc {  Foo.new(:bar => Bar.new) }.should_not raise_error
      proc {  Foo.new(:bar => "Hello") }.should raise_error(Doodle::ValidationError)
    end
    it "should apply validations for 'has Bar' as if 'has :bar, :kind => Bar' was used" do
      class Bar
      end
      class Foo < Doodle
        has Bar
      end
      proc {  Foo.new(:bar => Bar.new) }.should_not raise_error
      proc {  Foo.new(:bar => "Hello") }.should raise_error(Doodle::ValidationError)
    end
    it "should apply validations for 'has Bar' as if 'has :bar, :kind => Bar' was used" do
      class Bar
      end
      class Foo < Doodle
        has Bar
      end
      proc {  Foo.new(:bar => Bar.new) }.should_not raise_error
      proc {  Foo.new(:bar => "Hello") }.should raise_error(Doodle::ValidationError)
    end
  end
end
