module A; def who = "A"; end
module B; include A; end
class C; include B; include A; end
p C.new.who
module B; def who = "B"; end
