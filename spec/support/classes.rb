module Memory
  class User < Struct.new('User',:id, :roles)
    include RoleAuth::UserClassMethods
  end

  class Role < Struct.new('Role', :name, :type, :object_id)
  end

  class Site < Struct.new('Site',:id)
  end

  class Post < Struct.new('Post',:id, :site, :user_id, :published)
    attr_accessor :updated_attributes
    def updated_attributes
      @updated_attributes ||= []
    end
  end

  class Comment < Struct.new('Comment', :id, :site, :post)
    attr_accessor :updated_attributes
    def updated_attributes
      @updated_attributes ||= []
    end
  end
end

RoleAuth.config= { :user_class => 'DataMapper::User' }

module DataMapper
  class User
    include RoleAuth::UserClassMethods
    include DataMapper::Resource
    property :id,         Serial

    has n, :roles
    has n, :posts
  end
  class Site
    include DataMapper::Resource
    property :id,         Serial

    has n, :posts
    has n, :comments
  end
  class Post
    include DataMapper::Resource

    property :id,         Serial
    property :content, Text
    property :published, Boolean
    property :site_id, Integer
    property :user_id, Integer

    belongs_to :site
    belongs_to :user

    check_permission_before(:initialize, :create, :update, :destroy, :on => Site)
  end
  class Role
    include DataMapper::Resource
    property :id,         Serial
    property :name, String
    property :type, String
    property :object_id, Integer
    property :user_id, Integer

    belongs_to :user
  end
  class Comment
    include DataMapper::Resource
    property :id,         Serial
    property :content, Text
    property :published, Boolean
    property :site_id, Integer
    property :post_id, Integer

    belongs_to :site
    belongs_to :post
  end
end
