module A; def who = "A"; end
module B; include A; end
class C; include B; include A; end
module B
  1.times do
    def who = "B"
  end
end
p C.new.who
