require 'spec_helper'

describe Bebop do
  include Rack::Test::Methods
  include RouteHelper

  before :each do
    TestClass.after = nil
    @test_app = TestClass.new
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

  it "should provide route helpers outside the resource block" do
    get '/outside'
    last_response.body.should include('/foos/1/bars/2')
  end

  it "should define a route with new for the new method" do
    get '/foos/new'
    response_equal("new")
  end

  it "should define a route with an identifer and append edit for the edit method" do
    get '/foos/1/edit'
    response_equal('edit 1')
  end

  it "shoud define a route with an identifer for show and recieve the proper parameters" do
    get '/foos/1/bars/2'
    response_equal('show 1 2')
  end

  it "should respond correctly when the route is consulted" do
    post '/foos'
    response_match(/#{TestClass::BEFORE_ALL}/)
  end

  it "should call before and after blocks correctly based on the identifier" do
    put '/foos/1'
    response_match(/#{TestClass::BEFORE_UPDATE}/)

    post '/foos'
    response_match(/#{TestClass::BEFORE_UPDATE}/, :not)
  end

  it "should correctly append any vanilla sinatra method with the resource prefix" do
    get '/foos/arbitrary'
    response_equal('baz')
  end

  it "should not call before and after blocks in a nested resource based on the identifer" do
    put '/foos/1/bars/1'
    response_match(/#{TestClass::BEFORE_UPDATE}/, :not)
  end

  it "should call before all blocks on all resource routes" do
    put '/foos/1'
    response_match(/#{TestClass::BEFORE_ALL}/)

    post '/foos'
    response_match(/#{TestClass::BEFORE_ALL}/)

    get '/foos/1/bars'
    response_match(/#{TestClass::BEFORE_ALL}/)

    delete '/foos/1/bars/1'
    response_match(/#{TestClass::BEFORE_ALL}/)

    put '/foos/1/bars/1'
    response_match(/#{TestClass::BEFORE_ALL}/)
  end

  it "should call before and after resource blocks only on the nested resource routes" do
    get '/foos/1/bars'
    response_match(/#{TestClass::BEFORE_BARS}/)

    delete '/foos/1/bars/1'
    response_match(/#{TestClass::BEFORE_BARS}/)
  end

  it "should not call before and after resource blocks on non nested resource blocks" do
    post '/foos'
    response_not_match(/#{TestClass::BEFORE_BARS}/)
  end

  it "should call before and after filters without any identifier specified before all routes" do
    put '/foos/1'
    response_match(/#{TestClass::BEFORE_ALL_2}/)

    post '/foos'
    response_match(/#{TestClass::BEFORE_ALL_2}/)

    get '/foos/1/bars'
    response_match(/#{TestClass::BEFORE_ALL_2}/)

    delete '/foos/1/bars/1'
    response_match(/#{TestClass::BEFORE_ALL_2}/)

    put '/foos/1/bars/1'
    response_match(/#{TestClass::BEFORE_ALL_2}/)
  end

  it "should call before and after filters that specify multiple identifiers before the proper routes" do
    post '/foos'
    TestClass.after.should == TestClass::AFTER_VALUE

    put '/foos/1'
    TestClass.after.should == TestClass::AFTER_VALUE
  end

  it "should not prepend previous nested routes on non nested routes that follow" do
    get '/foos/do/something'
    response_match(/success/)
  end

  it "should produce correct routes for more than 2 levels of nesting" do
    get '/foos/1/bars/2/bazs'
    response_equal "two levels of nesting"
  end

  context "targeted filters" do
    it "should run targetted before filters with the proper id specified" do
      get '/foos/bak_filter_target'
      response_equal 'bak'
    end

    it "should not run filters for other routes that follow the filter" do
      get '/foos/not_bak_filter_target'
      response_not_match /bak/
    end
  end

  def response_match(regex, mod=nil)
    last_response.body.send("should#{mod ? '_' + mod.to_s : ''}", match(regex))
  end

  def response_not_match(regex)
    response_match(regex, :not)
  end

  def response_equal(string)
    last_response.body.should == string
  end
end


class TestClass < Sinatra::Base
  register Bebop
  set :show_exceptions, true

  class << self
    def after
      @@after
    end

    def after=(val)
      @@after = val
    end
  end

  BEFORE_BARS = '__before_bars__'
  BEFORE_UPDATE = '__before_update__'
  BEFORE_ALL = '__all__'
  BEFORE_ALL_2 = '__2all__'
  AFTER_VALUE = '__after__'

  get '/outside' do
    foo_bars_update_path(1,2)
  end

  resource :foos do |foo|

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
      @@after = AFTER_VALUE
    end

    foo.get('/do/something') { 'success' }

    foo.get '/route_helper_test' do
      foos_bars_update_path(1,2) + foos_bars_path(1)
    end

    foo.get '/exception' do
      foos_bars_update_path(1)
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
        baz.index { "two levels of nesting" }
      end
    end

    foo.before :bak_filter_target do
      @bak = 'bak'
    end

    foo.get('/bak_filter_target', :id => :bak_filter_target) { @bak }
    foo.get('/not_bak_filter_target', :id => :not_bak_filter_target) { @bak }

    foo.show { params[:foo_id] }
  end
end
