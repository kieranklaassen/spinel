#!/usr/bin/env ruby
# fam11-gen.rb OUT: a constant given a class by a bare name, written in a body where CRuby may
# read a constant of its own before the program's class of that name: the body mixes in, opens
# or inherits Math, Process, Errno, File or Enumerator, and the program has a class named as
# theirs (DomainError, Status, ENOENT, Stat, Lazy) or by a name they do not have (Plain).
# The write in that body, in a body nested in it, in another body, or at the program's level;
# the value bare or rooted (`::Name`); read by is_a? and instance_of? in the body and by path,
# and by rescue and raise where the class is an exception's. One read a program.
require 'fileutils'
out = ARGV[0] or abort "usage: fam11-gen.rb OUT"
FileUtils.mkdir_p("#{out}/p")
# [the holder, its constant, how a body takes it in: the header of the body and its first line]
HOLDERS = [
  ["Math", "DomainError", "module Calc", "include Math", "Calc"],
  ["Process", "Status", "module Process", nil, "Process"],
  ["Errno", "ENOENT", "module Calc", "include Errno", "Calc"],
  ["File", "Stat", "class Calc < File", nil, "Calc"],
  ["Enumerator", "Lazy", "class Enumerator", nil, "Enumerator"],
]
ind = ->(s, n = 1) { s.gsub(/^(?=.)/, "  " * n) }
n = 0
HOLDERS.each do |holder, theirs, header, mix, body|
  [theirs, "Plain"].each do |name|
    exc = %w[DomainError ENOENT].include?(name)
    cls = "class #{name}#{" < StandardError" if exc}; end\n"
    mk = exc ? "#{name}.new(\"m\")" : "#{name}.new"
    ["#{name}", "::#{name}"].each_with_index do |value, vi|
      # where the write stands: [the text with QUERY for a method of its body, the path of the constant]
      places = {
        body:   ["#{header}\n#{ind.("#{mix}\n") if mix}  K = #{value}\nQUERY1end\n", "#{body}::K"],
        nested: ["#{header}\n#{ind.("#{mix}\n") if mix}  module In\n    K = #{value}\nQUERY2  end\nend\n", "#{body}::In::K"],
        other:  ["#{header}\n#{ind.("#{mix}\n") if mix}end\nmodule Elsewhere\n  K = #{value}\nQUERY1end\n", "Elsewhere::K"],
        top:    ["#{header}\n#{ind.("#{mix}\n") if mix}end\nK = #{value}\nmodule Elsewhere\nQUERY1end\n", "K"],
      }
      places.each do |pk, (text, kpath)|
        qbody = pk == :nested ? "#{body}::In" : pk == :body ? body : "Elsewhere"
        reads = {
          isa_in:  ["def self.q(v) = v.is_a?(K)\n", "p [#{mk}, 7].map { |v| #{qbody}.q(v) }\n"],
          iof_in:  ["def self.q(v) = v.instance_of?(K)\n", "p [#{mk}, 7].map { |v| #{qbody}.q(v) }\n"],
          isa_path: ["", "p [#{mk}, 7].map { |v| v.is_a?(#{kpath}) }\n"],
          kof_path: ["", "p [#{mk}, 7].map { |v| v.kind_of?(#{kpath}) }\n"],
        }
        if exc
          reads[:rescue_path] = ["", "p((begin; raise #{name}, \"m\"; rescue #{kpath}; \"k\"; rescue StandardError; \"std\"; end))\n"]
          reads[:rescue_in] = ["def self.q\n  yield\nrescue K\n  \"k\"\nrescue StandardError\n  \"std\"\nend\n", "p #{qbody}.q { raise #{name}, \"m\" }\n"]
          reads[:raise_path] = ["", "p((begin; raise #{kpath}, \"m\"; rescue #{name}; \"mine\"; rescue StandardError; \"std\"; end))\n"]
        end
        reads.each do |rk, (meth, line)|
          t = text.sub("QUERY1", ind.(meth)).sub("QUERY2", ind.(meth, 2))
          File.write("#{out}/p/h_#{holder.downcase}_#{name == theirs ? "theirs" : "plain"}_#{vi == 0 ? "bare" : "root"}_#{pk}_#{rk}.rb", cls + t + line)
          n += 1
        end
      end
    end
  end
end
# The value by a path (`K = Calc::DomainError`): CRuby looks the last name up in Calc and in
# what Calc mixes in or inherits, so it is the program's class only where Calc defines it. The
# class at the program's level, inside the body, or one in each; the write at the program's
# level, in another body, or in the body itself. Written to OUT/pv.
FileUtils.mkdir_p("#{out}/pv")
m = 0
HOLDERS.each do |holder, theirs, header, mix, body|
  [theirs, "Plain"].each do |name|
    exc = %w[DomainError ENOENT].include?(name)
    sup = exc ? " < StandardError" : ""
    arg = exc ? "(\"m\")" : ""
    %i[top own both].each do |defs|
      next if defs != :top && header !~ /Calc/   # a class added to CRuby's own namespace is CRuby's
      top = defs == :own ? "" : "class #{name}#{sup}; end\n"
      inner = defs == :top ? "" : "  class #{name}#{sup}; end\n"
      open = "#{header}\n#{ind.("#{mix}\n") if mix}#{inner}end\n"
      objs = { top: ["#{name}.new#{arg}"], own: ["#{body}::#{name}.new#{arg}"], both: ["#{name}.new#{arg}", "#{body}::#{name}.new#{arg}"] }[defs]
      value = "#{body}::#{name}"
      places = {
        top:   ["K = #{value}\nmodule Elsewhere\nQUERYend\n", "K", "Elsewhere"],
        other: ["module Elsewhere\n  K = #{value}\nQUERYend\n", "Elsewhere::K", "Elsewhere"],
        body:  ["#{header.sub(/ < \w+/, "")}\n  K = #{value}\nQUERYend\n", "#{body}::K", body],
      }
      places.each do |pk, (text, kpath, qbody)|
        list = "[#{(objs + ["7"]).join(", ")}]"
        reads = {
          isa_path: ["", "p #{list}.map { |v| v.is_a?(#{kpath}) }\n"],
          iof_path: ["", "p #{list}.map { |v| v.instance_of?(#{kpath}) }\n"],
          isa_in:   ["def self.q(v) = v.is_a?(K)\n", "p #{list}.map { |v| #{qbody}.q(v) }\n"],
        }
        if exc
          raised = defs == :own ? "#{body}::#{name}" : name
          reads[:rescue_path] = ["", "p((begin; raise #{raised}, \"m\"; rescue #{kpath}; \"k\"; rescue StandardError; \"std\"; end))\n"]
          reads[:raise_path] = ["", "p((begin; raise #{kpath}, \"m\"; rescue #{raised}; \"mine\"; rescue StandardError; \"std\"; end))\n"]
        end
        reads.each do |rk, (meth, line)|
          File.write("#{out}/pv/v_#{holder.downcase}_#{name == theirs ? "theirs" : "plain"}_#{defs}_#{pk}_#{rk}.rb", top + open + text.sub("QUERY", ind.(meth)) + line)
          m += 1
        end
      end
    end
  end
end
puts n, m
