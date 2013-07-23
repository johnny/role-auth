require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

sysop = DataMapper::User.create
admin = DataMapper::User.create
alternative_admin = DataMapper::User.create
author = DataMapper::User.create
class_author = DataMapper::User.create
general_author = DataMapper::User.create
alternative_author = DataMapper::User.create
moderator = DataMapper::User.create
moderator_author = DataMapper::User.create
site_admin = DataMapper::User.create
user = DataMapper::User.create

sysop_role = DataMapper::Role.create(:name => 'sysop', :user => sysop)
admin_role = DataMapper::Role.create(:name => 'admin', :user => admin)
alternative_admin_role = DataMapper::Role.create(:name => 'alternative_admin', :user => alternative_admin)
author_role = DataMapper::Role.create(:name =>'author', :type => 'DataMapper::Site', :object_id => 1, :user => author)
general_author_role = DataMapper::Role.create(:name =>'author', :user => general_author)
class_author_role = DataMapper::Role.create(:name =>'author', :type => 'DataMapper::Site', :user => class_author)
alternative_author_role = DataMapper::Role.create(:name => 'alternative_author', :type => 'DataMapper::Site', :object_id => 1, :user => alternative_author)
moderator_author_role = DataMapper::Role.create(:name => 'moderator_author', :user => moderator_author)
moderator_role = DataMapper::Role.create(:name => 'moderator', :user => moderator)
site_admin_role = DataMapper::Role.create(:name => 'site_admin', :type => 'DataMapper::Site', :object_id => 1, :user => site_admin)
user_role = DataMapper::Role.create(:name => 'user', :user => user)
# guest_role = DataMapper::Role.new('guest')

site = DataMapper::Site.create

own_post = DataMapper::Post.create(:site_id => site.id, :user => author)
other_authors_post = DataMapper::Post.create(:site_id => site.id, :user => sysop)
published_post = DataMapper::Post.create(:site => site, :user => author, :published => true)
comment = DataMapper::Comment.create(:site => site, :post => own_post)
comment_on_published_post = DataMapper::Comment.create(:site => site, :post => published_post)

other_site = DataMapper::Site.create

other_post = DataMapper::Post.create(:site => other_site, :user => author)
other_comment = DataMapper::Comment.create(:site => other_site, :post => other_post)

describe "RoleAuth DataMapper" do
  before :all do
    Comment = DataMapper::Comment
    Site = DataMapper::Site
    Role = DataMapper::Role
    Post = DataMapper::Post
    User = DataMapper::User
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

  before :each do
    @own_post.reload
  end

  after :all do
    User.current = nil
  end

  def update_attributes(object, *attrs)
    object.reload
    attrs.each do |attr|
      case attr
        when :content then object.content = Time.now.to_s
        when :published then object.published = !object.published
        when :user_id then object.user_id = (User.current.id + 1)
      end
    end
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

  describe 'author on Site class' do
    include_context "class_author_role"
    before(:all) do
      User.current = nil
      @own_post = DataMapper::Post.create(:site_id => site.id, :user => class_author)
      @comment = DataMapper::Comment.create(:site => site, :post => @own_post)
      @published_post = DataMapper::Post.create(:site => site, :user => class_author, :published => true)
      User.current = class_author
    end
  end

  describe 'author' do
    include_context "general_author_role"
    before(:all) do
      User.current = nil
      @own_post = DataMapper::Post.create(:site_id => site.id, :user => general_author)
      @comment = DataMapper::Comment.create(:site => site, :post => @own_post)
      @published_post = DataMapper::Post.create(:site => site, :user => general_author, :published => true)
      User.current = general_author
    end
  end

  describe 'alternative author' do
    include_context "author_role"
    before(:all) do
      User.current = alternative_author
      @own_post = DataMapper::Post.create(:site => site, :user => alternative_author)
      @published_post = DataMapper::Post.create(:site => site, :user => alternative_author, :published => true)
      @comment = DataMapper::Comment.create(:site => site, :post => @own_post)
      @comment_on_published_post = DataMapper::Comment.create(:site => site, :post => @published_post)
    end
  end

  describe 'moderator author' do
    include_context "moderator_author_role"
    before(:all) do
      User.current = moderator_author
      @own_post = DataMapper::Post.create(:site => site, :user => moderator_author)
      @published_post = DataMapper::Post.create(:site => site, :user => moderator_author, :published => true)
      @comment = DataMapper::Comment.create(:site => site, :post => @own_post)
      @comment_on_published_post = DataMapper::Comment.create(:site => site, :post => @published_post)
    end
  end

  describe 'moderator' do
    include_context "moderator_role"
    before(:all) do
      User.current = nil
      @own_post = DataMapper::Post.create(:site_id => site.id, :user => moderator)
      @comment = DataMapper::Comment.create(:site => site, :post => @own_post)
      User.current = moderator
    end
  end

  describe 'site admin' do
    include_context "site_admin_role"
    before :all do
      User.current = site_admin
      @own_post = DataMapper::Post.create(:site_id => site.id, :user => site_admin)
      @comment = DataMapper::Comment.create(:site => site, :post => @own_post)
    end
  end

  describe 'sysop' do
    include_context "sysop_role"
    before(:all){ User.current = sysop }
  end

  describe 'user' do
    include_context "user_role"
    before(:all){ User.current = user }
  end

  describe 'callbacks' do
    def create_post(options = {})
      lambda {Post.create({:user => User.current}.merge(options))}
    end
    def new_post(options = {})
      lambda {Post.new({:user => User.current}.merge(options))}
    end
    def update(post, options = {})
      lambda {post.reload.update(options)}
    end
    def destroy(post)
      lambda {post.destroy}
    end
    it 'should work with create' do
      User.current = user
      create_post(:site => site).should raise_error
      User.current = author
      create_post(:site => site).should_not raise_error
      create_post(:site_id => site.id).should_not raise_error
      create_post(:site => other_site).should raise_error
      create_post.should raise_error
      User.current = moderator_author
      create_post(:site => site).should_not raise_error
      create_post(:site => other_site).should_not raise_error
    end
    it 'should work with destroy' do
      post = Post.create(:user => author, :site => site)
      published_post = Post.create(:user => author, :site => site, :published => true)
      other_post = Post.create(:user => moderator_author, :site => site)

      User.current = user
      destroy(post).should raise_error

      User.current = author
      destroy(post).should_not raise_error
      destroy(published_post).should raise_error
      destroy(other_post).should raise_error

      User.current = moderator_author
      destroy(other_post).should_not raise_error
      destroy(published_post).should raise_error

      User.current = admin
      destroy(published_post).should_not raise_error
    end
    it 'should work with initialize' do
      User.current = user
      new_post(:site => site).should raise_error
      User.current = author
      new_post(:site => site).should_not raise_error
      new_post(:site_id => site.id).should_not raise_error
      new_post(:site => other_site).should raise_error
      new_post.should raise_error
      User.current = moderator_author
      new_post(:site => site).should_not raise_error
      new_post(:site => other_site).should_not raise_error
    end
    it 'should work with update' do
      post = Post.create(:user => user, :site => site)
      other_post = Post.create(:user => moderator_author, :site => site)
      published_post = Post.create(:user => author, :site => site, :published => true)

      User.current = user
      update(post, :content => rands).should raise_error
      User.current = author
      post = Post.create(:user => author, :site => site)
      update(post, :content => rands).should_not raise_error
      update(post).should_not raise_error
      update(post, :content => rands, :published => true).should raise_error
      update(post, :published => true).should raise_error
      update(published_post, :content => rands).should raise_error
      update(published_post).should_not raise_error
      User.current = moderator_author
      update(post, :published => true).should_not raise_error
      update(post, :content => rands).should raise_error
      update(published_post, :published => false).should_not raise_error
      update(other_post, :published => true, :content => rands).should_not raise_error
    end

    def rands
      (rand*Time.now.to_i).to_s
    end
  end
end
