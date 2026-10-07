def nilf
  puts "nilf"
  nil
end
class K
  def v=(x)
    @v = x
    42
  end
  def v = @v
end
a = K.new
def rd = nil
x1 = rd
class Object
  def rd = 13
end
t = rd
r = (a.v = t)
p r
p a.v
