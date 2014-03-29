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
        if current_diff_array && line.match(/^```$/)
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

  # Apply the diff described in this +FileDiff+ to an existing file with
  # +filename+.
  def apply
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
