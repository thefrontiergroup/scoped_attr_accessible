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
  
end