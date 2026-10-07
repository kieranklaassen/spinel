<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
h = {}
%w[a b a].each { |w| h[w] ||= +""; h[w] << "!" }
p h      # CRuby: {"a" => "!!", "b" => "!"}. Here: {"a" => "", "b" => ""}, with nothing said
```

Written `h[w] = +""` it is right. The walks that list a container's stores knew a literal's elements, push and `[]=`, and not the value of an IndexOrWriteNode or an IndexAndWriteNode, so that value went into the boxed slot as a plain String beside the handles of every other store. It is now listed as the last argument of `[]=` is. The same for `&&=`, for an Array slot, and for a Hash or an Array an instance variable or a parameter holds. It shares for `||=` what master shares for `=` and nothing more; this stands on the guard (#____) because `h[:k] ||= h[:j]` is now followed into the Hash it is stored into, and without the guard a row of such stores costs n! walks.

**It also carries a refusal master makes for `=` over to `||=`.** Master refuses a Hash that took a String by `h[k] = v` and is then walked by a block that appends to what it is handed, because the block is handed a copy. That check reads the list of stores, and the `||=` value is on the list now. This program is right on master and is refused with this commit:

```ruby
h = {}
h[:list] ||= []
h[:name] ||= +"n"
h.each_value { |v| v << "item" if v.is_a?(Array) }
p h      # master and CRuby: {list: ["item"], name: "n"}
```

```
spinel: t.rb:3: a String stored in a Hash is passed to an appending value block: a String is not yet shared by reference through a Hash's values. Append to the String before storing it in the Hash.
```

Written with `=` in place of `||=`, master refuses it today, in those words at that line. The check cannot tell whether the append lands on the String. Here it lands only on the Array, so a program that is right on master stops building. Where it does land (`h[:name] ||= +"n"; h.each_value { |v| v << "!" }; p h`), master prints `{name: "n"}` in silence and the refusal is the better answer. So this is a fix that also refuses: the `||=` twin of each program master already refuses for `=`, right ones among them. Keeping the `||=` value off the list that check reads would give the right ones back and send the wrong ones back to a silent wrong answer, so the check is not narrowed.

On master dafa0d047, against CRuby 3.3.6: of 2,814 generated programs 1,008 go from wrong to right (1,254 right before, 2,262 after) and none that is right answers differently or stops building; the 552 left are `=` programs and `||=` / `&&=` programs that print the lines of their `=` twin. Of 12 programs written to meet the refusal, 11 are refused, 8 that are right on master and 3 that are wrong, and master refuses all 11 at the same line when they are written with `=`.

Appending to a key the write did not store, over `Hash.new`, raises NoMethodError as CRuby does, where master raises FrozenError; the test's last section pins that such a key is still nil.

## `make gate` (on this branch merged with current master)

```
not run in full here: the full gate runs on the Mac before anything goes upstream.
In the cloud, above the guard on master dafa0d047: tools/gate.rb check passes (no Ruby 4.0 here, so .expected was not compared).
cident: 6277 identical, 5 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against dafa0d047): the four that print the compiler's revision and the new test. Taken with the guard's test set aside, because master's compiler does not finish it.
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; it prints Arrays, Strings, booleans and nil)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #____ (the guard: A container that stores many of its own elements no longer stalls the compiler)
