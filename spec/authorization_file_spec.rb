require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'authorization2' do
  before(:all) do
    User = Memory::User
    load_authorization_file('authorization2')
    sysop_role = Memory::Role.new('sysop')
    Memory::User.current = Memory::User.new(1,[sysop_role])
  end
  it 'should define default actions :create, :delete, :update' do
    can?(:create, Memory::Site).should be_true
    can?(:update, Memory::Site).should be_true
    can?(:delete, Memory::Site).should be_true
  end

  it 'should not raise on uninitialised method' do
    lambda { can?(:praise, Memory::Site) }.should_not raise_error
  end
end

describe 'authorization3' do

  before(:all) do
    User = Memory::User
    load_authorization_file('authorization3')
    role = Memory::Role.new('user')
    Memory::User.current = Memory::User.new(1,[role])
  end

  it 'should override update' do
    site = Memory::Site
    can?(:update, Memory::Post.new(1, site, 2)).should be_false
    can?(:update, Memory::Post.new(1, site, 1)).should be_true
  end

  it 'should accept class as argument' do
    can?(:create, Memory::Post).should be_true
  end

  it 'should handle User classes gracefully' do
    can?(:create, User).should be_true
  end

end

describe 'authorization4' do

  before(:all) do
    User = Memory::User
    load_authorization_file('authorization4')
    role = Memory::Role.new('user')
    Memory::User.current = Memory::User.new(1,[role])
  end

  it 'can_not has precidence over can' do
    can?(:create, Memory::Site).should be_false
    can?(:create, Memory::Role).should be_false
    can?(:create, Memory::Post).should be_false
    can?(:delete, Memory::Site).should be_nil
  end

end
