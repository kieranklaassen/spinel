#!/usr/bin/env ruby
# fam9-gen.rb OUT: a bare constant read in a body that CRuby looks up elsewhere first (a body of
# CRuby's own, a class that inherits or mixes in one that holds constants), a BasicObject
# subclass, a constant taken away by remove_const, and the query defined by a string of its name. Every raise CRuby makes is rescued into
# false, the answer master's fault prints, so a program here can be right on master.
out = ARGV[0] or abort "usage: fam9-gen.rb OUT"
Dir.mkdir("#{out}/p") rescue nil
T = { int: ["", "Integer", "7", '"s"'], user: ["class Pt; end\nclass Qt; end\n", "Pt", "Pt.new", "Qt.new"] }
SHOW = "def show\n  p yield\nrescue NameError, TypeError\n  p false\nend\n"
# name of the constant, the body that reads it bare, the call that reaches that read
H = {
  procmod:   ["Status",  "module Process\n  def self.t(v) = v.Q(Status)\nend\n", "Process.t(V)"],
  floatcls:  ["EPSILON", "class Float\n  def t(v) = v.Q(EPSILON)\nend\n", "1.5.t(V)"],
  mathinc:   ["E",  "class Calc\n  include Math\n  def t(v) = v.Q(E)\nend\n", "Calc.new.t(V)"],
  mathprep:  ["PI", "class Calc\n  prepend Math\n  def t(v) = v.Q(PI)\nend\n", "Calc.new.t(V)"],
  mathlate:  ["E",  "class Calc\n  def t(v) = v.Q(E)\nend\nCalc.include(Math)\n", "Calc.new.t(V)"],
  mathsend:  ["E",  "class Calc\n  def t(v) = v.Q(E)\nend\nCalc.send(:include, Math)\n", "Calc.new.t(V)"],
  mathext:   ["E",  "class Calc\n  extend Math\n  class << self\n    def t(v) = v.Q(E)\n  end\nend\n", "Calc.t(V)"],
  mathvia:   ["E",  "module Helpers\n  include Math\nend\nclass Calc\n  include Helpers\n  def t(v) = v.Q(E)\nend\n", "Calc.new.t(V)"],
  filesub:   ["Stat", "class MyFile < File\n  def self.t(v) = v.Q(Stat)\nend\n", "MyFile.t(V)"],
  filenew:   ["Stat", "Mine = Class.new(File)\nclass Mine\n  def self.t(v) = v.Q(Stat)\nend\n", "Mine.t(V)"],
  sclass:    ["K",  "O = Object.new\nclass << O\n  def t(v) = v.Q(K)\nend\n", "O.t(V)"],
  cmp:       ["K",  "class Ver\n  include Comparable\n  def <=>(o) = 0\n  def t(v) = v.Q(K)\nend\n", "Ver.new.t(V)"],
  errsub:    ["K",  "class MyErr < StandardError\n  def t(v) = v.Q(K)\nend\n", "MyErr.new(\"m\").t(V)"],
  structsub: ["K",  "class Row < Struct.new(:a)\n  def t(v) = v.Q(K)\nend\n", "Row.new(1).t(V)"],
  plain:     ["K",  "class Plain\n  def t(v) = v.Q(K)\nend\n", "Plain.new.t(V)"],
  selfs:     ["K",  "class Plain\n  class << self\n    def t(v) = v.Q(K)\n  end\nend\n", "Plain.t(V)"],
}
n = 0
put = ->(name, text) { File.write("#{out}/p/b9_#{name}.rb", text); n += 1 }
T.each do |t, (su, c, y, no)|
  %w[is_a? kind_of? instance_of?].each do |q|
    qn = q.delete("?")
    H.each do |h, (k, body, call)|
      body = body.gsub("Q", q)
      head = "#{su}#{SHOW}#{k} = #{c}\n#{body}"
      both = ->(tpl) { "show { #{tpl.sub('V', y)} }\nshow { #{tpl.sub('V', no)} }\n" }
      {
        nested: both.(call),
        top:    both.("V.#{q}(#{k})"),
        meth:   "def chk(v) = v.#{q}(#{k})\n" + both.("chk(V)"),
        other:  "class Other\n  def t(v) = v.#{q}(#{k})\nend\n" + both.("Other.new.t(V)"),
        rooted: both.("V.#{q}(::#{k})"),
      }.each { |s, tail| put.("#{h}_#{s}_#{t}_#{qn}", head + tail) }
    end
    # a BasicObject subclass: its instance answers no kind query, its body reads no outer constant
    bshow = "def show\n  p yield\nrescue NameError, NoMethodError\n  p false\nend\n"
    { sub: "class Blank < BasicObject\n  def t(v) = v.#{q}(K)\nend\n",
      new: "Blank = Class.new(BasicObject) do\n  def t(v) = 7\nend\n" }.each do |f, blank|
      { blank: "Blank", val: c }.each do |kn, kv|
        head = "#{su}#{bshow}#{blank}K = #{kv}\n"
        put.("basic_#{f}_#{kn}_typed_#{t}_#{qn}", head + "b = Blank.new\nshow { b.#{q}(K) }\n")
        put.("basic_#{f}_#{kn}_boxed_#{t}_#{qn}", head + "[Blank.new, #{y}].each { |v| show { v.#{q}(K) } }\n")
        put.("basic_#{f}_#{kn}_body_#{t}_#{qn}", head + "show { Blank.new.t(#{y}) }\nshow { Blank.new.t(Blank.new) }\n")
        put.("basic_#{f}_#{kn}_else_#{t}_#{qn}", head + "show { #{y}.#{q}(K) }\nshow { #{no}.#{q}(K) }\n")
      end
    end
    # remove_const: Spinel raises NoMethodError at it; the read after it is NameError in CRuby
    tail = "#{SHOW}show { #{y}.#{q}(K) }\ndef chk(v) = v.#{q}(K)\nshow { chk(#{y}) }\n"
    { send: "begin\n  Object.send(:remove_const, :K)\nrescue NoMethodError\nend\n",
      mod:  "(Object.send(:remove_const, :K)) rescue nil\n",
      str:  "begin\n  Object.send(:remove_const, \"K\")\nrescue NoMethodError\nend\n",
      body: "class Object\n  begin\n    remove_const(:K)\n  rescue NoMethodError\n  end\nend\n",
    }.each { |f, rm| put.("rmconst_#{f}_#{t}_#{qn}", "#{su}K = #{c}\n#{rm}#{tail}") }
    # the query defined by a string of its name, and Class.new under BasicObject by a rooted path
    put.("ownstr_define_#{t}_#{qn}", "#{su}class Odd\n  define_method(\"#{q}\") { |k| false }\nend\nK = Odd\np [Odd.new, #{y}].map { |v| v.#{q}(K) }\n")
    put.("ownstr_alias_#{t}_#{qn}", "#{su}class Odd\n  def mine(k) = false\n  alias_method \"#{q}\", :mine\nend\nK = Odd\np [Odd.new, #{y}].map { |v| v.#{q}(K) }\n")
  end
end
puts n
