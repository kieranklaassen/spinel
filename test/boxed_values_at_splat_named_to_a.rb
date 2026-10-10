# A to_a the program defines by a String name is one of its own too: a
# splat in values_at on a boxed receiver is read as it was.

class Integer
  define_method("to_a") { [] }
end
a = [[10, 20, 30], nil][ARGV.size]
i = ARGV.size + 1
p a.values_at(0, *i)
