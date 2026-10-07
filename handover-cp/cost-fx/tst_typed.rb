class K
  def initialize = @n = 0
  def then
    @n += 1
    self
  end
  def n = @n
end
k = K.new
i = 0
while i < 300_000
  k.then
  i += 1
end
p k.n
