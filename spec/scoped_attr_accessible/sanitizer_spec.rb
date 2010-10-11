require 'spec_helper'

describe ScopedAttrAccessible::Sanitizer do
  
  let :complex_sanitizer_one do
    ScopedAttrAccessible::Sanitizer.new.tap do |s|
      s.make_protected  :a, :default
      s.make_protected  :b, :default
      s.make_accessible :all, :default
      s.make_protected  :a, :admin
      s.make_accessible :all, :admin
    end
  end
  
  let :complex_sanitizer_two do
    ScopedAttrAccessible::Sanitizer.new.tap do |s|
      s.make_protected  :d, :admin
      s.make_accessible :all, :admin
      s.make_accessible :a, :default
      s.make_accessible :b, :default
    end
  end
  
  let :example_attributes_one do
    {:a => 'a', :b => 'c', :c => 'c', :d => 'd', :e => 'e'}
  end
  
  let :example_attributes_two do
    {'a' => 'a', 'b' => 'c', 'c' => 'c', 'd' => 'd'}
  end
  
  context 'normalizing scopes' do
    
    subject { ScopedAttrAccessible::Sanitizer.new }
    
    before :each do
      subject.define_recognizer :a do |context, object|
        object.to_s == "a" || context == "test context a"
      end
      subject.define_recognizer :b do |context, object|
        object.to_s == "b" || context == "test context b"
      end
      subject.define_converter do |context, object|
        return :number  if object.is_a?(Numeric)
        return :admin   if !object.nil? && %(admin darcy).include?(object)
        return :awesome if context == "another test context"
      end
    end
    
    it 'should return the argument if passed a symbol' do
      subject.normalize_scope(:a, nil).should == :a
      subject.normalize_scope(:another, nil).should == :another
    end
    
    it 'should let you provide optional context' do
      subject.normalize_scope(nil, "test context a").should == :a
      subject.normalize_scope(nil, "test context b").should == :b
      subject.normalize_scope(nil, "another test context").should == :awesome
    end
    
    it 'should use recognizers in an attempt to find a scope' do
      subject.normalize_scope("a", nil).should == :a
      subject.normalize_scope("b", nil).should == :b
    end
    
    it 'should use converters in an attempt to find a scope' do
      subject.normalize_scope(2, nil).should   == :number
      subject.normalize_scope(3.0, nil).should == :number
      subject.normalize_scope('admin', nil).should == :admin
      subject.normalize_scope('darcy', nil).should == :admin
    end
    
    it 'should return default when the item is unknown' do
      subject.normalize_scope("unknown item here", nil).should == :default
    end
    
  end
  
  context 'marking attributes availability' do
    
    def allow(*args)
      be_allow(*args)
    end
    
    let :empty_sanitizer do
      ScopedAttrAccessible::Sanitizer.new
    end
    
    let :accessible_sanitizer do
      ScopedAttrAccessible::Sanitizer.new.tap do |s|
        s.make_accessible :a, :default
        s.make_accessible :b, :default
        s.make_accessible :c, :admin
      end
    end
    
    let :protected_sanitizer do
      ScopedAttrAccessible::Sanitizer.new.tap do |s|
        s.make_protected :a, :default
        s.make_protected :b, :default
        s.make_protected :c, :admin
      end
    end
        
    it 'should return true by default an empty list' do
      empty_sanitizer.should allow(:a)
      empty_sanitizer.should allow(:b)
      empty_sanitizer.should allow(:c)
      empty_sanitizer.should allow(:d)
      empty_sanitizer.should allow(:a, :admin)
      empty_sanitizer.should allow(:b, :admin)
      empty_sanitizer.should allow(:c, :admin)
      empty_sanitizer.should allow(:d, :admin)
    end
    
    it 'should return false by default with an unknown attribute and an accessible list' do
      accessible_sanitizer.should_not allow(:d)
      accessible_sanitizer.should_not allow(:d, :admin)
      accessible_sanitizer.should_not allow(:c)
      accessible_sanitizer.should_not allow(:a, :admin)
      accessible_sanitizer.should_not allow(:b, :admin)
    end
    
    it 'should return false when it is protected' do
      protected_sanitizer.should_not allow(:a, :default)
      protected_sanitizer.should_not allow(:b, :default)
      protected_sanitizer.should_not allow(:c, :admin)
    end
    
    it 'should work with a string' do
      complex_sanitizer_two.should allow('a')
      complex_sanitizer_two.should allow('b')
      complex_sanitizer_two.should_not allow('d', :admin)
      complex_sanitizer_two.should allow('a', :admin)
    end
    
    it 'should return true if it is in the accessible' do
      accessible_sanitizer.should allow(:a)
      accessible_sanitizer.should allow(:b)
      accessible_sanitizer.should allow(:c, :admin)
      accessible_sanitizer.should_not allow(:d)
      accessible_sanitizer.should_not allow(:d, :admin)
    end
    
    it 'should return true if all are accessible' do
      complex_sanitizer_one.should_not allow(:a)
      complex_sanitizer_one.should_not allow(:b)
      complex_sanitizer_one.should allow(:c)
      complex_sanitizer_one.should allow(:d)
      complex_sanitizer_one.should_not allow(:a, :admin)
      complex_sanitizer_one.should allow(:b, :admin)
      complex_sanitizer_one.should allow(:c, :admin)
      complex_sanitizer_one.should allow(:d, :admin)
    end
    
  end
  
  context 'sanitize_with_scope' do
    
    it 'should remove protected attributes' do
      complex_sanitizer_one.sanitize_with_scope(example_attributes_one, :default,  nil).should only_have_attributes('c', 'd', 'e')
      complex_sanitizer_one.sanitize_with_scope(example_attributes_one, :admin, nil).should    only_have_attributes('b', 'c', 'd', 'e')
      complex_sanitizer_two.sanitize_with_scope(example_attributes_one, :default, nil).should  only_have_attributes('a', 'b')
    end
    
  end
  
  context 'sanitize' do
    
    subject { ScopedAttrAccessible::Sanitizer.new }
    
    it 'should call with the default scope' do
      mock(subject).sanitize_with_scope example_attributes_one, :default, anything
      subject.sanitize example_attributes_one
    end
    
    it 'should let you provide a context' do
      my_context = 42
      mock(subject).sanitize_with_scope example_attributes_one, :default, my_context
      subject.sanitize example_attributes_one, my_context
    end
    
  end
  
end 