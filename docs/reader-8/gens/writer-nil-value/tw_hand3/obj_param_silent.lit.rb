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
a.v = nil
puts "unreached"
