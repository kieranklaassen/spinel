# The indexes of values_at on a boxed receiver are read before the
# receiver runs. Where the receiver can change what a splat's operand
# holds, the splat is read as it was: what it holds by then is what CRuby
# splats, and nil or an empty Range gives none.

a = [[10, 20, 30], nil][ARGV.size]
j = 1
p (j = nil; a).values_at(*j)
r = (0..1)
p (r = (2..1); a).values_at(*r)
$j = 1
def geta(x)
  $j = nil
  x
end
p geta(a).values_at(*$j)
