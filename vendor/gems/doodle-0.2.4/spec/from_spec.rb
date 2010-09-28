require File.dirname(__FILE__) + '/spec_helper.rb'

describe 'Doodle', 'from' do
  temporary_constant :Foo, :Name do
    before :each do
      class Name < String
        include Doodle::Core
        # this is fiddly - needed to avoid infinite regress from trying to do Name.new
        from String do |s|
          n = self.allocate
          n.replace(s)
          n.doodle.update
        end
        must "be > 3 chars long" do
          size > 3
        end
      end

      class Foo < Doodle
        has Name do
          must "start with A" do |s|
            s =~ /^A/
          end
        end
      end
    end

    it 'should convert a value based on conversions in doodle class' do
      proc { foo = Foo 'Arthur' }.should_not raise_error
    end

    it 'should convert a value based on conversions in doodle class to the correct class' do
      foo = Foo 'Arthur'
      foo.name.class.should_be Name
    end

    it 'should apply validations from attribute' do
      proc { Foo 'Zaphod' }.should raise_error(Doodle::ValidationError)
    end

    it 'should apply validations from doodle type' do
      proc { Foo 'Art' }.should raise_error(Doodle::ConversionError)
    end

  end
end

describe 'Doodle', 'from' do
  temporary_constant :Answer do
    before :each do
    end

    it 'should allow specifying from in #has params' do
      class Answer < Doodle
        has :value, :from => { Integer => proc {|i| i.to_s }}
      end
      name = Answer.new(42)
      name.value.should_be "42"
    end

    it 'should allow specifying from in #has params with :kind specified' do
      class Answer < Doodle
        has :value, :kind => String, :from => { Integer => proc {|i| i.to_s }}
      end
      name = Answer.new(42)
      name.value.should_be "42"
    end

    it 'should override from clause in #has params with one defined in block' do
      class Answer < Doodle
        has :value, :kind => String, :from => { Integer => proc {|i| i.to_s }} do
          # this should override :from clause in has params
          from Float do |i|
            (Integer(i + 20)).to_s
          end
        end
      end

      name = Answer.new(22.0)
      name.value.should_be "42"

      name = Answer.new(42)
      name.value.should_be "42"
    end
  end
end
