require 'spec_helper'

describe ScopedAttrAccessible::ActiveModelMixin do

  before :all do
    ScopedAttrAccessible.mixin!
  end

  subject { Class.new { include ActiveModel::MassAssignmentSecurity } }

  let(:subject_instance) { subject.new }

  context 'attr_accessible overrides' do

    before :each do
      @sanitizer = ScopedAttrAccessible::Sanitizer.new
      stub(subject).scoped_attr_sanitizer { @sanitizer }
    end

    it 'should call make_accessible' do
      mock(@sanitizer).make_accessible(:a, :x)
      subject.attr_accessible :a, :scope => :x
    end

    it 'should default the scope' do
      mock(@sanitizer).make_accessible(:a, :default)
      subject.attr_accessible :a
    end

    it 'should call it correctly when given multiple scopes' do
      mock(@sanitizer).make_accessible(:a, :admin)
      mock(@sanitizer).make_accessible(:a, :normal)
      subject.attr_accessible :a, :scope => [:admin, :normal]
    end

    it 'should call make_accessible for each attribute' do
      mock(@sanitizer).make_accessible(:a, :default)
      mock(@sanitizer).make_accessible(:b, :default)
      subject.attr_accessible :a, :b
    end

    it 'should set the active authorizer' do
      subject._active_authorizer = nil
      subject.attr_accessible :a, :b
      subject._active_authorizer.should == @sanitizer
    end

  end

  context 'attr_protected overrides' do

    before :each do
      @sanitizer = ScopedAttrAccessible::Sanitizer.new
      stub(subject).scoped_attr_sanitizer { @sanitizer }
    end

    it 'should call make_protected' do
      mock(@sanitizer).make_protected(:a, :x)
      subject.attr_protected :a, :scope => :x
    end

    it 'should default the scope' do
      mock(@sanitizer).make_protected(:a, :default)
      subject.attr_protected :a
    end

    it 'should call it correctly when given multiple scopes' do
      mock(@sanitizer).make_protected(:a, :admin)
      mock(@sanitizer).make_protected(:a, :normal)
      subject.attr_protected :a, :scope => [:admin, :normal]
    end

    it 'should call make_protected for each attribute' do
      mock(@sanitizer).make_protected(:a, :default)
      mock(@sanitizer).make_protected(:b, :default)
      subject.attr_protected :a, :b
    end

    it 'should set the active authorizer' do
      subject._active_authorizer = nil
      subject.attr_protected :a, :b
      subject._active_authorizer.should == @sanitizer
    end

  end

  context 'getting the current sanitizer' do

    it 'should create a new sanitizer if not present' do
      subject._scoped_attr_sanitizer = nil
      @sanitizer = ScopedAttrAccessible::Sanitizer.new
      mock(ScopedAttrAccessible::Sanitizer).new { @sanitizer }
      subject.scoped_attr_sanitizer.should equal(@sanitizer)
    end

    it 'should memoize the sanitizer' do
      sanitizer = subject.scoped_attr_sanitizer
      sanitizer_two = subject.scoped_attr_sanitizer
      sanitizer.should equal(sanitizer)
    end

  end

  context 'current sanitizer scope' do

    it 'should let you get the default sanitizer scope' do
      subject.current_sanitizer_scope.should be_nil
    end

    it 'should let you set the sanitizer scope' do
      subject.current_sanitizer_scope = :a
      subject.current_sanitizer_scope.should == :a
      subject.current_sanitizer_scope = :b
      subject.current_sanitizer_scope.should == :b
    end

    it 'should let you temporary change the sanitizer scope' do
      subject.current_sanitizer_scope = :before
      inner_called = false
      subject.with_sanitizer_scope :after do
        inner_called = true
        subject.current_sanitizer_scope.should == :after
      end
      inner_called.should be_true
    end

    it 'should reset the scope after a temporary change' do
      subject.current_sanitizer_scope = :before
      inner_called = false
      subject.with_sanitizer_scope :after do
        inner_called = true
      end
      inner_called.should be_true
      subject.current_sanitizer_scope.should == :before
    end

  end

  context 'instance level scoping' do

    before :each do
      subject.current_sanitizer_scope          = :class_level
      subject_instance.current_sanitizer_scope = :instance_level
    end

    it 'should use the instance scope if present' do
      subject_instance.current_sanitizer_scope.should == :instance_level
    end

    it 'should fallback to the class scope if the instance scope is not present' do
      subject_instance.current_sanitizer_scope = nil
      subject_instance.current_sanitizer_scope.should == :class_level
    end

    it 'should fallback to the global scope if others aren\'t set' do
      subject_instance.current_sanitizer_scope = nil
      subject.current_sanitizer_scope = nil
      called = false
      ScopedAttrAccessible.with_sanitizer_scope :global_scope do
        called = true
        subject_instance.current_sanitizer_scope.should == :global_scope
      end
      called.should be_true
    end

    it 'should fallback to default if no scope is set' do
      subject_instance.current_sanitizer_scope = nil
      subject.current_sanitizer_scope = nil
      subject_instance.current_sanitizer_scope.should == nil
    end

    it 'should let you assign the instance level scope' do
      subject_instance.current_sanitizer_scope = :after
      subject_instance.current_sanitizer_scope.should == :after
    end

  end

  context 'recognizers and converters' do

    before :each do
      @sanitizer = ScopedAttrAccessible::Sanitizer.new
      stub(subject).scoped_attr_sanitizer { @sanitizer }
    end

    it 'should call the sanitizers methods when defining a converter' do
      mock(@sanitizer).define_converter
      subject.sanitizer_scope_converter {}
    end

    it 'should call the sanitizers methods when defining a recognizer' do
      mock(@sanitizer).define_recognizer(:admin)
      subject.sanitizer_scope_recognizer(:admin) { }
    end

  end

  context 'hooking into the process' do

    subject do
      Class.new do
        include ActiveModel::MassAssignmentSecurity

        attr_accessible :a, :b, :c
        attr_accessible :a, :b, :c, :d, :scope => :owner
        attr_accessible :all,           :scope => :admin
        attr_protected :c, :d,          :scope => :guy_who_deletes_stuff

        def sanitized_keys_from(hash)
          sanitize_for_mass_assignment(hash).keys
        end
      end
    end

    let(:subject_instance) { subject.new }

    let :example_attributes do
      {'a' => 'a', 'b' => 'c', 'c' => 'c', 'd' => 'd', 'e' => 'e'}
    end

    it 'should return the correct attributes for the default scope' do
      subject_instance.current_sanitizer_scope = nil
      subject.current_sanitizer_scope          = nil
      subject_instance.sanitized_keys_from(example_attributes).should == %w(a b c)
    end

    it 'should return the correct attributes for the owner scope' do
      subject_instance.current_sanitizer_scope = :owner
      subject_instance.sanitized_keys_from(example_attributes).should == %w(a b c d)
    end

    it 'should return the correct attributes for the admin scope' do
      subject_instance.current_sanitizer_scope = :admin
      subject_instance.sanitized_keys_from(example_attributes).should == %w(a b c d e)
    end

    it 'should return the correct attributes for an unknown scope' do
      subject_instance.current_sanitizer_scope = :unknown_scope
      subject_instance.sanitized_keys_from(example_attributes).should == %w(a b c d e)
    end

    it 'should return the correct attributes for the guy_who_deletes_stuff scope' do
      subject_instance.current_sanitizer_scope = :guy_who_deletes_stuff
      subject_instance.sanitized_keys_from(example_attributes).should == %w(a b e)
    end

  end

  context 'tying it all together' do

    subject do
      Class.new do
        include ActiveModel::MassAssignmentSecurity

        attr_accessible :a, :b, :c
        attr_accessible :a, :b, :c, :d, :scope => :owner
        attr_accessible :all,           :scope => :admin
        attr_protected :c, :d,          :scope => :guy_who_deletes_stuff

        sanitizer_scope_recognizer :owner do |record, value|
          value.is_a?(Numeric)
        end

        sanitizer_scope_converter do |record, value|
          return :admin if value == "hola"
          return :guy_who_deletes_stuff if record.name == "Bob"
        end

        attr_accessor :name

        def sanitized_keys_from(hash)
          sanitize_for_mass_assignment(hash).keys
        end
      end
    end

    let(:subject_instance) { subject.new }

    let :example_attributes do
      {'a' => 'a', 'b' => 'c', 'c' => 'c', 'd' => 'd', 'e' => 'e'}
    end

    before :each do
      subject_instance.current_sanitizer_scope = nil
      subject.current_sanitizer_scope          = nil

    end

    it 'should return the correct attributes for the default scope' do
      subject_instance.sanitized_keys_from(example_attributes).should == %w(a b c)
    end

    it 'should return the correct attributes for the owner scope' do
      subject_instance.current_sanitizer_scope = 12
      subject_instance.sanitized_keys_from(example_attributes).should == %w(a b c d)
    end

    it 'should return the correct attributes for the admin scope' do
      subject_instance.current_sanitizer_scope = "hola"
      subject_instance.sanitized_keys_from(example_attributes).should == %w(a b c d e)
    end

    it 'should return the correct attributes for the guy_who_deletes_stuff scope' do
      subject_instance.name = "Bob"
      subject_instance.current_sanitizer_scope = "trigger-it"
      subject_instance.sanitized_keys_from(example_attributes).should == %w(a b e)
      subject_instance.name = nil
    end

    it 'should fallback if with a different sanitizer' do
      klass = Class.new(subject)
      klass._active_authorizer = nil
      instance = klass.new
      instance.sanitized_keys_from(example_attributes).should == %w(a b c d e)
    end

    it 'should not overwrite children class sanitizers' do
      klass = Class.new(subject)
      klass.attr_accessible :e, :scope => :owner
      subject.scoped_attr_sanitizer.sanitize_with_scope(example_attributes, :owner, nil).should only_have_attributes('a', 'b', 'c', 'd')
    end

  end

end