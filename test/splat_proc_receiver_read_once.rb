# `f.call(*ar[0])` reads its receiver before the operand runs, and once.
# An index is a call: the program's own Array#[] may write the local the
# Proc is read from, and CRuby has the receiver in hand by then.
class Array
  def [](i); $w.call; 42; end
end
pr = proc { |a| [:pr, a] }
la = lambda { |a| [:la, a] }
f = pr
ar = [1, 2]
$w = -> { f = la; 7 }
begin
  r = f.call(*ar[0])
  p r
rescue ArgumentError
  puts "AE"
end
p f.call(5)
