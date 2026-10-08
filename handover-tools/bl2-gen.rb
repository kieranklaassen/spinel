#!/usr/bin/env ruby
# bl2-gen.rb OUT: attacks on `rescue K` and `raise K` through a constant: programs where the
# constant does not hold the class when the clause runs, where the read names another constant,
# or where the program answers `===`, `exception` or `raise` itself. Whatever CRuby raises is
# caught by an outer rescue that prints its class.
out = ARGV[0] or abort "usage: bl2-gen.rb OUT"
Dir.mkdir("#{out}/p") rescue nil
T = { arg: ["", "ArgumentError", "TypeError"],
      my:  ["class MyErr < StandardError; end\nclass OtherErr < StandardError; end\n", "MyErr", "OtherErr"] }
OUTER = ->(body) { "begin\n#{body.gsub(/^/, '  ')}rescue Exception => o\n  puts \"outer \#{o.class}\"\nend\n" }
n = 0
put = ->(name, text) { File.write("#{out}/p/b2_#{name}.rb", text); n += 1 }
T.each do |t, (su, c, o)|
  res = ->(k, cls = c) { "begin\n  raise #{cls}, \"x\"\nrescue #{k} => e\n  puts \"got \#{e.class}\"\nend\n" }
  rai = ->(k) { "raise #{k}, \"x\"\n" }
  { r: res, x: rai }.each do |f, use|
    # the clause runs before the constant is written
    put.("early_#{f}_#{t}", "#{su}def m\n#{use.('LATE').gsub(/^/, '  ')}end\n#{OUTER.("m\n")}LATE = #{c}\n")
    put.("lateok_#{f}_#{t}", "#{su}def m\n#{use.('LATE').gsub(/^/, '  ')}end\nLATE = #{c}\n#{OUTER.("m\n")}")
    put.("replaced_#{f}_#{t}", "#{su}class Gate\n  def m = puts(\"none\")\nend\nGate.new.m\nAFTER = #{c}\nclass Gate\n  def m\n#{use.('AFTER').gsub(/^/, '    ')}  end\nend\n")
    put.("cond_#{f}_#{t}", "#{su}K = #{c} if ARGV.empty?\n#{OUTER.(use.('K'))}")
    # written again, hidden or taken away by its name
    put.("twice_#{f}_#{t}", "#{su}K = #{o}\nK = #{c}\n#{OUTER.(use.('K'))}")
    put.("constset_#{f}_#{t}", "#{su}K = #{c}\nObject.const_set(:K, #{o})\n#{OUTER.(use.('K'))}")
    put.("private_#{f}_#{t}", "#{su}module Vault\n  HK = #{c}\n  private_constant :HK\nend\n#{OUTER.(use.('Vault::HK'))}")
    put.("removed_#{f}_#{t}", "#{su}K = #{c}\nbegin\n  Object.send(:remove_const, :K)\nrescue NoMethodError\nend\n#{OUTER.(use.('K'))}")
    # another body's constant of that name
    put.("otherbody_#{f}_#{t}", "#{su}module Dock\n  class Bin < StandardError; end\nend\nclass Yard\n  Bin = #{c}\nend\n#{OUTER.(use.('Dock::Bin'))}")
    put.("ownbody_#{f}_#{t}", "#{su}class Yard\n  Bin = #{c}\n  def self.m\n#{use.('Bin').gsub(/^/, '    ')}  end\nend\n#{OUTER.("Yard.m\n")}")
    # a body CRuby looks up elsewhere first
    put.("process_#{f}_#{t}", "#{su}Status = #{c}\nmodule Process\n  def self.m\n#{use.('Status').gsub(/^/, '    ')}  end\nend\n#{OUTER.("Process.m\n")}")
    put.("math_#{f}_#{t}", "#{su}E = #{c}\nclass Calc\n  include Math\n  def m\n#{use.('E').gsub(/^/, '    ')}  end\nend\n#{OUTER.("Calc.new.m\n")}")
    put.("plain_#{f}_#{t}", "#{su}K = #{c}\nclass Plain\n  def m\n#{use.('K').gsub(/^/, '    ')}  end\nend\n#{OUTER.("Plain.new.m\n")}")
    put.("basic_#{f}_#{t}", "#{su}class Blank < BasicObject; end\nK = #{c}\n#{OUTER.(use.('K'))}")
    # values that only spell a name define nothing
    put.("values_#{f}_#{t}", "#{su}K = #{c}\nstate = [:fail, :raise, :exception, \"raise\"]\nputs state.size\n#{OUTER.(use.('K'))}")
  end
  next unless t == :my
  # the program answers === , exception or raise itself
  { def: "  def self.===(e) = false\n", sclass: "  class << self\n    def ===(e) = false\n  end\n",
    dsm: "  define_singleton_method(:===) { |e| false }\n", dyn: "  %i[===].each { |n| define_singleton_method(n) { |e| false } }\n",
  }.each { |f, d| put.("owneqq_#{f}", "class MyErr < StandardError\n#{d}end\nK = MyErr\n#{OUTER.(res.('K'))}") }
  { def: "  def self.exception(*a) = ArgumentError.new(\"swapped\")\n",
    dsm: "  define_singleton_method(:exception) { |*a| ArgumentError.new(\"swapped\") }\n",
    alias: "  class << self\n    def swap(*a) = ArgumentError.new(\"swapped\")\n    alias exception swap\n  end\n",
  }.each { |f, d| put.("ownexc_#{f}", "class MyErr < StandardError\n#{d}end\nK = MyErr\n#{OUTER.(rai.('K'))}") }
  put.("ownraise_def", "class MyErr < StandardError; end\nK = MyErr\ndef raise(*a) = puts(\"no raise\")\n#{OUTER.(rai.('K'))}")
  put.("ownfail_def", "class MyErr < StandardError; end\nK = MyErr\ndef fail(*a) = puts(\"no fail\")\n#{OUTER.("fail K, \"x\"\n")}")
end
puts n
