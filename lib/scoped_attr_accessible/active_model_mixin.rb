require 'active_support/concern'
require 'active_support/core_ext/class/inheritable_attributes'
require 'active_support/core_ext/array/extract_options'

module ScopedAttrAccessible
  module ActiveModelMixin    
    extend ActiveSupport::Concern
    
    
    module IncludedHook
      def included(base)
        super
        base.class_eval { include ActiveModelMixin }
      end
    end
    
    included do
      extlib_inheritable_accessor :_scoped_attr_sanitizer
    end
    
    module ClassMethods
      
      def attr_accessible(*args)
        scopes    = scopes_from_args(args)
        sanitizer = self.scoped_attr_sanitizer
        args.each do |attribute|
          scopes.each { |s| sanitizer.make_accessible attribute, s }
        end
        self._active_authorizer = sanitizer
      end
      
      def attr_protected(*args)
        scopes    = scopes_from_args(args)
        sanitizer = self.scoped_attr_sanitizer
        args.each do |attribute|
          scopes.each { |s| sanitizer.make_protected attribute, s }
        end
        self._active_authorizer = sanitizer
      end
      
      def scoped_attr_sanitizer
        self._scoped_attr_sanitizer ||= ScopedAttrAccessible::Sanitizer.new
      end
      
      def current_sanitizer_scope
        Thread.current[current_sanitizer_scope_key]
      end
      
      def current_sanitizer_scope=(value)
        Thread.current[current_sanitizer_scope_key] = value
      end
      
      def with_sanitizer_scope(scope_name)
        old_scope = current_sanitizer_scope
        self.current_sanitizer_scope = scope_name
        yield if block_given?
      ensure
        self.current_sanitizer_scope = old_scope
      end
      
      def sanitizer_scope_recognizer(name, &recognizer)
        scoped_attr_sanitizer.define_recognizer(name, &recognizer)
      end
      
      def sanitizer_scope_converter(&converter)
        scoped_attr_sanitizer.define_converter(&converter)
      end
      
      protected
      
      def current_sanitizer_scope_key
        :"#{name}_sanitizer_scope"
      end
      
      def scopes_from_args(args)
        options = args.extract_options!
        scope   = Array(options.delete(:scope)).map(&:to_sym)
        scope  << :default if scope.empty?
        args   << options unless options.empty?
        scope
      end
      
    end
    
    module InstanceMethods

      def current_sanitizer_scope
        @current_sanitizer_scope || self.class.current_sanitizer_scope
      end

      def current_sanitizer_scope=(value)
        @current_sanitizer_scope = value
      end

      protected

      def sanitize_for_mass_assignment(attributes)
        authorizer = self.mass_assignment_authorizer
        if authorizer.respond_to?(:sanitize_with_scope)
          authorizer.sanitize_with_scope attributes, current_sanitizer_scope, self
        else
          super
        end
      end

    end
    
  end
end