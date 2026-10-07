# A method that matches starts with no match of its own: `$~` belongs to the
# method, so its caller's match is not read through it.

def reads_first(s)
  before = $1
  s =~ /a(.)/
  [before, $1]
end

"k9" =~ /k(\d)/
p reads_first("ab")
p $1

# a branch that did not match sees none either
def maybe(s, go)
  s =~ /a(.)/ if go
  [$~.nil?, $1]
end

p maybe("ab", false)
p maybe("ab", true)
p $1

# every call of a recursion starts empty
def depth(n)
  seen = $1
  ("n" + n.to_s) =~ /n(\d+)/
  n == 0 ? [seen, $1] : depth(n - 1) + [seen, $1]
end

p depth(2)
p $1

# an instance method and a class method
class Row
  def initialize(s) = @s = s

  def first_seen
    was = $~
    @s =~ /r(.)/
    [was.nil?, $1]
  end

  def self.seen(s)
    was = Regexp.last_match(1)
    s =~ /c(.)/
    [was, $1]
  end
end

p Row.new("r2").first_seen
p Row.seen("c3")
p $1

# a method called from a method that has matched
def inner(s)
  was = $1
  s =~ /i(.)/
  [was, $1]
end

def outer(s)
  s =~ /o(.)/
  [inner("i4"), $1]
end

p outer("o5")
p $1

# and one called after a raise left another method
def raises(s)
  s =~ /nope/
  raise ArgumentError, "x"
end

begin
  raises("zq")
rescue ArgumentError
end
p reads_first("ab")
p $1
