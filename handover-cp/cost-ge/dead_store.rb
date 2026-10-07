class Tally
  def initialize = @n = 0
  def n = @n
  def bump(x) = @n = x
  def freeze
    @n += 1
    super
  end
end
t = Tally.new
i = 0
while i < 3_000_000
  t.bump(i)
  i += 1
end
p t.n
