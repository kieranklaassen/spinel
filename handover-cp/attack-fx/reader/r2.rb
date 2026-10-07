class W; def initialize; @n = 0; end; def n; @n; end; def then; puts "own then ran"; self; end; end
def pick(f) = f ? W.new : nil
b = pick(false)
b.then
puts "done"
