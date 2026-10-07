# A method that matches through a boxed operand saves no frame, so its match is
# written to its caller's registers. A program with such a method keeps the
# registers as they are left by a raise: here `boom` leaves the capture the top
# level had.
def loose(v, s) = v =~ s

def boom(s)
  s =~ /k(\d)/
  raise ArgumentError, "x"
end

"k9" =~ /k(\d)/
loose([/a(.)/, 1][0], "ab")
begin
  boom("k9")
rescue ArgumentError
end
p $1
