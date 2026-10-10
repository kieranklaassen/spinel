# spinel: int64 -- assumes a 64-bit Integer (a Bignum index needs it)
# A boxed Array read by a Bignum is CRuby's RangeError. Where the program
# reopens RangeError and gives it an `initialize`, CRuby runs that for the
# error too, and the rescue here prints what element 0, which that read
# answered, printed. A `raise` the program writes runs such an
# `initialize` and a raise by the runtime does not, so in a program that
# reopens a builtin exception class every read keeps the answer it gave.
class RangeError
  def initialize(m = nil)
    super("nil")
  end
end
g = [[nil, "s", :z], 2**70]
a = g[0]
k = g[1]
begin
  p a[k]
rescue => e
  puts e.message
end
