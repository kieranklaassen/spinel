#!/usr/bin/env ruby
# fam13-gen.rb OUT: a constant given a class by a path (`K = Conn::Plain`) where the body the
# path names holds the class, inherits it, or does not have it: there CRuby raises NameError,
# or a const_missing of the program answers with a builtin, another class of the program, or
# the class itself. The hook as `def self.`, in `class << self`, by define_singleton_method,
# from a module the body extends, on Object or on Module. The write at the program's level
# or in another body; one read and one object a program, so a line master has right stands
# alone. Then a bare value beside a const_set of the class's name, a write that stands
# before the class's definition, and the exception's rescue and raise. Written to OUT/p.
require 'fileutils'
out = ARGV[0] or abort "usage: fam13-gen.rb OUT"
FileUtils.mkdir_p("#{out}/p")
HOOKS = {   # [a line of Conn's body, text before Conn]
  none:    ["", ""],
  selfdef: ["  def self.const_missing(n) = RET\n", ""],
  sclass:  ["  class << self\n    def const_missing(n) = RET\n  end\n", ""],
  definer: ["  define_singleton_method(:const_missing) { |n| RET }\n", ""],
  extend:  ["  extend Hook\n", "module Hook\n  def const_missing(n) = RET\nend\n"],
  object:  ["", "class Object\n  def self.const_missing(n) = RET\nend\n"],
  module:  ["", "class Module\n  def const_missing(n) = RET\nend\n"],
  base:    ["", "class Root\n  def self.const_missing(n) = RET\nend\n"],
}
# where the class is: [text before Conn, a line of Conn's body, Conn's header, the value, the class's own path]
DEFS = {
  top:   ["class Plain; end\n", "", "class Conn", "Conn::Plain", "Plain"],
  other: ["module Elsewhere\n  class Plain; end\nend\n", "", "class Conn", "Conn::Plain", "Elsewhere::Plain"],
  own:   ["", "  class Plain; end\n", "class Conn", "Conn::Plain", "Conn::Plain"],
  inherited: ["class Base\n  class Plain; end\nend\n", "", "class Conn < Base", "Conn::Plain", "Base::Plain"],
}
RETS = { builtin: "Integer", another: "Another", itself: nil }
n = 0
emit = ->(name, text) { File.write("#{out}/p/#{name}.rb", text); n += 1 }
DEFS.each do |dk, (before, inner, header, value, cpath)|
  found = %i[own inherited].include?(dk)
  HOOKS.each do |hk, (hline, hbefore)|
    next if found && !%i[none selfdef module].include?(hk)
    next if hk == :base && dk != :top
    (hk == :none || found ? [:builtin] : RETS.keys).each do |rk|
      ret = RETS[rk] || "::#{cpath}"
      head = hk == :base ? "class Conn < Root" : header
      conn = "#{head}\n#{inner}#{hline.gsub("RET", ret)}end\n"
      pre = "class Another; end\n" + before + hbefore.gsub("RET", ret)
      { top: ["K = #{value}\n", "K"], held: ["module Holder\n  K = #{value}\nend\n", "Holder::K"] }.each do |pk, (write, kpath)|
        reads = {
          isa_own: "p #{cpath}.new.is_a?(#{kpath})\n",
          isa_int: "p 7.is_a?(#{kpath})\n",
          iof_own: "p #{cpath}.new.instance_of?(#{kpath})\n",
          meth_own: "def q(v) = v.kind_of?(#{kpath})\np q(#{cpath}.new)\n",
        }
        reads.each { |qk, line| emit.("m_#{dk}_#{hk}_#{rk}_#{pk}_#{qk}", pre + conn + write + line) }
      end
    end
  end
end
# a bare value in a body that sets a constant of the class's name by const_set
%w[Integer Another].each do |ret|
  ["const_set(:Plain, #{ret})", "self.const_set(\"Plain\", #{ret})"].each_with_index do |set, si|
    { own: "Plain.new", int: "7", another: "Another.new" }.each do |ok, obj|
      emit.("s_#{ret.downcase}_#{si}_#{ok}", "class Another; end\nclass Plain; end\nmodule M\n  #{set}\n  K = Plain\nend\np #{obj}.is_a?(M::K)\n")
    end
  end
end
# the write before the class is defined: the hook answers the name where the write stands
{ module: "class Module\n  def const_missing(n) = RET\nend\n", object: "class Object\n  def self.const_missing(n) = RET\nend\n" }.each do |hk, hook|
  %w[Integer Another].each do |ret|
    shapes = {
      bare: ["K = Plain\nclass Plain; end\n", "Plain", "K"],
      root: ["K = ::Plain\nclass Plain; end\n", "Plain", "K"],
      path: ["class Conn; end\nK = Conn::Plain\nclass Conn\n  class Plain; end\nend\n", "Conn::Plain", "K"],
      held: ["module Holder\n  K = ::Plain\nend\nclass Plain; end\n", "Plain", "Holder::K"],
      body: ["class Conn\n  K = Plain\n  class Plain; end\nend\n", "Conn::Plain", "Conn::K"],
    }
    shapes.each do |sk, (text, cpath, kpath)|
      { isa_own: "p #{cpath}.new.is_a?(#{kpath})\n", isa_int: "p 7.is_a?(#{kpath})\n", iof_own: "p #{cpath}.new.instance_of?(#{kpath})\n",
        meth_own: "def q(v) = v.kind_of?(#{kpath})\np q(#{cpath}.new)\n" }.each do |qk, line|
        emit.("o_#{hk}_#{ret.downcase}_#{sk}_#{qk}", "class Another; end\n" + hook.gsub("RET", ret) + text + line)
      end
    end
  end
end
# the exception's rescue and raise through the path
%i[top own].each do |dk|
  %i[none selfdef module].each do |hk|
    hline, hbefore = HOOKS[hk]
    cpath = dk == :top ? "Oops" : "Conn::Oops"
    pre = (dk == :top ? "class Oops < StandardError; end\n" : "") + hbefore.gsub("RET", "ArgumentError")
    conn = "class Conn\n#{"  class Oops < StandardError; end\n" if dk == :own}#{hline.gsub("RET", "ArgumentError")}end\nK = Conn::Oops\n"
    emit.("e_#{dk}_#{hk}_rescue", pre + conn + "p((begin; raise #{cpath}, \"m\"; rescue K; \"k\"; rescue StandardError; \"std\"; end))\n")
    emit.("e_#{dk}_#{hk}_raise", pre + conn + "p((begin; raise K, \"m\"; rescue #{cpath}; \"mine\"; rescue StandardError; \"std\"; end))\n")
    emit.("e_#{dk}_#{hk}_isa", pre + conn + "p((begin; raise #{cpath}, \"m\"; rescue StandardError => e; e.is_a?(K); end))\n")
  end
end
puts n
