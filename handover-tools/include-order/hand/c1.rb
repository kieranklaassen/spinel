LIMITS = { low: 1, high: 2 }.freeze
SPAN = (1..3)
PAT = /a+/
module A; def who = "A"; end
module B; include A; def who = "B"; end
class C
  OPTS = { a: [1, 2] }
  include B
  include A
end
p C.new.who
