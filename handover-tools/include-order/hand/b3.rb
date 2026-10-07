module A; def who = "A"; end
class P; end
module B; include A; def who = "B"; end
class C < P; include B; end
class P; include A; end
class C; include A; end
p C.new.who
class C
  private def who = "C"
end
p C.new.send(:who)
