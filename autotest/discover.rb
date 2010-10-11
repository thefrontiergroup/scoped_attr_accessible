begin
  require 'autotest/fsevent'
  require 'autotest/growl'
rescue LoadError
end

Autotest.add_discovery { "rspec2" }
