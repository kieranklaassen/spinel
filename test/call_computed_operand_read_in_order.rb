# A computed operand is read where it is written: `ms(n).center(@i + 5, bump)`,
# with `bump` adding to @i, takes its width before `bump` runs.
$g = 0
class T
  @@k = 0
  def initialize = @i = 0
  def bump = (@i += 1; "a")
  def ibump = (@i += 1)
  def gbump = ($g += 1; "a")
  def kbump = (@@k += 1; "a")
  def ms(n) = "s#{n}t"
  def val(n) = n
  def nums = [10, 20, 30, 40]
  def tens = {1 => 10, 2 => 20, 3 => 30, 4 => 40}
  def mixed = [1, "x", :s]
  def take3(a, b, c) = "#{a}:#{b}:#{c}"

  def width(n) = ms(n).center(@i + 5, bump)
  def twice(n) = ms(n).ljust(@i * 2 + 5, bump).rjust(@i + 9, bump)
  def global(n) = ms(n).center($g + 5, gbump)
  def klass(n) = ms(n).center(@@k + 5, kbump)
  def either(n) = ms(n).center(@i > 5 ? 9 : 5, bump)
  def slice(n) = ms(n)[@i - 6, ibump - 6].to_s
  def index(n) = nums.insert(@i - 7, ibump).join(",")
  def key(n) = tens.fetch(@i - 8, ibump)
  def mix(n) = mixed.insert(@i - 9, bump).inspect
  def local(n)
    v = 3
    la = -> { v = 9; "a" }
    ms(n).center(v + 5, la.call)
  end
  # a method of the program takes its arguments in order already
  def user(n) = take3(val(n), @i + 5, bump)
  # nothing here can change n
  def same(n) = ms(n).center(n + 5, bump)
end

t = T.new
puts t.width(1), t.width(2)
puts t.twice(3)
puts t.global(4), t.global(5)
puts t.klass(6), t.klass(7)
puts t.either(8), t.either(9)
puts t.slice(1)
puts t.index(2)
puts t.key(3)
puts t.mix(4)
puts t.local(5), t.local(6)
puts t.user(7)
puts t.same(8)
