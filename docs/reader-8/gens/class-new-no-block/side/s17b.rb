class MyErr < UncaughtThrowError; end
begin
  raise MyErr, "x"
rescue UncaughtThrowError => e
  puts "rescued #{e.class}"
rescue ArgumentError => e
  puts "ArgumentError: #{e.message}"
end
