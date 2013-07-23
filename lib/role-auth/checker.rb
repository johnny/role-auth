module RoleAuth

  # The Checker class checks the permissions of the current User.
  # It is accessable via RoleAuth.checker.
  class Checker

    Alias = {:destroy => :delete, :index => :list, :show => :read, :new => :create, :edit => :update}

    # @param [Parser] parser The parser
    # @param [String] eval_string The ruby code for checking the defined tasks
    def initialize(parser,eval_string)
      @parser = parser
      # puts eval_string
      instance_eval(eval_string)
    end

    # Attribute accessor
    #
    # @return [Hash] The Hash representation of the defined roles
    def roles ; @parser.roles; end

    def can?(task, object, options = {}, user = User.current)
      raise ArgumentError, 'User is missing. Did you forget to set User.current?' unless user
      self.send(Alias[task] || task, user, object, options)
    end

    def is?(role_name, options, user = User.current)
      role_definition = @parser.roles[role_name]
      child_roles = role_definition[:descendants].dup << role_name

      # Check the :on parameter
      return false if options[:on] && role_definition[:on] && options[:on].class != role_definition[:on]

      user.roles.any? do |role|
        child_roles.include?(role.name.to_sym) && ( !role_definition[:on] || !role.type || (role.type == role_definition[:on].to_s && options[:on] && (role.object_id.nil? || role.object_id == options[:on].id)))
      end
    end

    private

    def method_missing(name, *args)
      file = caller.find{|line| line !~ /lib\/role-auth/}
      puts "RoleAuth warning: Task #{name} hasn't been defined but you tried to access it in #{file}"
    end
  end
end
