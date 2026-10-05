# `fetch` with a default can answer the default, a String another name
# holds, whatever the Array holds.
K = [+"k"]
A = ["q"]
A.fetch(5, K[0]) << "!"
p K
