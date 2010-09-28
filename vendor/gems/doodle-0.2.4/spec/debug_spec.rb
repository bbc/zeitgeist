require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle::Debug do
  temporary_constant :Foo do

    before :each do
      class Foo
        def call_me
          Doodle::Debug.calling_method
        end
        def do_call
          call_me
        end
        def who_am_i?
          Doodle::Debug.this_method
        end
      end
    end

    it 'should display calling method' do
      foo = Foo.new
      foo.do_call.should_be "do_call"
      foo.who_am_i?.should_be "who_am_i?"
    end

  end
end

