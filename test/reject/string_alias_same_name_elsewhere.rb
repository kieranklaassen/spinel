# The alias is of another class's method of the same name: a method keeps
# the value ABI when any alias uses its name, so the top-level `bump` takes
# a copy too (CRuby prints "ba").
class K
  def bump(v) = v
  alias bump2 bump
end
def bump(v)
  v.succ!
  v
end
s = +"az"
bump(s)
p s
