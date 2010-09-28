$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'doodle'
require 'pp'

class Animal < Doodle
  has :species
end

class AnimalHouse < Doodle
  has :animals, :collect => Animal
end

class Barn < AnimalHouse
end

class Pond < AnimalHouse
end

class Farm < Doodle
  has Barn
  has Pond
  def to_output
    self.class.to_s + " contains\n[\n" + 
    doodle.attributes.keys.map{ |x|
      v = send(x)
      "  " + v.class.to_s + " contains\n  [\n" +
      "    " + v.animals.map{ |a| a.species}.join("\n    ") +
      "\n  ]\n"
    }.join("\n") + "]\n"
  end
end

def barnCreator
  barn do
    animal "dog"
    animal "cat"
  end
end

farm = Farm do
  barnCreator
  pond do
    animal "whale"
    animal "shark"
  end
end

data = DATA.read
pp farm
puts farm.to_output
puts farm.to_output == data

__END__
Farm contains
[
  Barn contains
  [
    dog
    cat
  ]

  Pond contains
  [
    whale
    shark
  ]
]
