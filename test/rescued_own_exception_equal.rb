# equal? and == between a rescued exception and the same exception typed as
# the program's own class: one object, whichever way each side is typed.
class MyErr < StandardError; end
class Coded < StandardError
  attr_reader :code
  def initialize(m, code = 1)
    super(m)
    @code = code
  end
end

k = MyErr.new("n")
o = MyErr.new("n")
begin
  raise k
rescue => e
  p e.equal?(k), k.equal?(e), e == k, e != k, e.eql?(k)
  # another object of the same class and message is not it
  p e.equal?(o), o.equal?(e), e == o
end

begin
  raise MyErr, "a"
rescue MyErr => f
  x = f
  p f.equal?(f), f.equal?(x), x.equal?(f), f.exception.equal?(f), !f.equal?(f)
  puts(f.equal?(x) ? "same" : "other")
end

c = Coded.new("c", 7)
begin
  raise c
rescue StandardError => g
  p g.equal?(c), c.equal?(g), g == c, c.code
end
