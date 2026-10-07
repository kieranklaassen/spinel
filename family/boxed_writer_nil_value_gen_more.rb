# gen14b.rb DIR: gen14.rb's places with the listed kinds its values do not reach as a
# nil-typed value: a loop inside a sequence, false, keyword arguments, a Range literal alone.
src = File.read(File.join(__dir__, "boxed_writer_nil_value_gen.rb"))
src.sub!(/^V = \{.*?^\}\n/m, <<~'RB')
  V = {
    "seq_while"  => "(while $g < 2 do $g += 1; bump end; nil)",
    "seq_until"  => "(until $g >= 2 do $g += 1; bump end; nil)",
    "call_false" => "show(false)",
    "call_kw"    => "show(k: 1)",
    "call_float" => "show(1.5)",
    "call_range" => "show((1..2).first)",
    "if_while"   => "(if $c < 99 then while $g < 1 do $g += 1; bump end end; nil)",
  }
RB
ARGV[0] ||= "g14b"
eval(src)
