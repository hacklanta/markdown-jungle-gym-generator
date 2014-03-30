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

# Set up starting point, which is base repo; no starting point means
# blank dir/git init.

repository_directory = ARGV[0] || 'lift-jungle-gym-repository'

directory = options[:directory]
sort_strategy = options[:sort] if sort_strategies.include?(options[:sort].to_sym)

unless Dir.exists?(repository_directory)
  Dir.mkdir(repository_directory)
end

def run_command(*command)
  if VERBOSE
    puts " -> #{command}"
    system(*command)
    puts " -> Done."
  else
    %x{#{command.first} #{command[1..-1].map { |part| %{"#{part.gsub('"', '\"')}"} }.join(" ")}}
  end
end

unless Dir.exists?(File.join(repository_directory, '.git'))
  Dir.chdir(repository_directory) do
    run_command('git', 'init')
  end
end

puts "Reading directory #{directory} using sort strategy #{sort_strategy}..."

absolute_repository_directory = File.realdirpath(repository_directory)

Dir.chdir(directory) do
  filenames = Dir.glob('*.md').sort(&sort_strategies[sort_strategy.to_sym])

  section_infos = []
  filenames.each do |filename|
    next unless File.file?(filename)

    File.open(filename) do |file|
      puts "\tProcessing #{filename}" if VERBOSE

      file_title = file.gets.sub(/^#+/, '').strip
      file_diffs = FileDiff.diffs_from(file)

      Dir.chdir(absolute_repository_directory) do
        file_diffs.each_with_index do |file_diff, i|
          puts "\t\tFound file reference #{file_diff.filename}" if VERBOSE
          if File.exists?(file_diff.filename)
            puts "\t\tAttempting to patch previous file." if VERBOSE
            file_diff.apply

            # couldn't patch previous file, please select appropriate range
          else
            puts "\t\tExisting file not found, creating file." if VERBOSE
            file_diff.create
          end

          checkpoint_message = "#{file_title} (Checkpoint #{i + 1})"
          puts "\tGenerating checkpoint commit with message #{checkpoint_message}" if VERBOSE

          run_command 'git', 'add', '*'
          run_command 'git', 'commit', '-m', checkpoint_message
        end

        section_infos << { :commit => `git rev-parse HEAD`.strip, :name => file_title }
      end
    end
  end

  names = section_infos.collect { |info| info[:name] }
  common_prefix = names[1..-1].inject(names[0]) do |possible_prefix, name|
    until name.match(/^#{possible_prefix}/)
      possible_prefix = possible_prefix[0..-2]
    end

    possible_prefix
  end

  Dir.chdir(absolute_repository_directory) do
    section_infos.each_with_index do |section_info, i|
      tag_name =
        section_info[:name]
          .gsub(/^#{common_prefix}/, '')
          .downcase
          .gsub(/\s+/, '-')

      full_tag = "step-#{i + 1}-#{tag_name}"

      puts "\tTagging #{full_tag}"
      run_command 'git', 'tag', full_tag, section_info[:commit]
    end
  end
end

starting_point = 'git://github.com/Shadowfiend/lift-tutorial.git'
puts "Created git history. Repo is ready for push."

# puts "Creating docker containers for each checkpoint."
