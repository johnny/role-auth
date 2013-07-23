module RoleAuth::Adapters
  module Merb
    def lockdown(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:object] ||= _guess_model_class_from_controller_name

      actions = args.empty? ? public_methods(false) : args

      _define_lockdown(options)
      before :"_lockdown_#{options[:object]}", :only => actions
    end

    def _guess_model_class_from_controller_name
      self.to_s[/([^:]*)$/,1].singularize
    end

    def _define_lockdown(options)
      options_hash = options[:on] ? ", :on => #{options[:on]}" : ''
      self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def _lockdown_#{options[:object]}
          can! params[:action].to_sym, #{options[:object]} #{options_hash}
        end
RUBY
    end
  end # Merb
end # RoleAuth::Adapters

Merb::AbstractController.send(:include, RoleAuth::InstanceMethods)
Merb::AbstractController.send(:extend, RoleAuth::Adapters::Merb)

class Merb::BootLoader::RoleAuth < Merb::BootLoader
  after AfterAppLoads
  class << self
    def run
      RoleAuth.config = Merb::Plugins.config[:role-auth].blank? ? {:exception_class => Merb::ControllerExceptions::Forbidden} : Merb::Plugins.config[:role-auth]
      RoleAuth::Builder.new(File.new(Merb.root/'config/authorization_rules.rb')).build
    end
  end
end
