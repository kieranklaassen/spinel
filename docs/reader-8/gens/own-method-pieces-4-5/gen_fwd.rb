#!/usr/bin/env ruby
# Second reader 8, pieces 4 and 5: the forwarding forms (asked for on master
# 26d456ec, where ForwardingArgumentsNode got a node kind).  A method that
# forwards with `...`, `*args`, `**opts`, `&blk` to an own object_id / __id__
# / ivar reflection method, and an own method of those names that itself
# takes `(...)`.
# usage: gen_fwd.rb OUT4 OUT5
require "fileutils"
def emitter(out)
  FileUtils.mkdir_p(out)
  n = 0; seen = {}
  lambda do |tag, src|
    next if src.nil? || seen[src]
    seen[src] = true
    n += 1
    File.write(File.join(out, format("%04d_%s.rb", n, tag.gsub(/[^A-Za-z0-9_]/, "_"))), src)
  end
end
HEAD = "  def initialize(n) = @n = n\n  def n = @n\n"

# forwarders: [label, text with NAME, call expression given (recv, extra-args-with-leading-comma-or-empty)]
def forwarders(m)
  {
    "dots"      => ["def fwd(o, ...) = o.#{m}(...)\n", ->(r, a) { "fwd(#{r}#{a})" }],
    "dotsblk"   => ["def fwd(o, ...)\n  o.#{m}(...)\nend\n", ->(r, a) { "fwd(#{r}#{a})" }],
    "rest"      => ["def fwd(o, *args) = o.#{m}(*args)\n", ->(r, a) { "fwd(#{r}#{a})" }],
    "opts"      => ["def fwd(o, **opts) = o.#{m}(**opts)\n", ->(r, a) { a.empty? ? "fwd(#{r})" : nil }],
    "blk"       => ["def fwd(o, &blk) = o.#{m}(&blk)\n", ->(r, a) { a.empty? ? "fwd(#{r})" : nil }],
    "blkgiven"  => ["def fwd(o, &blk) = o.#{m}(&blk)\n", ->(r, a) { a.empty? ? "fwd(#{r}) { 9 }" : nil }],
    "all"       => ["def fwd(o, *args, **opts, &blk) = o.#{m}(*args, **opts, &blk)\n", ->(r, a) { "fwd(#{r}#{a})" }],
    "restblk"   => ["def fwd(o, *args, &blk) = o.#{m}(*args, &blk)\n", ->(r, a) { "fwd(#{r}#{a})" }],
    "anon"      => ["def fwd(o, *) = o.#{m}(*)\n", ->(r, a) { "fwd(#{r}#{a})" }],
    "anonblk"   => ["def fwd(o, &) = o.#{m}(&)\n", ->(r, a) { a.empty? ? "fwd(#{r})" : nil }],
    "anonkw"    => ["def fwd(o, **) = o.#{m}(**)\n", ->(r, a) { a.empty? ? "fwd(#{r})" : nil }],
    "send"      => ["def fwd(o, ...) = o.send(...)\n", ->(r, a) { "fwd(#{r}, :#{m}#{a})" }],
    "sendname"  => ["def fwd(o, name, ...) = o.send(name, ...)\n", ->(r, a) { "fwd(#{r}, :#{m}#{a})" }],
    "sendrest"  => ["def fwd(o, *args) = o.send(:#{m}, *args)\n", ->(r, a) { "fwd(#{r}#{a})" }],
    "psend"     => ["def fwd(o, ...) = o.public_send(...)\n", ->(r, a) { "fwd(#{r}, :#{m}#{a})" }],
    "usend"     => ["def fwd(o, *args) = o.__send__(:#{m}, *args)\n", ->(r, a) { "fwd(#{r}#{a})" }],
    "twohop"    => ["def fwd2(o, ...) = o.#{m}(...)\ndef fwd(o, ...) = fwd2(o, ...)\n", ->(r, a) { "fwd(#{r}#{a})" }],
    "lambda"    => ["FWD = ->(o, *args) { o.#{m}(*args) }\n", ->(r, a) { "FWD.call(#{r}#{a})" }],
    "holder"    => ["class Holder\n  def initialize(o) = @o = o\n  def get(...) = @o.#{m}(...)\nend\n", ->(r, a) { "Holder.new(#{r}).get(#{a.sub(/\A, /, '')})" }],
    "holderrest" => ["class Holder\n  def initialize(o) = @o = o\n  def get(*a, &b) = @o.#{m}(*a, &b)\nend\n", ->(r, a) { "Holder.new(#{r}).get(#{a.sub(/\A, /, '')})" }],
    "mm"        => ["class Proxy\n  def initialize(o) = @o = o\n  def method_missing(name, ...) = @o.send(name, ...)\n  def respond_to_missing?(n, p = false) = true\nend\n", ->(r, a) { "Proxy.new(#{r}).zz_#{m.delete('?')}(#{a.sub(/\A, /, '')})" }, :mm],
  }
end
# forwarders written inside the class (self as the receiver)
def inner(m)
  {
    "selfdots"  => "  def via(...) = #{m}(...)\n",
    "selfdots2" => "  def via(...) = self.#{m}(...)\n",
    "selfrest"  => "  def via(*a) = #{m}(*a)\n",
    "selfrest2" => "  def via(*a, &b) = self.#{m}(*a, &b)\n",
    "selfanon"  => "  def via(*) = #{m}(*)\n",
  }
end

USES = {
  "p"     => ->(c) { "p #{c}" },
  "var"   => ->(c) { "x = #{c}\np x\np x.class" },
  "class" => ->(c) { "p #{c}.class" },
  "eq"    => ->(c) { "p #{c} == #{c}" },
}

# ------------------------------------------------------------------ piece 4
e4 = emitter(ARGV[0])
%w[object_id __id__].each do |nm|
  kinds = {
    "int"   => [:val, "  def #{nm} = @n * 10\n"],
    "str"   => [:val, "  def #{nm} = \"id-\#{@n}\"\n"],
    "none"  => [:addr, ""],
    "opt"   => [:val, "  def #{nm}(x = 3) = x * @n\n"],
    "rest"  => [:val, "  def #{nm}(*a) = a.size + @n\n"],
    "owndots" => [:val, "  def helper(*a) = a.size + @n\n  def #{nm}(...) = helper(...)\n"],
    "owndots0" => [:val, "  def helper = @n * 10\n  def #{nm}(...) = helper(...)\n"],
    "ownanon" => [:val, "  def helper(*a) = a.size + @n\n  def #{nm}(*) = helper(*)\n"],
    "ownblk" => [:val, "  def #{nm}(&b) = b ? b.call : @n\n"],
    "ownkw"  => [:val, "  def #{nm}(**o) = o.size + @n\n"],
    "ownall" => [:val, "  def #{nm}(*a, **o, &b) = a.size + o.size + @n\n"],
  }
  kinds.each do |kk, (kind, body)|
    forwarders(nm).each do |fk, (ftext, call, flag)|
      next if flag == :mm
      (kind == :addr ? %w[class eq] : %w[p var]).each do |uk|
        next if nm == "__id__" && uk != (kind == :addr ? "class" : "p")
        c = call.("t", "") or next
        e4.("F_#{kk}_#{nm}_#{fk}_#{uk}", "class Tk\n#{HEAD}#{body}end\n#{ftext}t = Tk.new(4)\n#{USES[uk].(c)}\n")
      end
      # one argument forwarded where the method takes one
      if %w[opt rest owndots ownanon ownall].include?(kk) && nm == "object_id"
        c = call.("t", ", 7") or next
        e4.("F1_#{kk}_#{nm}_#{fk}", "class Tk\n#{HEAD}#{body}end\n#{ftext}t = Tk.new(4)\np #{c}\n")
      end
    end
    inner(nm).each do |ik, itext|
      uk = kind == :addr ? "class" : "p"
      e4.("I_#{kk}_#{nm}_#{ik}", "class Tk\n#{HEAD}#{body}#{itext}end\nt = Tk.new(4)\n#{USES[uk].('t.via')}\n")
    end
    # direct calls on an own method that takes (...)
    next unless kk.start_with?("own")
    ["t.#{nm}", "t.#{nm}()", "t.#{nm}(7)", "t.#{nm}(7, 8)", "t.#{nm} { 5 }", "t.#{nm}(k: 1)", "t.#{nm}(*[7])", "t&.#{nm}"].each_with_index do |c, i|
      e4.("D_#{kk}_#{nm}_#{i}", "class Tk\n#{HEAD}#{body}end\nt = Tk.new(4)\np(#{c})\n")
    end
  end
  # super with forwarded arguments
  e4.("S_kiddots_#{nm}", "class Base\n#{HEAD}  def #{nm}(x = 1) = @n * 10 + x\nend\nclass Tk < Base\n  def #{nm}(...) = super(...)\nend\nt = Tk.new(4)\np t.#{nm}\np t.#{nm}(2)\n")
  e4.("S_kidzsuper_#{nm}", "class Base\n#{HEAD}  def #{nm}(x = 1) = @n * 10 + x\nend\nclass Tk < Base\n  def #{nm}(...) = super\nend\nt = Tk.new(4)\np t.#{nm}\np t.#{nm}(2)\n")
  e4.("S_kidrest_#{nm}", "class Base\n#{HEAD}  def #{nm}(*a) = @n * 10 + a.size\nend\nclass Tk < Base\n  def #{nm}(*a) = super(*a)\nend\nt = Tk.new(4)\np t.#{nm}\np t.#{nm}(2)\n")
  e4.("S_dotssuper_#{nm}", "class Tk\n#{HEAD}  def #{nm}(...) = super(...)\nend\nt = Tk.new(4)\np t.#{nm} == t.#{nm}\n")
  e4.("S_delegate_own_#{nm}", "class Inner\n#{HEAD}  def #{nm} = @n * 10\nend\nclass Tk\n  def initialize(n) = @i = Inner.new(n)\n  def #{nm}(...) = @i.#{nm}(...)\nend\nt = Tk.new(4)\np t.#{nm}\n")
  e4.("S_delegate_none_#{nm}", "class Inner\n#{HEAD}end\nclass Tk\n  def initialize(n) = @i = Inner.new(n)\n  def #{nm}(...) = @i.#{nm}(...)\nend\nt = Tk.new(4)\np t.#{nm} == t.#{nm}\np t.#{nm}.class\n")
  e4.("S_mm_#{nm}", "class Inner\n#{HEAD}  def #{nm} = @n * 10\nend\nclass Proxy\n  def initialize(o) = @o = o\n  def method_missing(name, ...) = @o.send(name, ...)\n  def respond_to_missing?(n, p = false) = true\nend\nq = Proxy.new(Inner.new(4))\np q.n\np q.#{nm}.class\n")
end

# ------------------------------------------------------------------ piece 5
e5 = emitter(ARGV[1])
N5 = {
  "get"  => ["instance_variable_get", "(name)", ", :@n", "name"],
  "set"  => ["instance_variable_set", "(name, value)", ", :@n, 5", "name"],
  "def"  => ["instance_variable_defined?", "(name)", ", :@n", "name"],
  "list" => ["instance_variables", "", "", "@n"],
  "rm"   => ["remove_instance_variable", "(name)", ", :@n", "name"],
}
N5.each do |k, (m, pr, a, first)|
  nargs = a.empty? ? 0 : a.count(",")
  kinds = {
    "str"   => "  def #{m}#{pr} = \"own \#{#{first}} \#{@n}\"\n",
    "none"  => "",
    "same"  => { "get" => "  def #{m}(name) = @n\n", "set" => "  def #{m}(name, value) = @n = value\n", "def" => "  def #{m}(name) = true\n",
                 "list" => "  def #{m} = [:@n]\n", "rm" => "  def #{m}(name) = @n\n" }[k],
    "rest"  => "  def #{m}(*a) = [:rest, a.size, @n]\n",
    "owndots" => "  def helper(*a) = [:dots, a.size, @n]\n  def #{m}(...) = helper(...)\n",
    "owndotsx" => "  def helper#{pr} = [:exact, @n]\n  def #{m}(...) = helper(...)\n",
    "ownanon" => "  def helper(*a) = [:anon, a.size, @n]\n  def #{m}(*) = helper(*)\n",
    "ownall" => "  def #{m}(*a, **o, &b) = [:all, a.size, o.size, b ? 1 : 0]\n",
    "ownblk" => "  def #{m}(*a, &b) = b ? b.call : [:noblk, a.size]\n",
  }
  kinds.each do |kk, body|
    forwarders(m).each do |fk, (ftext, call, flag)|
      %w[p var].each do |uk|
        next if uk == "var" && !%w[str none].include?(kk)
        c = call.("r", a) or next
        e5.("F_#{kk}_#{k}_#{fk}_#{uk}", "class Rec\n#{HEAD}#{body}end\n#{ftext}r = Rec.new(4)\n#{USES[uk].(c)}\np r.n\n")
      end
    end
    inner(m).each do |ik, itext|
      e5.("I_#{kk}_#{k}_#{ik}", "class Rec\n#{HEAD}#{body}#{itext}end\nr = Rec.new(4)\np r.via(#{a.sub(/\A, /, '')})\np r.n\n")
    end
    # a literal name with the rest forwarded
    if k == "set"
      e5.("L_#{kk}_set_dots", "class Rec\n#{HEAD}#{body}end\ndef put(o, ...) = o.instance_variable_set(:@n, ...)\nr = Rec.new(4)\np put(r, 5)\np r.n\n")
      e5.("L_#{kk}_set_rest", "class Rec\n#{HEAD}#{body}end\ndef put(o, *v) = o.instance_variable_set(:@n, *v)\nr = Rec.new(4)\np put(r, 5)\np r.n\n")
      e5.("L_#{kk}_set_selfdots", "class Rec\n#{HEAD}#{body}  def put(...) = instance_variable_set(:@n, ...)\nend\nr = Rec.new(4)\np r.put(5)\np r.n\n")
    end
    if nargs == 1
      e5.("L_#{kk}_#{k}_litblk", "class Rec\n#{HEAD}#{body}end\ndef fwd(o, &b) = o.#{m}(:@n, &b)\nr = Rec.new(4)\np fwd(r)\np fwd(r) { 9 }\n")
      e5.("L_#{kk}_#{k}_litkw", "class Rec\n#{HEAD}#{body}end\ndef fwd(o, **kw) = o.#{m}(:@n, **kw)\nr = Rec.new(4)\np fwd(r)\n")
      e5.("L_#{kk}_#{k}_litrest0", "class Rec\n#{HEAD}#{body}end\ndef fwd(o, *more) = o.#{m}(:@n, *more)\nr = Rec.new(4)\np fwd(r)\n")
    end
    next unless kk.start_with?("own") || kk == "rest"
    args = a.sub(/\A, /, "")
    ["r.#{m}", "r.#{m}()", "r.#{m}(#{args})", "r.#{m}(:@n, 5, 6)", "r.#{m}(#{args}) { 5 }", "r.#{m}(:@n, k: 1)", "r.#{m}(*[:@n])", "r&.#{m}(#{args})", "r.#{m}(\"@n\")"].each_with_index do |c, i|
      e5.("D_#{kk}_#{k}_#{i}", "class Rec\n#{HEAD}#{body}end\nr = Rec.new(4)\np(#{c})\n")
    end
  end
  args = a.sub(/\A, /, "")
  e5.("S_kiddots_#{k}", "class Base\n#{HEAD}  def #{m}#{pr} = [:base, @n]\nend\nclass Rec < Base\n  def #{m}(...) = super(...)\nend\nr = Rec.new(4)\np r.#{m}(#{args})\n")
  e5.("S_kidzsuper_#{k}", "class Base\n#{HEAD}  def #{m}#{pr} = [:base, @n]\nend\nclass Rec < Base\n  def #{m}(...) = super\nend\nr = Rec.new(4)\np r.#{m}(#{args})\n")
  e5.("S_kidrest_#{k}", "class Base\n#{HEAD}  def #{m}(*a) = [:base, a.size]\nend\nclass Rec < Base\n  def #{m}(*a) = super(*a)\nend\nr = Rec.new(4)\np r.#{m}(#{args})\n")
  e5.("S_dotssuper_#{k}", "class Rec\n#{HEAD}  def #{m}(...) = super(...)\nend\nr = Rec.new(4)\np r.#{m}(#{args})\n")
  e5.("S_restsuper_#{k}", "class Rec\n#{HEAD}  def #{m}(*a) = super(*a)\nend\nr = Rec.new(4)\np r.#{m}(#{args})\n")
  e5.("S_delegate_own_#{k}", "class Inner\n#{HEAD}  def #{m}#{pr} = [:inner, @n]\nend\nclass Rec\n  def initialize(n) = @i = Inner.new(n)\n  def #{m}(...) = @i.#{m}(...)\nend\nr = Rec.new(4)\np r.#{m}(#{args})\n")
  e5.("S_delegate_none_#{k}", "class Inner\n#{HEAD}end\nclass Rec\n  def initialize(n) = @i = Inner.new(n)\n  def #{m}(...) = @i.#{m}(...)\nend\nr = Rec.new(4)\np r.#{m}(#{args})\n")
  e5.("S_delegate_rest_none_#{k}", "class Inner\n#{HEAD}end\nclass Rec\n  def initialize(n) = @i = Inner.new(n)\n  def #{m}(*a) = @i.#{m}(*a)\nend\nr = Rec.new(4)\np r.#{m}(#{args})\n")
  e5.("S_mm_#{k}", "class Inner\n#{HEAD}  def #{m}#{pr} = [:inner, @n]\nend\nclass Proxy\n  def initialize(o) = @o = o\n  def method_missing(name, ...) = @o.send(name, ...)\n  def respond_to_missing?(n, p = false) = true\nend\nq = Proxy.new(Inner.new(4))\np q.n\n")
end
puts "written"
