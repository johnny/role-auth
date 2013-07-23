module RoleAuth
  class Builder

    def initialize(authorization_file)
      @parser = Parser.new(authorization_file)
    end

    def build
      task_methods = @parser.tasks.keys.collect do |task|
        next if task == :do
        build_task(task)
      end.join
      RoleAuth.checker = Checker.new(@parser, task_methods)
    end

    protected

    def build_task(task)
      permission_case_clauses = []

      pcc = build_case_clause(@parser.permissions, task)
      rcc = build_case_clause(@parser.restrictions, task)

      permission_case_clauses << "(#{pcc})" if !pcc.empty?
      permission_case_clauses << "!(#{rcc})" if !rcc.empty?
      %!
### #{task}
def #{task}(user, object, options = {})
  _user, _object, _options = user, object, options
  (#{permission_case_clauses.join(" && \n   ")}) #{build_alternative_permissions_clause(task)}
end
    !
    end

    def build_alternative_permissions_clause(parent_task)
      return if @parser.tasks[parent_task].options[:alternatives].nil?
      "|| " + @parser.tasks[parent_task].options[:alternatives].map do |task_name|
        "#{task_name}(_user, _object, _options)"
      end.join(" || ")
    end

    def build_any_clause(permissions, task)
      clause = build_permission_clauses(permissions, task, :any)
      clause.empty? ? "" : clause
    end

    def build_case_clause(permissions, task)
      when_clauses = (permissions[task].keys + permissions[:do].keys).uniq.map do |model|
        next if model == :any
        build_when_clause(permissions, task, model)
      end.join
      if when_clauses.empty?
        build_any_clause(permissions, task)
      else
        any_clause = build_any_clause(permissions, task)
        case_clause =  %!
case _object.is_a?(Class) ? _object.to_s : _object.class.to_s
  #{when_clauses}
end!
        any_clause.empty? ? case_clause : "#{any_clause} || #{case_clause}"
      end
    end

    def build_when_clause(permissions, task, model)
      permission_clauses = build_permission_clauses(permissions, task, model)
      return if permission_clauses.empty?
      %!
when '#{model}' then
#{RoleAuth.instance_name(model)} = _object
#{permission_clauses}!
    end

    def build_permission_clauses(permissions, task, model)
      mixed_permissions = permissions[task][model].values + permissions[:do][model].values
      mixed_permissions.map { |perm| build_permission(perm) }.join(" ||\n")
    end

    def build_permission(permission)
      permission.load_task_options(@parser)
      build_role_clause(permission) + build_permission_parts(permission)
    end

    def build_role_clause(permission)
      roles = (@parser.roles[permission.role.name][:descendants].dup << permission.role.name)

      instance_assignment = ''
      block = "%w{ #{roles.join(" ")} }.include?( user_role.name )"

      if !permission.options[:on].empty?
        model = permission.options[:on].first
        instance_name = RoleAuth.instance_name(model)
        instance_value = permission.model.instance_methods.include?(instance_name.to_sym) ? "_options[:on] || _object.#{instance_name}" : "_options[:on]"

        instance_assignment = "((#{instance_name} = #{instance_value} || (_object.is_a?(#{model}) ? _object : nil)) || true) &&"
        block = "#{block} && ( user_role.type != '#{model}' || ( !#{instance_name}.nil? && (user_role.object_id.nil? || user_role.object_id == #{instance_name}.id )))"
      end
      "#{instance_assignment} _user.roles.any? {|user_role| #{block} }"
    end

    def build_permission_parts(permission)
      return "" if permission.options[:if].empty?
      dsl_parser = DSLBuilder.pick(permission.model)
      " && " + permission.options[:if].collect do |type, entries|
        dsl_parser.send type, entries
      end.join(" && ")
    end

  end

  class DSLBuilder
    class << self
      def pick(model)
        pair = builders.find do | builder, base_class |
          model.is_a? base_class
        end
        pair ? pair[0] : self
      end

      def string(entries)
        "(#{entries.join(") && (")})"
      end

      def change(entries)
        symbol_entries = entries.uniq.collect {|e| ":#{e}" }.join(', ')
        "(_object.updated_attributes - [#{symbol_entries}]).empty?"
      end

      protected

      def builders
        @@builders ||= {}
      end

      def use_for(base_class)
        builders[self] = base_class
      end

    end
  end

end
