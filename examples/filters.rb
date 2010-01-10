require File.join(File.dirname(__FILE__), '..', 'lib', 'bebop')
require 'sinatra'

class MyApp < Sinatra::Base
  register Bebop

  resource :foos do |foos|
    # Bebop provides some simple targeting for before and after filters, with the 
    # caveat that they must be defined before the routes they target within the resource block    
    # To have your filter run before all routes under a given resource and its child resources
    # pass :all as the first parameter
    # 
    foos.before :all do
      @all = 'all'
    end
    
    # To have your filter run before a specific route, the route must be one of the seven helper
    # routes (see example/routes.rb) or specify the :identifier parameter
    #
    foos.before :new do
      @new = 'new'
    end

    foos.new do
      "#{@all} #{@new}" # => 'all new'
    end
   
    # You can target the vanila methods by providing the :identifier hash option
    #
    # GET /foos/baz
    foos.get '/baz', :identifier => :new do
      @new # => 'new'
    end

    # You can also specify a before filter for nested routes by using the child resource name
    # 
    foos.before :bars do
      @bars = 'some bars'
    end
    
    foos.resource :bars do |bars|
      bars.get '/some_bars' do
        @bars # => 'some bars'
      end
    end

    foos.get '/bak' do
      @bars # => nil
    end

    # Finally you can specify many different methods in your filters by passing many identifiers
    # 
    foos.before :bak, :baz do
      @bak_baz = "bak 'n' baz"
    end

    foos.get('/something', :identifier => :bak) { @bak_baz }
    foos.get('/anything', :identifier => :baz) { @bak_baz }    
  end
end
