# Each `K === x` below asks the class or the module an arm under a test of
# the engine defines: K is not the value the class A holds under the same
# name.
class A
  Foo = 3
  Bar = "abc"
  Baz = 3
  NAME = "abc"
  LIMIT = 1..5
end
if RUBY_ENGINE == "ruby"
  class Foo; end
  module Bar; end
  class LIMIT; end
end
if defined?(RubyVM)
  class Baz; end
end
unless RUBY_ENGINE == "spinel"
  class NAME; end
end
p(Foo === 3)
p(Bar === "abc")
p(Baz === 3)
p(NAME === "abc")
p(LIMIT === 3)
