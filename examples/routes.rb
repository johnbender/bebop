class MyApp < Sinatra::Base
  resource :foos do |foos|

    # Any of the traditional sinatra methods called on the block parameter
    # will take the first argument (or an empty string) and apply it to
    # the resource base
    #
    # GET /foos/bar
    foos.get '/bar' do
      haml :bar
    end
    
    # There are 7 helper methods for the traditional resource actions. They
    # are index, new, create, update, edit, destroy, and show. Each is a wrapper
    # for the corresponding Sinatra method
    #
    # GET /foos
    foos.index do
      haml :index
    end

    # In the case of the actions that require parameters the paramater is simple the singular
    # version of the resource with '_id' appended.
    # GET /foos/:foo_id
    foos.show {}

    # For each of the helper methods, and any generic method (eg foos.get) that specifies the :identifier
    # option, bebop will define a relative path helper. See the nested resource below for the nameing of those
    # methods
    # 
    # POST /foos
    foos.create do
      @foo = Foo.new(params)
      redirect foos_show_path(@foo.id)
    end

    # GET /foos/new
    foos.new {}

    # PUT /foos/:foo_id
    foos.update {}
    
    # GET /foos/:foo_id/edit
    foos.edit {}

    # DELETE /foos/:foo_id
    foos.destroy {}

    # If you want to represent the relationship of your models through nested resources simply call
    # the resource method on foos and all new routes will be nested and parameterized properly
    #
    foos.resource :bars do |bars|
      
      # GET /foos/:foo_id/bars/:bar_id
      bars.show do
        "foo: #{params[:food_id]} bar: #{params[:bar_id]}"
      end 

      
      bars.get '/redirect' do
        
        # The route helper method naming convention is simple and easy to remember as it follows
        # the order of nesting for the given route starting with the original parent resource and
        # ending with the method identifier. 
        #
        # Redirects to /foos/1/bars/2
        redirect foos_bars_show_path(1, 2)
      end
    end
  end
end
