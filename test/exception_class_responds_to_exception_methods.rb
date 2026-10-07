# respond_to? of the methods Exception gives every exception, asked of an
# instance of a class the program puts under a builtin exception: a typed
# one, a rescued one, and one kept as a boxed value.
class MyErr < StandardError; end
class Deeper < MyErr
  def hint = "deeper"
end
class Shy < StandardError
  private :message
end
class Gone < StandardError
  undef_method :message
end
module App
  class Missing < KeyError; end
end

e = MyErr.new("never raised")
p [e.respond_to?(:message), e.respond_to?(:detailed_message), e.respond_to?(:backtrace), e.respond_to?(:cause)]
p e.respond_to?(:nope), e.respond_to?(:hint), e.respond_to?("message")
puts(e.respond_to?(:message) ? e.message : "no message")
p e.backtrace if e.respond_to?(:backtrace)
p e.cause if e.respond_to?(:cause)

d = Deeper.new("d")
p d.respond_to?(:cause), d.respond_to?(:hint)

begin
  raise App::Missing, "gone"
rescue App::Missing => g
  p g.respond_to?(:message), g.respond_to?(:backtrace)
  puts g.backtrace.class if g.respond_to?(:backtrace)
end

# a name the class made private or took away is not answered for
p Shy.new("s").respond_to?(:message), Shy.new("s").respond_to?(:cause)
p Gone.new("g").respond_to?(:message), Gone.new("g").respond_to?(:backtrace)

def duck(x) = x.respond_to?(:message) ? "error: #{x.message}" : "value: #{x.inspect}"
[MyErr.new("boxed"), d, 3, "s", nil].each { |x| puts duck(x) }
[:message, :cause, :nope].each { |n| p e.respond_to?(n) }
