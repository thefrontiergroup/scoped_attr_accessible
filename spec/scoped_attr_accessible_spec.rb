require 'spec_helper'
require 'active_model'

describe ScopedAttrAccessible do

  it 'should automatically mix it in when hijacked' do
    ScopedAttrAccessible.mixin!
    klass = Class.new { include ActiveModel::MassAssignmentSecurity }
    klass.ancestors.include?(ActiveModel::MassAssignmentSecurity).should be_true
    klass.ancestors.include?(ScopedAttrAccessible::ActiveModelMixin).should be_true
    klass.should respond_to(:with_sanitizer_scope)
    klass.new.should respond_to(:current_sanitizer_scope)
  end

  it 'should let you set the current global sanitizer scope permanently' do
    begin
      old = ScopedAttrAccessible.current_sanitizer_scope
      ScopedAttrAccessible.current_sanitizer_scope  = :a
      ScopedAttrAccessible.current_sanitizer_scope.should == :a
      ScopedAttrAccessible.current_sanitizer_scope = {:a => 1}
      ScopedAttrAccessible.current_sanitizer_scope.should == {:a => 1}
    ensure
      ScopedAttrAccessible.current_sanitizer_scope = old
    end
  end

  it 'should let you temporary replace the sanitizer scope' do
    begin
      old = ScopedAttrAccessible.current_sanitizer_scope
      ScopedAttrAccessible.current_sanitizer_scope = :before_scope
      ScopedAttrAccessible.current_sanitizer_scope.should == :before_scope
      called = false
      ScopedAttrAccessible.with_sanitizer_scope :between do
        called = true
        ScopedAttrAccessible.current_sanitizer_scope.should == :between
      end
      called.should == true
      ScopedAttrAccessible.current_sanitizer_scope.should == :before_scope
    ensure
      ScopedAttrAccessible.current_sanitizer_scope = old
    end

  end

end