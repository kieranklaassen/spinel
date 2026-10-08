#!/usr/bin/env ruby
# fam12-gen.rb OUT: two sets for the guard of the is_a? constant rewrite.
# OUT/lib: a constant read or written in a body whose superclass or mixed-in module is a
# library's (Socket, Timeout, Date), a builtin with no constants (Comparable, StandardError),
# the program's own, or one the program names like a library's (its own Vector); the program's
# class named as a constant of the library's or not.
# OUT/sent: const_set, remove_const and private_constant reached through send, __send__ and
# public_send by a Symbol, a String, a variable or a second send, and the program's own is_a?
# defined by define_method or alias_method under a literal or a computed name.
require 'fileutils'
out = ARGV[0] or abort "usage: fam12-gen.rb OUT"
%w[lib sent].each { |d| FileUtils.mkdir_p("#{out}/#{d}") }
n = 0
# [tag, lines before, the body's header, its first line, a constant the ancestor holds]
ANC = [
  ["socket_sub",   "require \"socket\"\n",  "class Conn < Socket", nil, "Option"],
  ["socket_open",  "require \"socket\"\n",  "class Socket", nil, "Option"],
  ["socket_mix",   "require \"socket\"\n",  "class Conn", "include Socket::Constants", "AF_INET"],
  ["timeout_mix",  "require \"timeout\"\n", "class Conn", "include Timeout", "Error"],
  ["date_sub",     "require \"date\"\n",    "class Conn < Date", nil, "Infinity"],
  ["comparable",   "",                      "class Conn", "include Comparable", "Option"],
  ["stderror",     "",                      "class Conn < StandardError", nil, "Option"],
  ["own_base",     "class Base; end\nmodule Mix; end\n", "class Conn < Base", "include Mix", "Option"],
  ["own_vector",   "class Vector; end\n",   "class Conn < Vector", nil, "Option"],
  ["struct",       "",                      "class Conn < Struct.new(:a)", nil, "Option"],
  ["math_mix",     "",                      "class Conn", "include Math", "PI"],
  ["send_mix",     "",                      "class Conn", "send(:include, Math)", "PI"],
  ["cond_mix",     "",                      "class Conn", "include Math if true", "PI"],
]
ANC.each do |tag, pre, header, first, theirs|
  [theirs, "Plain"].each do |name|
    body = header[/\A(?:class|module) (\w+)/, 1]
    fl = first ? "  #{first}\n" : ""
    forms = {
      # the constant at the program's level, read in the body
      read_in:   "#{name} = String\n#{header}\n#{fl}  def self.q(v) = v.is_a?(#{name})\nend\np [\"s\", 7].map { |v| #{body}.q(v) }\n",
      read_iof:  "#{name} = String\n#{header}\n#{fl}  def self.q(v) = v.instance_of?(#{name})\nend\np [\"s\", 7].map { |v| #{body}.q(v) }\n",
      # the program's level reads its own
      read_top:  "#{name} = String\n#{header}\n#{fl}end\np [\"s\", 7].map { |v| v.is_a?(#{name}) }\n",
      # a class of the program's by that name, held by a constant written in the body
      val_in:    "class #{name}; end\n#{header}\n#{fl}  K = #{name}\nend\np [#{name}.new, 7].map { |v| v.is_a?(#{body}::K) }\n",
      val_path:  "class #{name}; end\n#{header}\n#{fl}end\nK = #{body}::#{name}\np [#{name}.new, 7].map { |v| v.is_a?(K) }\n",
      val_top:   "class #{name}; end\n#{header}\n#{fl}end\nK = #{name}\np [#{name}.new, 7].map { |v| v.is_a?(K) }\n",
    }
    forms.each do |fk, text|
      File.write("#{out}/lib/l_#{tag}_#{name == theirs ? "theirs" : "plain"}_#{fk}.rb", pre + text)
      n += 1
    end
  end
end
m = 0
# how the constant is set again, hidden or taken away: [tag, the line, K stays Integer after it]
AGAIN = [
  ["plain_sym",     "Object.const_set(:K, String)"],
  ["send_sym",      "Object.send(:const_set, :K, String)"],
  ["send_str",      "Object.send(\"const_set\", :K, String)"],
  ["send_var",      "m = :const_set\nObject.send(m, :K, String)"],
  ["send_send",     "Object.send(:send, :const_set, :K, String)"],
  ["usend_var",     "m = :const_set\nObject.__send__(m, :K, String)"],
  ["psend_str",     "Object.public_send(\"const_set\", \"K\", String)"],
  ["psend_psend",   "Object.public_send(:public_send, :const_set, :K, String)"],
  ["send_name_var", "k = :K\nObject.send(:const_set, k, String)"],
  ["send_splat",    "a = [:const_set, :K, String]\nObject.send(*a)"],
  ["send_other",    "s = [3, 1, 2].send(:sort)\nt = [3, 1, 2].send(\"max\")"],        # a send of something else, by literals
  ["send_other_var", "op = :sort\ns = [3, 1, 2].send(op)"],                          # by a variable: any method
]
READS = {
  top:   ["", "p [7, \"s\"].map { |v| v.is_a?(K) }\n"],
  kof:   ["", "p [7, \"s\"].map { |v| v.kind_of?(K) }\n"],
  meth:  ["def q(v) = v.is_a?(K)\n", "p [7, \"s\"].map { |v| q(v) }\n"],
  body:  ["class Box\n  def self.q(v) = v.is_a?(K)\nend\n", "p [7, \"s\"].map { |v| Box.q(v) }\n"],
}
AGAIN.each do |tag, line|
  READS.each do |rk, (defs, read)|
    File.write("#{out}/sent/s_#{tag}_#{rk}.rb", "$VERBOSE = nil\nK = Integer\n" + defs + line + "\n" + read)
    m += 1
  end
end
# the program's own is_a? under a definer: [tag, the lines inside class Proxy]
OWN = [
  ["def",          "def is_a?(k) = false"],
  ["dm_sym",       "define_method(:is_a?) { |k| false }"],
  ["dm_str",       "define_method(\"is_a?\") { |k| false }"],
  ["dm_computed",  "define_method((\"is_\" + \"a?\").to_sym) { |k| false }"],
  ["dm_var",       "n = :is_a?\n  define_method(n) { |k| false }"],
  ["dm_send",      "send(:define_method, (\"is_\" + \"a?\").to_sym) { |k| false }"],
  ["am_sym",       "def no(k) = false\n  alias_method :is_a?, :no"],
  ["am_var",       "def no(k) = false\n  n = \"is_a?\".to_sym\n  alias_method n, :no"],
  ["alias",        "def no(k) = false\n  alias is_a? no"],
  ["dm_other",     "define_method(:other) { |k| false }"],                           # a definer of another name, literal
  ["dm_other_var", "n = :other\n  define_method(n) { |k| false }"],                  # by a variable: any name
  ["dsm_computed", "define_singleton_method((\"is_\" + \"a?\").to_sym) { |k| false }"],
]
OWN.each do |tag, lines|
  [["inst", "p [Proxy.new, 7].map { |v| v.is_a?(K) }\n"], ["kof", "p [Proxy.new, 7].map { |v| v.kind_of?(K) }\n"],
   ["cls", "p Proxy.is_a?(K), Proxy.new.instance_of?(K)\n"]].each do |rk, read|
    File.write("#{out}/sent/o_#{tag}_#{rk}.rb", "class Proxy\n  #{lines}\nend\nK = Proxy\n" + read)
    m += 1
  end
end
puts n, m
