require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, "to_a" do
  temporary_constant :Event, :Location do
    before :each do
      class ::Location < Doodle
        has :name, :kind => String
      end
      class ::Event < Doodle
        has :locations, :init => [], :collect => ::Location
      end
      @event = Event do
        location "Stage 1"
        location do
          name "Stage 2"
        end
      end
    end
    it "should serialize nested doodles to array" do
      @event.doodle.to_a.should_be [[:locations, [[[:name, "Stage 1"]], [[:name, "Stage 2"]]]]]
    end
  end
end
