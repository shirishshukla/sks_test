##
# Document:
##

class appd_agent::linux (
  $appName              = $appd_agent::appName,
  $tierName             = $appd_agent::tierName,
  $controllerHost       = $appd_agent::controllerHost,
  $controllerPort       = $appd_agent::controllerPort,
  $controllerSSLEnabled = $appd_agent::controllerSSLEnabled,
  $accountName          = $appd_agent::accountName,
  $accountAccesKey      = $appd_agent::accountAccesKey,
  $simEnabled           = $appd_agent::simEnabled,
  $orchestrationEnabled = $appd_agent::orchestrationEnabled,
  $appInstallBinary     = $appd_agent::appInstallBinary,
  $machineInstallBinary = $appd_agent::machineInstallBinary,
  $baseAppdDir          = $appd_agent::baseAppdDir,
  $appInstallDir        = $appd_agent::appInstallDir,
  $appAgentOwner        = $appd_agent::appAgentOwner,
  $appAgentGroup        = $appd_agent::appAgentGroup,
  $machineInstallDir    = $appd_agent::machineInstallDir,
  $machineAgentOwner    = $appd_agent::machineAgentOwner,
  $machineAgentGroup    = $appd_agent::machineAgentGroup
) {

  ## Create recurse $baseAppdDir
  exec { "Create ${baseAppdDir}":
    creates => $baseAppdDir,
    command => "mkdir -p ${baseAppdDir}",
    path    => $::path
  } -> file { $baseAppdDir:  }

  ## Install App Agent 
  $app_controller_info_file = "${appInstallDir}/conf/controller-info.xml"
  # Create Dir 
  file {$appInstallDir:
  ensure => directory,
  owner  => $appAgentOwner,
  group  => $appAgentGroup
  }

  # Extract Binary  
  archive { $appInstallDir:
    path         => "${appInstallDir}/${appInstallBinary}",
    source       => "puppet:///modules/${module_name}/${appInstallBinary}",
    extract      => true,
    extract_path => $appInstallDir,
    user         => $appAgentOwner,
    group        => $appAgentGroup,
    cleanup      => true,
    creates      => $app_controller_info_file,
    require      => File[$appInstallDir]
  }

  # Set controller config file 
  file { $app_controller_info_file:
    ensure  => 'file',
    content => epp("${module_name}/app_agent_controller-info.xml.epp",
      {
        'controller_host'        => $controllerHost,
        'account_name'           => $accountName,
        'account_access_key'     => $accountAccesKey,
        'controller_port'        => $controllerPort,
        'controller_ssl_enabled' => $controllerSSLEnabled,
        'orchestration_enabled'  => $orchestrationEnabled,
        'tier_name'              => $tierName,
        'application_name'       => $appName,
        'node_name'              => $facts['hostname']
      }
    ),
    require => Archive[$appInstallDir]
  }

  #### Machine Agent 
  $machine_controller_info_file = "${machineInstallDir}/conf/controller-info.xml"
  $machine_agent_sysconfig_file = '/etc/sysconfig/appdynamics-machine-agent'

  # Create Dir 
  file {$machineInstallDir:
    ensure => directory,
    owner  => $machineAgentOwner,
    group  => $machineAgentGroup
  }

  # Extract Binary  
  archive { $machineInstallDir:
    path         => "${machineInstallDir}/${machineInstallBinary}",
    source       => "puppet:///modules/${module_name}/${machineInstallBinary}",
    extract      => true,
    extract_path => $machineInstallDir,
    user         => $machineAgentOwner,
    group        => $machineAgentGroup,
    cleanup      => true,
    creates      => $machine_controller_info_file,
    require      => File[$machineInstallDir]
  }

  # Set controller config file 
  file { $machine_controller_info_file:
    ensure  => 'file',
    content => epp("${module_name}/machine_agent_controller-info.xml.epp",
      {
        'controller_host'        => $controllerHost,
        'account_name'           => $accountName,
        'account_access_key'     => $accountAccesKey,
        'controller_port'        => $controllerPort,
        'controller_ssl_enabled' => $controllerSSLEnabled,
        'orchestration_enabled'  => $orchestrationEnabled,
        'sim_enabled'            => $simEnabled,
      }
    ),
    require => Archive[$machineInstallDir],
  }

  # Setup machine-agent sysconfig file 
  file { $machine_agent_sysconfig_file:
    ensure  => 'file',
    content => epp("${module_name}/machine_agent_sysconfig.epp",
      {
        'machine_agent_install_dir' => $machineInstallDir,
        'machine_agent_owner'       => $machineAgentOwner,
        'machine_agent_group'       => $machineAgentGroup
      }
    ),
    require => Archive[$machineInstallDir],
  }

  # Machine Agent daemon service file
  File { '/etc/init.d/appdynamics-machine-agent':
    source  => "${machineInstallDir}/etc/init.d/appdynamics-machine-agent",
    mode    => '0755',
    require => File['/etc/sysconfig/appdynamics-machine-agent']
  }

  # Start Enable service 
  service { 'appdynamics-machine-agent':
    ensure  => running,
    enable  => true,
    #provider   => 'init',
    require => File['/etc/init.d/appdynamics-machine-agent']
  }

} ## END CLASS
