#===============================================================================
# Filename:    logtime.rb
#
# Developer:   Raku (rakudayo@gmail.com)
#
# Description: This file simply dumps a timestamp to a binary timestamp file.
#===============================================================================

require 'common'

# Make sure RMXP isn't running
exit if check_for_rmvx

# Get the project directory from command-line argument
$PROJECT_DIR = ARGV[0]

# Uhh...is a comment really necessary here?
dump_startup_time