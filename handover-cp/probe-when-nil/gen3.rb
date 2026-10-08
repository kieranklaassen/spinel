pre = <<~P
  def tern(x) = x > 3 ? true : nil
  def early(x)
    return nil if x < 0
    x > 3
  end
  def impl(x)
    if x > 3
      true
    end
  end
  def whl(x)
    x > 3 if x > 0
  end
  class Box
    def initialize(n) = @n = n
    def flag = @flag
    def set = @flag = @n > 3
    def big? = @n > 3
    def late
      @late = @n > 3 if @n > 100
      @late
    end
  end
  b = Box.new(1)
  z = nil
  z = 5 > 9 if ARGV.empty?
  y = nil
  y = 5 > 9 if ARGV.size > 3
  bs = [true, false]
  es = [1].select { |e| e > 5 }.map { |e| e > 0 }
  h = { a: true, b: false }
  o = [Box.new(9)].find { |e| e.big? == false }
  w = (5 > 9 if ARGV.size > 3)
  s = "abc"
P
exprs = ["tern(1)", "tern(5)", "early(-1)", "early(1)", "impl(1)", "impl(9)", "whl(0)", "whl(1)", "b.flag", "b.late", "z", "y", "bs[5]", "bs[1]", "bs.first", "es.first", "es.last",
  "h[:b]", "h[:zz]", "o&.big?", "w", "(s.empty? if s.size > 9)", "s.match?(/x/)", "1.nil?", "(3 > 5)", "!s", "(s == 3)", "s.frozen?", "bs.include?(nil)", "[1].empty?", "(true && nil)", "(false || nil)", "(s.size > 1 and nil)"]
puts pre
exprs.each_with_index do |e, i|
  puts "puts(case #{e}\n  when nil then \"#{i} nil\"\n  when false then \"#{i} false\"\n  when true then \"#{i} true\"\n  else \"#{i} other\"\n  end)"
end
