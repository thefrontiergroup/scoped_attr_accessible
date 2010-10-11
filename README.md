# scoped\_attr\_accessible

scoped\_attr\_accessible provides scopeable versions of attr\_accessible and attr\_protected.

## Usage

You can declare scoping with an optional :scope parameter, as such:

    class User < ActiveRecord::Base
      attr_accessible :a
      attr_accessible :b, :scope => :admin
      attr_protected  :c, :scope => :owner
    end
    
Then, you can set the sanitizer\_scope to declare which it should use:

    u = User.new
    u.sanitizer_scope = :admin
    u.attributes = {'a' => '...'}
    
Or, for simpler purposes:

    u.with_sanitizer_scope :admin do
      # Scoped to :admin
    end
    
Or, for all in a given context:

    User.with_sanitizer_scope :admin do
      # All calls will be scoped to admin.
    end

Finally, you can declare how it converts from non-symbols do symbols using
one of two methods:

    class User < ActiveRecord::Base
    
      # 1. using a scope detector
      define_sanitizer_scope :admin do |object|
        return true if object.is_a?(User) && object.has_role?(:admin)
      end
      
      # 2. Use an scope convertor
      define_sanitizer_scope_convertor do |object|
        return :owner if object.is_a?(User) && object.has_role?(:owner)
      end
      
    end


## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Commit, do not mess with rakefile, version, or history. (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 The Frontier Group. See LICENSE for details.
