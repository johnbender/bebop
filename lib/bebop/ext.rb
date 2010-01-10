module Sinatra
  module Bebop
    class InvalidPathArgumentError < ArgumentError; end
    PARAM_REGEX = /:[a-zA-Z0-9_]+/

    def resource(name, &block)
      resource = ResourceRouter.new
      resource.resource(name, &block)
      resource.routes.each do |method, route, options, block, helper|
        send(method, route, options, &block)
        define_route_helper(helper, route) if helper
      end
      resource.print if ENV['PROUTES']
    end

    def define_route_helper(helper, route)
      define_method helper do |*args|
        unless route.scan(PARAM_REGEX).length == args.length
          raise InvalidPathArgumentError.new("invalid number of parameters #{args.length} for: #{route}")
        end
        
        args.inject(route.dup) do |acc, arg|
          #handle fixnums and ar objects
          arg = (arg.kind_of?(Fixnum) ? arg : arg.id)
          acc.sub!(PARAM_REGEX, arg.to_s) 
        end
      end
    end
    
    
    class ResourceRouter
      attr_accessor :routes 
      
      def initialize(parent_resources=[], before_all=[], after_all=[])
        @current_resource = parent_resources.pop
        @parent_resources = parent_resources
        @before, @after, @routes = before_all, after_all, []
      end
      
      def get(route='', options={}, &block)
        add_route(:get, route, options, block)
      end

      def put(route='', options={}, &block)
        add_route(:put, route, options, block)
      end
      
      def post(route, options={}, &block)
        add_route(:post, route, options, block)
      end

      def delete(route='', options={}, &block)
        add_route(:delete, route, options,  block)
      end

      def head(route='', options={}, &block)
        add_route(:head,  route, options,  block)
      end

      def new(options={}, &block)
        get 'new', options.merge(:identifier => :new), &block
      end
      
      def create(options={}, &block)
        post '' , options.merge(:identifier => :create), &block
      end

      def edit(options={}, &block)
        get append_token(resource_identifier, 'edit') , options.merge(:identifier => :edit), &block
      end

      def index(options={}, &block)
        get '', options.merge(:identifier => :index), &block
      end

      def show(route=nil, options={}, &block)
        get append_token(resource_identifier, (route || '').to_s), options.merge(:identifier => route || :show), &block
      end

      def destroy(options={}, &block)
        delete resource_identifier, options.merge(:identifier => :destroy), &block
      end

      def update(options={}, &block)
        put resource_identifier, options.merge(:identifier => :update), &block
      end

      #TODO add nested resource before filter
      def before(*params, &block)
        add_filter(@before, params, block)
      end

      def after(*params, &block)
        add_filter(@after, params, block)
      end

      def resource(name, &block)
        before_filters = filters(@before, :all, name)
        after_filters = filters(@after, :all, name)

        router = self.class.new(all_resources.compact << name, before_filters, after_filters)
        yield(router)
        @routes += router.routes
      end

      def print
        #TODO 6! 6! Block parameters, Ah Ah Ah! 
        @routes.each do |method, route, options, block, helper, identifier|
          puts "#{route}"
          puts "  method:     #{method.to_s.upcase}"
          puts "  helper:     #{helper}" if helper
          puts "  identifier: #{identifier}" if identifier
          puts
        end
      end
      
      private
      
      def all_resources
        @parent_resources << @current_resource
      end

      def resource_identifier(resource=@current_resource)
        ":#{resource.to_s.singularize}_id"
      end

      def add_filter(type, params, block)
        params = [:all] if params.empty?
        type << {:routes => params, :block => block}
      end
            
      def add_route(method, route, options, block) 
        identifier =options[:identifier]
        route = append_to_path(route)
        block = add_filters_to_block(block, identifier, method)
        helper = route_helper(identifier)

        #Sinatra doesn't like the spurious options
        options.delete(:identifier)

        @routes << [method, route, options, block, helper]
      end

      def append_to_path(str)
        append_token(append_token(parent_resource_path, @current_resource), str)
      end

      def parent_resource_path
        @parent_resources.inject('') do |acc, x|
          append_token(append_token(acc, x), resource_identifier(x))
        end
      end

      def append_token(l, tkn)
        tkn = tkn.to_s
        tkn = "/#{tkn}" unless tkn.empty? || tkn =~ /^\//
        "#{l}#{tkn}"
      end

      def route_helper(identifier)
        helper_tokens = (@parent_resources.dup << @current_resource) << identifier
        "#{helper_tokens.join('_')}_path".to_sym
      end

      def add_filters_to_block(block, identifier, method)
        before = filters(@before, identifier, method, :all, @current_resource)
        after = filters(@after, identifier, method, :all, @current_resource)
        Proc.new do
          before.each { |f| instance_eval( &f[:block] ) }
          result = instance_eval(&block)
          after.each { |f| instance_eval(&f[:block]) }
          result
        end
      end

      def filters(list, *identifiers)
        list.select do |filter|
          rs = filter[:routes]
          !(rs & identifiers).empty?
        end
      end
    end
  end

  register Bebop
end


Sinatra::Base.send(:register, Sinatra::Bebop)
