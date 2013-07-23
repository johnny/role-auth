module RoleAuth

  # Within the Parser class your authorization file will be evaled.
  class Parser
    attr_reader :tasks, :restrictions, :permissions, :roles

    DEFAULT_TASKS = [:create, :update, :delete, :list, :read]

    # @param [File] authorization_file The authorization file which will be evaled.
    def initialize(authorization_file)
      @permissions = Hash.new {|h,k| h[k] = (Hash.new {|h,k| h[k] = {}})}
      @restrictions = Hash.new {|h,k| h[k] = (Hash.new {|h,k| h[k] = {}})}
      @tasks, @roles = {}, {}

      DEFAULT_TASKS.each {|t| task(t)}
      instance_eval(authorization_file.read)
      process_roles
      process_tasks
    end

    # Define a new role which can be given to a user.
    #
    # @example
    # role :moderator, :on => Site do
    #   is :user
    #   can :moderate, Comment
    # end
    #
    # @param [Symbol] name The name of the Role.
    # @param [Hash] options
    # @option options [Class] :on The Role will be bound to instances of the given Class.
    # @yield Defines the details of the role
    def role(name, options = {})
      @roles[name] = options.merge(:name => name, :is => [], :descendants => [])
      @role = InternalRole.new(name,options)
      yield if block_given?
      @role = nil
    end

    # Define parent roles for the current role.
    # The current role will behave exactly like the given roles.
    #
    # Can only be called within a role block.
    #
    # @example define many parents
    # is :moderator, :author, :user
    #
    # @param [Symbol, ...] parent_roles
    def is(*parent_roles)
      @roles[@role.name][:is] += parent_roles
    end

    # Define a permission for the current role.
    #
    # Can only be called within a role block.
    #
    # @example Author permissions
    # can :delete, :update, Post, :if => [%{ !post.published }, only_changed(:content)]
    # can :create, Post, :if => %{ !post.published }
    #
    # @example alternative definition
    # task :update_and_delete_unpublished, :is => [:delete, :update], :if => %{ !post.published }
    # can :update_and_delete_unpublished, Post, if => only_changed(:content)
    # can :create, Post, :if => %{ !post.published }
    #
    # @overload can(*tasks, *classes, options = {})
    #   @param [Symbol, ...] tasks One or more tasks to bind the permission to
    #   @param [Class, ...] classes One or more classes to bind the permission to
    #   @param [Hash] options
    def can(*args)
      add_permission(@permissions, *args)
    end

    # Define a restriction ( a negative permission ) for the current role.
    #
    # Can only be called within a role block.
    #
    # @example
    # can_not :delete, Post
    #
    # @see #can Argument details and further examples
    def can_not(*args)
      args.last.is_a?(Hash) ? args.last[:restriction]= true : args << {:restriction => true}
      add_permission(@restrictions, *args)
    end

    # Define a new task.
    #
    # @example Define an entirely new task
    # task :push
    #
    # @example Define a publish task
    # task :publish, :is => :update, :if => only_changed(:published)
    #
    # @example Define a joined manage task
    # task :manage, :is => [:update, :create, :delete]
    #
    # @see #can More examples for the :if option
    # @see DEFAULT_TASKS Default tasks
    #
    # @param [Symbol] name The name of the task.
    # @param [Hash] options
    # @option options [Symbol, Array<Symbol>] :is Optional parent tasks. The options of the parents will be inherited.
    # @option options [String, Hash, Array<String,Hash>] :if The conditions for this task.
    def task(name, options = {})
      options[:is] = options[:is].is_a?(Array) ? options[:is] : [options[:is]].compact
      @tasks[name] = Task.new(name,options)
    end

    # Define fields that can be changed by the current user.
    # Use this on an :if attribute of #can, #can_not, #task.
    #
    # @see #task Usage examples with a task definition
    #
    # @return [Hash] An internal representation
    def only_changed(*fields)
      {:change => fields}
    end

    # Restrict access to the owner of the object.
    # Use this on an :if attribute of #can, #can_not, #task.
    def is_owner
      "object.user_id == user.id"
    end

    protected

    # Creates an internal Permission
    #
    # @param [Hash] target Either the permissions or the restrictions hash
    # @param [Array] args The function arguments to the #can, #can_not methods
    def add_permission(target, *args)
      raise '#can and #can_not have to be used inside a role block' unless @role
      options = args.last.is_a?(Hash) ? args.pop : {}
      tasks = []
      models = []

      models << args.pop if args.last == :any
      args.each {|arg| arg.is_a?(Symbol) ? tasks << arg : models << arg}

      tasks.each do |task|
        models.each do |model|
          if permission = target[task][model][@role]
            permission.load_options(options)
          else
            target[task][model][@role] = Permission.new(@role, task, model, options)
          end
        end
      end
    end

    # Flattens the tasks. It sets the ancestors and the alternative tasks
    def process_tasks
      @tasks.each_value do |task|
        task.options[:ancestors] = []
        set_ancestor_tasks(task)
        set_alternative_tasks(task) if @permissions.key? task.name
      end
    end

    # Set the ancestors on task.
    #
    # @param [Task] task The task for which the ancestors are set
    # @param [Task] ancestor The ancestor to process. This is the recursive parameter
    def set_ancestor_tasks(task, ancestor = nil)
      task.options[:ancestors] += (ancestor || task).options[:is]
      (ancestor || task).options[:is].each do |parent_task|
        set_ancestor_tasks(task, @tasks[parent_task])
      end
    end

    # Set the alternatives of the task.
    # Alternatives are the nearest ancestors, which are used in permission definitions.
    #
    # @param [Task] task The task for which the alternatives are set
    # @param [Task] ancestor The ancestor to process. This is the recursive parameter
    def set_alternative_tasks(task, ancestor = nil)
      (ancestor || task).options[:is].each do |task_name|
        if @permissions.key? task_name
          (@tasks[task_name].options[:alternatives] ||= []) << task.name
        else
          set_alternative_tasks(task, @tasks[task_name])
        end
      end
    end

    # Flattens the roles. It sets all descendants of a role.
    def process_roles
      @roles.each_value {|role| set_descendant_roles(role)}
    end

    # Set the descendant_role as a descendant of the ancestor
    def set_descendant_roles(descendant_role, ancestor_role = nil)
      role = ancestor_role || descendant_role
      return unless role[:is]

      role[:is].each do |role_name|
        (@roles[role_name][:descendants] ||= []) << descendant_role[:name]
        set_descendant_roles(descendant_role, @roles[role_name])
      end
    end

    # InternalRole because otherwise it might conflict with other Role classes
    InternalRole = Struct.new('InternalRole', :name, :options)
    Task = Struct.new('Task', :name, :options)

    class Permission
      attr_reader :role, :task, :model, :options
      def initialize(role, task, model, options)
        @role, @task, @model = role, task, model
        @options = Hash.new {|h,k| h[k]=[]}
        @options[:if] = Hash.new {|h,k| h[k]=[]}

        load_options(options)
        load_options(@role.options)
      end

      def load_options(options)
        return unless options.is_a? Hash
        [:on].each do |key|
          @options[key] << options[key] if options.key? key
        end
        add_if(options[:if])
      end

      def add_if(options)
        case options
        when Hash then @options[:if].update(options)
        when Array then options.each { |entry| add_if(entry) }
        when String then @options[:if][:string] << options
        end
      end

      # Load the options of the task and all ancestor tasks.
      # The tasks are not necessarily accessable at the creation of the permission.
      #
      # @param parser[Parser] the parser which provides the tasks
      def load_task_options(parser)
        return if @loaded_task_options || parser.tasks[@task].nil?
        load_options(parser.tasks[@task].options)
        parser.tasks[@task].options[:ancestors].each do |task|
          load_options(parser.tasks[task].options)
        end
        @loaded_task_options = true
      end

    end

  end
end
