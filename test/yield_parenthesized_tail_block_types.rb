# A method whose last statement is a `yield` in parentheses, called with
# blocks that answer different types: each call answers its own block's
# value, as a bare `yield` tail does. In parentheses the first site's
# block typed every call: `handed { 9 }` below answered :"" for 9.
def handed
  (yield)
end
p handed { :s }
p handed { 9 }

def passed(x)
  (yield x)
end
p passed(1) { |v| v + 1 }
p passed(2) { |v| v.to_s }
p passed(3) { |v| [v] }

def twice
  ((yield))
end
p twice { 2.5 }
p twice { "s" }
p twice { nil }

class Box
  def initialize(n)
    @n = n
  end

  def with
    (yield @n)
  end
end
b = Box.new(4)
p b.with { |n| n * 2 }
p b.with { |n| "n#{n}" }
p b.with { |n| n > 3 }
