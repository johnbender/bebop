require File.join(File.dirname(__FILE__), '..', 'lib', 'bebop')
require 'rack/test'
require 'sinatra/base'
begin
  require 'ruby-debug'
rescue LoadError; end

class TestApp < Sinatra::Base;
  register Bebop
end

module RouteHelper
  include Rack::Test::Methods

  def normal_route_methods
    # TODO head providing empty result
    [:get, :post, :put, :delete]
  end

  def bebop_route_methods
    [:new, :create, :show, :index, :update, :destroy]
  end

  def define_all_route_methods(resource, opts = {}, &block)
    normal_route_methods.each do |method|
      resource.send(method, '/vanilla', opts, &block)
    end

    bebop_route_methods.each do |method|
      resource.send(method, opts, &block)
    end
  end

  def app
    @test_app ||= TestApp.new
    @test_app
  end
end

