require 'spec_helper'

describe "filters" do
  include RouteHelper

  context "all" do
    context "explicit" do
      let(:value) { "explicit" }

      it "should run for all routes" do
        @class_const = 'Explicit'
        test_routes filter_setup(:filter_targets => [:all])
      end
    end

    context "implicit" do
      let(:value) { "implicit" }

      it "should run for all routes" do
        @class_const = 'Implicit'
        test_routes filter_setup
      end
    end
  end

  context "targeted at specific routes" do
    let(:value) { "bar route" }

    it "should run on those routes" do
      @class_const = 'Targeted'
      routes = filter_setup(:filter_targets => [:foo], :ids => [:foo]).select do |r|
        r[:route] =~ /vanilla/
      end

      test_routes routes
    end

    it "should not run on other routes" do
      @class_const = 'NotTargeted'
      routes = filter_setup(:filter_targets => [:fiz], :ids => [:not_fiz])
      test_routes(routes, "")
    end
  end

  context "targeted at many routes" do
    let(:value) { "many targeted route" }

    context "that are vanilla" do
      it "should run on each route" do
        @class_const = 'ManyVanillaTargeted'

        routes = filter_setup(:filter_targets => [:fiz, :bar], :ids => [:fiz, :bar]).select do |route|
          route[:route] =~ /vanilla/
        end

        test_routes routes
      end
    end

    context "that are special bebop routes" do
      it "should run on each route" do
        @class_const = 'ManySpecialTargeted'

        routes = filter_setup(:filter_targets => [:new, :create]).select do |route|
          route[:helper].to_s =~ /new/ || route[:helper].to_s =~ /create/
        end

        test_routes routes
      end

      it "should not run on other routes" do
        @class_const = 'ManySpecialNotTargeted'

        special_routes = [:new, :create]
        routes = filter_setup(:filter_targets => special_routes).reject do |route|
          route[:helper].to_s =~ /new/ || route[:helper].to_s =~ /create/
        end

        test_routes routes, ""
      end
    end
  end

  context "for nested route sets" do
    let (:value) { 'nested' }

    context "targetted directly" do
      it "should run on each route in the nested resource" do
        @class_const = 'NestedTargeted'
        test_routes filter_setup do |foo|
          foo.resource :bars do |bar|
            define_routes(bar) do
              @value
            end
          end
        end
      end

      it "should not run on other nested resources" do
        @class_const = 'NestedUntargeted'
        routes = filter_setup(:filter_targets => [:bars]) do |foo|
          foo.resource :bars do |bar|
            define_routes(bar) do
              @value
            end
          end
          foo.resource :bazs do |baz|
            define_routes(baz) do
              @value || ""
            end
          end
        end

        # filters under the nested bars resource should set @value
        test_routes routes.select { |r| r[:route] =~ /bar/ }, value

        # filters under the nested baz set should not set @value
        test_routes routes.select { |r| r[:route] =~ /baz/ }, ""
      end
    end

    context "that are implicitly or explicitly all" do
      it "should run for all routes on all nested resources" do
        @class_const = 'NestedImplicitAll'
        test_routes filter_setup do |foo|
          foo.resource :bars do |bar|
            define_routes(bar) do
              @value
            end

            bar.resource :bazs do |baz|
              define_routes(bar) do
                @value
              end
            end
          end
        end
      end
    end
  end

  # value is defined in a let block for each test context
  def test_routes(routes, check_for = value)
    routes.should_not be_empty
    routes.each do |route|
      send(route[:method], route[:route]).body.should == check_for
      $after_filter.should == check_for
      $after_filter = ""
    end
  end

  def filter_setup(opts = {})
    route_class

    value_block, filter_block = define_blocks

    routes = @class_const.resource :foos do |foo|
      [:before, :after].each do |type|
        foo.send(type, *(opts[:filter_targets] || []), &filter_block)
      end

      if block_given?
        yield foo
      else
        define_routes(foo, opts[:ids], &value_block)
      end
    end

    @test_app = @class_const.new
    routes
  end

  def route_class
    eval("class #{@class_const} < Sinatra::Base; end")
    @class_const = Kernel.const_get(@class_const)
    @class_const.register Bebop
  end

  def define_blocks
    return_value = value
    [Proc.new { @value }, Proc.new { @value = return_value; $after_filter = return_value }]
  end

  def define_routes(resource, ids = [], &value_block)
    if ids && !ids.empty?
      ids.each do |id|
        define_all_route_methods(resource, :id => id, &value_block)
      end
    else
      define_all_route_methods(resource, &value_block)
    end
  end
end
