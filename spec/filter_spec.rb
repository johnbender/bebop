require 'spec_helper'

describe "filters" do
  include RouteHelper
  context "all" do
    context "explicit" do
      let(:value) { "explicit" }

      it "should run for all routes" do
        class Explicit < Sinatra::Base; end
        @class_const = Explicit
        test_routes filter_setup(:filter_targets => [:all])
      end

      it "should run for nested routes"
    end

    context "implicit" do
      let(:value) { "implicit" }

      it "should run for all routes" do
        class Implicit < Sinatra::Base; end
        @class_const = Implicit
        test_routes filter_setup
      end

      it "should run for nested routes"
    end
  end

  context "targeted at specific routes" do
    let(:value) { "bar route" }

    it "should run on those routes" do
      class Targeted < Sinatra::Base; end
      @class_const = Targeted
      routes = filter_setup(:filter_targets => [:foo], :ids => [:foo]).select do |r|
        r[:route] =~ /vanilla/
      end

      test_routes routes
    end

    it "should not run on other routes" do
      class NotTargeted < Sinatra::Base; end
      @class_const = NotTargeted
      routes = filter_setup(:filter_targets => [:fiz], :ids => [:not_fiz])
      test_routes(routes, "")
    end
  end

  context "targetted at many routes" do
    let(:value) { "many targetted route" }

    context "that are vanilla" do
      it "should run on each route" do
        class ManyVanillaTargetted < Sinatra::Base; end
        @class_const = ManyVanillaTargetted

        routes = filter_setup(:filter_targets => [:fiz, :bar], :ids => [:fiz, :bar]).select do |route|
          route[:route] =~ /vanilla/
        end

        test_routes routes
      end
    end

    context "that are special bebop routes" do
      it "should run on each route" do
        class ManySpecialTargetted < Sinatra::Base; end
        @class_const = ManySpecialTargetted

        special_routes = [:new, :create]
        routes = filter_setup(:filter_targets => special_routes).select do |route|
          route[:helper].to_s =~ /new/ || route[:helper].to_s =~ /create/
        end

        test_routes routes
      end

      it "should not run on other routes" do
        class ManySpecialNotTargetted < Sinatra::Base; end
        @class_const = ManySpecialNotTargetted

        special_routes = [:new, :create]
        routes = filter_setup(:filter_targets => special_routes).reject do |route|
          route[:helper].to_s =~ /new/ || route[:helper].to_s =~ /create/
        end

        test_routes routes, ""
      end
    end
  end

  def test_routes(routes, check_for = value)
    routes.should_not be_empty
    routes.each do |route|
      send(route[:method], route[:route]).body.should == check_for
      $after_filter.should == check_for
      $after_filter = ""
    end
  end

  def filter_setup(opts = {})
    @class_const.register Bebop

    return_value = value
    value_block = Proc.new { @value }
    filter_block = Proc.new { @value = return_value; $after_filter = return_value }

    routes = @class_const.resource :foos do |foo|
      [:before, :after].each do |type|
        foo.send(type, *(opts[:filter_targets] || []), &filter_block)
      end

      if opts[:ids]
        opts[:ids].each do |id|
          define_all_route_methods(foo, :id => id, &value_block)
        end
      else
        define_all_route_methods(foo, &value_block)
      end
    end

    @test_app = @class_const.new
    routes
  end
end
