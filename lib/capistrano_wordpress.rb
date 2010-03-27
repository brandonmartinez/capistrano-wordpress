require 'capistrano'
require 'capistrano/cli'
 
Dir.glob(File.join(File.dirname(__FILE__), '/wordpress/*.rb')).each { |f| load f }