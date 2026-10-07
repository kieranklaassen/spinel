# A proc that assigns its parameter and then appends to it, passed with `&`
# to a method that yields a String variable: the method runs as its proc
# form and the proc grows a copy. Refused rather than compiled with the
# append lost.
def run(s) = yield(s)
f = proc { |k| k ||= +"z"; k << "x" }
s = +"a"
run(s, &f)
p s
