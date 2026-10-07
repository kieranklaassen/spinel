# A default block that stores its answer stores into the Hash it was read
# from. A merge's result carries the receiver's default block: read there,
# the block is given the result, not the receiver.
words = Hash.new { |hash, key| hash[key] = "made #{key}" }
words[:a] = "a"
extra = {}
extra[:b] = "b"
merged = words.merge(extra)
p merged[:zz]
p merged.size
p merged.key?(:zz)
p words.size
p words.key?(:zz)

# The block sees the Hash that was read.
seen = Hash.new { |hash, key| hash.size }
seen[1] = "one"
both = seen.merge(extra)
p both[9]
p seen[9]

# A merge of a merge reads through both.
again = merged.merge(extra)
p again[:yy]
p again.size
p merged.key?(:yy)
p words.key?(:yy)
