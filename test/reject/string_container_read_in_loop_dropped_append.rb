# A local written once with an Array of new Strings and read once: the read
# runs twice, and its own block shows the String its first run changed.
a = [+"q", +"r"]
2.times do
  a.find { |s| puts s; true } << "!"
end
