<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`Socket.getaddrinfo` now and then answers another host's address:

```ruby
require "socket"
hosts = ["127.0.0.1", "127.0.0.2", "127.0.0.3", "127.0.0.4", "127.0.0.5", "127.0.0.6", "127.0.0.7"]
kept = 500
ring = []
i = 0
while i < kept
  ring << Socket.getaddrinfo(hosts[i % 7], 80)
  i += 1
end
bad = 0
while i < 100000
  want = hosts[(i - kept) % 7]
  ring[i % kept].each { |row| bad += 1 unless row[2] == want && row[3] == want }
  ring[i % kept] = Socket.getaddrinfo(hosts[i % 7], 80)
  i += 1
end
p bad
```

```
spinel diff: output-diff
  program: getaddrinfo.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-0
+14
```

14 of the rows read back 500 calls later hold another host's address, "127.0.0.4" for "127.0.0.3". `sp_sock_getaddrinfo` makes a row's address String and then the row's Array, with the String held by a C local alone: when making the Array collects, the String is freed and the row points at memory the next address takes. The String is now rooted until the row holds it. The compiler is not touched; a row costs 25 instructions more.

Not here: a family or socket type argument is still ignored, as on master: `Socket.getaddrinfo(host, 80, nil, :STREAM)` answers three rows where CRuby answers one.

Test: `test/socket_getaddrinfo_many_calls.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
