__DIR__ = File.dirname(__FILE__)

$LOAD_PATH.unshift __DIR__ unless
  $LOAD_PATH.include?(__DIR__) ||
  $LOAD_PATH.include?(File.expand_path(__DIR__))

%w{checker builder parser}.each do |file|
  require "role-auth/#{file}"
end

module RoleAuth

  class AuthorizationError < StandardError; end

  DEFAULT_CONFIGURATION = {
    :user_class => 'User',
    :exception_class => AuthorizationError
  }

  attr_accessor :checker
  module_function :checker, :checker=

  module_function

  def config=(options = {})
    @config = DEFAULT_CONFIGURATION.merge(options)
  end
  def config
    @config ||= DEFAULT_CONFIGURATION
  end

  def instance_name(model)
    model.to_s[/([^:]*)$/,1].downcase
  end

  module InstanceMethods

    def user!
      User.current || raise(ArgumentError, "User.current is not set")
    end

    def can?(task, object, options = {})
      user!.can?(task, object, options)
    end

    def can!(task, object, options = {})
      user!.can!(task, object, options)
    end

    def is?(role, options = {})
      user!.is?(role, options)
    end

  end

  module UserClassMethods
    def self.included(klass)
      klass.extend ClassMethods
    end

    def can?(task, object, options = {})
      RoleAuth.checker.can?(task, object, options, self)
    end

    def can!(task, object, options = {})
      can?(task, object, options) || raise(RoleAuth.config[:exception_class])
    end

    def is?(role_name, options = {})
      RoleAuth.checker.is?(role_name, options, self)
    end

    module ClassMethods
      def current=(user)
        Thread.current[:user] = user
      end
      def current
        Thread.current[:user]
      end
    end
  end
end

%w{ data_mapper merb}.each do |file|
  require "role-auth/adapters/#{file}" if Object.const_defined? file.split('_').map{|e| e.capitalize}.join
end
