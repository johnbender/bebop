require File.join(File.dirname(__FILE__), '..', 'lib', 'bebop')
require 'rack/test'

class TestClass < Sinatra::Base; end

describe Sinatra::Bebop do
  include Rack::Test::Methods
  
  def app; TestClass.new end

  before(:all) do 
    @class = TestClass
    use_bebop 
  end
  
  it "should register a GET route at the resource root" do
    @class.should_receive(:post) do |route, options|
      route.should == '/foos'
      options.should == {}
    end
    use_bebop
  end

  it "should have the parent and identifier prepended to nested resources" do
    @class.should_receive(:get) do |route, options|
      route.should == '/foos/:foo_id/bars'
    end
    use_bebop
  end

  it "route helpers should be defined properly for routes specifying an identifier" do
    @class.instance_methods.should include('foos_bars_index_path')
    @class.instance_methods.should include('foos_create_path')
  end  

  it "should respond correctly when the route is consulted" do
    post '/foos'
    last_response.body.should match(/create/)
  end

  it "should call before and after blocks correctly based on the identifier" do
    put '/foos/1'
    last_response.body.should match(/#{BEFORE_UPDATE}/)

    post '/foos'
    last_response.body.should_not match(/#{BEFORE_UPDATE}/)
  end

  it "should not call before and after blocks in a nested resource based on the identifer" do
    put '/foos/1/bars/1'
    last_response.body.should_not match(/#{BEFORE_UPDATE}/)
  end

  it "should call before and after all blocks on all resource routes" do
    put '/foos/1'
    last_response.body.should match(/#{BEFORE_ALL}/)

    post '/foos'
    last_response.body.should match(/#{BEFORE_ALL}/)

    get '/foos/1/bars'
    last_response.body.should match(/#{BEFORE_ALL}/)
    
    delete '/foos/1/bars/1'
    last_response.body.should match(/#{BEFORE_ALL}/)    

    put '/foos/1/bars/1'
    last_response.body.should match(/#{BEFORE_ALL}/)
  end
  
  it "should call before and after resource blocks only on the nested resource routes" do
    get '/foos/1/bars'
    last_response.body.should match(/#{BEFORE_BARS}/)
    
    delete '/foos/1/bars/1'
    last_response.body.should match(/#{BEFORE_BARS}/)
  end
  
  it "should not call before and after resource blocks on non nested resource blocks" do
    post '/foos' 
    last_response.body.should_not match(/#{BEFORE_BARS}/)
  end
  
  BEFORE_BARS = '__before_bars__'
  BEFORE_UPDATE = '__before_update__'
  BEFORE_ALL = '__all__'

  def use_bebop
    # ENV['PROUTES']='t'
    @class.resource :foos do |foo|
      
      foo.before :all do
        @all = BEFORE_ALL
      end

      foo.before :update do
        @update = BEFORE_UPDATE
      end
      
      foo.before :bars do
        @bars = BEFORE_BARS
      end

      foo.create { "create#{@all}#{@update}#{@bars}" }
      foo.update { "#{@all}#{@update}#{@bars}" }

      foo.resource :bars do |bar|
        bar.index { "#{@all}#{@update}#{@bars}" }
        bar.update { "#{@all}#{@update}#{@bars}" }
        bar.destroy { "#{@all}#{@update}#{@bars}" }
      end
    end    
  end
end
