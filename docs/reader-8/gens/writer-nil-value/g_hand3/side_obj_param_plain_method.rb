class N
  def name = "n"
end
class C
  def set(x)
    @v = x.name
  end
end
def nilf = nil
a = C.new
a.set(N.new)
a.set(nilf)
puts "unreached"
