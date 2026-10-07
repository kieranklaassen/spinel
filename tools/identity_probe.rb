# Identity probe: a String taken out of what holds it and changed in place,
# CRuby against spinel, case by case.
#
#   ruby tools/identity_probe.rb [--strength T | --random N] [--seed S]
#                                [--only F=L,..] [--batch B] [--jobs J]
#                                [--out DIR] [--timeout SEC] [--keep]
#                                [--no-reduce]
#
# Takes the cases of tools/identity_gen.rb -- what holds the String, the
# container derived from the holder, the way one String is taken out of it,
# what the taken String goes through, what is done to it, how the holder was
# built and the String made, the slot's type, where the holder is kept and
# the scope -- runs them B to a program under CRuby and under spinel, and
# compares each case's lines. Strength 1 (the default) is every level of
# every factor alone, under each holder, the other factors at their simplest:
# a finding is then one level's own. Strength 2 and up is the greedy covering
# array, for the levels that pass alone, and --random N is N random rows;
# --only pins factors to a level each (a case that cannot take one is left
# out), so `--only via=local` asks every level again through a local.
#
# A case prints its holder, takes a String out of it and changes it, and
# prints the holder again, so a difference is named by the role of the first
# line that differs: `held: unchanged` is a holder that prints after the
# change what it printed before it, where CRuby's shows the change. That one
# is a String handed out as a copy with nothing said, against
# docs/limitations.md, "Aliased in-place mutation is observed". An exception
# CRuby raises (the FrozenError of a frozen literal, by every route) is part
# of the expected answer.
#
# The call-binding probe (tools/call_binding_probe.rb) crosses the ways a
# String reaches a callee that appends to it; this probe crosses the ways it
# leaves its holder, which is where spinel decides whether the holder's
# Strings are shared at all.
#
# The runner, shared with the call-binding probe, is tools/probe_common.rb:
# it splits a failing program to the case that carries it, reduces each
# finding toward the simplest levels of the factors, and sorts the findings
# into tiers, families and shapes. Output, under DIR (default
# build/identity-probe): summary.txt and <label>/case_<id>.rb.
#
# Exit status: 0 no wrong answer, 1 a wrong answer, 4 the tool's own error.

require_relative "identity_gen"

# A name the generator defines, undefined: the program is wrong, not spinel
# (a local, a helper method it calls, or a class or a Struct).
UNDEFINED = Regexp.union(/NameError: undefined local variable or method [`'][a-z]+\d+'[^\n]*/,
                         /NoMethodError: undefined method [`'][a-z]+\d+'[^\n]*/,
                         /NameError: uninitialized constant [A-Z]\d+[^\n]*/)

# Differences docs/limitations.md gives as the answer on purpose (see
# ProbeCommon::Probe#initialize): a `<<` to a String in a local, an instance
# variable, a Hash value or an Array element that holds other kinds too,
# which the holder does not show. The holder then prints what it printed
# before, a line CRuby printed too, so the entry names the finding's kind. A
# route that loses the change in a plain slot loses it here as well and is
# filed with these: the boxed slot is asked of the routes that pass alone.
DOCUMENTED = [
  { doc: "limitations.md, \"A plain String in a slot that holds other values too is not shared by `<<`\"",
    when: ->(r) { r[:slot] == "boxed" && r[:act] == "append" && r[:holder] != "struct" },
    kind: "held: unchanged" }
].freeze

exit ProbeCommon.main(IdentityGen, "identity_probe", ARGV,
                      out: File.expand_path("../build/identity-probe", __dir__), strength: 1,
                      undefined: UNDEFINED, documented: DOCUMENTED)
