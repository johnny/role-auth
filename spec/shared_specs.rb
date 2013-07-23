shared_examples "user_role" do
  it 'should behave like user' do
    #is?(:user, :on => @site).should be_true
    #is?(:user).should be_true

    can?(:create, Comment.new).should be_true
    can?(:push, Comment.new).should be_true
  end
end
shared_examples "admin_role" do
  it "should behave like admin" do

    can?(:build, Post).should be_true

    can?(:create, Post.new).should be_true
    can?(:create, Role.new).should be_false
    can?(:create, Comment.new).should be_true
    can?(:create, Site.new).should be_true

    can?(:update, @own_post).should be_true

    can?(:publish, @own_post).should be_true
  end
end

shared_examples "shared_author_role" do
  include_context "user_role"
  it 'should behave like all authors' do
    update_attributes(@own_post, :content)

    can?(:update, @own_post).should be_true

    update_attributes(@other_authors_post, :content)
    can?(:update, @other_authors_post).should be_false

    can?(:publish, @comment).should be_false
    can?(:publish, @comment_on_published_post).should be_true
    can?(:publish, @other_comment).should be_false

    can?(:delete, @own_post).should be_true
    can?(:delete, @other_authors_post).should be_false
    can?(:delete, @published_post).should be_false
  end
end

shared_examples "author_role" do
  include_context "shared_author_role"
  it "should behave like author" do
    user, User.current = User.current, nil
    post = Post.new
    User.current = user
    can?(:create, post).should be_false
    can?(:create, post, :on => @site).should be_true
    can?(:create, post, :on => @other_site).should be_false
    can?(:create, @own_post).should be_true
    can?(:create, @other_post).should be_false

    can?(:update, @own_post).should be_true
    can?(:update, @published_post).should be_false

    update_attributes(@own_post, :published)
    can?(:update, @own_post).should be_false
  end
end

shared_examples "general_author_role" do
  include_context "shared_author_role"
  it 'should behave like general author' do
    is?(:author, :on => @site).should be_true
    is?(:author, :on => @other_site).should be_true
    is?(:author).should be_true

    user, User.current = User.current, nil
    post = Post.new
    User.current = user
    can?(:create, post).should be_true
    can?(:create, post, :on => @site).should be_true
    can?(:create, post, :on => @other_site).should be_true

    can?(:update, @own_post).should be_true
    can?(:update, @published_post).should be_false

    update_attributes(@own_post, :published)
    can?(:update, @own_post).should be_false
  end
end

shared_examples "class_author_role" do
  include_context "shared_author_role"
  it 'should behave like class author' do
    user, User.current = User.current, nil
    post = Post.new
    User.current = user
    can?(:create, post).should be_false
    can?(:create, post, :on => @site).should be_true
    can?(:create, post, :on => @other_site).should be_true

    can?(:update, @own_post).should be_true
    can?(:update, @published_post).should be_false

    update_attributes(@own_post, :published)
    can?(:update, @own_post).should be_false
  end
end

shared_examples "shared_moderator_role" do
  it 'should behave like all moderators' do
    is?(:moderator, :on => @site).should be_true
    is?(:moderator, :on => Comment.new).should be_true
    is?(:moderator).should be_true

    update_attributes(@own_post)
    can?(:update, @own_post).should be_true
    can?(:update, @published_post).should be_true

    update_attributes(@other_post, :published)
    can?(:publish, @other_post).should be_true
    can?(:update, @other_post).should be_true
    can?(:moderate, @other_comment).should be_true
    can?(:update, @other_comment).should be_true

    update_attributes(@own_post, :published)
    can?(:publish, @own_post).should be_true
    can?(:update, @own_post).should be_true
    can?(:moderate, @comment).should be_true
    can?(:update, @comment).should be_true

    update_attributes(@own_post, :published, :user_id)
    can?(:publish, @own_post).should be_false
  end
end

shared_examples "site_admin_role" do
  include_context "shared_author_role"
  include_context "shared_moderator_role"
  it 'should behave like site admin' do
    is?(:site_admin, :on => @site).should be_true
    is?(:site_admin, :on => @other_site).should be_false
    comment = Comment.new
    comment.id = @site.id
    is?(:site_admin, :on => comment).should be_false
    is?(:site_admin).should be_false

    can?(:update, @site).should be_true
    can?(:delete, @site).should be_false

    user, User.current = User.current, nil
    post = Post.new
    User.current = user
    can?(:create, post).should be_false
    can?(:create, post, :on => @site).should be_true
    can?(:create, post, :on => @other_site).should be_false
    can?(:create, @own_post).should be_true
    can?(:create, @other_post).should be_false

    update_attributes(@own_post, :published, :content)
    can?(:create, @own_post).should be_true

    can?(:delete, @comment).should be_true
    can?(:delete, @other_comment).should be_false
  end
end

shared_examples "malformed_site_admin_role" do
  it 'should not behave like site admin' do
    is?(:site_admin, :on => @site).should be_false
    is?(:site_admin, :on => @other_site).should be_false
  end
end

shared_examples "moderator_author_role" do
  include_context "shared_author_role"
  include_context "shared_moderator_role"
  it "should behave like moderator author" do
    is?(:moderator_author, :on => @site).should be_true
    is?(:moderator_author).should be_true

    is?(:author).should be_true
    is?(:author, :on => @site).should be_true

    can?(:create, Post.new).should be_true
    can?(:create, Post.new, :on => @site).should be_true
    can?(:create, Post.new, :on => @other_site).should be_true
    can?(:create, @own_post).should be_true
    can?(:create, @other_post).should be_true

    update_attributes(@own_post, :published, :content)
    can?(:create, @own_post).should be_true
  end
end

shared_examples "sysop_role" do
  it "should allow all normal options to sysop" do
    is?(:sysop).should be_true

    can?(:create, Post).should be_true
    can?(:create, Role).should be_true
    can?(:create, Comment.new).should be_true

    can?(:update, @own_post).should be_true

    can?(:publish, @own_post).should be_false
  end
end

shared_examples "moderator_role" do
  include_context "shared_moderator_role"
  it "should allow moderators to publish posts" do
    user, User.current = User.current, nil
    post = Post.new
    User.current = user
    can?(:create, user).should be_false
    can?(:create, user, :on => @site).should be_false
    can?(:create, user, :on => @other_site).should be_false

    update_attributes(@own_post, :content)
    can?(:publish, @own_post).should be_false
    can?(:update, @own_post).should be_false
    can?(:moderate, @comment).should be_false
    can?(:update, @comment).should be_false

    update_attributes(@own_post)
    can?(:delete, @own_post).should be_false
  end
end
