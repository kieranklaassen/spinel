#!/usr/bin/env ruby
# early-gen.rb OUT: a call made before the constant's write that the compiler may bind to a
# method body written after it. OUT/p: is_a?(K); OUT/t: the class named; OUT/e: K === v.
# Drop each program's last line for the form that makes only the early call.
out = ARGV[0] or abort "usage: early-gen.rb OUT"
shapes = {
  "reopen"   => "class A\n  def g(v) = false\nend\np A.new.g(7)\nK = Integer\nclass A\n  def g(v) = TEST\nend\np A.new.g(7)\n",
  "sub"      => "class P\n  def g(v) = false\nend\nclass A < P\nend\np A.new.g(7)\nK = Integer\nclass A\n  def g(v) = TEST\nend\np A.new.g(7)\n",
  "alias"    => "class A\n  def h(v) = false\n  alias g h\nend\np A.new.g(7)\nK = Integer\nclass A\n  def g(v) = TEST\nend\np A.new.g(7)\n",
  "mmissing" => "class A\n  def method_missing(n, *a) = false\n  def respond_to_missing?(n, p = false) = true\nend\np A.new.g(7)\nK = Integer\nclass A\n  def g(v) = TEST\nend\np A.new.g(7)\n",
  "nomethod" => "class A\nend\np((A.new.g(7) rescue false))\nK = Integer\nclass A\n  def g(v) = TEST\nend\np A.new.g(7)\n",
  "respond"  => "class A\nend\na = A.new\np(a.respond_to?(:g) ? a.g(7) : false)\nK = Integer\nclass A\n  def g(v) = TEST\nend\np a.g(7)\n",
  "include"  => "module M\n  def g(v) = false\nend\nclass A\n  include M\nend\np A.new.g(7)\nK = Integer\nclass A\n  def g(v) = TEST\nend\np A.new.g(7)\n",
  "prepend"  => "class A\n  def g(v) = false\nend\np A.new.g(7)\nK = Integer\nmodule M\n  def g(v) = TEST\nend\nclass A\n  prepend M\nend\np A.new.g(7)\n",
  "defmeth"  => "class A\n  def g(v) = false\nend\np A.new.g(7)\nK = Integer\nclass A\n  define_method(:g) { |v| TEST }\nend\np A.new.g(7)\n",
  "toplevel" => "def g(v) = false\np g(7)\nK = Integer\ndef g(v) = TEST\np g(7)\n",
  "single"   => "o = Object.new\ndef o.g(v) = false\np o.g(7)\nK = Integer\ndef o.g(v) = TEST\np o.g(7)\n",
  "modfn"    => "module U\n  def self.g(v) = false\nend\np U.g(7)\nK = Integer\nmodule U\n  def self.g(v) = TEST\nend\np U.g(7)\n",
}
shapes.each do |n, s|
  File.write("#{out}/p/#{n}.rb", s.sub("TEST", "v.is_a?(K)"))
  File.write("#{out}/t/#{n}.rb", s.sub("TEST", "v.is_a?(Integer)"))
  File.write("#{out}/e/#{n}.rb", s.sub("TEST", "(K === v)"))
end
