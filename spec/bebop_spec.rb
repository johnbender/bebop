require File.join(File.dirname(__FILE__), '..', 'lib', 'bebop')
require 'rack/test'
require 'sinatra/base'
require 'ruby-debug'

class TestClass < Sinatra::Base
  register Bebop
  set :show_exceptions, true

  def self.global
    @@global
  end
  def self.global=(val)
    @@global = val
  end
end

describe Bebop do
  include Rack::Test::Methods

  def app
    @test_app ||= TestClass.new
    @test_app
  end

  before :all do
    app
    @class = TestClass
    use_bebop
  end

  before :each do
    TestClass.global = nil
  end

  it "should provide the correct relative url from the route helpers" do
    get '/foos/route_helper_test'
    last_response.body.should include('/foos/1/bars')
    last_response.body.should include('/foos/1/bars/2')
  end

  it "should raise an error when the wrong number of paramters are passed to a route helper" do
    get '/foos/exception'
    last_response.body.should include('Bebop::InvalidPathArgumentError')
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
    last_response.body.should match(/#{BEFORE_ALL}/)
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

  it "should call before and after filters without any identifier specified before all routes" do
    put '/foos/1'
    last_response.body.should match(/#{BEFORE_ALL_2}/)

    post '/foos'
    last_response.body.should match(/#{BEFORE_ALL_2}/)

    get '/foos/1/bars'
    last_response.body.should match(/#{BEFORE_ALL_2}/)

    delete '/foos/1/bars/1'
    last_response.body.should match(/#{BEFORE_ALL_2}/)

    put '/foos/1/bars/1'
    last_response.body.should match(/#{BEFORE_ALL_2}/)
  end

  it "should call before and after filters that specify multiple identifiers before the proper routes" do
    post '/foos'
    TestClass.global.should == AFTER_VALUE

    put '/foos/1'
    TestClass.global.should == AFTER_VALUE
  end

  it "should not call before and after filters that specify multiple parameters on anything else" do
    get '/foos/new'
    TestClass.global = nil
  end

  it "should not prepend previous nested routes on non nested routes that follow" do
    get '/foos/do/something'
    last_response.body.should == 'success'
  end

  it "should produce correct routes for more than 2 levels of nesting" do
    get '/foos/1/bars/2/bazs'
    last_response.body.should match(/#{BEFORE_ALL_2}/)
  end

  BEFORE_BARS = '__before_bars__'
  BEFORE_UPDATE = '__before_update__'
  BEFORE_ALL = '__all__'
  BEFORE_ALL_2 = '__2all__'
  AFTER_VALUE = '__after__'

  def use_bebop
    @class.resource :foos do |foo|

      foo.before :all do
        @all = BEFORE_ALL
      end

      foo.before do
        @all2 = BEFORE_ALL_2
      end

      foo.before :update do
        @update = BEFORE_UPDATE
      end

      foo.before :bars do
        @bars = BEFORE_BARS
      end

      foo.after :create, :update do
        TestClass.global = AFTER_VALUE
      end

      foo.get(:arbitrary) { 'baz' }

      foo.create { "#{@all2}#{@all}#{@update}#{@bars}" }
      foo.update { "#{@all2}#{@all}#{@update}#{@bars}" }

      foo.new { "new" }
      foo.edit { "edit #{params[:foo_id]}" }

      foo.resource :bars do |bar|
        bar.index { "#{@all2}#{@all}#{@update}#{@bars}" }
        bar.update { "#{@all2}#{@all}#{@update}#{@bars}" }
        bar.destroy { "#{@all2}#{@all}#{@update}#{@bars}" }

        bar.show { "show #{params[:foo_id]} #{params[:bar_id]}" }

        bar.resource :bazs do |baz|
          baz.index { @all2 }
        end
      end

      foo.get('/do/something') { 'success' }

      foo.get '/route_helper_test' do
        foos_bars_update_path(1,2) + foos_bars_path(1)
      end

      foo.get '/exception' do
        foos_bars_update_path(1)
      end
    end
  end
end
