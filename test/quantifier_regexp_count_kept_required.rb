# The top level of a required file is a frame of its own in CRuby and runs in
# the top level's here. A program that asks in one file and reads the
# registers in another keeps asking every element.
require_relative "quantifier_regexp_count_kept_required/asks"
p $~
a = ["yb", "q"]
p a.none?(/(.)b/)
require_relative "quantifier_regexp_count_kept_required/reads"
