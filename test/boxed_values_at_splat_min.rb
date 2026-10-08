# spinel: int64
# A splatted Range that excludes its end is walked up to the end as it
# stands: one less than the smallest Integer wraps.

a = [[10, 20, 30], nil][ARGV.size]
m = -9223372036854775807 - 1
p a.values_at(0, *(1...m))
p a.values_at(0, *(1..m))
