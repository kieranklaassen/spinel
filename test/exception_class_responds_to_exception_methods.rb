# respond_to? of the methods Exception gives every exception, asked of an
# instance of a class the program puts under a builtin exception: a typed
# one, a rescued one, and one kept as a boxed value.
class MyErr < StandardError; end
class Deeper < MyErr
  def hint = "deeper"
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
p e.respond_to?(:full_message), e.respond_to?("full_message")
p e.full_message.include?("never raised") if e.respond_to?(:full_message)
puts e.detailed_message(highlight: false) if e.respond_to?(:detailed_message)
p e.full_message(highlight: false, order: :top).include?("never raised") if e.respond_to?(:full_message)

d = Deeper.new("d")
p d.respond_to?(:cause), d.respond_to?(:hint)

begin
  raise App::Missing, "gone"
rescue App::Missing => g
  p g.respond_to?(:message), g.respond_to?(:backtrace)
  puts g.backtrace.class if g.respond_to?(:backtrace)
end

def duck(x) = x.respond_to?(:message) ? "error: #{x.message}" : "value: #{x.inspect}"
[MyErr.new("boxed"), d, 3, "s", nil].each { |x| puts duck(x) }
def render(x) = x.respond_to?(:full_message) ? x.full_message(highlight: false).include?("boxed") : false
p [MyErr.new("boxed"), 3, nil].map { |x| render(x) }
[:message, :cause, :nope].each { |n| p e.respond_to?(n) }
