# scoped\_attr\_accessible

scoped\_attr\_accessible is a plugin that makes it easy to scope the `attr_accessible` and `attr_protected`
methods on any library using ActiveModel's MassAssignmentSecurity module. For those unfamiliar with it,
[read here](http://api.rubyonrails.org/classes/ActiveModel/MassAssignmentSecurity/ClassMethods.html#method-i-attr_accessible)
to get a bit of back story about how it works in ActiveRecord - thanks to ActiveModel, you can
now get the joy of scoped access restrictions across any ORM built on ActiveModel, including [mongoid](http://mongoid.org/)!

## Installation ##


To use, just add to any application using ActiveModel. In Rails 3, this is a simple job of adding:

    gem 'scoped_attr_accessible'
    
To our Gemfile and running `bundle install`.

## Usage

With it enabled, your application should continue to work as usual with classic `attr_accessible` and `attr_protected`.
When in use, you can simply pass the `:scope` option in your declaration to declare a scope in which it should be accessible.

For example,

    class User < ActiveRecord::Base
    
      # All attributes are accessible for the admin scope.
      attr_accessible :all, :scope => :admin
      
      # The default scope can only access a and b.
      attr_accessible :a, :b
      
      # Make both :c and :d accessible for owners and the default scope
      attr_accessible :c, :d, :scope => [:owner, :default]
      
      # Also, it works the same with attr_protected!
      attr_protected :n, :scope => :default
    
    end
    
If both `attr_accessible` and `attr_protected` are used on a given scope, attributes
declared in `attr_protected` take precedence. Also, If `attr_accessible` isn't called for a scope
at all, it will allow all variables except those marked as protected.

When declaring the scopes in the accessible / protected part, please note that they need to
be symbol names for simplicity's sake.

### Setting the Scope

Next, when you call methods that use mass assignment (e.g. `ActiveRecord::Base#attributes=`),
it will use your current scope to sanitize mass-assigned variables. By default, with no
user intervention this scope is simply `:default`.

To set the scope, you can do so on a class an instance level with instance-level taking precedence.

To set it on a class level, simply do:
    
    User.current_sanitizer_scope = :admin
    # Or, dynamically:
    User.current_sanitizer_scope = @user.role.name.to_sym
    
This will be set Thread local. Also note you can get the current class-level scope:

    p User.current_sanitizer_scope # => nil by default
    
Or, temporarily switch it out, resetting it afterwards:

    p User.current_sanitizer_scope
    User.with_sanitizer_scope :admin do
      p User.current_sanitizer_scope
    end
    p User.current_sanitizer_scope

You can also declare this on the instance level, e.g:

    user = User.find(params[:id])
    user.current_sanitizer_scope = :admin
    # Or, more complex:
    user.current_sanitizer_scope = "something-else"
    
### Complex Scoping

Although the scope on a given accessible / protected declaration must be a symbol,
scoped\_attr\_accessible provides a way to deal with non-symbol scopes when assigning them - Namely,
you can set the `current_sanitizer_scope` value on classes or instances to an
arbitrary object and let scoped\_attr\_accessible dynamically convert it for you.

This is done using two seperate processes - Recognizers and Converters, each run when a given
scope is not a symbol.

The first of these (and the highest priority) are recognizers - they are simply blocks you
can declare (like below) that have a scope name and return a value denoting whether or not  they
match. e.g:

    # Reeopen the class
    class User < ActiveRecord::Base
      
      sanitizer_scope_recognizer :admin do |record, scope_value|
        scope_value.is_a?(User) && user.admin?
      end
      
      sanitizer_scope_recognizer :owner do |record, scope_value|
        scope_value.is_a?(User) && scope_value == record
      end
    
    end
    
In this example, we could simply do:

    user = User.find(params[:id])
    user.current_sanitizer_scope = current_user
    user.update_attributes params[:user]
    
And it would automatically set the scope to :owner / :admin when sanitizing the attributes.

The second and more flexible option is scope convertors - they're given the same information (e.g.
a record and scope value) and they are responsible for returning nil or a reduced form of the scope.
If they return a reduced form (e.g. they may return their creating user, or a plain symbol) it is
smart enough to reduce it until it does have a symbol.

As an example, we could implement the following:

    # Reeopen the class
    class User < ActiveRecord::Base
      
      sanitizer_scope_converter do |record, scope_value|
        return user.role.name.to_sym if scope_value.is_a?(User)
        return scope_value.user if scope_value.is_a?(UserSession)
      end
    
    end

When combined, these all form a very flexible way to dynamically scope attribute accessible.

## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Commit, do not mess with rakefile, version, or history. (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Contributors

* Darcy Laycock
* Mario Visic

## Copyright

Copyright (c) 2010 The Frontier Group. See LICENSE for details.
