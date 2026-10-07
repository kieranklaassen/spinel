#!/usr/bin/env ruby
# fam10-gen.rb OUT: a constant written by a required file, read through is_a?, rescue and raise.
# A require that stands inside a def, a lambda, a block or an expression loads its file when
# that runs; the compiler splices the file's text ahead of the statement. Each program reads
# the constant before anything loads the file (CRuby: not defined yet) or after a require
# that is a statement of its own (CRuby: defined). OUT/p/lib holds the required files.
require 'fileutils'
out = ARGV[0] or abort "usage: fam10-gen.rb OUT"
FileUtils.mkdir_p("#{out}/p/lib")
n = 0
# how the file is required => [text before the reads, loaded by the time the reads run?]
REQ = {
  top:      ->(f) { ["require_relative \"lib/#{f}\"\n", true] },
  topparen: ->(f) { ["require_relative(\"lib/#{f}\")\n", true] },
  via:      ->(f) { ["require_relative \"lib/#{f}_via\"\n", true] },        # a file that requires the file
  def:      ->(f) { ["def load_k = require_relative(\"lib/#{f}\")\n", false] },
  defbody:  ->(f) { ["def load_k\n  require_relative \"lib/#{f}\"\nend\n", false] },
  lambda:   ->(f) { ["LOAD = -> { require_relative \"lib/#{f}\" }\n", false] },
  proc:     ->(f) { ["load_k = proc { require_relative \"lib/#{f}\" }\n", false] },
  class:    ->(f) { ["class Loader\n  def self.go = require_relative(\"lib/#{f}\")\nend\n", false] },
  viadef:   ->(f) { ["def load_k = require_relative(\"lib/#{f}_via\")\n", false] },  # the outer require is late
  value:    ->(f) { ["ok = require_relative(\"lib/#{f}\")\n", true] },      # spliced ahead of its own statement
  iftrue:   ->(f) { ["if ARGV.empty?\n  require_relative \"lib/#{f}\"\nend\n", true] },
  iffalse:  ->(f) { ["if ARGV.any?\n  require_relative \"lib/#{f}\"\nend\n", false] },
  modfalse: ->(f) { ["require_relative \"lib/#{f}\" if ARGV.any?\n", false] },
  andfalse: ->(f) { ["ARGV.any? && require_relative(\"lib/#{f}\")\n", false] },
  begin:    ->(f) { ["begin\n  require_relative \"lib/#{f}\"\nrescue LoadError\n  puts \"none\"\nend\n", true] },
}
READ = {
  isa_top:     "p(defined?(K) ? 7.is_a?(K) : false)\n",
  isa_meth:    "def int?(v) = defined?(K) ? v.is_a?(K) : false\np int?(7)\n",
  isa_rescue:  "def int?(v)\n  v.is_a?(K)\nrescue NameError\n  false\nend\np int?(7)\n",
  kind_boxed:  "p [7, \"s\"].map { |v| defined?(K) ? v.kind_of?(K) : false }\n",
  rescue_meth: "def try\n  raise ArgumentError, \"x\"\nrescue EK\n  \"got\"\nend\nbegin\n  puts try\nrescue ArgumentError, NameError => e\n  puts \"outer \#{e.class}\"\nend\n",
  raise_top:   "begin\n  raise EK, \"x\"\nrescue ArgumentError, NameError => e\n  puts \"outer \#{e.class}\"\nend\n",
}
REQ.each do |rq, mk|
  READ.each do |rd, text|
    name = "b10_#{rq}_#{rd}"
    File.write("#{out}/p/lib/#{name}_k.rb", "K = Integer\nEK = ArgumentError\n")
    File.write("#{out}/p/lib/#{name}_k_via.rb", "require_relative \"#{name}_k\"\nVIA = 1\n")
    req, _ = mk.("#{name}_k")
    File.write("#{out}/p/#{name}.rb", req + text)
    n += 1
  end
end
puts n
