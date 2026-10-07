class K
  def initialize = @n = 0
  def then
    @n += 1
    self
  end
  def n = @n
end
k = K.new
row = [5, 6, 7, 8, k]
i = 0
while i < 300_000
  x = row[4]
  x.then
  i += 1
end
p k.n
