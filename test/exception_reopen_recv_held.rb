# A method a reopening of StandardError defines, called on an exception
# made for the call: nothing else holds the receiver while the method
# runs, so what the method allocates took its place. The loop shows it in
# a plain run; the last lines under SPINEL_GC_STRESS=2 (gc-stress-test).

class StandardError
  def checked
    other = RuntimeError.new("zz" + message.size.to_s)
    other.message.size > 0 ? message : ""
  end
end

def made(i) = RuntimeError.new("m" + i.to_s)

bad = 0
i = 0
while i < 50_000
  bad += 1 unless made(i).checked == "m" + i.to_s
  i += 1
end
p bad

k = ARGV.size
p RuntimeError.new("r" + k.to_s).checked
p made(k).checked
