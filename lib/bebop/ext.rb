# The module registered in the Sinatra::Base subclass
#
# # Basic use
#
# While bebop can be used in the global context and with a Sinatra::Base subclass, the later is preferred. Example:
#
#     class MyApp < Sinatra::Base
#       register Bebop
#     end
#
# With the above in place you can use the {Bebop#resource} method to begin nesting your routes. See {RoutesApp} for examples
module Bebop

  # Used to report an invalid number of path arguments passed to route helpers defined by bebop
  class InvalidPathArgumentError < ArgumentError; end

  PARAM_REGEX = /:[\w_]+/i

  # Initial class level method registered with Sinatra::Base. A new {ResourceRouter} instance will be passed as
  # a block parameter
  #
  #    class MyApp < Sinatra::Base
  #      resource :foos do |foos|
  #        # nest routes, create filters, etc
  #      end
  #    end
  #
  # @param [Symbol] name the name of the resource
  # @param [Block] block the actions performed on the resource
  # @return nil
  def resource(name, &block)
    resource = ResourceRouter.new
    resource.resource(name, &block)
    resource.routes.each do |route|
      send(route[:method], route[:route], route[:options], &route[:block])
      define_route_helper(route[:helper], route[:route]) if route[:helper]
    end
    resource.print if ENV['PROUTES']
    resource.routes
  end

  # For each route defined in the {Bebop#resource} block that  provides the :id option
  # (either explicitly or implicitly as is the case with the new, index, show etc methods)
  # a route helper will be defined for use within other route blocks in the Sinatra application. Example:
  #
  #     class MyApp < Sinatra::Base
  #       resource :foos do |foos|
  #         foos.show do
  #           # some action
  #         end
  #
  #         foos.get '/bar' do
  #           redirect foos_show_path(Foo.first)
  #         end
  #       end
  #
  #       get '/bak' { redirect foos_show_path(Foo.first) }
  #     end
  #
  # In the example foos_show_path will use either the object or its to_param method to produce
  # `/foos/1/bar` if in this case Foo.first.to_param was equal to 1 or Foo.first itself was equal to one
  #
  # @param [String, Symbol] helper the name of the helper method
  # @param [String] route the route string where the parameters will be inserted
  # @return Proc
  def define_route_helper(helper, route)
    define_method helper do |*args|
      unless route.scan(PARAM_REGEX).length == args.length
        raise InvalidPathArgumentError.new("invalid number of parameters #{args.length} for: #{route}")
      end

      args.inject(route.dup) do |acc, arg|
        #handle fixnums and ar objects
        final_argument = arg.respond_to?(:to_param) ? arg.to_param : arg
        acc.sub!(PARAM_REGEX, final_argument.to_s)
      end
    end
  end

  # A new instance of this class is yielded to the blocks passed to {Bebop#resource} method
  # and its own {ResourceRouter#resource} method.
  class ResourceRouter
    # A container for the routes arrays
    attr_accessor :routes

    @@logger = Logger.new(STDOUT)

    # Provides access to logger used to display routing information
    #
    # @return [Logger]
    def self.logger
      @@logger
    end

    # Allows the user to define a new logger for displaying routing information
    #
    # @param [Logger] val the logging mechanism to be used when priting routes
    # @return [Logger]
    def self.logger=(val)
      @@logger = val
    end

    # When an instance is created the parent resources and filters covering all routes
    # are used to create path definitions, helpers and properly filtered blocks
    #
    # @param [Array] parent_resources an array of the resources under which this new router will need to nest
    # @param [Array] before_all an array of the filters that must be applied before all route blocks are executed
    # @param [Array] after_all an array of the filters that must be applied after all route blocks are executed
    def initialize(parent_resources=[], before_all=[], after_all=[])
      @current_resource = parent_resources.pop
      @parent_resources = parent_resources
      @before, @after, @routes = before_all, after_all, []
    end

    # Allows definition of routes in the same fashion as the vanilla sinatra DSL
    #
    # @param [String] route the route
    # @param [Hash] options the options, including :id used in filter definition, that will be passed
    #                       to Sinatra
    # @param [Proc] block the proc to execute upon request
    def get(route, options={}, &block)
      add_route(:get, route, options, block)
    end

    # See {ResourceRouter#get}
    def put(route, options={}, &block)
      add_route(:put, route, options, block)
    end

    # See {ResourceRouter#get}
    def post(route, options={}, &block)
      add_route(:post, route, options, block)
    end

    # See {ResourceRouter#get}
    def delete(route, options={}, &block)
      add_route(:delete, route, options, block)
    end

    # See {ResourceRouter#get}
    def head(route, options={}, &block)
      add_route(:head, route, options,  block)
    end

    # One of the custom route methods. Generally used for presenting information on the creation of a resource. Example:
    #
    #    class MyApp < Sinatra::Base
    #      resource :foos do |foos|
    #        # GET /foos/new
    #        foos.new {}
    #
    #        # GET /foos/new
    #        foos.get('new', :id => :new){}
    #      end
    #    end
    #
    # The two route definitions in the above example are functionally equivalent
    #
    # @param [Hash] options the options hash that will be passed on to Sinatra
    # @param [Proc] block the proc to execute upon request
    def new(options={}, &block)
      get 'new', options.merge(:id => :new), &block
    end

    # One of the custom route methods. Generally used for the creation of a resource. Example:
    #
    #    class MyApp < Sinatra::Base
    #      resource :foos do |foos|
    #        # POST /foos
    #        foos.create {}
    #
    #        # POST /foos
    #        foos.post('', :id => :create){}
    #      end
    #    end
    #
    # The two route definitions in the above example are functionally equivalent
    #
    # @param [Hash] options the options hash that will be passed on to Sinatra
    # @param [Proc] block the proc to execute upon request
    def create(options={}, &block)
      post '' , options.merge(:id => :create), &block
    end

    # One of the custom route methods. Generally used to present information on altering a resource. Example:
    #
    #    class MyApp < Sinatra::Base
    #      resource :foos do |foos|
    #        # GET /foos/:foo_id/edit
    #        foos.edit {}
    #
    #        # GET /foos/:foo_id/edit
    #        foos.get(':foo_id/edit', :id => :edit){}
    #      end
    #    end
    #
    # The two route definitions in the above example are functionally equivalent
    #
    # @param [Hash] options the options hash that will be passed on to Sinatra
    # @param [Proc] block the proc to execute upon request
    def edit(options={}, &block)
      get append_token(resource_identifier, 'edit') , options.merge(:id => :edit), &block
    end

    # One of the custom route methods. Generally used for presenting a list of resources instances. Example:
    #
    #    class MyApp < Sinatra::Base
    #      resource :foos do |foos|
    #        # GET /foos
    #        foos.index {}
    #
    #        # GET /foos
    #        foos.get('', :id => :index){}
    #      end
    #    end
    #
    # The two route definitions in the above example are functionally equivalent
    #
    # @param [Hash] options the options hash that will be passed on to Sinatra
    # @param [Proc] block the proc to execute upon request
    def index(options={}, &block)
      get '', options.merge(:id => :index), &block
    end

    # One of the custom route methods. Generally used for presenting information on a resource instance. Example:
    #
    #    class MyApp < Sinatra::Base
    #      resource :foos do |foos|
    #        # GET /foos/:foos_id
    #        foos.show {}
    #
    #        # GET /foos/:foos_id
    #        foos.get(':foos_id', :id => :show){}
    #
    #        # filter targetted at the following show route
    #        foos.before(:orly){}
    #
    #        # GET /foos/:foos_id/orly
    #        foos.show(:orly) {}
    #      end
    #    end
    #
    # The two route definitions in the above example are functionally equivalent. Additionally you can define
    # extra routing information that will be appended to the route and used as the filter identifier see {ResourceRouter#before}
    #
    # @param [Hash] options the options hash that will be passed on to Sinatra
    # @param [Proc] block the proc to execute upon request
    def show(route=nil, options={}, &block)
      get append_token(resource_identifier, (route || '').to_s), options.merge(:id => route || :show), &block
    end

    # One of the custom route methods. Generally used for presenting information on the creation of a resource. Example:
    #
    #    class MyApp < Sinatra::Base
    #      resource :foos do |foos|
    #        # DELETE /foos/:foos_id
    #        foos.destroy {}
    #
    #        # DELETE /foos/:foos_id
    #        foos.delete(':foos_id', :id => :destroy){}
    #      end
    #    end
    #
    # The two route definitions in the above example are functionally equivalent
    #
    # @param [Hash] options the options hash that will be passed on to Sinatra
    # @param [Proc] block the proc to execute upon request
    def destroy(options={}, &block)
      delete resource_identifier, options.merge(:id => :destroy), &block
    end

    # One of the custom route methods. Generally used for altering a resource. Example:
    #
    #    class MyApp < Sinatra::Base
    #      resource :foos do |foos|
    #        # PUT /foos/:foos_id
    #        foos.put {}
    #
    #        # PUT /foos/:foos_id
    #        foos.put('new', :id => :new){}
    #      end
    #    end
    #
    # The two route definitions in the above example are functionally equivalent
    #
    # @param [Hash] options the options hash that will be passed on to Sinatra
    # @param [Proc] block the proc to execute upon request
    def update(options={}, &block)
      put resource_identifier, options.merge(:id => :update), &block
    end

    # Before filters allow for the application of functionality across many routes
    #
    #    class MyApp < Sinatra::Base
    #      resource :foos do |foos|
    #        before(:all) {}
    #
    #        before(:index){}
    #
    #        # GET /foos
    #        foos.index {}
    #
    #        # GET /foos
    #        foos.get('', :id => :index){}
    #      end
    #    end
    #
    # As long as the route has defined an :id (the custom routes new, index, show, etc do this for you)
    # it can be targeted directly by a before filter. Both of the filters defined in the above example will apply to
    # both of the routes. You can also provide a list of identifiers of routes that you wish the filter to apply to.
    # If no identifier is defined the default is all.
    #
    # IMPORTANT: all filters must be defined before the routes they apply to.
    #
    # @param [Array<Symbol>] params the route identifiers to target
    # @param [Proc] block the proc to execute when targeted
    def before(*params, &block)
      add_filter(@before, params, block)
    end

    # After filters behave in the same manner as before filters save that they are executed after the route block.
    # See {ResourceRouter#before}
    #
    # @param [Array<Symbol>] params the route identifiers to target
    # @param [Proc] block the proc to execute when targeted
    def after(*params, &block)
      add_filter(@after, params, block)
    end

    # Nested resources can be defined by calling this method. Example:
    #
    #    class MyApp < Sinatra::Base
    #      resource :foos do |foos|
    #
    #        # GET /foos/bak
    #        foos.get('/bak'){}
    #
    #        foos.resource :bars do |bars|
    #
    #          # GET /foos/:foos_id/bars/bak
    #          bars.get('/bak') {}
    #        end
    #      end
    #    end
    #
    # Bebop takes care of nesting the resources as you grown used to in frameworks like Rails.
    #
    # @param [Symbol] name the plural of the resource name
    # @param [Proc] block the block of routes to nest under parent resources
    def resource(name, &block)
      before_filters = filters(@before, :all, name)
      after_filters = filters(@after, :all, name)

      router = self.class.new(all_resources + [name], before_filters, after_filters)
      yield(router)
      @routes += router.routes
    end

    # Used to print all the routes for a given router instance and its children
    def print
      @routes.each do |route|
        @@logger.info "#{justify(route, :helper, :r)}\t#{justify(route, :method, :l).upcase}\t#{justify(route, :route, :l)}"
      end
    end

    private

    def value_length(key)
      @routes.map { |r| r[key].to_s.length }.max
    end

    def justify(route, key, direction)
      route[key].to_s.send("#{direction}just", value_length(key))
    end

    def all_resources
      #in the initial call to resource there isn't a current_resource
      @current_resource ? @parent_resources + [@current_resource] : @parent_resources
    end

    def resource_identifier(resource=@current_resource)
      ":#{resource.to_s.singularize}_id"
    end

    def add_filter(type, params, block)
      params = [:all] if params.empty?
      type << {:routes => params, :block => block}
    end

    def add_route(method, route, options, block)
      identifier = options[:id]

      #Sinatra doesn't like the spurious options
      options.delete(:id)

      @routes << {
        :method => method,
        :route => append_to_path(route),
        :options => options,
        :block => add_filters_to_block(block, identifier, method),
        :helper => route_helper(identifier)
      }
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
      "#{helper_tokens.compact.join('_')}_path".to_sym
    end

    def add_filters_to_block(block, identifier, method)
      before = filters(@before, identifier, method, :all, @current_resource)
      after = filters(@after, identifier, method, :all, @current_resource)
      Proc.new do
        before.each { |f| instance_eval( &f[:block] ) }
        result = instance_eval(&block)
        after.each { |f| instance_eval( &f[:block] ) }
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
