# `when *list` in a case statement asks each element `===` of the subject, as
# the case used as a value does, and takes a list of any kind: one held
# boxed, a Range, nil, a value that is no Array, a typed Array beside a
# subject of another kind. It matched only a typed Array of the subject's
# own kind by ==, answered no match for a boxed list, and did not build for
# an Integer list beside a String.
def id(v) = v
KINDS = [1..3, /a/, String, :q, nil].freeze
def which(v, list)
  case v
  when *list then :hit
  else :miss
  end
end
p [2, 7, "xa", :za, :q, :r, nil, 4.5].map { |v| which(v, KINDS) }
# a Range, a Regexp and a Class in a list are no match for themselves
p [1..3, /a/, String].map { |v| which(v, KINDS) }
p [(case 1..3 when *KINDS then :hit else :miss end), (case String when *[String, Class] then :hit else :miss end)]
# a lambda in a list is called
p [7, 9, 8].map { |v| which(v, [->(x) { x == 7 }, 9]) }

boxed = id([1, 2])
case 2
when *boxed then p :boxed_list
else p :miss
end
case 2
when 9, *boxed then p :after_a_value
else p :miss
end
# a Range spreads to its members, nil to nothing, a plain value to itself
r = id(1..3)
x = (4..6)
n = id(nil)
s = id(2)
h = { a: 1 }
res = []
case 2 when *r then res << :range end
case 2.5 when *r then res << :not_a_member end
case 5 when *x then res << :typed_range end
case nil when *n then res << :nil_is_empty end
case 2 when *s then res << :scalar end
case [:a, 1] when *h then res << :pair end
p res
# a typed list beside a subject of another kind
ints = [1, 2]
strs = %w[a b]
flts = [1.5, 2.0]
res = []
case "a" when *ints then res << :str_in_ints end
case 2.0 when *ints then res << :float_in_ints end
case :a when *strs then res << :sym_in_strs end
case "b" when *strs then res << :str_in_strs end
case 2 when *flts then res << :int_in_floats end
case id(2) when *ints then res << :boxed_in_ints end
p res
# the subject is read once
calls = 0
feed = -> { calls += 1; 2 }
case feed.call
when *KINDS then p [:once, calls]
end
# a Range that cannot be walked raises, as spreading it anywhere does
[id(1.0..3.0), id(1..), id(..3)].each do |open|
  begin
    case 2 when *open then p :hit end
  rescue TypeError, RangeError => e
    p [e.class, e.message]
  end
end
