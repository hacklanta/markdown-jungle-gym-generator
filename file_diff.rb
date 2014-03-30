require 'fileutils'
require 'pathname'

# Describes a diff to a file, as represented in a Markdown document.
# This is NOT in patch format (at least not yet).  Calling +apply+
# attempts to create a patch diff based on an existing file at
# +filename+ and the described diff.
#
# The format here is that there may be one or more lines that consist
# solely of `...`. These indicate areas of the existing file that have
# been elided. When generating a patch, +FileDiff+ tries to find the
# line or lines immediately following the `...` to find the insertion
# point. It then finds the first line where things differ, as well as
# the trailing line where things match again. It then discards all
# intervening content and replaces it with the content in the diff.
class FileDiff
  attr_reader :filename

  class <<self
    # Extract a set of +FileDiff+s from the given lines, read from a file.
    # +FileDiff+s are created from Markdown code blocks delimited by ```
    # that include filename info (after the filetype and a colon, to produce
    # an opening delimiter of type ```scala:src/main/scala/code/Test.scala).
    # Each one of these code blocks is turned into a +FileDiff+.
    def diffs_from(lines)
      diffs = []

      current_diff_filename = nil
      current_diff_array = nil
      lines.each do |line|
        if current_diff_filename && line.match(/^```$/)
          diffs << FileDiff.new(current_diff_filename, current_diff_array)

          current_diff_filename = nil
          current_diff_array = []
        elsif current_diff_array
          current_diff_array << line
        elsif match = line.match(/^```(?:[^:]+):(.+)$/)
          current_diff_filename = match[1]
          current_diff_array = []
        end
      end

      diffs
    end
  end

  def initialize(filename, diff_array)
    @filename = filename
    @diff_array = diff_array
  end

  def lines_match?(file_line, diff_line)
    file_line == diff_line or
      file_line == diff_line.gsub(/->.*<-/, '')
  end

  # Apply the diff described in this +FileDiff+ to an existing file with
  # +filename+. Assumes +filename+ exists.
  def apply
    diff_chunks =
      @diff_array.inject([]) do |chunks, line|
        if line == '...'
          chunks << []
        else
          # If there is only a one-line change, there may be no leading ...
          if chunks.last.nil?
            chunks << []
          end

          chunks.last << line
        end

        chunks
      end

    final_lines = []
    File.open(@filename) do |file|
      diff_chunks.each do |current_chunk|
        while current_chunk.length > 0 && ! file.eof?
          # insert lines through first line matching the chunk
          while (file_line = file.gets) && ! lines_match?(file_line, current_chunk.first)
            final_lines << file_line
          end

          # scan all leading matching lines in
          final_lines << current_chunk.shift.gsub(/->(.*)<-/, '\1')
          matching_lines = current_chunk.take_while { |chunk_line| file.gets == chunk_line }
          final_lines += matching_lines
          current_chunk = current_chunk.drop(matching_lines.length)

          # move on if there's nothing left in the current chunk
          next if current_chunk.empty?

          # drop non-matching lines from input file
          loop while file_line = file.gets && ! current_chunk.include?(file_line)

          # insert diff lines through next matching line
          matching_lines = current_chunk.take_while { |chunk_line| file_line != chunk_line }
          final_lines += current_chunk
          current_chunk = current_chunk.drop(matching_lines.length)
        end
      end

      # scan the rest of the file
      while file_line = file.gets
        final_lines << file_line 
      end
    end

    File.write(@filename, final_lines.join(''), :mode => 'w')
  end

  # Create the file described in this +FileDiff+ at +filename+.
  def create
    FileUtils.mkpath(Pathname.new(@filename).dirname)
    File.write(@filename, @diff_array.join(''), :mode => 'w')
  end

  def to_s
    "<FileDiff #{@filename}:\n\t#{@diff_array.join("\t")}\n>"
  end
end
