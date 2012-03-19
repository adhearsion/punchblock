require 'tempfile'
stderr_file = Tempfile.new "ahn.stderr"
$stderr.reopen stderr_file.path
current_dir = Dir.pwd

at_exit do
  stderr_file.rewind
  lines = stderr_file.read.split("\n").uniq
  stderr_file.close!

  pb_warnings, other_warnings = lines.partition { |line| line.include?(current_dir) && !line.include?('vendor') && line.include?('warning') }

  if pb_warnings.any?
    puts
    puts "-" * 30 + " PB Warnings: " + "-" * 30
    puts
    puts pb_warnings.join("\n")
    puts
    puts "-" * 75
    puts
  end

  if other_warnings.any?
    Dir.mkdir 'tmp' unless Dir.exists? 'tmp'
    File.open('tmp/warnings.txt', 'w') { |f| f.write other_warnings.join("\n") }
    puts
    puts "Non-PB warnings written to tmp/warnings.txt"
    puts
  end

  exit 1 if pb_warnings.any? # fail the build...
end
