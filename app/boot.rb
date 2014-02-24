$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

require 'bundler'
Bundler.require
Dotenv.load
Cocaine::CommandLine.path = '/usr/local/bin'

Bugsnag.configure do |config|
  config.api_key = ENV['BUGSNAG_API_KEY']
end

ENV['REVISION'] = `git rev-parse --short HEAD`.strip

require 'generator/face'
require 'generator/detector'
require 'generator/compositor'
require 'app'