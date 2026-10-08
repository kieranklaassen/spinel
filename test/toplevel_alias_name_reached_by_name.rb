# A top-level `alias` over a name a top-level `def` holds is left as it was
# where the program reaches the name in a way a rename of the calls above the
# alias does not follow. Each of these calls keeps the body it had.

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

# a name put together at run time, above the alias
def plain = "plain"
def fancy = "fancy"
name = "pla" + "in"
p send(name)
alias plain fancy
