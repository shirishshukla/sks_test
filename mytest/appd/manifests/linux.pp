##
# Document:
##

class appd_agent::linux (
  $fileserver                  = $appd_agent::fileserver,
  $app_name                    = $appd_agent::app_name,
  $tier_name                   = $appd_agent::tier_name,
  $controller_host             = $appd_agent::controller_host,
  $controller_port             = $appd_agent::controller_port,
  $controller_ssl_enabled      = $appd_agent::controller_ssl_enabled,
  $account_name                = $appd_agent::account_name,
  $account_acces_key           = $appd_agent::account_acces_key,
  $sim_enabled                 = $appd_agent::sim_enabled,
  $orchestration_enabledd      = $appd_agent::orchestration_enabledd,
  $db_agent_binary_file        = $appd_agent::db_agent_binary_file,
  $app_agent_binary            = $appd_agent::app_agent_binary,
  $machine_agent_binary        = $appd_agent::machine_agent_binary,
  $base_appd_dir               = $appd_agent::base_appd_dir,
  $db_agent_install_dir        = $appd_agent::db_agent_install_dir,
  $app_agent_install_dir       = $appd_agent::app_agent_install_dir,
  $app_agent_owner             = $appd_agent::app_agent_owner,
  $app_agent_group             = $appd_agent::app_agent_group,
  $machine_agent_install_dir   = $appd_agent::machine_agent_install_dir,
  $machine_agent_owner         = $appd_agent::machine_agent_owner,
  $machine_agent_group         = $appd_agent::machine_agent_group
) {

  ## Fail if free space on /opt < 4000 MB
  $opt_free_space = $facts['free_space_opt'].scanf('%d')[0]
  if $opt_free_space < 4000 {
    fail("Fail: free space on /opt is ${opt_free_space}M less than 4G")
  }

  ## Variables
  # DB Agent 
  #$installer_file_name          = "dbagent-${version}.zip"
  #$installer_file_path          = "puppet:///${fileserver}/${db_agent_binary_file}" # lint:ignore:puppet_url_without_modules
  #$install_directory            = '/opt/was/appdynamics/dbagent'
  # Java Agent   
  $app_agent_binary_source      = "puppet:///${fileserver}/${app_agent_binary}"     # lint:ignore:puppet_url_without_modules
  $app_controller_info_file     = "${app_agent_install_dir}/conf/controller-info.xml"
  # Machine Agent 
  $machine_agent_binary_source  = "puppet:///${fileserver}/${machine_agent_binary}" # lint:ignore:puppet_url_without_modules
  $machine_controller_info_file = "${machine_agent_install_dir}/conf/controller-info.xml"
  $machine_agent_sysconfig_file = '/etc/sysconfig/appdynamics-machine-agent'
  $app_agent_version            = regsubst($app_agent_binary.split('-')[-1], '^(.+)\.zip$', '\1')
  $machine_agent_version        = regsubst($machine_agent_binary.split('-')[-1], '^(.+)\.zip$', '\1')

  ## Install unzip package 
  # Unzip package is required
  package { 'unzip':
    ensure => installed
  }

  ## Create recurse $base_appd_dir
  exec { "Create ${base_appd_dir}":
    creates => $base_appd_dir,
    command => "mkdir -p ${base_appd_dir}",
    path    => $::path
  } -> file { $base_appd_dir:  }

  ## Create  symlink pinting to $base_appd_dir
  file {'/opt/AppDynamics':
    ensure => link,
    target => $base_appd_dir,
    owner  => $app_agent_owner,
    group  => $app_agent_group
  }

  #### Install DB Agent

  #### Install App Agent 
  if $facts['appdynamics_java_agent_version'] != undef {
    $old_version = $facts['appdynamics_java_agent_version']
  } else {
    $old_version = $app_agent_version # make them the same so you dont need to backup; versioncmp() will return 0 since equal
  }

  $_version     = regsubst($app_agent_version, '(^\d+\.\d+\.\d+).*$', '\1')     # Don't care about the patch level
  $_old_version = regsubst($old_version, '(^\d+\.\d+\.\d+).*$', '\1')           # Don't care about the patch level

  if versioncmp($_version, $_old_version) > 0 {   # Need to upgrade, so backup
    exec { "Backup AppD JavaAgent ${old_version}":
      command => "test -d ${app_agent_install_dir} && mv ${app_agent_install_dir} ${app_agent_install_dir}.${old_version}",
      path    => ['/usr/sbin/','/usr/bin/','/bin', '/sbin']
    }

    # Create Dir `
    file {$app_agent_install_dir:
      ensure => directory,
      owner  => $app_agent_owner,
      group  => $app_agent_group
    }

    # Extract Binary  
    archive { $app_agent_install_dir:
      path         => "${app_agent_install_dir}/${app_agent_binary}",
      source       => $app_agent_binary_source,
      extract      => true,
      extract_path => $app_agent_install_dir,
      user         => $app_agent_owner,
      group        => $app_agent_group,
      cleanup      => true,
      creates      => $app_controller_info_file,
      require      => File[$app_agent_install_dir]
    }

  } elsif versioncmp($_version, $_old_version) < 0 { # Downgrading
    fail("Downgrading isn't enabled.")
  }

  # Set controller config file 
  file { $app_controller_info_file:
    ensure  => 'file',
    content => epp("${module_name}/app_agent_controller-info.xml.epp",
      {
        'controller_host'        => $controller_host,
        'account_name'           => $account_name,
        'account_access_key'     => $account_acces_key,
        'controller_port'        => $controller_port,
        'controller_ssl_enabled' => $controller_ssl_enabled,
        'orchestration_enabled'  => $orchestration_enabledd,
        'tier_name'              => $tier_name,
        'application_name'       => $app_name,
        'node_name'              => $facts['hostname']
      }
    ),
    require => Archive[$app_agent_install_dir]
  }

  #### Machine Agent
  if $facts['appdynamics_machine_agent_version'] != undef {
    $old_version = $facts['appdynamics_machine_agent_version']
  } else {
    $old_version = $machine_agent_version # make them the same so you dont need to backup; versioncmp() will return 0 since equal
  }

  $_version     = regsubst($machine_agent_version, '(^\d+\.\d+\.\d+).*$', '\1')     # Don't care about the patch level
  $_old_version = regsubst($old_version, '(^\d+\.\d+\.\d+).*$', '\1')               # Don't care about the patch level

  if versioncmp($_version, $_old_version) > 0 {   # Need to upgrade, so backup
    exec { "Backup AppD Machine Agent ${old_version}":
      command => "test -d ${machine_agent_install_dir} && mv ${machine_agent_install_dir} ${machine_agent_install_dir}.${old_version}",
      path    => ['/usr/sbin/','/usr/bin/','/bin', '/sbin',],
    }

    # Create Dir 
    file {$machine_agent_install_dir:
      ensure => directory,
      owner  => $machine_agent_owner,
      group  => $machine_agent_group
    }

    # Extract Binary  
    archive { $machine_agent_install_dir:
      path         => "${machine_agent_install_dir}/${machine_agent_binary}",
      source       => $machine_agent_binary_source,
      extract      => true,
      extract_path => $machine_agent_install_dir,
      user         => $machine_agent_owner,
      group        => $machine_agent_group,
      cleanup      => true,
      creates      => $machine_controller_info_file,
      require      => File[$machine_agent_install_dir]
    }

  } elsif versioncmp($_version, $_old_version) < 0 { # Downgrading
    fail("Downgrading isn't enabled.")
  }

  # Set controller config file 
  file { $machine_controller_info_file:
    ensure  => 'file',
    content => epp("${module_name}/machine_agent_controller-info.xml.epp",
      {
        'controller_host'        => $controller_host,
        'account_name'           => $account_name,
        'account_access_key'     => $account_acces_key,
        'controller_port'        => $controller_port,
        'controller_ssl_enabled' => $controller_ssl_enabled,
        'orchestration_enabled'  => $orchestration_enabledd,
        'sim_enabled'            => $sim_enabled,
      }
    ),
    require => Archive[$machine_agent_install_dir]
  }

  # Setup machine-agent sysconfig file 
  file { $machine_agent_sysconfig_file:
    ensure  => 'file',
    content => epp("${module_name}/machine_agent_sysconfig.epp",
      {
        'machine_agent_install_dir' => $machine_agent_install_dir,
        'machine_agent_owner'       => $machine_agent_owner,
        'machine_agent_group'       => $machine_agent_group
      }
    ),
    require => Archive[$machine_agent_install_dir],
  }

  # Machine Agent daemon service file
  File { '/etc/init.d/appdynamics-machine-agent':
    source  => "${machine_agent_install_dir}/etc/init.d/appdynamics-machine-agent",
    mode    => '0755',
    require => File['/etc/sysconfig/appdynamics-machine-agent']
  }

  # Start Enable service 
  service { 'appdynamics-machine-agent':
    ensure  => running,
    enable  => true,
    #provider => 'init',
    require => File['/etc/init.d/appdynamics-machine-agent']
  }

} ## END CLASS