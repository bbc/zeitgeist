# 1.8.7+ versions
class Doodle
  class AppendableAttribute < AttributeCollector
    def define_collector
      collection_name = self.name
      collector_spec.each do |collector_name, collector_class|
        if collector_class.nil?
          doodle_owner.sc_eval do
            define_method collector_name do |*args, &block|
              collection = send(collection_name)
              #p [collector_name, 1, collection_name, args]
              # unshift the block onto args so not consumed by <<
              args.unshift(block) if block_given?
              collection.<<(*args)
            end
          end
        else
          doodle_owner.sc_eval do
            define_method collector_name do |*args, &block|
              if !collector_class.kind_of?(Class)
                collector_class = Doodle::Utils.const_resolve(collector_class)
              end
              collection = send(collection_name)
              #p [collector_name, 1, collection_name, args]
              if args.size > 0 and args.all?{|x| x.kind_of?(collector_class)}
                collection.<<(*args, &block)
              else
                collection << collector_class.new(*args, &block)
              end
            end
          end
        end
      end
    end
  end

  class KeyedAttribute < AttributeCollector
    def define_collector
      # save ref to self for use in closure
      collection_name = self.name
      collection_key = self.key
      collector_spec.each do |collector_name, collector_class|
        if collector_class.nil?
          doodle_owner.sc_eval do
            #p [:defining, collector_name]
            define_method collector_name do |*args, &block|
              #p [collector_name, 1, args]
              collection = send(collection_name)
              args.unshift(block) if block_given?
              args.each do |arg|
                collection[arg.send(collection_key)] = arg
              end
            end
          end
        else
          doodle_owner.sc_eval do
            #p [:defining, collector_name]
            define_method collector_name do |*args, &block|
              if !collector_class.kind_of?(Class)
                collector_class = Doodle::Utils.const_resolve(collector_class)
              end
              #p [collector_name, 2, args]
              collection = send(collection_name)
              #p [:collector, collector_name, collector_class]
              if args.size > 0 and args.all?{|x| x.kind_of?(collector_class)}
                args.each do |arg|
                  collection[arg.send(collection_key)] = arg
                end
              else
                obj = collector_class.new(*args, &block)
                collection[obj.send(collection_key)] = obj
              end
            end
          end
        end
      end
    end
  end
end
