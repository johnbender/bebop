require 'spec_helper'

describe "filters" do
  include RouteHelper

  context "before" do
    module Before; end

    context "all" do
      context "and explicit" do
        let(:string) { "explicit" }

        it "should run for all routes" do
          class Before::Explicit < Sinatra::Base; end
          @routes = before_filter_setup(Before::Explicit, string, :all)
          test_routes(@routes, string)
        end
      end

      context "implicit" do
        let(:string) { "implicit" }

        it "should run for all routes" do
          class Before::Implicit < Sinatra::Base; end
          @routes = before_filter_setup(Before::Implicit, string)
          test_routes(@routes, string)
        end
      end
    end

    context "targeted at specific routes" do
      let(:string) { "bar route" }

      it "should run on targeted routes" do
        class Before::Targeted < Sinatra::Base; end

        @routes = before_filter_setup(Before::Targeted, string, :foo, :id => :foo).select do |r|
          r[:route] =~ /vanilla/ # id's are used with vanilla routing methods
        end

        test_routes(@routes, string)
      end

      it "should not run on other routes" do
        class Before::NotTargeted < Sinatra::Base; end
        @routes = before_filter_setup(Before::NotTargeted, string, :fiz, :id => :foo)
        test_routes(@routes, "")
      end
    end

    def test_routes(routes, value)
      routes.each do |route|
        send(route[:method], route[:route]).body.should == value
      end
    end

    def before_filter_setup(class_const, value, filter_target = nil, opts = {})
      class_const.register Bebop

      value_block = Proc.new { @value }
      filter_block = Proc.new { @value = value }

      routes = class_const.resource :foos do |foo|
        if filter_target
          foo.before filter_target, &filter_block
        else
          foo.before &filter_block
        end

        define_all_route_methods(foo, opts, &value_block)
      end

      @test_app = class_const.new
      routes
    end
  end

  context "after" do
    context "all" do

    end
  end
end
