rows = []
24.times do
  rows << Array.new(2, $0).map { |x| x.class }
  rows << Array.new(2, $PROGRAM_NAME).map { |x| x.class }
  rows << Array.new(2, __FILE__).map { |x| x.class }
  rows << Array.new(2, RUBY_VERSION).map { |x| x.class }
  rows << Array.new(2, RUBY_PLATFORM).map { |x| x.class }
  rows << Array.new(2, __method__.to_s).map { |x| x.class }
  z = "a" + rows.size.to_s
end
p rows.size
p rows.uniq
