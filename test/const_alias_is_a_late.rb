# A file required inside a method is loaded when the method runs: a constant
# it writes is not there before that, wherever the file's text stands.
require_relative "const_alias_is_a_late/top"
def load_late = require_relative("const_alias_is_a_late/late")
def late?(v) = defined?(LateKind) ? v.is_a?(LateKind) : false
p late?(7)
p 7.is_a?(TopKind)
