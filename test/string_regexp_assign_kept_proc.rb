# Right before `s[re] = v` set the match, and still: a program whose Proc
# matches is emitted as it was, and the method's assignment leaves its
# caller's match alone.
def fix(t)
  t[/(\d+)/] = "N"
  t
end

pr = proc { |x| x =~ /(m+)/ ? $1 : nil }
"k9" =~ /k(\d)/
p fix(+"a 12 b")
p $1
p pr.call("ammm")
