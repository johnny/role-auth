role :sysop do
  can :create, :update, :delete, :any
end

role :admin do
  can :do, Post, Comment, Site
end

role :alternative_admin do
  can :do, :any
  can_not :do, Role
end

role :author, :on => Site do
  is :user

  can :create, Post
  can :update, Post, :if => only_changed(:content)
  can :update, :delete, Post, :if => [is_owner, %{!post.published}]
  can :publish, Comment, :if => %{ comment.post.published }
end

role :alternative_author, :on => Site do
  is :user

  can :create, :update_and_delete, Post
  can :publish, Comment, :if => %{ comment.post.published }
end

role :moderator do
  is :user

  can :publish, Post
  can :moderate, Comment
end

role :site_admin, :on => Site do
  is :moderator
  is :author

  can :delete, Comment
  can :update, Site # Document
end

role :moderator_author do
  is :author, :moderator

  can :create_and_publish, Post
end

role :user do
  can :create, Comment
  can :push, Comment
end

task :push

task :publish, :is => :update, :if => only_changed(:published)

task :moderate, :is => :update, :if => %{ user.can?(:publish, comment.post) }

task :create_update_own, :is => [:create, :update], :if => is_owner

task :create_and_publish, :is => :create_update_own, :if => only_changed(:published, :content)

task :update_and_delete, :is => [:update, :delete], :if => [is_owner, %{ !post.published}, only_changed(:content)]

task :build
