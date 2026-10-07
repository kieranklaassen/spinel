# The Hash is a global's.
$h = {}
$h[:a] = +"q"
$h.values.each { |x| x << "!" }
p $h
