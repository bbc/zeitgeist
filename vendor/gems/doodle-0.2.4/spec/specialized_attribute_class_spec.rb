require File.dirname(__FILE__) + '/spec_helper.rb'

require 'doodle/datatypes'

describe 'Doodle', 'specialized attributes' do
  temporary_constant :Foo, :SpecializedAttribute do
    before :each do
      class SpecializedAttribute < Doodle::DoodleAttribute
      end

      class Foo < Doodle
      end
    end

    it 'should allow :using keyword' do
      proc {
        Foo.class_eval do
          has :ivar1, :kind => String, :using => SpecializedAttribute
        end
      }.should_not raise_error
    end

    it 'should interpret :using keyword and return a specialized attribute of correct class' do
      class Foo < Doodle
        rv = has(:ivar1, :kind => String, :using => SpecializedAttribute)
        rv.class.should_be SpecializedAttribute
      end
    end

    it 'should allow additional attributes belonging to specialized attribute of correct class' do
      class SpecializedAttribute
        has :flag, :kind => String
      end
      class Foo < Doodle
        rv = has(:ivar1, :kind => String, :using => SpecializedAttribute, :flag => "sflag")
        rv.class.should_be SpecializedAttribute
        rv.flag.should_be 'sflag'
      end
    end

    it 'should allow additional directives invoking specialized attribute of correct class' do
      class SpecializedAttribute
        has :flag, :kind => String
      end
      class Foo < Doodle
        class << self
          def option(*args, &block)
            # this is how to add extra options onto args array for has
            # - all hashes get merged into one
            args << { :using => SpecializedAttribute }
            has(*args, &block)
          end
        end
        rv = option(:ivar1, :kind => String, :flag => "sflag")
        rv.class.should_be SpecializedAttribute
        rv.flag.should_be 'sflag'
      end
      Foo.doodle.attributes[:ivar1].flag.should_be "sflag"
      foo = Foo.new('hi')
      foo.doodle.attributes[:ivar1].flag.should_be "sflag"
    end

    it 'should allow using datatypes in additional directives invoking specialized attribute of correct class' do
      class SpecializedAttribute
        doodle do
          string :flag, :max => 1
        end
      end
      class Foo < Doodle
        class << self
          def option(*args, &block)
            # this is how to add extra options onto args array for has
            # - all hashes get merged into one
            args << { :using => SpecializedAttribute }
            has(*args, &block)
          end
        end
        rv = option(:ivar1, :kind => String, :flag => "x")
        rv.class.should_be SpecializedAttribute
        rv.flag.should_be 'x'
      end
      Foo.doodle.attributes[:ivar1].flag.should_be "x"
      foo = Foo.new('hi')
      foo.doodle.attributes[:ivar1].flag.should_be "x"
    end

    it 'should allow using datatypes in additional directives invoking specialized attribute of correct class and raise error if incorrect value supplied' do
      class SpecializedAttribute
        doodle do
          string :flag, :max => 1
        end
      end
      class Foo < Doodle
        class << self
          def option(*args, &block)
            args << { :using => SpecializedAttribute }
            has(*args, &block)
          end
        end
      end
      proc { Foo.class_eval { option(:ivar1, :kind => String, :flag => "ab") }}.should raise_error(Doodle::ValidationError)
    end

    it 'should allow specifying name as named parameter' do
      class Foo < Doodle
        has :name => :ivar
      end
    end
  end
end

