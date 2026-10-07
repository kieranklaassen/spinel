# Socket.getaddrinfo answers the address it was asked for, as CRuby does,
# however many answers the program holds: a row's address String lives
# through the collection that making the row can cause. About one call in
# 2,600 answered another host's address, "127.0.0.4" for "127.0.0.3".
require "socket"

hosts = ["127.0.0.1", "127.0.0.2", "127.0.0.3", "127.0.0.4", "127.0.0.5", "127.0.0.6", "127.0.0.7"]
kept = 500
ring = []
i = 0
while i < kept
  ring << Socket.getaddrinfo(hosts[i % 7], 80)
  i += 1
end

# each answer is checked as it leaves the ring, 500 calls after it was made
bad = 0
while i < 100000
  want = hosts[(i - kept) % 7]
  ring[i % kept].each { |row| bad += 1 unless row[2] == want && row[3] == want }
  ring[i % kept] = Socket.getaddrinfo(hosts[i % 7], 80)
  i += 1
end
p bad
