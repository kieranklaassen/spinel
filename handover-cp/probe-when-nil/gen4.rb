pre = <<~P
  S = Struct.new(:ok, :n)
  class Box
    attr_reader :seen, :w
    attr_accessor :acc
    def initialize(n) = @n = n
    def mark = @seen = @n > 3
    def self.conf = @conf
    def self.setconf = @conf = 2 > 1
    def memo = @memo ||= nil
    def setw(v) = @w = v
  end
  def dflt(v = nil) = v
  def opt(v = nil)
    case v
    when nil then "p nil"
    when false then "p false"
    else "p true"
    end
  end
  def kw(v: nil)
    case v
    when nil then "k nil"
    when false then "k false"
    else "k true"
    end
  end
  def resc(x)
    v = Integer(x) > 3
    v
  rescue ArgumentError
    nil
  end
  def blk = yield
  def viablk
    r = blk { 3 > 5 }
    r
  end
  def iff(x)
    if x > 3 then x > 5 end
  end
  def unl(x)
    unless x > 3 then x > 5 end
  end
  def cas(x)
    case x when 1 then true when 2 then false end
  end
  def wh(x)
    while x > 100; return true; end
  end
  b = Box.new(1)
  c = Box.new(9); c.mark
  bs = [true, false]
  eb = [true]; eb.pop
  if ARGV.size > 3
    q = 3 > 5
  end
  $g = 3 > 5 if ARGV.size > 3
  st = S.new
  st2 = S.new(false, 1)
  begin
    rv = Integer("zz") > 3
  rescue ArgumentError
  end
  lz = nil
  1.times { lz = 3 > 5 if ARGV.size > 3 }
  t3 = (ARGV.size > 3 ? (1 > 2) : nil)
  ws = Box.new(1); ws.setw(false); wn = Box.new(1)
  ac = Box.new(1); ac.acc = false; an = Box.new(2)
  dd = [[true, false], [false]]
  hb = { 1 => true, 2 => false }
  hb.default = nil
P
exprs = ["b.seen", "c.seen", "Box.conf", "b.memo", "dflt", "dflt(false)", "q", "$g", "st.ok", "st2.ok", "rv", "lz", "t3", "eb.pop", "eb.shift", "eb.first", "eb.last", "bs.find { |e| e == 3 }",
  "bs.detect { |e| !e && e }", "eb.sample", "eb.max_by { |e| e ? 1 : 0 }", "eb[0]", "bs.at(7)", "bs.dig(9)", "resc(\"zz\")", "resc(\"1\")", "viablk", "iff(1)", "iff(4)", "unl(9)", "unl(1)", "cas(3)", "cas(2)", "wh(1)",
  "wn.w", "ws.w", "an.acc", "ac.acc", "dd[5]&.first", "dd[1][3]", "dd.last.first", "hb[9]", "hb[2]", "hb.fetch(9, nil)", "hb.dig(9)", "bs.each_slice(2).to_a[3]&.first", "(bs.first if bs.size > 9)", "bs.cycle.first(0).first", "bs.take(0).first", "bs.reverse.find_index(3)&.zero?", "bs.min_by { |e| e ? 1 : 0 } && nil", "[].any? && nil", "(ARGV[0] && ARGV[0].empty?)", "ARGV[0]&.empty?", "(ARGV.first and true)"]
puts pre
exprs.each_with_index do |e, i|
  puts "puts(case #{e}\n  when nil then \"#{i} nil\"\n  when false then \"#{i} false\"\n  when true then \"#{i} true\"\n  else \"#{i} other\"\n  end)"
end
puts "puts opt", "puts opt(false)", "puts kw", "puts kw(v: false)"
