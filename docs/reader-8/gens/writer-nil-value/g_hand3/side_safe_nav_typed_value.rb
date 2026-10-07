class K
  def v=(x)
    @v = x
  end
end
def bump
  puts "bump"
  3
end
def pick(f) = f ? K.new : nil
b = pick(false)
b&.v = bump
puts "end"
