# KeyError.new, NameError.new and FrozenError.new store the key and the
# receiver they are given into the exception they have just made. Making
# the value can collect, and the collection promotes the exception, so the
# store has to be recorded.
# gc-stress-test runs this under SPINEL_GC_STRESS=2.

errs = []
600.times { |i| errs << KeyError.new("missing", key: "k#{i}") }
bad = 0
errs.each_with_index { |e, i| bad += 1 if e.key != "k#{i}" }
p [errs.size, bad, errs[599].key]

# the receiver is large enough to collect again after the key is stored
errs = []
600.times { |i| errs << KeyError.new("missing", key: "k#{i}", receiver: "r#{i}" * 800) }
bad = 0
errs.each_with_index { |e, i| bad += 1 if e.key != "k#{i}" || e.receiver != "r#{i}" * 800 }
p [errs.size, bad, errs[599].key, errs[599].receiver.size]

errs = []
600.times { |i| errs << NameError.new("undef", receiver: "r#{i}") }
bad = 0
errs.each_with_index { |e, i| bad += 1 if e.receiver != "r#{i}" }
p [errs.size, bad, errs[599].receiver]

errs = []
600.times { |i| errs << FrozenError.new("frozen", receiver: "f#{i}") }
bad = 0
errs.each_with_index { |e, i| bad += 1 if e.receiver != "f#{i}" }
p [errs.size, bad, errs[599].receiver]

# raised and rescued
errs = []
600.times do |i|
  begin
    raise KeyError.new("gone", key: "k#{i}", receiver: [i])
  rescue KeyError => e
    errs << e
  end
end
bad = 0
errs.each_with_index { |e, i| bad += 1 if e.key != "k#{i}" || e.receiver != [i] }
p [errs.size, bad, errs[0].key, errs[599].receiver]
