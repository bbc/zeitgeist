# some prob with different versions of libxml on different platforms
# begin
#   require 'nokogiri'
# rescue LoadError
require 'rexml/document'
# end

class Doodle
  module EscapeXML
    ESCAPE = { '&' => '&amp;', '"' => '&quot;', '>' => '&gt;', '<' => '&lt;', "'" => "&apos;" }

    def self.escape(s)
      s.to_s.gsub(/[&"><]/) { |special| ESCAPE[special] }
    end
    def self.unescape(s)
      ESCAPE.inject(s.to_s) do |str, (k, v)|
        # don't use gsub! here - don't want to modify argument
        str.gsub(v, k)
      end
    end
  end

  # adds to_xml and from_xml methods for serializing and deserializing
  # Doodle object graphs to and from XML
  #
  # works for me but YMMV
  module XML
    include Utils
    class Document < Doodle
      include Doodle::XML
      def self.tag(value)
        define_method :tag do
          value
        end
      end
    end

    class Element < Document
    end

    # adapter module for REXML
    module REXMLAdapter

      # return the parsed xml DOM
      def parse_xml(xml)
        REXML::Document.new(xml)
      end

      # test whether a node is a text node
      def text_node?(node)
        node.kind_of?(::REXML::Text)
      end

      # get the first XML element in the document
      def get_root(doc)
        # skip :REXML::XMLDecl
        # REXML children does not properly implement shift (or pop)
        root = doc.children.find { |el, i| el.kind_of?(REXML::Element) }
        if root.nil?
          raise ArgumentError, "XML document does not contain any elements"
        else
          root
        end
      end
    end

    # adapter module for Nokogiri
    module NokogiriAdapter

      # return the parsed xml DOM
      def parse_xml(xml)
        Nokogiri::XML(xml)
      end

      # test whether a node is a text node
      def text_node?(node)
        node.name == "text"
      end

      # get the first XML element in the document
      def get_root(doc)
        doc.children.first
      end
    end

    if Object.const_defined?(:Nokogiri)
      extend NokogiriAdapter
    else
      extend REXMLAdapter
    end

    class << self
      # parse XML +str+ into a Doodle object graph, using +ctx+ as the
      # root namespace (can be module or class)
      #
      # this is the entry point - most of the heavy lifting is done by
      # +from_xml_elem+
      def from_xml(ctx, str)
        doc = parse_xml(str)
        root = get_root(doc)
        from_xml_elem(ctx, root)
      end

      # helper function to handle recursion
      def from_xml_elem(ctx, root)
        #p [:from_xml_elem, :ctx, root]
        attributes = root.attributes.inject({ }) { |hash, (k, v)| hash[k] = EscapeXML.unescape(v.to_s); hash}
        text, children = root.children.partition{ |x| text_node?(x) }
        text = text.map{ |x| x.to_s}.reject{ |s| s =~ /^\s*$/}.join('')
        element_name = root.name
        if element_name !~ /[A-Z]/
          element_name = Doodle::Utils.camel_case(element_name)
        end
        klass = Utils.const_lookup(element_name, ctx)
        #p [:creating_new, klass, text, attributes]
        #p [:root1, root]
        # don't pass in empty text - screws up when class has only
        # child elements (and no attributes) because tries to
        # instantiate child element from empty string ""
        if text == ""
          text = nil
        end
        args = [text, attributes].compact
        oroot = klass.new(*args) {
          #p [:in_block]
          from_xml_elem(root)
        }
        #p [:oroot, oroot]
        oroot
      end
      private :from_xml_elem
    end

    def from_xml_elem(parent)
      #p [:from_xml_elem, :parent, parent]
      children = parent.children.reject{ |x| XML.text_node?(x) }
      children.each do |child|
        text = child.children.select{ |x| XML.text_node?(x) }.map{ |x| x.to_s}.reject{ |s| s =~ /^\s*$/}.join('')
        element_name = child.name
        if element_name !~ /[A-Z]/
          element_name = Doodle::Utils.camel_case(element_name)
        end
        method = Doodle::Utils.snake_case(Utils.normalize_const(element_name))
        #p [:method, method]
        object = const_lookup(element_name)
        attributes = child.attributes.inject({ }) { |hash, (k, v)| hash[k] = EscapeXML.unescape(v.to_s); hash}
        if text == ""
          text = nil
        end
        args = [text, attributes].compact
        #p [:from_xml_elem, object, text, attributes]
        send(method, object.new(*args) {
               from_xml_elem(child)
             })
      end
      #parent
      self
    end
    private :from_xml_elem

    # override this to define a tag name for output - the default is
    # to use the classname (without namespacing)
    # TODO: interpreting namespaces
    def tag(namespace = '')
      namespace + self.class.to_s.split(/::/).last
    end

    def format_attribute(k, v, attr)
      %[#{attr.namespace ? attr.namespace + ':' : '' }#{ k }="#{ v }"]
    end

    # override this to define a specialised attributes format
    def format_attributes(attributes)
      if attributes.size > 0
        " " + attributes.map{ |k, v, attr| format_attribute(k, v, attr)}.join(" ")
      else
        ""
      end
    end

    # override this to define a specialised tag format
    def format_tag(tag, attributes, body)
      if body.size > 0
        ["<#{tag}#{format_attributes(attributes)}>", body, "</#{tag}>"]
      else
        ["<#{tag}#{format_attributes(attributes)} />"]
      end.join('')
    end

    # output Doodle object graph as xml
    def to_xml(*a)
      parent_key, parent_attr = *a
      body = []
      attributes = []
      self.doodle.attributes.map do |k, attr|
        # don't store defaults
        next if self.default?(k)
        # arbitrary - could be CDATA?
        if k == :_text_
          body << self._text_
          next
        end
        v = send(k)
        # note: can't use polymorphism here because we don't know if object has to_xml method
        if v.kind_of?(Doodle)
          # if value is a Doodle, call its to_xml method
          body << v.to_xml(k, attr)
        elsif v.kind_of?(Array)
          # if it's an Array, map each to_xml
          # TODO: handle case when object does not have a to_xml method
          body << v.map{ |x| x.to_xml }
        else
          # it's an attribute
          # TODO: allow opting in to being an XML attribute (by adding option to #has?)
          # e.g. has :name, :xml_options => {:attribute => true}
          # or   has :name, :is_xml_attribute => true
          # or   has :name, :xml => :attr
          # or   has :name, :xml => {:attribute => true, :ns => :default}
          # or   xml_attr :name
          attributes << [k, EscapeXML.escape(v), attr]
        end
      end
      if parent_attr && parent_attr.namespace
        ns = parent_attr.namespace + ':'
      else
        ns = ''
      end
      format_tag(tag(ns), attributes, body)
    end
  end
end

