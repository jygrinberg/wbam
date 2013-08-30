require 'yaml'                 # These lines ensure Delayed Job uses syck YAML correctly
YAML::ENGINE.yamler = 'syck'   #

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
