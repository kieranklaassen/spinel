# A top-level `alias` over a name a top-level `def` holds is left as it was
# where the program reaches the name in a way a rename of the calls above the
# alias does not follow, or where the renamed body would show. Each of these
# calls keeps the body it had.

# a call on self above the alias
def near = "near"
def far = "far"
p self.near
alias near far

# a lambda written above the def
late = -> { slow }
def slow = "slow"
def fast = "fast"
p late.call
alias slow fast

# respond_to? answers for the name
def here = 1
def there = 2
alias here there
p respond_to?(:here, true)
p respond_to?(:nowhere, true)

# the name aliased again below the alias
def greet = "hello"
def shout = "HELLO"
p greet
alias greet shout
alias third greet
p third

# a body that asks its own name
def title = __method__
def label = :x
p title
alias title label
p label

# a body that asks its own name through send
def badge = send(:__method__)
def stamp = :y
p badge
alias badge stamp
p stamp

# a method object taken of the name below the alias
def twice(&b) = b.call(2)
def again(&b) = b.call(2)
p twice { |v| v }
alias twice again
p method(:twice).call { |v| v }
