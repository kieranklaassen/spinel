# A block belongs to the frame it is written in, wherever it runs: a match made
# by a proc, or by a block a method kept, is its writer's `$~` after the method
# that called it was left by a raise or a throw. A program with such a block
# keeps the caller's registers as they are left.
def calls(s, pr)
  s =~ /a/
  pr.call
  raise ArgumentError, "x"
end

pr = proc { "k9" =~ /k(\d)/ }
begin
  calls("a", pr)
rescue ArgumentError
end
p $1

class Hook
  def on(&b) = @b = b
  def fire(s)
    s =~ /f/
    @b.call
    throw :done
  end
end

h = Hook.new
h.on { "m7" =~ /m(\d)/ }
catch(:done) { h.fire("f") }
p $1
