role :user do
  can :update, :create, Memory::Post, Memory::User
end

task :update, :if => is_owner
