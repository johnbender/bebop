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

  it "should not prepend previous nested routes on non nested routes that follow" do
    get '/foos/do/something'
    response_match(/success/)
  end

  it "should produce correct routes for more than 2 levels of nesting" do
    get '/foos/1/bars/2/bazs'
    response_equal "two levels of nesting"
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
