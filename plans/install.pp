plan puppetdb::install (
  TargetSpec $nodes,
  Boolean $is_master = false,
) {
  # Bolt's Puppet does not run with access to any local Puppet configuration
  # so it is not possible to validate the PuppetDB connection in a Bolt apply
  $strict_validation = false

  # Install the puppet-agent package if Puppet is not detected.
  # Copy over custom facts from the Bolt modulepath.
  # Run the `facter` command line tool to gather node information.
  $nodes.apply_prep

  $confdir_result = run_task('puppetdb::lookup_confdir', $nodes)

  # Install a monolithic PuppetDB/Postgres
  get_targets($nodes).each |$target| {
    $confdir = $confdir_result.find($target.name).value()['confdir']
    apply($target, _run_as => root) {
      # Set up PuppetDB/PostgreSQL
      class { 'puppetdb::globals': }
      class { 'puppetdb': }

      notify { 'title' : message => $confdir }

      if $is_master {
        # Applies the necessary settings in Puppet's confdir to
        # instruct the Master to send data to PuppetDB
        class { 'puppetdb::master::config':
          puppet_confdir    => $confdir,
          puppet_conf       => "${confdir}/puppet.conf",
          strict_validation => $strict_validation,
        }
      }
    }
  }
}
