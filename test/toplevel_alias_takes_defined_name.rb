# A top-level `alias` over a name a top-level `def` already holds takes the
# name from there on, as a later `def` does; the calls above it keep the body
# they had.

def greet = "hello"
def shout = "HELLO"
p greet
alias greet shout
p greet
p shout

# with an argument, and from a method defined below the alias
def pace(x) = x + 1
def leap(x) = x * 10
p pace(4)
alias pace leap
p pace(4)
def twice(x) = pace(pace(x))
p twice(2)

# the old body kept under another name
def unit = "m"
def other = "ft"
alias metric unit
alias unit other
p unit
p metric

# a chain: an alias names what its target meant where it stands
def one = 1
def two = 2
def three = 3
alias one two
alias two three
p one
p two
p three

# a method that calls itself is itself until the alias
def total(n) = n <= 0 ? 0 : 1 + total(n - 1)
def flat(n) = n * 10
p total(3)
alias total flat
p total(3)

# a block, and a call inside a block
def pick(&b) = b.call(1)
def bundle(&b) = b.call(2)
p pick { |v| v + 100 }
alias pick bundle
p pick { |v| v + 100 }
[10].each { |w| p pick { |v| v + w } }

# another arity
def none = "0"
def some(x = "dflt") = x
alias none some
p none
p none("given")

# a later def takes the name back
def cur = "a"
def nxt = "b"
alias cur nxt
def cur = "c"
p cur
p nxt

# an alias that does not run takes nothing
def keep = "kept"
def shed = "dropped"
if ARGV.size > 3
  alias keep shed
end
p keep

# main's own method of the name is still the one called
def base = "object"
def swap = "swapped"
def self.base = "main"
p base
alias base swap
p base
