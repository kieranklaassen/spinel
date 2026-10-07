# An operand written in parentheses runs in its place, after the operands
# written before it, as in CRuby: `mk.length + ($o.val > 9 ? 1 : 2)` checked
# $o for nil before mk had made it, and raised.
class Box
  def val = 7
end

$o = nil
$log = []

def mk
  $o = Box.new
  $log << "mk"
  "t"
end

def late
  $log << "late"
  2
end

z = ARGV.length

p mk.length + ($o.val > 9 ? 1 : 2)
$o = nil
p mk + ([$o.val, 1].first > 9 ? "x" : "y")
$o = nil
p mk + (if z > 3 then "w" else t = $o.val; t.to_s end)
$o = nil
p mk.length * ($o.val)
$o = nil
p mk.center(($o.val > 9 ? 1 : 5), "*")
$o = nil
p mk.sub("t", ($o.val > 9 ? "x" : "y"))

# a call in parentheses that only logs: gcc ran it first
$log.clear
p mk * (late)
p $log

# a computed operand written before the one in parentheses is read first
$i = 1
def bump = ($i += 10; 3)
def nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
p nums.slice($i + 1, (bump))

# ...and so is one that stays in the call: in parentheses itself, a Symbol's
# conditional, a division that raises. With the last operand bound around
# them they ran after bump; those calls compile as they did
$i = 1
p nums.values_at(($i + 5), (bump))
def syms = { a: 1, b: 2 }
$i = 1
p syms.fetch($i > 3 ? :b : :a, (bump))
$i = 1
begin
  p nums.values_at((7 / z), (bump))
rescue ZeroDivisionError
  p $i
end

# two fresh Arrays in parentheses went bare into one C call: gcc made the
# second first, and neither was held while the other was made
def one = ($log << "one"; [1, 2])
def two = ($log << "two"; [3])
$log.clear
p((one) + (two))
p $log
