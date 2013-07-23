class RoleAuth::DataMapperDSLBuilder < RoleAuth::DSLBuilder
  use_for DataMapper::Model
  class << self
    def change(entries)
      symbol_entries = entries.uniq.collect {|e| ":#{e}" }.join(', ')
      "(_object.dirty_attributes.keys.map{ |attr| attr.name} - [#{symbol_entries}]).empty?"
    end
  end
end # RoleAuth::DataMapperDSLBuilder

module RoleAuth::Adapters
  module DataMapper
    module Hook
      def check_permission_before(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        include RoleAuth::InstanceMethods
        extend RoleAuth::Adapters::DataMapper::ClassMethods
        args.each do |filter|
          self.send "_create_permission_filter_before_#{filter}", options
        end
      end
    end # Hook
    module ClassMethods
      protected
      def _create_permission_filter_before(action, options)
        options_literal = options[:on] ? ", :on => #{RoleAuth.instance_name(options[:on])}" : ''
        self.class_eval <<-RUBY
          before :#{action} do
            can!(:#{options[:as] || action}, self #{options_literal}) if ::#{RoleAuth.config[:user_class]}.current
          end
        RUBY
      end

      def _create_permission_filter_before_initialize(options)
        options_literal = if options[:on]
                            instance_name = RoleAuth.instance_name(options[:on])
                            ", :on => attributes[:#{instance_name}] || ::#{options[:on]}.get(attributes[:#{instance_name}_id])"
                          end || ''
        self.class_eval <<-RUBY
          def initialize(attributes = {})
            can!(:create, self #{options_literal}) if ::#{RoleAuth.config[:user_class]}.current
            super
          end
        RUBY
      end


      def _create_permission_filter_before_create(options)
        _create_permission_filter_before(:create, options)
      end
      def _create_permission_filter_before_update(options)
        _create_permission_filter_before(:update, options)
      end
      def _create_permission_filter_before_destroy(options)
        _create_permission_filter_before(:destroy, options.merge(:as => :delete))
      end
    end # ClassMethods
  end # DataMapper
end # RoleAuth::Adapters
DataMapper::Model.append_extensions(RoleAuth::Adapters::DataMapper::Hook)
