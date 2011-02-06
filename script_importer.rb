#===============================================================================
# Filename:    script_importer.rb
#
# Developer:   Raku (rakudayo@gmail.com)
#
# Description: This script import scripts into RMVX's Scripts.rvdata file.  This
#    script should only be used to import text files that have previously been
#    exported with the script_exporter.rb script.
#
# Usage:       ruby script_importer.rb <project_directory>
#===============================================================================

require 'common'

#--------------------------------
#      RGSS EXPORT SCRIPT
#--------------------------------

# Make sure RMVX isn't running
exit if check_for_rmvx

# Set up the directory paths
$INPUT_DIR  = $PROJECT_DIR + "/" + $SCRIPTS_DIR + "/"
$OUTPUT_DIR = $PROJECT_DIR + "/" + $rvdata_DIR + "/"

print_separator(true)
puts "  RGSS Script Import"
print_separator(true)

# Check if the input directory exists
if not (File.exists? $INPUT_DIR and File.directory? $INPUT_DIR)
  puts_verbose "Input directory #{$INPUT_DIR} does not exist."
  puts_verbose "Nothing to import...skipping import."
  puts_verbose
  exit
end

# Create the output directory if it doesn't exist
if not (File.exists? $OUTPUT_DIR and File.directory? $OUTPUT_DIR)
  puts "Error: Output directory #{$OUTPUT_DIR} does not exist."
  puts "Hint: Check that the rvdata_dir config option in config.yaml is set correctly."
  puts
  exit
end

start_time = Time.now

# Import the RGSS scripts from Ruby files
if File.exists?($INPUT_DIR + $EXPORT_DIGEST_FILE)
  # Load the export digest
  digest = []
  i = 0
  File.open($INPUT_DIR + $EXPORT_DIGEST_FILE, File::RDONLY) do |digestfile|
    digestfile.each do |line|
      line.chomp!
      digest[i] = []
      digest[i][0] = line[0..$COLUMN1_WIDTH-1].rstrip.to_i
      digest[i][1] = line[$COLUMN1_WIDTH..($COLUMN1_WIDTH+$COLUMN2_WIDTH-1)].rstrip
      digest[i][2] = line[($COLUMN1_WIDTH+$COLUMN2_WIDTH)..-1].rstrip
      i += 1
    end
  end

  # Find out how many non-empty scripts we have
  num_scripts  = digest.select { |e| e[2].upcase != "EMPTY" }.size
  num_exported = 0

  # Create the scripts data structure
  scripts = []
  #for i in (0..digest.length-1)
  digest.each_index do |i|
    scripts[i] = []
    scripts[i][0] = digest[i][0]
    scripts[i][1] = digest[i][1]
    scripts[i][2] = ""
    
    # Get the time starting import for this file
    deflate_start_time = Time.now
    if digest[i][2].upcase != "EMPTY"
      begin
        scriptname = $INPUT_DIR + "/" + digest[i][2]
        File.open(scriptname, File::RDONLY) do |infile|
          scripts[i][2] = infile.read
        end
      rescue Errno::ENOENT
        puts "ERROR:      No such file or directory - #{scriptname.gsub!('//','/')}.\n" +
             "Suggestion: If you are using a versioning system, check if this is a new\n" + 
             "RGSS script that was not commited to the repository."
      end
      num_exported += 1
    end
      # Perform the deflate on the compressed script
      scripts[i][2] = Zlib::Deflate.deflate(scripts[i][2])
      # Calculate the elapsed time for the deflate
      deflate_elapsed_time = Time.now - deflate_start_time
      # Build a log string
      str =  "Imported #{digest[i][2].ljust($FILENAME_WIDTH)}(#{num_exported.to_s.rjust(3, '0')}/#{num_scripts.to_s.rjust(3, '0')})"
      str += "         #{deflate_elapsed_time} seconds" if deflate_elapsed_time > 0.0
      puts_verbose str if digest[i][2].upcase != "EMPTY"
  end

  # Dump the scripts data structure to the RMVX's Scripts.rvdata file
  File.open($OUTPUT_DIR + "Scripts.rvdata", File::WRONLY|File::TRUNC|File::CREAT|File::BINARY) do |outfile|
    Marshal.dump(scripts, outfile)
  end

  elapsed_time = Time.now - start_time

  print_separator
  puts_verbose "The total import time:  #{elapsed_time} seconds."
  print_separator
elsif
  puts_verbose "No scripts to import."
end

puts_verbose