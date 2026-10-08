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

`spinel -c`, user and system seconds, the lower of two runs (x86_64 Linux, gcc 13.3). The table was measured with master at 8dc552254; the `cident` and `scale-test` lines further down were read on 5d762fb16:

| | before "A method reached again from nearer the top follows its results" (a39414338) | master (8dc552254) | this |
|---|---|---|---|
| the bus, 64 classes and sites | 0.14 | 0.16 | 0.11 |
| 128 | 0.39 | 0.71 | 0.35 |
| 256 | 1.16 | 4.40 | 1.26 |
| 512 | 4.54 | 29.71 | 4.85 |
| every class also appends through the next (`def mark(i); @nxt.peek(i) << "3"; @nxt.mark(i); end`), 256 | 2.69 | 10.70 | 2.79 |
| 512 | 10.99 | 77.99 | 11.39 |
| one class, 1,024 methods that reach one another by three routes, 1,024 sites | 3.62 | 6.06 | 3.73 |
| the same with five routes | 7.17 | 18.22 | 9.52 |
| one class, 256 methods of 60 returns each, 256 sites | 14.94 | 22.67 | 19.29 |

That change (pull request 7806) is right, and what it does stays: a method first met at the walk's bound is walked again when it is reached from nearer the top, and since "A method a demand reaches again is walked again only if its walk was cut", only where its walk was cut. In the bus every walk is. And a receiver of no known class goes by name. The first descent takes nearly every class's `peek` to the bound, each is then walked again at every depth above it, and each of those walks looked through all the scopes for the methods of its result, to find them walked. A demand made about four times N such scans where it had made four, so twice the bus took 3.9 times as long before and takes 6.8 times as long now.

`strbuf_demand_user_elem_call` now keeps, for a demand, the depth at which each name's by-name loop was begun. Such a loop takes every method of the name to its own depth or nearer the top, so a call of the name no nearer the top than one begun, ended or still running, has nothing to add and returns. What the scan handed up was whether a walk it skipped was cut; the call hands up the loop's own answer once the loop has ended, and "cut" while it runs, which at most has a method walked again. A receiver of a known class has one method of the name, and it is looked up once a call instead of once a scope.

No generated C changes: `tools/cident.sh 5d762fb16` reads 6492 identical and 4 that differ, the tests that print the compiler's revision, and 5,851 generated programs around a delegating reader (a bus of 0 to 8 classes with the holder first, last or in the middle behind 0 to 5 helpers; call graphs drawn at random over 2 to 20 method names, by name and by class, with two and three routes; the programs of the table) compile to master's C; under `--share-strings` 5,723 do and 128 are refused as master refuses them. `test/append_through_reader_reached_twice.rb` and `test/append_through_delegating_reader.rb` print their `.expected` both ways.

The counted work of `spinel -c` (`make build/spinel-work`), counted on 8dc552254 over the 6,219 programs `test/` held there, is the same for 6,173 and less for 46, in sum 53,998 less (counted with address randomisation off).

`make scale-test` gains the bus at 64 and 128 classes, as a count of work like the instance_eval leg: on 5d762fb16 it reads 4.37 on master (the leg fails there) and 2.58 with this, limit 3. The commit message and the Makefile comment give the figures read on 8dc552254: 2.56 before that change, 4.37 on master, 2.59 with this.

```
scale-test: delegating-reader work at 2x the bus is 2.58x (limit 3.00)
```

Not in this change: the larger rows stay above their time before that change. The bus rows are close to it (4.85 seconds against 4.54 at 512; 11.39 against 10.99 where every class also appends), the one-class rows less so (9.52 against 7.17 with five routes). What is left is the visits a method cut at the bound still gets from nearer the top; walking the calls level by level would visit each once, and it would change the order the demands are made in, so it is not done here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
