# A `yield` in parentheses whose value is boxed (blocks of different types
# reach it as an argument, or as one arm of a conditional), given a block
# that answers nil: the splice handed its bare nil to the boxed consumer,
# and the C did not build.
def show(x)
  x
end

def passed
  show((yield))
end
p passed { 9 }
p passed { "s" }
p passed { nil }

def chosen(c)
  v = (c ? (yield) : 1.5)
  v
end
p chosen(true) { 9 }
p chosen(true) { "s" }
p chosen(true) { nil }
p chosen(false) { 0 }
