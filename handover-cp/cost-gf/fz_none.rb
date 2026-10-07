class K
  def initialize = @s = 0
  def s = @s
end
k = K.new
row = [5, "q", nil, :s, 2.5, k]
i = 0
while i < 3_000_000
  x = row[i % 6]
  x.freeze
  i += 1
end
p k.s
