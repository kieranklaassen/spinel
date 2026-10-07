class MyErr < StandardError
  def initialize(m)
    @m = m
    super
  end
  def tw = Array.new(2, @m)
end
s = "abc"
t = "def"
u = "xyz"
rows = []
24.times do
  rows << (MyErr.new(s + t).tw)
  z = s + u
  z = u + s
end
bad = rows.count { |r| r != rows[0] }
p rows.size
p bad
p rows[0]
