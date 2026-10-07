# A method that matches keeps its caller's match alive while it runs. The
# frame that saves the caller's registers held the only reference to their
# Strings, and held it unrooted: a collection inside the method freed them,
# and the caller read another String's bytes out of $1.
$keep = []
def churn
  GC.start
  300.times { $keep << "x" * 40 << "y" * 4 << "w" * 84 << "p" * 15 << "o" * 24 }
end
def busy(s)
  s =~ /z/
  churn
  s.size
end
def nested(s)
  s =~ /(b+)/
  busy(s)
  $1
end
def leaves(s)
  return 0 if s =~ /q/
  churn
  1
end
def raises(s)
  s =~ /a/
  churn
  raise ArgumentError, "no"
end

subject = "pre" * 5 + "key" + 7.to_s + "=" + "v" * 40 + "post" * 6
subject =~ /(key\d)=(v+)/
subject = nil
n = busy("abc")
p n, $1, $2, $~[0]
p $`, $'
p nested("a" + "b" * 44).size, $1, $2.size
p leaves("abc"), leaves("q"), $1, $~[0].size
begin
  raises("abc")
rescue ArgumentError => e
  p e.message
end
churn
"z" + 1.to_s =~ /z(\d)/
p busy("abc"), $1
