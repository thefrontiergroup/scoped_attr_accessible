ENV["RAILS_ENV"] ||= 'test'
$LOAD_PATH.unshift Pathname(__FILE__).dirname.dirname.join("lib").to_s

require 'bundler/setup'
Bundler.setup
Bundler.require :default, :development

require 'scoped_attr_accessible'
require 'rspec'

Dir[Pathname(__FILE__).dirname.join("support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rr
  config.include   CustomMatchers
end