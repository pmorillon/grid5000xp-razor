# Module:: razor5k
# Manifest:: init.pp
#

# Class:: razor5k
#
#
class razor5k {

  class { 'sudo':
    config_file_replace => false,
  }

  include razor

} # Class:: razor5k
