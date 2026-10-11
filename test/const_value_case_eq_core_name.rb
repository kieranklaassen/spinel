# A bare Marshal or Errno, read outside the class that sets a constant of
# that name, is CRuby's own module: no value passes its ===.
class A
  Marshal = 3
  Errno = "abc"
end
p(Marshal === 3)
p(Errno === "abc")
