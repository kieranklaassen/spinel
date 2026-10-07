class N
  def name = "n"
end
class C
  def v=(x)
    @v = x.name
  end
end
def nilf = nil
a = C.new
a.v = N.new
t = nilf
a.v = t
puts "unreached"
