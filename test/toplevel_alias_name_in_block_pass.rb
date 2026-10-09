# A top-level `alias` over a name a top-level `def` holds is left as it was
# where a block-pass above it hands on a name put together at run time: the
# name can be the def's, and a rename of the calls above the alias does not
# follow it. Each of these calls keeps the body it had.

public
def plain(x = 0) = "plain"
def fancy(x = 0) = "fancy"
name = ("pla" + "in").to_sym
p 1.then(&name)
tail = "in"
p [1, 2].map(&:"pla#{tail}")
p name.to_proc.call(1)
alias plain fancy
p 7
