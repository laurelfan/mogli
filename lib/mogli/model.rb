module Mogli
  class Model < Hashie::Dash
    def client=(val)
      @client=val
    end
    
    def client
      @client || Mogli::Client.new
    end

    def initialize(hash={},client=nil)
      self.client=client
      super(hash||{})
    end
    
    def post_params
      post_params = {}
      self.class.creation_keys.each do |key|
        post_params[key] = self[key]
      end
      post_params
    end
    
    def destroy
      client.delete(id)
      freeze
    end
    
    def self.included(other)
      other.extend(ClassMethods)
    end

    def method_missing(method, *args)
      method_as_s = method.to_s
      if method_as_s.to_s[-1].chr == "="
        warn_about_invalid_property(method_as_s.chop)
      else 
        super
      end
    end
    def warn_about_invalid_property(property)
      puts "Warning: property #{property} doesn't exist for class #{self.class.name}"
    end
          
    def self.define_properties(*args)
      args.each do |arg|
        property arg
      end
    end
    
    def self.creation_properties(*args)
      @creation_properties = args
    end
    
    def self.creation_keys
      @creation_properties || []
    end
    
    def self.hash_populating_accessor(method_name,*klass)
      define_method "#{method_name}=" do |hash|
        instance_variable_set("@#{method_name}",client.map_data(hash,klass))
      end
      define_method "#{method_name}" do
        instance_variable_get "@#{method_name}"
      end
      
      add_creation_method(method_name,klass)
      
    end
    
    def self.add_creation_method(name,klass)
      define_method "#{name}_create" do |arg|
        params = arg.nil? ? {} : arg.post_params
        klass_to_send = arg.nil? ? nil : klass
        client.post("#{id}/#{name}", klass_to_send, params)
      end
    end
    
    def self.has_association(name,klass)
      define_method name do
        if (ret=instance_variable_get("@#{name}")).nil?
          ret = client.get_and_map("#{id}/#{name}",klass)
          instance_variable_set("@#{name}",ret)
        end
        return ret
      end
      
      add_creation_method(name,klass)
    end
    
    def self.recognize?(data)
      true
    end
    
    def self.find(id,client=nil)
      (client||Mogli::Client.new).get_and_map(id,self)
    end
  end
end