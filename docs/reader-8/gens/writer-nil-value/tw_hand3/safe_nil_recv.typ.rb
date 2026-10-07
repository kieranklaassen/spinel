class K
  def v=(x)
    @v = x
  end
end
def nilf
  puts "nilf"
  nil
end
def pick(f) = f ? K.new : nil
b = pick(false)
b&.v = (nilf; 3)
puts "end"
