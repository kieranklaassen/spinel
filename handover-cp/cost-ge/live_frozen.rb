class Tally
  def initialize = @n = 0
  def n = @n
  def freeze
    @n += 1
    super
  end
  def frozen? = super && @n > 0
end
t = Tally.new
t.freeze
c = 0
i = 0
while i < 3_000_000
  c += 1 if t.frozen?
  i += 1
end
p c
