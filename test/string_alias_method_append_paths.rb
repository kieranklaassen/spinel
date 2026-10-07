# A method that appends to its String parameter and has an alias: the
# programs beside the refused ones that still build.
def add(v)
  v << "!"
  v
end
alias add2 add

# a fresh String or any other expression: nothing else can see it grow
s = +"az"
p add(s.dup)
p add2(+"q")
p add("#{s}?")
p s

# an element of an Array
a = [+"az"]
add(a[0])
p a

# a method written in place of the alias, calling the other
def put(v)
  v << "!"
  v
end
def put2(v) = put(v)
t = +"az"
put(t)
put2(t)
p t

# the method binds its parameter to a new String first
def copy(v)
  v = v.dup
  v << "!"
  v
end
alias copy2 copy
u = +"az"
p copy(u)
p copy2(u)
p u

# an aliased method that only reads
def len(v) = v.size
alias len2 len
p len(u), len2(u)

# an alias of another method in the class
class K
  def push(v)
    v << "!"
    v
  end
  def name = "k"
  alias label name
  def run
    w = +"az"
    push(w)
    w
  end
end
p K.new.run
p K.new.label
