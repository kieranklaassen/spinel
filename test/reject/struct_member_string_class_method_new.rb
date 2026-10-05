# A bare `new` in a class method of the Struct stores its argument in the
# member the same way.
S = Struct.new(:x, :n) do
  def self.make(x) = new(x, 1)
end
c = S.make("q".dup)
c.x << "z"
p c.x
