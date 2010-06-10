Bebop
=====

Bebop is small Sinatra/Monk extension for DRY resource based routing. It provides targeted filters, path helpers, nested resources, printable routing information, and familiar action methods like new, show, destroy, update, and index.

The name comes from its happy partnering with the [Monk](http://monkrb.com) glue framework, as Thelonius Monk is considered to be the father of bebop.


dependencies
------------

* Sinatra
* ActiveSupport

install
-------

Make sure you have gemcutter.org as one of your sources:

    gem sources -a http://gemcutter.org

Then:

	gem install bebop

verify
------

Requires rspec version 1.2.9 or higher

	cd /path/to/bebop; spec spec

sample
------

If you wanted to expose the resource foo (in this case Foo is implemented as an AR model):

	require 'bebop'
	require 'sinatra'
	require 'foo'

	class MyApp < Sinatra::Base
	  register Bebop

	  resource :foos do |foos|

	    # GET /foos/:foo_id
	    foos.show do
	      @foo = Foo.find(params[:foo_id])
	      haml :'foos/show'
	    end

	    # GET /foos/new
	    foos.new do
	      @foo = Foo.new
	      haml :'foos/new'
	    end
	  end
	end

more detail
-----------

See the examples directory. You can play with each of the examples as follows:

    $ pwd
	/path/to/bebop
	$ ruby examples/routes.rb
	== Sinatra/0.9.4 has taken the stage on 4567 for development with backup from Thin
	>> Thin web server (v1.2.4 codename Flaming Astroboy)
	>> Maximum connections set to 1024
	>> Listening on 0.0.0.0:4567, CTRL+C to stop

[Full documentation](http://johnbender.github.com/bebop/) also available.

routes
------

Run your sinatra/monk app with the PROUTES env variable set to view the routes created with the resource method

	$ ruby my_app.rb PROUTES=true

or

	$ thor monk:start PROUTES=true

NOTE: planning to change the formatting soon, as it currently sucks

license
-------

(The MIT License)

Copyright (c) 2010 FIX

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
