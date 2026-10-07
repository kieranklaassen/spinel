rows = []
24.times do
  rows << Array.new(2, ARGV).map(&:size)
  rows << Array.new(2, ENV).map { |e| e.key?("NOPE_NOT_SET") }
  z = "a" + rows.size.to_s
end
p rows.size
p rows.uniq
