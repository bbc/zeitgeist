require 'yaml'
class Doodle
  module ToHash
    # create 'pure' hash of scalars only from attributes - hacky but works (kinda)
    def to_hash
      Doodle::Utils.symbolize_keys!(YAML::load(to_yaml.gsub(/!ruby\/object:.*$/, '')) || { }, true)
      #begin
      #  YAML::load(to_yaml.gsub(/!ruby\/object:.*$/, '')) || { }
      #rescue Object => e
      #  doodle.attributes.inject({}) {|hash, (name, attribute)| hash[name] = send(name); hash}
      #end
    end
    def to_string_hash
      Doodle::Utils.stringify_keys!(YAML::load(to_yaml.gsub(/!ruby\/object:.*$/, '')) || { }, true)
    end
  end
end
