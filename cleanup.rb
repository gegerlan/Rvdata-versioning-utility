#===============================================================================
# Filename:    cleanup.rb
#
# Developer:   Raku (rakudayo@gmail.com)
#
# Description: This file is a convenient utility to help check if any Ruby
#    scripts are in the scripts directory (the location where scripts are 
#    exported to) but are stale.  
#
#    Stale scripts are scripts which are not included in the script export 
#    digest, and hence will not be imported into RMXP.  Scripts can become stale
#    if they are added in RMXP's script editor, exported, and then later removed
#    from the script editor.
#
#    Simply invoke the script like so...
#
#      > ruby cleanup.rb
#
#    ...and it will spit out any stale scripts which you might want to go ahead
#    and delete or backup.
#===============================================================================

require 'common'

# Fix relative path to scripts directory
$SCRIPTS_DIR = "../" + $SCRIPTS_DIR

# Check if the export digest even exists
if not File.exists?($SCRIPTS_DIR + "/" + $EXPORT_DIGEST_FILE)
  puts "Error: Export digest is missing."
  puts "Hint: Have you exported your RGSS scripts yet?"
  exit
end

puts

# Import the RGSS scripts from Ruby files
digest_entries = []
File.open($SCRIPTS_DIR + "/" + $EXPORT_DIGEST_FILE, "r+") do |digest|
  digest.each do |line|
  line.chomp!
  digest_entries << line[($COLUMN1_WIDTH+$COLUMN2_WIDTH)..-1].rstrip
  end
end

# Build a list of Ruby scripts in the script export directory
dir_entries = Dir.entries($SCRIPTS_DIR)
dir_entries.map! {|entry| File.extname(entry) == '.rb' ? entry : nil}
dir_entries.compact!
dir_entries.delete("clean.rb")

# Select only the Ruby scripts that are not in the export digest
stale_scripts = dir_entries.select {|entry| digest_entries.index(entry) == nil}

# Print the stale scripts
puts "The following Ruby scripts are stale (i.e. no longer in your project, but\n" + 
     "they are still in your scripts directory). You may want to remove them.\n\n"

puts "  None" if stale_scripts.empty?

stale_scripts.each do |script|
  puts "  - #{script}"
end