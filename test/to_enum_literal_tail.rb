# A method that returns `to_enum(:m) unless block_given?` and whose block
# form answers a literal answers that literal when called with a block and
# its Enumerator when called without one. te_tail_is_value knew a Hash, a
# String, a Symbol and a number among the literals and not an Array, a
# Range, an interpolated String, a Regexp, a Rational, a Complex or a
# lambda, so such a method's return was pinned to Enumerator, as an
# each-like method's is, and the literal stored through it did not build.
class Pair
  def initialize = @a = [1, 2]
  def each
    return to_enum(:each) unless block_given?
    @a.each { |x| yield x }
    [@a.size, :done]
  end
end
class Span
  def each(&b)
    return enum_for(:each) unless b
    [3, 4].each(&b)
    (3..4)
  end
end
class Tag
  def initialize = @n = 5
  def walk
    if block_given?
      yield @n
      "n#{@n}"
    else
      to_enum(:walk)
    end
  end
end
class Rest
  def initialize = @n = 6
  def pattern
    return to_enum(:pattern) unless block_given?
    yield @n
    /a#{@n}+/
  end
  def plain
    return to_enum(:plain) unless block_given?
    yield @n
    /b+/
  end
  def ratio
    return to_enum(:ratio) unless block_given?
    yield @n
    3r
  end
  def imag
    return to_enum(:imag) unless block_given?
    yield @n
    2i
  end
  def fn
    return to_enum(:fn) unless block_given?
    yield @n
    -> { 7 }
  end
end
# A literal returned early beside a `self` tail is not the block form's last
# expression: these two stay each-like, as they were.
class Early
  def scan
    return to_enum(:scan) unless block_given?
    return [0] if $skip
    yield 8
    self
  end
end
class Late
  def scan
    return to_enum(:scan) unless block_given?
    return [0] if $skip
    yield 9
    self
  end
end
$skip = false
pair = Pair.new
r = pair.each { |x| p x }
p r
p pair.each.to_a
span = Span.new
p span.each { |x| p x }
p span.each.to_a
tag = Tag.new
p tag.walk { |x| p x }
p tag.walk.to_a
rest = Rest.new
p rest.pattern { |x| x }.source
p rest.pattern.to_a
p rest.plain { |x| x }.source
p rest.plain.to_a
p rest.ratio { |x| x }
p rest.ratio.to_a
p rest.imag { |x| x }
p rest.imag.to_a
p rest.fn { |x| x }.call
p rest.fn.to_a
[Early.new, Late.new].each { |t| p t.scan.with_index.to_a }
