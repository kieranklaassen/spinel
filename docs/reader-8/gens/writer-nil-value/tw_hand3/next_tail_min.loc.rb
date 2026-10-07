class K
  def v=(x)
    @v = x
  end
end
def nilf = nil
a = K.new
p [1, 2].map { |i| next 7 if i > 1; t = nilf; a.v = t }
