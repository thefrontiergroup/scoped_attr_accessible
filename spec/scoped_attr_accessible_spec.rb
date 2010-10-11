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
  
end