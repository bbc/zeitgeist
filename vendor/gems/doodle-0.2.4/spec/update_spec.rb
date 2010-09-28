require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'doodle.update' do
  temporary_constants :Foo, :Bar, :Baz do
    before(:each) do
      class Dude < Doodle
        has :name, :kind => String
      end
    end

    it 'updates attributes using a hash' do
      dude = Dude("Dude")
      dude.doodle.update(:name => "The Dude")
      dude.name.should_be "The Dude"
    end

    it 'updates attributes using a block and does not validate until the end' do
      dude = Dude("Dude")
      dude.doodle.update do
        name "The Dude"
      end
      dude.name.should_be "The Dude"
    end

    it 'updates with block taking precedence' do
      dude = Dude("Dude")
      dude.doodle.update :name => "Jeff" do
        name "The Dude"
      end
      dude.name.should_be "The Dude"
    end

    it 'does not validate the object until the end of the block' do
      dude = Dude("Dude")
      dude.doodle.update do
        name "Jeff"
        name "The Dude"
      end
      dude.name.should_be "The Dude"
    end

    it 'will not prevent individual ~attribute~ validations in the argument list' do
      dude = Dude("Dude")
      expect_error(Doodle::ValidationError) {
        dude.doodle.update :name => 123
      }
    end

    it 'will not prevent individual ~attribute~ validations in the block' do
      dude = Dude("Dude")
      expect_error(Doodle::ValidationError) {
        dude.doodle.update do
          name 123
        end
      }
    end

    it 'will not prevent individual ~attribute~ validations in the argument list even if valid attribute value supplied in block' do
      dude = Dude("Dude")
      expect_error(Doodle::ValidationError) {
        dude.doodle.update :name => 123 do
          name "The Dude"
        end
      }
    end

  end
end
