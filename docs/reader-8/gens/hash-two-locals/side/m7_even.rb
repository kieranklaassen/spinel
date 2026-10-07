h = {a: 1, b: 2}
h[:k] = "s"
h.each { |_k, v| p v.even? }
