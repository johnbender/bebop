require File.join(File.dirname(__FILE__), '..', 'lib', 'bebop')
require 'rack/test'

class TestClass < Sinatra::Base; end

describe Sinatra::Bebop do
  include Rack::Test::Methods
  
  def app
    @test_app ||= TestClass.new 
    @test_app
  end

  before(:all) do
    app
    @class = TestClass
    use_bebop 
  end
  
  it "should define route helpers properly for routes specifying an identifier" do
    @class.instance_methods.should include('foos_bars_index_path')
    @class.instance_methods.should include('foos_create_path')
  end  

  it "should provide the correct relative url from the route helpers" do
    @test_app.foos_bars_index_path(1).should == '/foos/1/bars'
    @test_app.foos_bars_update_path(1,2).should == '/foos/1/bars/2'
  end

  it "should raise an error when the wrong number of paramters are passed to a route helper" do
    lambda {@test_app.foos_bars_update_path(1)}.should raise_error(Sinatra::Bebop::InvalidPathArgumentError)
  end

  it "should define a route with new for the new method" do
    get '/foos/new'
    last_response.body.should == "new"
  end

  it "should define a route with an identifer and append edit for the edit method" do
    get '/foos/1/edit'
    last_response.body.should == 'edit 1'
  end

  it "shoud define a route with an identifer for show and recieve the proper parameters" do
    get '/foos/1/bars/2'
    last_response.body.should == 'show 1 2'
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

  it "should correctly append any vanilla sinatra method with the resource prefix" do
    get '/foos/arbitrary'
    last_response.body.should == 'baz'
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

      foo.get(:arbitrary) { 'baz' }        

      foo.create { "create#{@all}#{@update}#{@bars}" }
      foo.update { "#{@all}#{@update}#{@bars}" }

      foo.new { "new" }
      foo.edit { "edit #{params[:foo_id]}" }

      foo.resource :bars do |bar|
        bar.index { "#{@all}#{@update}#{@bars}" }
        bar.update { "#{@all}#{@update}#{@bars}" }
        bar.destroy { "#{@all}#{@update}#{@bars}" }

        bar.show { "show #{params[:foo_id]} #{params[:bar_id]}" }
      end
    end    
  end
end
