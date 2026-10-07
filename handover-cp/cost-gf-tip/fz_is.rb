class K
  def initialize = @s = 0
  def freeze
    @s += 1
    self
  end
  def s = @s
end
k = K.new
k.freeze
row = [5, "q"]
i = 0
while i < 3_000_000
  x = row[i % 2]
  x.freeze
  i += 1
end
p k.s
