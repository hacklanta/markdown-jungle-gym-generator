#!/usr/bin/env ruby

puts "Reading directory..."
strategy = 'alphabetical'
puts "Using sort strategy #{strategy}"
starting_point = 'git://github.com/Shadowfiend/lift-tutorial.git'
puts "Using starting point #{starting_point}"
current_file = "getting-started-section-1"
puts "Processing file #{current_file}"
file_reference = "src/main/webapp/index.html"
puts "\tFound file reference #{file_reference}"
puts "\tNo eliding found, creating/replacing file"
puts "\tEliding found, attempting to patch previous file"
puts "\tCouldn't patch previous file, please select appropriate range"
puts "\tGenerating checkpoint commit with message #{View-First Development (Lift Getting Started, Section 1)}"
puts "\tTagging section-1"
puts "Created git history. Repo is ready for push."

# puts "Creating docker containers for each checkpoint."
