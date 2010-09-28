require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle::Utils do
  temporary_constant :Foo do
    before do
      class ::Foo
      end
    end
    it "should flatten arrays to one level only" do
      Doodle::Utils.flatten_first_level([1, [[2], 3]]).should_be [1, [2], 3]
      Doodle::Utils.flatten_first_level([[1, [[2], 3]]]).should_be [1, [[2], 3]]
    end

    it "should convert strings to snake_case" do
      Doodle::Utils.snake_case("HelloWorld").should_be "hello_world"
      Doodle::Utils.snake_case("URI").should_be "uri"
      Doodle::Utils.snake_case("IPAddress").should_be "ip_address"
    end

    it "should convert strings to CamelCase" do
      Doodle::Utils.camel_case("hello_world").should_be "HelloWorld"
      Doodle::Utils.camel_case("URI").should_be "URI"
      Doodle::Utils.camel_case("uri").should_be "Uri"
      Doodle::Utils.camel_case("IPAddress").should_be "IPAddress"
      Doodle::Utils.camel_case("ip_address").should_be "IpAddress"

      Doodle::Utils.camel_case("Hello_world", false).should_be "HelloWorld"
      Doodle::Utils.camel_case("hello_world", false).should_be "helloWorld"
    end

    it 'should resolve constants' do
      Doodle::Utils.const_resolve(::Foo).should_be ::Foo
      Doodle::Utils.const_resolve(:Foo).should_be ::Foo
      Doodle::Utils.const_resolve("Foo").should_be ::Foo
      proc { Doodle::Utils.const_resolve("Bar") }.should raise_error(NameError)
    end

    it 'should deepcopy an object' do
      array = [1,[2,["hello"]]]
      copy = Doodle::Utils.deep_copy(array)
      copy.should_be [1,[2,["hello"]]]
      copy[1][1][0].object_id.should_not_be array[1][1][0].object_id
    end

    it "should pluralize a word" do
      Doodle::Utils.pluralize("rose").should_be "roses"
      Doodle::Utils.pluralize("bus").should_be "buses"
      Doodle::Utils.pluralize("fox").should_be "foxes"
      Doodle::Utils.pluralize("try").should_be "tries"
      Doodle::Utils.pluralize("fly").should_be "flies"
      Doodle::Utils.pluralize("country").should_be "countries"
      Doodle::Utils.pluralize("address").should_be "addresses"
    end

    def be_greater_than_one
      simple_matcher("greater than one") {|x| x > 1 }
    end

    it 'should show the caller' do
      old_debug = $DEBUG
      $DEBUG = false
      e = Exception.new("dummy")
      e.set_backtrace(["hello", "/doodle/lib/utils.rb", "world"])
      Doodle::Utils.doodle_caller(e).size.should_be 2
      $DEBUG = true
      Doodle::Utils.doodle_caller(e).size.should_be 3
      $DEBUG = old_debug
    end

    it 'should try harder' do
      proc { Doodle::Utils.try { 1/0 }}.should_not raise_error
      Doodle::Utils.try { 1/0 }.should be_kind_of(ZeroDivisionError)
      Doodle::Utils.try { 6 * 7 }.should_be 42
    end

    it 'should normalize a string to contain only those characters valid for constants' do
      Doodle::Utils.normalize_const("123?ABC''h$$").should_be "123ABCh" # "
    end
  end
end

describe Doodle::Utils, "normalize hash" do
  temporary_constants :Foo, :Bar, :Baz do
    before do
      module ::Foo
        A = 1
        class Bar
          A = 2
          class Baz
            A = 3
          end
        end
      end
    end
    it 'should resolve a constant along the module nesting path' do
      Doodle::Utils.const_lookup(:A, ::Foo).should_be 1
      Doodle::Utils.const_lookup(:A, ::Foo::Bar).should_be 2
      Doodle::Utils.const_lookup(:A, ::Foo::Bar::Baz).should_be 3
      proc { Doodle::Utils.const_lookup(:B, ::Foo::Bar::Baz) }.should raise_error(NameError)
    end
  end
end

describe Doodle::Utils, "normalize hash" do
  before do
    @hash = { "a" => 1, :b => 2, "c" => { "d" => 3, :e => 4 }}
    @normalized_hash = { :a => 1, :b => 2, :c => { "d" => 3, :e => 4 }}
    @deep_normalized_hash = { :a => 1, :b => 2, :c => { :d => 3, :e => 4 }}

    @string_normalized_hash = { "a" => 1, "b" => 2, "c" => { "d" => 3, :e => 4 }}
    @string_deep_normalized_hash = { "a" => 1, "b" => 2, "c" => { "d" => 3, "e" => 4 }}
  end

  it "should normalize a hash's keys in place" do
    Doodle::Utils.normalize_keys!(@hash)
    @hash.should_be @normalized_hash
  end

  it "should normalize a hash's keys" do
    hash = Doodle::Utils.normalize_keys(@hash)
    hash.should_be @normalized_hash
    @hash.should_not_be @normalized_hash
  end

  it "should deep normalize a hash's keys in place when recursive == true" do
    Doodle::Utils.normalize_keys!(@hash, true)
    @hash.should_be @deep_normalized_hash
  end

  it "should deep normalize a hash's keys when recursive == true" do
    hash = Doodle::Utils.normalize_keys(@hash, true)
    hash.should_be @deep_normalized_hash
    @hash.should_not_be @normalized_hash
  end

  it "should symbolize a hash's keys in place" do
    Doodle::Utils.symbolize_keys!(@hash)
    @hash.should_be @normalized_hash
  end

  it "should symbolize a hash's keys in place" do
    Doodle::Utils.symbolize_keys!(@hash, true)
    @hash.should_be @deep_normalized_hash
  end

  it "should symbolize a hash's keys" do
    hash = Doodle::Utils.symbolize_keys(@hash)
    hash.should_be @normalized_hash
    @hash.should_not_be @normalized_hash
  end

  it "should symbolize a hash's keys" do
    hash = Doodle::Utils.symbolize_keys(@hash, true)
    hash.should_be @deep_normalized_hash
    @hash.should_not_be @normalized_hash
  end

  it "should stringify a hash's keys in place" do
    Doodle::Utils.stringify_keys!(@hash)
    @hash.should_be @string_normalized_hash
  end

  it "should stringify a hash's keys in place" do
    Doodle::Utils.stringify_keys!(@hash, true)
    @hash.should_be @string_deep_normalized_hash
  end

  it "should stringify a hash's keys" do
    hash = Doodle::Utils.stringify_keys(@hash)
    hash.should_be @string_normalized_hash
    @hash.should_not_be @string_normalized_hash
  end

  it "should stringify a hash's keys" do
    hash = Doodle::Utils.stringify_keys(@hash, true)
    hash.should_be @string_deep_normalized_hash
    @hash.should_not_be @string_normalized_hash
  end
end

