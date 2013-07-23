require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

sysop_role = Memory::Role.new('sysop')
admin_role = Memory::Role.new('admin')
alternative_admin_role = Memory::Role.new('alternative_admin')
author_role = Memory::Role.new('author','Memory::Site',1)
class_author_role = Memory::Role.new('author','Memory::Site')
general_author_role = Memory::Role.new('author')
alternative_author_role = Memory::Role.new('alternative_author','Memory::Site',1)
moderator_author_role = Memory::Role.new('moderator_author')
site_admin_role = Memory::Role.new('site_admin','Memory::Site',1)
malformed_site_admin_role = Memory::Role.new('site_admin','site',1)
moderator_role = Memory::Role.new('moderator')
user_role = Memory::Role.new('user')
guest_role = Memory::Role.new('guest')

sysop = Memory::User.new(1,[sysop_role])
admin = Memory::User.new(2,[admin_role])
alternative_admin = Memory::User.new(2,[alternative_admin_role])
author = Memory::User.new(3,[author_role])
class_author = Memory::User.new(3,[class_author_role])
general_author = Memory::User.new(3,[general_author_role])
alternative_author = Memory::User.new(3,[alternative_author_role])
moderator = Memory::User.new(4,[moderator_role])
moderator_author = Memory::User.new(3,[moderator_author_role])
site_admin = Memory::User.new(3,[site_admin_role])
malformed_site_admin = Memory::User.new(3,[malformed_site_admin_role])
user = Memory::User.new(5, [user_role])

site = Memory::Site.new(1)
own_post = Memory::Post.new(1,site,3) # Memory::Post by author
other_authors_post = Memory::Post.new(3,site,2)
published_post = Memory::Post.new(4,site,3,true)
comment = Memory::Comment.new(1,site,own_post)
comment_on_published_post = Memory::Comment.new(1,site,published_post)

other_site = Memory::Site.new(2)
other_post = Memory::Post.new(2,other_site,2)
other_comment = Memory::Comment.new(2,other_site,other_post)

describe "RoleAuth in memory" do
  before :all do
    Comment = Memory::Comment
    Site = Memory::Site
    Role = Memory::Role
    Post = Memory::Post
    User = Memory::User
    load_authorization_file
    @site = site
    @own_post = own_post
    @other_authors_post = other_authors_post
    @published_post = published_post
    @comment = comment
    @comment_on_published_post = comment_on_published_post
    @other_site = other_site
    @other_post = other_post
    @other_comment = other_comment
  end

  def update_attributes(object, *attr)
    object.updated_attributes = attr
  end

  describe 'admin' do
    include_context "admin_role"
    before(:all){ User.current = admin }
  end

  describe 'alternative admin' do
    include_context "admin_role"
    before(:all){ User.current = alternative_admin }
  end

  describe 'author on site instance' do
    include_context "author_role"
    before(:all){ User.current = author }
  end

  describe 'author on site class' do
    include_context "class_author_role"
    before(:all){ User.current = class_author }
  end

  describe 'author' do
    include_context "general_author_role"
    before(:all){ User.current = general_author }
  end

  describe 'alternative author' do
    include_context "author_role"
    before(:all){ User.current = alternative_author }
  end

  describe 'moderator author' do
    include_context "moderator_author_role"
    before(:all){ User.current = moderator_author }
  end

  describe 'site admin' do
    include_context "site_admin_role"
    before(:all) { User.current = site_admin}
  end

  describe 'malformed site admin' do
    include_context "malformed_site_admin_role"
    before(:all) { User.current = malformed_site_admin}
  end

  describe 'moderator' do
    include_context "moderator_role"
    before(:all){ User.current = moderator }
  end

  describe 'sysop' do
    include_context "sysop_role"
    before(:all){ User.current = sysop }
  end

  describe 'user' do
    include_context "user_role"
    before(:all){ User.current = user }
  end
end
