### Letter FX, body -v3 (text only; the commits are those of notes-fx-v2.md)

`own-then-pr-body-v3.md` differs from -v2 in one bullet of "Not covered": the receiver that is typed as the class and not proved an object now carries one program for each of a parameter, an ivar, a method's value and a block parameter. No commit, test or count changes.

Checked for that bullet, on master 4f8b737c1402 and on the piece's pick there (1494b2634c6e), gcc, against CRuby 3.3.6. With the body's `Tally`, each prints 0 on both where Ruby prints 1:

- a parameter: `def run(t); t.then; nil; end` (with the call as the method's last expression, neither builds);
- an ivar: `@t.then` in a method of a class whose `initialize` writes `@t = Tally.new`;
- a method's value: `def make = $t`, `make.then`;
- a block parameter: `ts.map { |t| t.then; 1 }` for `ts = [Tally.new, Tally.new]`;
- and the four the bullet names without a program: a constant (`T = Tally.new; T.then`), a global (`$t.then`), `self` (`self.then` in a method of Tally), a local copied from another (`u = t; u.then`).

Read beside it, because a block parameter is where the first version of this piece faulted: 31 programs, 29 builtin iterations over a typed Array with a hole (`ts = [Tally.new]; ts[2] = Tally.new; ts.each { |t| t.then }`, and each_with_index (two forms), select, reject, map (two forms), any?, count, each_with_object, find, reverse_each, each_slice, sort_by, flat_map, inject, zip, each_index, partition, min_by, group_by, all?, sum, filter_map, take_while, cycle, each_cons, index, delete_if, each_entry, uniq). None crashes and none raises on the pick; master prints 0 for all 31, the pick 1 (Ruby's) for 28 and 0 for map (two forms) and sum. In the 28 the parameter is a boxed value and the call goes through the class switch, whose default arm takes nil; the 3 have master's C byte for byte.

Master e527d205d274 (the tip at 14:17 UTC 10-07) changes none of the piece's functions; the pick merges clean into it.
