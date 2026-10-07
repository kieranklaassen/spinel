class K
  def v=(x)
    @v = x
    42
  end
end
def yb
  p yield
  nil
end
a = K.new
b = K.new
yb { b.v = 6 }
a.v = nil
