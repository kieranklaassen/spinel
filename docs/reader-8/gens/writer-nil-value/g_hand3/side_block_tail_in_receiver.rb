class K
  def v=(x)
    @v = x
    42
  end
end
def pick(o)
  p yield
  o
end
a = K.new
b = K.new
pick(a) { b.v = 6 }.v = 5
