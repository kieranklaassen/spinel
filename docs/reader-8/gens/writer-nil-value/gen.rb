# gen.rb FAMILY... : writes g_<family>/*.rb
require_relative "dims"
NILV = %w[nilf nilfarg seq ifmod ifnot begin puts pnone print retnone retnil tern ternb ifelse yv yvnil lamv
          const gasgn orlit orf andnil case casef resc rescmod ens raiser raiser1 nested nestlit nest2 nest2lit
          nestseq nestseqn gcstart itself dig blk alloc]
CTLV = VALUES.keys - NILV
VS1 = %w[nilf seq ifmod ifnot puts retnone ternb yv const gasgn nested alloc]
VS2 = %w[nilf nilfarg seq ifnot ternb nest2 raiser1 alloc]
CTL1 = %w[lit maybe int strv local empty]
TW = ENV["TWINS"]
def out(fam, name, src)
  return if src.nil?
  d = "/home/claude/r8/p220/#{TW ? "tw" : "g"}_#{fam}"; Dir.mkdir(d) unless Dir.exist?(d)
  File.write("#{d}/#{name}#{TW ? "." + TW : ""}.rb", src)
end
alias build0 build
def build(**kw) = TW ? build0(**kw, twin: TW.to_sym) : build0(**kw)
ARGV.each do |fam|
  case fam
  when "wv"
    c4 = %w[stmt p asgn if]
    WRITERS.keys.each_with_index do |w, i|
      VS1.each_with_index { |v, j| c = c4[(i + j) % 4]; out(fam, "#{w}-#{v}-#{c}", build(w: w, h: "none", v: v, r: "local", c: c)) }
      CTL1.each_with_index { |v, j| c = c4[(i + j) % 2]; out(fam, "#{w}-#{v}-#{c}", build(w: w, h: "none", v: v, r: "local", c: c)) }
    end
  when "rv"
    c3 = %w[stmt p asgn]
    RECV.keys.each_with_index do |r, i|
      (VS1 + CTL1).each_with_index { |v, j| c = c3[(i + j) % 3]; out(fam, "#{r}-#{v}-#{c}", build(w: "ret", h: "none", v: v, r: r, c: c)) }
    end
  when "cv"
    CTX.keys.each do |c|
      (VS2 + %w[lit maybe strv]).each { |v| out(fam, "#{c}-#{v}", build(w: "ret", h: "none", v: v, r: "local", c: c)) }
    end
  when "vall"
    VALUES.keys.each { |v| %w[stmt p asgn].each { |c| out(fam, "#{v}-#{c}", build(w: "rets", h: "none", v: v, r: "local", c: c)) } }
  when "hist"
    HIST.keys.each do |h|
      %w[own ret say toi tos plus nilq two guard attr].each do |w|
        %w[nilf seq lit].each { |v| out(fam, "#{h}-#{w}-#{v}", build(w: w, h: h, v: v, r: "local", c: "p")) }
      end
    end
  when "cw"
    CTX.keys.each do |c|
      %w[own0 none super mod plus raise toi hist].each { |w| out(fam, "#{c}-#{w}", build(w: w, h: "none", v: "nilf", r: "local", c: c)) }
    end
  when "cr"
    %w[stmt p asgn interp if or blkmap arg hash twice ordef retype opor multi condv].each do |c|
      RECV.keys.each { |r| out(fam, "#{c}-#{r}", build(w: "say", h: "none", v: "seq", r: r, c: c)) }
    end
  when "resc"
    %w[plus raise toa own].each do |w|
      %w[nilf seq raiser1 lit].each do |v|
        %w[stmt p asgn if interp].each { |c| out(fam, "#{w}-#{v}-#{c}", build(w: w, h: "none", v: v, r: "local", c: c, rescue_all: true)) }
      end
    end
  when "rand"
    rng = Random.new(220)
    n = 0
    while n < 450
      w = WRITERS.keys.sample(random: rng); h = HIST.keys.sample(random: rng)
      v = (rng.rand < 0.8 ? NILV : CTLV).sample(random: rng)
      r = RECV.keys.sample(random: rng); c = CTX.keys.sample(random: rng)
      src = build(w: w, h: h, v: v, r: r, c: c)
      next if src.nil?
      out(fam, "#{w}-#{h}-#{v}-#{r}-#{c}", src); n += 1
    end
  when "smoke"
    %w[nilf seq lit maybe].each { |v| %w[stmt p].each { |c| out(fam, "#{v}-#{c}", build(w: "ret", h: "none", v: v, r: "local", c: c)) } }
  end
  puts "#{fam}: #{Dir["/home/claude/r8/p220/g_#{fam}/*.rb"].size}"
end
