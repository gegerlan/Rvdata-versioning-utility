#===============================================================================
# Filename:    data_exporter.rb
#
# Developer:   Raku (rakudayo@gmail.com)
#
# Description: This script exports RMVX's .rvdata files into a text format which
#    is able to be versioned with a versioning system, such as Subversion or 
#    Mercurial.  By versioning the game data in textual form, this allows for 
#    smooth, concurrent development of games without the problem of binary 
#    conflicts on the RMVX data files.  Whenever conflicts arise, they can be
#    resolved in plain text.
#
# Usage:       ruby data_exporter.rb <project_directory>
#===============================================================================

require 'rmvx/rgss'
require 'yaml'

require 'common'

# Make sure RMVX isn't running
exit if check_for_rmvx

# Set up the directory paths
$INPUT_DIR  = $PROJECT_DIR + '/' + $rvdata_DIR + '/'
$OUTPUT_DIR = $PROJECT_DIR + '/' + $YAML_DIR + '/'

print_separator(true)
puts "  RMVX Data Export"
print_separator(true)

$STARTUP_TIME = load_startup_time || Time.now

# Check if the input directory exists
if not (File.exists? $INPUT_DIR and File.directory? $INPUT_DIR)
  puts "Error: Input directory #{$INPUT_DIR} does not exist."
  puts "Hint: Check that the $rvdata_DIR variable in paths.rb is set to the correct path."
  exit
end

# Create the output directory if it doesn't exist
if not (File.exists? $OUTPUT_DIR and File.directory? $OUTPUT_DIR)
  recursive_mkdir( $OUTPUT_DIR )
end

# Create the list of rvdata files to export
files = Dir.entries( $INPUT_DIR )
files -= $rvdata_IGNORE_LIST
files = files.select { |e| File.extname(e) == '.rvdata' }
files = files.select { |e| file_modified_since?($INPUT_DIR + e, $STARTUP_TIME) or not rvdata_file_exported?($INPUT_DIR + e) }
files.sort!

if files.empty?
  puts_verbose "No data files need to be exported."
  puts_verbose
  exit
end

total_start_time = Time.now
total_load_time = 0.0
total_dump_time = 0.0

# For each rvdata file, load it and dump the objects to YAML
files.each_index do |i|
  data = nil
  start_time = Time.now
 
  # Load the data from rmvx's data file
  File.open( $INPUT_DIR + files[i], "r+" ) do |datafile|
    data = Marshal.load( datafile )
  end
  
  # Calculate the time to load the .rvdata file
  load_time = Time.now - start_time
  total_load_time += load_time

  start_time = Time.now
  
  # Prevent the 'magic_number' field of System from always conflicting
  if files[i] == "System.rvdata"
    data.magic_number = $MAGIC_NUMBER unless $MAGIC_NUMBER == -1
  end
  
  # Dump the data to a YAML file
  File.open($OUTPUT_DIR + File.basename(files[i], ".rvdata") + ".yaml", File::WRONLY|File::CREAT|File::TRUNC|File::BINARY) do |outfile|
    YAML::dump({'root' => data}, outfile )
  end

  # Calculate the time to dump the .yaml file
  dump_time = Time.now - start_time
  total_dump_time += dump_time
  
  # Update the user on the export status
  str =  "Exported "
  str += "#{files[i]}".ljust(30)
  str += "(" + "#{i+1}".rjust(3, '0')
  str += "/"
  str += "#{files.size}".rjust(3, '0') + ")"
  str += "    #{load_time + dump_time} seconds"
  puts_verbose str
end

# Calculate the total elapsed time
total_elapsed_time = Time.now - total_start_time

# Report the times
print_separator
puts_verbose "rvdata load time: #{total_load_time} seconds."
puts_verbose "YAML dump time:   #{total_dump_time} seconds."
puts_verbose "Total export time:  #{total_elapsed_time} seconds."
print_separator
puts_verbose