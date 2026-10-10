# A boxed Integer read by `true` is CRuby's TypeError. Where the program
# reopens TypeError and gives it an `initialize`, CRuby runs that for the
# error too, and the rescue here prints what bit 0, which a boxed Integer
# answered, printed. A `raise` the program writes runs such an `initialize`
# and a raise by the runtime does not, so in a program that reopens a
# builtin exception class every read keeps the answer it gave.
class TypeError
  def initialize(m = nil)
    super("0")
  end
end
a = [6, true, "s"]
x = a[0]
k = a[1]
begin
  p x[k]
rescue => e
  puts e.message
end
