$n = 0
S = Struct.new(:a) do
  def freeze
    $n += 1
    super
  end
end
s = S.new(1)
v = nil
x = ARGV.size > 5 ? s : v
y = x.freeze
p y.class
z = ARGV.size < 5 ? s : v
w = z.freeze
p w.a
p $n
