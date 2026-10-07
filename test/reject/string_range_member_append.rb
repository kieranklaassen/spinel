# A block that changes its String Range member in place is refused, as it
# was while the member was an element of the range's Array.
puts ("a".."e").find { |s| s << "!"; s.start_with?("c") }
