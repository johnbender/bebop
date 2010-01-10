require File.join(File.dirname(__FILE__), '..', 'lib', 'bebop')
require 'sinatra'

class MyApp < Sinatra::Base
  register Bebop

  resource :foos do |foos|

    # Any of the traditional sinatra methods called on the block parameter
    # will take the first argument (or an empty string) and apply it to
    # the resource base
    #
    # GET /foos/baz
    foos.get '/baz' do
      'baz'
    end
    
    # There are 7 helper methods for the traditional resource actions. They
    # are index, new, create, update, edit, destroy, and show. Each is a wrapper
    # for the corresponding Sinatra method
    #
    # GET /foos
    foos.index {}

    # For actions that require parameters the parameter name is derived from the singularized
    # name of the resource with '_id' appended.
    #
    # GET /foos/:foo_id
    foos.show {}

    # GET /foos/new
    foos.new {}

    # PUT /foos/:foo_id
    foos.update {}
    
    # GET /foos/:foo_id/edit
    foos.edit {}

    # DELETE /foos/:foo_id
    foos.destroy {}

    # For each of the helper methods, and any generic method (eg foos.get) that specifies the :identifier
    # option, bebop will define a relative path helper. See the nested resource below for the nameing of those
    # methods
    # 
    # POST /foos/redirect
    foos.get 'do/redirect' do
      # Redirects to /foos/1
      redirect foos_show_path(1)
    end

    # If you want to represent the relationship of your models through nested resources use
    # the resource method with the block parameter and all new routes will be nested and 
    # parameterized properly
    #
    # Prefix all with /foos/:foo_id
    foos.resource :bars do |bars|
      
      # GET /foos/:foo_id/bars/:bar_id/edit
      bars.edit do
        "foo: #{params[:foo_id]} bar: #{params[:bar_id]}"
      end 
      
      bars.get '/redirect' do
     
        # The route helper method naming convention is simple and easy to remember as it follows
        # the order of nesting for the given route starting with the original parent resource and
        # ending with the method identifier. 
        #
        # Redirects to /foos/1/bars/2/edit
        redirect foos_bars_edit_path(1, 2)
      end
    end
  end
end
