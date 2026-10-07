class W
  def initialize(n) = @n = n
end
xs = [1, 2, 3]
row = [2**70, -(2**70), Complex(2, 0), Complex(2, 1), "2", :two, true, false, [2], { 2 => 2 }, 2..2, W.new(2), nil, 2.0, 2, :pad]
row.each do |n|
  p [xs.include?(n), xs.index(n), xs.rindex(n)]
end
