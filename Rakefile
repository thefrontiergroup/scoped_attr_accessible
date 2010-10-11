require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name        = "scoped_attr_accessible"
    gem.summary     = %Q{Scoping for attr_accessible and attr_protected on ActiveModel objects.}
    gem.description = %Q{TODO: longer description of your gem}
    gem.email       = "team+darcy+mario@thefrontiergroup.com.au"
    gem.homepage    = "http://github.com/thefrontiergroup/scoped_attr_accessible"
    gem.authors     = ["Darcy Laycock", "Mario Visic"]
    gem.add_dependency             "activemodel", "~> 3.0"
    gem.add_development_dependency "rspec",       "~> 2.0"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core'
require 'rspec/core/rake_task'
task :default => :spec

desc "Run all specs in spec directory (excluding plugin specs)"
RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  desc "Run all specs with rcov"
  RSpec::Core::RakeTask.new(:rcov) do |t|
    t.rcov = true
    t.pattern = "./spec/**/*_spec.rb"
    t.rcov_opts = '--exclude spec/,/gems/,/Library/,/usr/,lib/tasks,.bundle,config,/lib/rspec/,/lib/rspec-'
  end
end



require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "scoped_attr_accessible #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
