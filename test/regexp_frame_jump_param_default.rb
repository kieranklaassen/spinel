# A parameter's default runs in the lambda or proc, in the frame it was
# written in: these keep reading the caller's match.
def first(l, s)
  r = l.call
  s =~ /b/
  r
end
def second(pr, s)
  r = pr.call(1)
  s =~ /b/
  r
end
"xa" =~ /(a)/
l = ->(x = $1) { x }
p first(l, "b")
pr = proc { |v, w = $~[0]| w }
p second(pr, "b")
