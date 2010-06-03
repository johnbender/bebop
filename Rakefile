require 'rake'
require 'spec/rake/spectask'

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('specs_with_rcov') do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.rcov = true
  t.rcov_opts = ['--exclude spec', '--exclude "gems/*"', '--exclude "bebop.rb"' ]
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "bebop"
    gemspec.summary = "A small Sinatra/Monk extension for resource routing"
    gemspec.description = gemspec.summary
    gemspec.email = "john.m.bender@gmail.com"
    gemspec.homepage = "http://github.com/johnbender/bebop"
    gemspec.authors = ["John Bender"]
    gemspec.add_dependency('activesupport', '>= 2.3.5')
    gemspec.add_dependency('sinatra', '= 1.0')
    gemspec.add_development_dependency('rspec', '>= 1.2.9')
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
