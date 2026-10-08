#!/usr/bin/env ruby
# diamond-gen.rb LEVELS: a program whose class includes a diamond of modules LEVELS deep
# (two modules a level, each including both of the level below) and reads a constant that
# three bodies define, so the read is looked up through every ancestor. To standard output.
n = (ARGV[0] || 14).to_i
puts 'module Lib; class X; def foo = "foo"; end; end'
puts 'module Lib2; class X; def bar = "bar"; end; end'
puts 'class X; def hi = "hi"; end'
puts "module A#{n}; end; module B#{n}; end"
(n - 1).downto(1) { |k| puts "module A#{k}; include A#{k + 1}, B#{k + 1}; end; module B#{k}; include A#{k + 1}, B#{k + 1}; end" }
puts 'class User; include A1; def go = X.new.hi; end'
puts 'p User.new.go'
puts 'p Lib::X.new.foo, Lib2::X.new.bar'
