# A `&.` call in statement position whose receiver hoists statements, such as
# a block that runs, ran them twice: the statement emitter of `v&.upto(n) { }`
# emitted the receiver, then declined the call, and what the receiver had
# hoisted stayed in front of the plain emission.
$n = 0
def none
  $n += 1
  nil
end
nil.tap { $n += 10 }&.size
puts $n
none.tap { $n += 10 }&.size
puts $n
[1, 2].each { $n += 10 }&.clear&.first&.size
puts $n
none.then { $n += 10; nil }&.size
puts $n
# in a method, at its tail, in a block
def m
  [1, 2].each { $n += 1 }&.size
  0
end
m
puts $n
def t = [1, 2].map { |q| $n += q; q }&.size
p t
puts $n
[0].each { 1.then { $n += 100; "s" }&.to_s }
puts $n
# a call with a block that the loop emitters do not take
nil.tap { $n += 1000 }&.then { $n += 5 }
puts $n
# the loops they do take run the receiver once, as before
[1, 2].each { $n += 10000 }&.each { |q| $n += q }
puts $n
2.tap { $n += 100000 }&.times { $n += 1 }
puts $n
# a receiver that is itself a `&.` call whose argument is built: the call ran twice
class K
  def bump(a)
    $n += 1000000
    a
  end
end
def mk(v) = v ? K.new : nil
k = mk(true)
w = 3
k&.bump([w, 2])&.size
puts $n
