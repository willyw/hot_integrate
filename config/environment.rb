# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.gem 'uuidtools'
  config.gem 'mime-types', :lib => 'mime/types'
  config.gem 'authlogic'
  # config.gem 'dropbox'
  config.gem 'delayed_job', :version => '~>2.0.4'
  
  config.time_zone = 'UTC'

end