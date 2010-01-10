class MyApp < Sinatra::Base
  resource :foos do |foos|
    
    # Bebop provides some simple targeting for your genric before and after filters, with the 
    # caveat that they must be defined before the routes they targeted within the resource block.    
    # To have your filter run before all routes under a given resource and its nesterd resources
    # pass :all as the first parameter
    foos.before :all do
      @var = 'before'
    end
    
    # To have your filter run before a specific route, the route must be one of the seven helper
    # routes (see example/routes.rb) or specify the :identifier parameter
    #
    foos.before :my_route do
      @var = 'my route'
    end
    
    foos.get '/baz', :identifier => :my_route do
      # @var == 'my route'
    end

    # The third option to is specify a before filter for nested routes by using the resource name
    # 
    foos.before :bars do
      @bars = 'some bars'
    end
    
    foos.resource :bars do
      # @bars == 'some bars'
    end

    foos.get '/bak' do
      # @bars == nil
    end
  end
end
