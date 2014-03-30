#!/usr/bin/env ruby
require './micro_optparse'
require './file_diff'

sort_strategies = {
  :alphabetical => proc  { |thing, other_thing| thing <=> other_thing }
}

options = Parser.new do |parser|
  parser.banner = <<-BANNER
    Generate lift-jungle-gym git repositories from a directory of markdown files.
  BANNER

  parser.version = "markdown-lift-jungle-gym-generator 0.1-alpha"
  parser.option :directory, "directory to read from", :short => 'd', :default => '.'
  parser.option :verbose, "enable verbose output"
  parser.option :sort, "sorting strategy to walk through files in directory", :default => 'alphabetical'
#  parser.option :chance, "set mutation chance", :default => 0.8, :value_satisfies => lambda {|x| x >= 0.0 && x <= 1.0}
end.process!

VERBOSE = options[:verbose]

repository_directory = ARGV[0] || 'lift-jungle-gym-repository'

directory = options[:directory]
sort_strategy = options[:sort] if sort_strategies.include?(options[:sort].to_sym)

unless Dir.exists?(repository_directory)
  Dir.mkdir(repository_directory)
end

unless Dir.exists?(File.join(repository_directory, '.git'))
  Dir.chdir(repository_directory) do
    if VERBOSE
      system("git init")
    else
      `git init`
    end
  end
end

puts "Reading directory #{directory} using sort strategy #{sort_strategy}..."

absolute_repository_directory = File.realdirpath(repository_directory)

Dir.chdir(directory) do
  filenames = Dir.entries('.').sort(&sort_strategies[sort_strategy.to_sym])

  filenames.each do |filename|
    next unless File.file?(filename)

    File.open(filename) do |file|
      puts "\tProcessing #{filename}" if VERBOSE

      file_diffs = FileDiff.diffs_from(file)
      puts file_diffs

      Dir.chdir(absolute_repository_directory) do
        file_diffs.each do |file_diff|
          if File.exists?(file_diff.filename)
            file_diff.apply
          else
            file_diff.create
          end
        end
      end
    end
  end
end

starting_point = 'git://github.com/Shadowfiend/lift-tutorial.git'
puts "Using starting point #{starting_point}"
current_file = "getting-started-section-1"
puts "Processing file #{current_file}"
file_reference = "src/main/webapp/index.html"
puts "\tFound file reference #{file_reference}"
puts "\tNo eliding found, creating/replacing file"
puts "\tEliding found, attempting to patch previous file"
puts "\tCouldn't patch previous file, please select appropriate range"
puts "\tGenerating checkpoint commit with message View-First Development (Lift Getting Started, Section 1)"
puts "\tTagging section-1"
puts "Created git history. Repo is ready for push."

# puts "Creating docker containers for each checkpoint."
