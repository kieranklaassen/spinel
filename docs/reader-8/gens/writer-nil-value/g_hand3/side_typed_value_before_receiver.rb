class K
  def v=(x)
    @v = x
  end
end
def get(o)
  puts "get"
  o
end
def bump
  puts "bump"
  3
end
a = K.new
get(a).v = bump
