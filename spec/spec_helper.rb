$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'dm-core'
require 'dm-migrations'
require 'role-auth'
#require 'sequel'
require 'rspec'
require 'rspec/autorun'

require 'support/classes'
require 'shared_specs'

RSpec.configure do |config|
  config.include RoleAuth::InstanceMethods
end

# If you want the logs displayed you have to do this before the call to setup
# DataMapper::Logger.new($stdout, :debug)

# An in-memory Sqlite3 connection:
DataMapper.setup(:default, 'sqlite3::memory:')

DataMapper.auto_migrate!

def load_authorization_file(name = 'authorization')
  file = File.new(File.expand_path(File.dirname(__FILE__) + "/support/#{name}.rb"))
  RoleAuth::Builder.new(file).build
end
