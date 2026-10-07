<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`sh test/scale/reader_bus.sh 512` prints a bus of 512 classes with 512 append sites, built as `test/append_through_delegating_reader.rb` builds its bus:

```ruby
class Dev1                         # Dev1 to Dev512, each the same
  def initialize(nxt) = @nxt = nxt
  def peek(i) = @nxt.peek(i)
end
class Leaf
  def initialize = @v = [+"leaf", +"two"]
  def peek(i) = cell(i)
  def cell(i) = @v[i]
end
kinds = [Dev1, Dev2]               # all 512
bus = Leaf.new
kinds.each { |k| bus = k.new(bus) }
bus.peek(0) << "!"                 # 512 such lines, the index 0 or 1
p bus.peek(0).size, bus.peek(1).size
```

`spinel -c`, user and system seconds, the lower of two runs (x86_64 Linux, gcc 13.3):

| | before "A method reached again from nearer the top follows its results" (a39414338) | master (1e68f4ca1) | this |
|---|---|---|---|
| the bus, 64 classes and sites | 0.14 | 0.17 | 0.11 |
| 128 | 0.39 | 0.84 | 0.40 |
| 256 | 1.16 | 4.93 | 1.24 |
| 512 | 4.54 | 38.97 | 4.95 |
| every class also appends through the next (`def mark(i); @nxt.peek(i) << "3"; @nxt.mark(i); end`), 256 | 2.69 | 12.55 | 2.97 |
| 512 | 10.99 | 87.94 | 12.51 |
| one class, 1,024 methods that reach one another by three routes, 1,024 sites | 3.62 | 6.74 | 4.14 |
| the same with five routes | 7.17 | 20.73 | 11.46 |
| one class, 256 methods of 60 returns each, 256 sites | 14.94 | 23.47 | 20.04 |

That change (pull request 7806) is right, and what it does stays: a method first met at the walk's bound is walked again when it is reached from nearer the top. But a receiver of no known class goes by name. The first descent takes nearly every class's `peek` to the bound, each is then walked again at every depth above it, and each of those walks looked through all the scopes for the methods of its result, to find them walked. A demand made about four times N such scans where it had made four, so twice the bus took 3.9 times as long before and takes 7.9 times as long now.

`strbuf_demand_user_elem_call` now keeps, for a demand, the depth at which each name's by-name loop was begun. Such a loop takes every method of the name to its own depth or nearer the top, so a call of the name no nearer the top than one begun, ended or still running, has nothing to add and returns. A receiver of a known class has one method of the name, and it is looked up once a call instead of once a scope.

No generated C changes: `tools/cident.sh 1e68f4ca1` reads 6375 identical, 0 differ, and 5,826 generated programs around a delegating reader (a bus of 0 to 8 classes with the holder first, last or in the middle behind 0 to 5 helpers; call graphs drawn at random over 2 to 20 method names, by name and by class, with two and three routes) compile to master's C with and without `--share-strings`. `test/append_through_reader_reached_twice.rb` and `test/append_through_delegating_reader.rb` print their `.expected` both ways.

`make scale-test` gains the bus at 64 and 128 classes, as a count of work like the instance_eval leg: 2.56 times before that change, 4.35 on master (the leg fails there), 2.59 with this, limit 3.

```
scale-test: delegating-reader work at 2x the bus is 2.59x (limit 3.00)
```

Not in this change: every row stays above its time before that change. The bus rows are close to it (4.95 seconds against 4.54 at 512; 12.51 against 10.99 where every class also appends), the one-class rows less so (11.46 against 7.17 with five routes). What is left is that change's own five visits a method; walking the calls level by level would visit each once, and it would change the order the demands are made in, so it is not done here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
