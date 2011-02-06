#===============================================================================
# Filename:    script_exporter.rb
#
# Developer:   Raku (rakudayo@gmail.com)
#
# Description: This file provides the functionality which allows the user to
#    export scripts from RMVX's Scripts.rvdata file to separate text files so
#    that they may be versioned with a versioning system such as Subversion or 
#    Mercurial.
#
# Usage:       ruby script_exporter.rb <project_directory>
#===============================================================================

require 'common'

# Make sure RMVX isn't running
exit if check_for_rmvx

# Set up the directory paths
$INPUT_DIR  = $PROJECT_DIR + '/' + $rvdata_DIR + '/'
$OUTPUT_DIR = $PROJECT_DIR + '/' + $SCRIPTS_DIR + '/'

print_separator(true)
puts "  RGSS Script Export"
print_separator(true)

$STARTUP_TIME = load_startup_time(true) || Time.now

# Check if the input directory exists
if not (File.exists? $INPUT_DIR and File.directory? $INPUT_DIR)
  puts "Error: Input directory #{$INPUT_DIR} does not exist."
  puts "Hint: Check that the rvdata_dir path in config.yaml is set to the correct path."
  exit
end

# Create the output directory if it doesn't exist
if not (File.exists? $OUTPUT_DIR and File.directory? $OUTPUT_DIR)
  recursive_mkdir( $OUTPUT_DIR )
end

if (not file_modified_since?($INPUT_DIR + "Scripts.rvdata", $STARTUP_TIME)) and (File.exists?($SCRIPTS_DIR + "/" + $EXPORT_DIGEST_FILE))
  puts_verbose "No RGSS scripts need to be exported."
  puts_verbose
  exit
end

start_time = Time.now

# Read in the scripts from script file
scripts = nil
File.open($INPUT_DIR + "Scripts.rvdata", File::RDONLY|File::BINARY) do |infile|
  scripts = Marshal.load(infile)
end

# Create the export digest
digest = []
File.open($OUTPUT_DIR + $EXPORT_DIGEST_FILE, File::WRONLY|File::CREAT|File::TRUNC) do |digestfile|
  scripts.each_index do |i|
    digest[i] = []
    digest[i] << scripts[i][0]
    digest[i] << scripts[i][1]
    digest[i] << generate_filename(scripts[i])
    line = "#{digest[i][0].to_s.ljust($COLUMN1_WIDTH)}#{digest[i][1].ljust($COLUMN2_WIDTH)}#{digest[i][2]}\n"
    #puts line
    digestfile << line
  end
end

# Find out how many non-empty scripts we have
num_scripts  = digest.select { |e| e[2].upcase != "EMPTY" }.size
num_exported = 0

# Save each script to a separate file
scripts.each_index do |i|
  if digest[i][2].upcase != "EMPTY"
    inflate_start_time = Time.now
    File.open($OUTPUT_DIR + digest[i][2], File::WRONLY|File::CREAT|File::TRUNC|File::BINARY) do |outfile|
      outfile << Zlib::Inflate.inflate(scripts[i][2])
    end
    num_exported += 1
    inflate_elapsed_time = Time.now - inflate_start_time
    str  = "Exported #{digest[i][2].ljust($FILENAME_WIDTH)}(#{num_exported.to_s.rjust(3, '0')}/#{num_scripts.to_s.rjust(3, '0')})"
    str += "         #{inflate_elapsed_time} seconds" if inflate_elapsed_time > 0.0
    puts_verbose str
                 
  end
end

puts "\n"

elapsed_time = Time.now - start_time

print_separator
puts_verbose "The total export time:  #{elapsed_time} seconds."
print_separator
puts_verbose
