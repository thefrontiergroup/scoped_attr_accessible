require 'active_support/concern'

module ScopedAttrAccessible
  autoload :Sanitizer,        'scoped_attr_accessible/sanitizer'
  autoload :ActiveModelMixin, 'scoped_attr_accessible/active_model_mixin'

  # Mixes the am mixin into ActiveModel's mass assignment helpers.
  def self.mixin!
    require 'active_model/mass_assignment_security'
    ActiveModel::MassAssignmentSecurity.module_eval do
      extend ScopedAttrAccessible::ActiveModelMixin::IncludedHook
    end
  end

  GLOBAL_SCOPE_KEY = :_scoped_attr_accessible_sanitizer_scope

  def self.current_sanitizer_scope
    Thread.current[GLOBAL_SCOPE_KEY]
  end

  def self.current_sanitizer_scope=(value)
    Thread.current[GLOBAL_SCOPE_KEY] = value
  end

  def self.with_sanitizer_scope(scope)
    old_sanitizer_scope = self.current_sanitizer_scope
    self.current_sanitizer_scope = scope
    yield if block_given?
  ensure
    self.current_sanitizer_scope = old_sanitizer_scope
  end

  if defined?(Rails::Railtie)
    class Railtie < Rails::Railtie
      initializer "scoped_attr_accessible.setup" do
        ScopedAttrAccessible.mixin!
      end
    end
  end

end