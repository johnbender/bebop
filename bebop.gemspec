Gem::Specification.new do |s|
  s.name = 'bebop'
  s.version = '0.1.0'
  s.date = '2010-1-10'
 
  s.description = "A small Sinatra extension for resource routing"
  s.summary = "A small Sinatra extension for resource routing"
 
  s.authors = ["John Bender"]
  s.email = 'john.m.bender@gmail.com'
 
  # = MANIFEST =
  s.files = %w[ 
README.markdown
Rakefile
bebop.gemspec
examples/filters.rb
examples/routes.rb
lib/bebop/ext.rb
lib/bebop.rb
spec/bebop_spec.rb
]
  # = MANIFEST = 
  s.add_dependency 'sinatra', '>= 0.9.4'
  s.add_dependency 'activesupport', '>= 2.3.5'

  s.add_development_dependency 'rspec', '>=1.2.9'
  
  s.has_rdoc = false
  s.require_paths = %w[lib]
  s.rubyforge_project = 'bebop'
  s.rubygems_version = '1.3.5'
end
