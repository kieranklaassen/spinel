h = {"a" => 1, "b" => 2}
h.each { |k, _v| h.delete(k) }
p h.to_a
