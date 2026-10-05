# A method handed an Array or Hash stores into it, and what the caller then
# does is something other than changing the stored String through the
# container. Each of these was right before the stored String became the
# caller's element (handed_container_string_append) and stays as it was.

def hr_change(q); q[0] << "y" * 40; end
r1 = [+"a"]
hr_change(r1)
p r1

def hr_store_and_change(q); q << +"s"; q[1] << "y" * 40; end
r2a = [+"a"]
hr_store_and_change(r2a)
p r2a

def hr_integer(q, n); q << n; end
r3 = [+"a"]
hr_integer(r3, 1)
r3[0] << "y" * 40
p r3

def hr_changed_first(q, v); v << "!" * 40; q << v; end
r4 = [+"a"]
hr_changed_first(r4, +"s")
r4[0] << "y" * 40
p r4

def hr_put(q, v); q << v; end
r5 = [+"a"]
hr_put(r5, +"s")
r5[1][0] = "y" * 40
p r5

r6 = []
hr_put(r6, +"s")
r6.map! { |e| e + "y" * 40 }
p r6

def hr_key(h, v); h[:k] = v; end
r7 = {a: +"a"}
hr_key(r7, +"s")
r7[:a] << "y" * 40
p r7.to_a

def hr_answer(q, v); q << v; q; end
r8 = [+"a"]
r8 = hr_answer(r8, +"s")
r8[1] << "y" * 40
p r8

def hr_fill(a, n); a << n; end
r9 = [1]
hr_fill(r9, 2)
p r9[1] << 3
p r9

r10 = [+"a"]
hr_put(r10, +"s")
p r10
p r10[1].size

r11 = [+"a"]
hr_put(r11, +"s")
r11[0] << "y" * 40
p r11

r12 = [+"a"]
3.times { |i| hr_put(r12, "n#{i}") }
puts r12.join(",")
p r12.map(&:upcase)

r13 = [+"a"]
r14 = [+"b"]
hr_put(r13, +"s")
hr_put(r14, +"t")
r13[0] << "y" * 40
p r13
p r14
