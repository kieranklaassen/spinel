# A builtin exception reopened with its superclass restated and an attribute
# declared. The runtime builds a builtin exception, the program has no struct
# for one, and the program builds as it did.
class RuntimeError < StandardError
  attr_accessor :code
end
class IOError < StandardError
  attr_accessor :code
end
class NotImplementedError < ScriptError
  attr_accessor :code
end
class ArgumentError < StandardError
  attr_accessor :code
end
class StopIteration < IndexError
  attr_accessor :code
end
class TypeError < StandardError
  attr_accessor :code
end
class KeyError < IndexError
  attr_accessor :code
end
class ZeroDivisionError < StandardError
  attr_accessor :code
end

begin
  raise ArgumentError, "a"
rescue StandardError => e
  puts e.message
end
puts "done"
