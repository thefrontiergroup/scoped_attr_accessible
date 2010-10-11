require 'set'

module ScopedAttrAccessible
  class Sanitizer
    
    def initialize
      @accessible_attributes = Hash.new { |h,k| h[k] = Set.new }
      @protected_attributes  = Hash.new { |h,k| h[k] = Set.new }
      # Scope recognizers return a boolean, with a hash key
      @scope_recognizers     = Hash.new { |h,k| h[k] = [] }
      # Returns a scope symbol.
      @scope_converters      = []
    end
    
    # Looks up a scope name from the registered recognizers and then from the converters.
    def normalize_scope(object, context)
      return object if object.is_a?(Symbol)
      # 1. Process recognizers, looking for a match.
      @scope_recognizers.each_pair do |name, recognizers|
        return name if recognizers.any? { |r| lambda(&r).call(context, object) }
      end
      # 2. Process converters, finding a result.
      @scope_converters.each do |converter|
        scope = lambda(&converter).call(context, object)
        return normalize_scope(scope, converter) unless scope.nil?
      end
      # 3. Fall back to default
      return :default
    end
    
    def sanitize(attributes, context = Object.new)
      sanitize_with_scope attributes, :default, context
    end
    
    def sanitize_with_scope(attributes, scope, context)
      scope = normalize_scope scope, context
      attributes.reject { |k, v| deny? k, scope }
    end
    
    def define_recognizer(scope, &blk)
      @scope_recognizers[scope.to_sym] << blk
    end
    
    def define_converter(&blk)
      @scope_converters << blk
    end
    
    def make_protected(attribute, scope = :default)
      @protected_attributes[scope.to_sym] << attribute.to_s
    end
    
    def make_accessible(attribute, scope = :default)
      @accessible_attributes[scope.to_sym] << attribute.to_s
    end
    
    def deny?(attribute, scope = :default)
      !attribute_assignable_with_scope?(attribute, scope)
    end
    
    def allow?(attribute, scope = :default)
      attribute_assignable_with_scope?(attribute, scope)
    end
    
    def attribute_assignable_with_scope?(attribute, scope)
      attribute = attribute.to_s.gsub(/\(.+/, '')
      scope     = scope.to_sym
      scope_protected, scope_accessible = @protected_attributes[scope], @accessible_attributes[scope]
      if scope_protected.include? attribute
        return false
      elsif scope_accessible.include?('all') || scope_accessible.include?(attribute)
        return true
      elsif !scope_accessible.empty?
        return false
      else
        return true
      end
    end
    
  end
end