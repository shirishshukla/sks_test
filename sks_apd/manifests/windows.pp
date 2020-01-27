# Description: Manage installtion of appdynamics app-agent and machine-agent on Linux and Windows OS
#
# @summary Install and configure AppDynamics
#
# @param app_name Application name
# @param tier_name Tier name
# @param account_name Account name
# @param controller_host Controller hostname
# @param account_access_key Access key
# @param controller_port Controller port number
# @param controller_ssl_enabled Controller SSL support
# @param orchestration_enabledd Should orchestration be enabled
# @param sim_enabled Should sim be enabled
# @param fileserver Location of binary files


# @param win_drive_letter Drive where agent is going to be installed
# @param win_binary_dir Directory
# @param win_java_agent_binary_file Java App agent binary file
# @param win_dot_net_agent_binary_file Dotnet agent binary file
# @param win_machine_agent_binary_file Windows machine agent binary file
# @param win_app_agent_install_dir App agent installation directory path
# @param win_machine_agent_install_dir Machine agent installation directory path
# @param opt_free_space desired free space in /opt


##
# Document:
#   DB Agent:
#     - https://docs.appdynamics.com/display/PRO45/Database+Agent+Configuration+Properties
#   Java Agent:
#     -
#   dotNet agent:
#     -
#   Machine Agent:
#     -
##

class ahead_appd::windows(
  $fileserver                        = $ahead_appd::fileserver,
  $app_name                          = $ahead_appd::app_name,
  $tier_name                         = $ahead_appd::tier_name,
  $controller_host                   = $ahead_appd::controller_host,
  $controller_port                   = $ahead_appd::controller_port,
  $controller_ssl_enabled            = $ahead_appd::controller_ssl_enabled,
  $orchestration_enabledd            = $ahead_appd::orchestration_enabledd,
  $account_name                      = $ahead_appd::account_name,
  $account_acces_key                 = $ahead_appd::account_acces_key,
  $sim_enabled                       = $ahead_appd::sim_enabled,
  $win_db_agent_binary_file          = $ahead_appd::win_db_agent_binary_file,
  $win_db_agent_install_jvm_options  = $ahead_appd::win_db_agent_install_jvm_options,
  $win_java_agent_binary_file        = $ahead_appd::win_java_agent_binary_file,
  $win_dot_net_agent_binary_file     = $ahead_appd::win_dot_net_agent_binary_file,
  $win_machine_agent_binary_file     = $ahead_appd::win_machine_agent_binary_file,
  $win_drive_letter                  = $ahead_appd::win_drive_letter,
  $win_binary_dir                    = $ahead_appd::win_binary_dir,
  $win_db_agent_install_dir          = $ahead_appd::win_db_agent_install_dir,
  $win_app_agent_install_dir         = $ahead_appd::win_app_agent_install_dir,
  $win_machine_agent_install_dir     = $ahead_appd::win_machine_agent_install_dir
) {

  # Validate Drive exist ?
  validate_absolute_path("${win_drive_letter}:\\")

  # Validate Drive have min 4000 MB free space
  $free_space = inline_template('<% val=@win_drive_letter %><%= @win_disk_space.grep(/#{val}/)[0].split(":")[-1].to_i  %>')
  if $free_space.scanf('%d')[0] < 3000 {
    fail("Fail: free space on /opt is ${free_space}M less than 4G")
  }

  ## Variables
  # Binary puppet fileserver source
  $dot_net_agent_source           = "puppet:///${fileserver}/${win_dot_net_agent_binary_file}" # lint:ignore:puppet_url_without_modules
  $win_java_agent_source          = "puppet:///${fileserver}/${win_java_agent_binary_file}"    # lint:ignore:puppet_url_without_modules
  $win_machine_agent_source       = "puppet:///${fileserver}/${win_machine_agent_binary_file}" # lint:ignore:puppet_url_without_modules
  $win_db_agent_source            = "puppet:///${fileserver}/${win_db_agent_binary_file}"      # lint:ignore:puppet_url_without_modules

  #
  $binary_dir                     = "${win_drive_letter}:\\${win_binary_dir}"
  $db_agent_install_dir           = "${binary_dir}\\${win_db_agent_install_dir}"
  $app_agent_install_dir          = "${binary_dir}\\${win_app_agent_install_dir}"
  $app_dotnet_agent_dir           = "${binary_dir}\\${win_app_agent_install_dir}"
  $machine_agent_install_dir      = "${binary_dir}\\${win_machine_agent_install_dir}"

  # Create Directory
  file { $binary_dir:
    ensure => directory
  }

  #### Install DB Agent
  $db_agent_binary_file              = "${db_agent_install_dir}\\${win_db_agent_binary_file}"
  $win_db_agent_controller_info_file = "${db_agent_install_dir}\\conf\\controller-info.xml"
  $db_agent_service_name             = 'Appdynamics Database Agent'
  $db_agent_version                  = regsubst($win_db_agent_binary_file.split('-')[-1], '^(.+)\.zip$', '\1')
  if $facts['win_db_agent_version'] != undef {
    $old_version = $facts['win_db_agent_version']
  } else {
    $old_version = $db_agent_version # make them the same so you dont need to backup; versioncmp() will return 0 since equal
  }

  $_version     = regsubst($db_agent_version, '(^\d+\.\d+\.\d+).*$', '\1')          # Don't care about the patch level
  $_old_version = regsubst($old_version, '(^\d+\.\d+\.\d+).*$', '\1')               # Don't care about the patch level

  notify {"hello ${_version} -> ${_old_version}":}

  if versioncmp($_version, $_old_version) > 0 {  # Need to upgrade, so backup

    notify{"Upgrading DB Agent from ${_old_version} to ${_version}":}

    ahead_appd::windows::service_action { "Stop Service ${db_agent_service_name}":
      service => $db_agent_service_name,
      status  => 'stop',
    }

    # UnInstall DB Agent as service if already installed
    exec { 'Un-install DB Agent as a Service':
      command  => "${$db_agent_install_dir}\\cscript UninstallService.vbs",
      provider => 'powershell',
      onlyif   => '$result = Test-Path -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Appdynamics Database Agent";if ($result -eq "True") { Exit 0 } else { Exit 1 };',  # lint:ignore:140chars
    }

    exec { "Backup AppD DB Agent ${old_version}":
      command  => "Rename-Item -Path ${db_agent_install_dir} -newName ${db_agent_install_dir}.${old_version}", #$ -ErrorAction Ignore,
      provider => 'powershell',
      onlyif   => "\$result = Test-Path -Path ${db_agent_install_dir};if (\$result -eq \"True\") { Exit 0 } else { Exit 1 };",   # lint:ignore:140chars
      notify   => File[$db_agent_install_dir],
      require  => Exec['Un-install DB Agent as a Service']
    }

  } elsif versioncmp($_version, $_old_version) < 0 { # Downgrading
      fail("Downgrading isn't enabled.")
  }

  # DB Agent Install Directory
  file{ $db_agent_install_dir:
    ensure => 'directory'
  }

  # Copy DB Agent Binary File
  file { $db_agent_binary_file:
    ensure  => 'present',
    source  => $win_db_agent_source,
    backup  => false,
    require => File[$db_agent_install_dir],
  }

  # Extract DB Agent ZIP file
  ahead_appd::windows::unzip { $db_agent_binary_file:
    destination => $db_agent_install_dir,
    creates     => $win_db_agent_controller_info_file,
    require     => File[$db_agent_binary_file],
    notify      => File[$win_db_agent_controller_info_file]
  }

  # Set controller config file
  file { $win_db_agent_controller_info_file:
    ensure  => 'file',
    content => epp("${module_name}/win_db_agent_controller-info.xml.epp",
      {
        'controller_host'        => $controller_host,
        'account_name'           => $account_name,
        'account_access_key'     => $account_acces_key,
        'controller_port'        => $controller_port,
        'controller_ssl_enabled' => $controller_ssl_enabled
      }
    ),
  }

  # Install DB Agent as service
  exec { 'Install DB Agent as a Service':
    command  => "cscript InstallService.vbs ${win_db_agent_install_jvm_options}",
    cwd      => $db_agent_install_dir,
    provider => 'powershell',
    onlyif   => '$result = Test-Path -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Appdynamics Database Agent";if ($result -eq "True") { Exit 1 } else { Exit 0 };', # lint:ignore:140chars
    require  => File[$win_db_agent_controller_info_file],
  }

  # Start Enable DB Agent Service
  service { 'Appdynamics Database Agent':
    ensure    => 'running',
    enable    => true,
    subscribe => File[$win_db_agent_controller_info_file],
    require   => Exec['Install DB Agent as a Service'],
  }

  #### Install App Agent (Java or .Net Agent)
  # App Agent Install Directory
  file{$app_agent_install_dir:
    ensure => directory
  }

  ## Determine Java Agent OR .Net Agent to be installed
  if $facts['apache_tomcat_installed_status'] == 'Installed' {
    ## Install Java Agent
    $java_agent_binary_file              = "${app_agent_install_dir}\\${win_java_agent_binary_file}"
    $win_java_agent_controller_info_file = "${app_agent_install_dir}\\conf\\controller-info.xml"

    # Copy Machine Agent Binary File
    file { $java_agent_binary_file:
      ensure  => 'present',
      source  => $win_java_agent_source,
      backup  => false,
      require => File[$app_agent_install_dir],
    }

    # Extract Java Agent ZIP file
    ahead_appd::windows::unzip { $java_agent_binary_file:
      destination => $app_agent_install_dir,
      creates     => $win_java_agent_controller_info_file,
      require     => File[$java_agent_binary_file],
      notify      => File[$win_java_agent_controller_info_file]
    }

    # Set controller config file
    file { $win_java_agent_controller_info_file:
      ensure  => 'file',
      content => epp("${module_name}/win_app_agent_controller-info.xml.epp",
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
      require => Ahead_appd::Windows::Unzip[$java_agent_binary_file]
    }

  } else {
    ## Install .Net agent
    $msi_name                       = $win_dot_net_agent_binary_file.split('-')[0]
    $msi_version                    = regsubst($win_dot_net_agent_binary_file.split('-')[1], '^(.+)\.msi$', '\1')
    $msi_file_path                  = "${app_agent_install_dir}\\${win_dot_net_agent_binary_file}"
    $msi_agent_installer_log_file   = "${app_agent_install_dir}\\AgentInstaller.log"
    $ad_config_file                 = "${app_agent_install_dir}\\AD_Config.xml"

  # .Net Agent Install Directory
    #file{$app_dotnet_agent_dir:
    #  ensure => directory
  #}

    # AD_Config file
    file { $ad_config_file:
      ensure  => 'file',
      content => epp("${module_name}/AD_Config_IIS.xml.epp",
        {
          'controller_host'        => $controller_host,
          'account_name'           => $account_name,
          'account_access_key'     => $account_acces_key,
          'controller_port'        => $controller_port,
          'controller_ssl_enabled' => $controller_ssl_enabled,
        }
      ),
      require => File[$app_dotnet_agent_dir],
    }

    # Copy APP Agent MSI FILE
    file { $msi_file_path:
      source  => $dot_net_agent_source,
      require => File[$app_dotnet_agent_dir]
    }

    # Downlaod install msi
    package { 'AppDynamics .NET Agent':
      ensure          => $msi_version,
      provider        => 'windows',
      source          => $msi_file_path,
      install_options => [
        '/lv', $msi_agent_installer_log_file,
        { 'INSTALLDIR'        => $app_agent_install_dir },
        { 'DOTNETAGENTFOLDER' => $app_dotnet_agent_dir  },
        { 'AD_SetupFile'      => $ad_config_file        },
      ],
      require         => File[$ad_config_file]
    }
    #~> exec { 'iisreset for appd':
    #  command     => 'iisreset',
    #  refreshonly => true,
    #  path        => $facts['path'],
    #}

    # net start AppDynamics.Agent.Coordinator_service
    service { 'AppDynamics.Agent.Coordinator_service':
      ensure  => 'running',
      enable  => true,
      require => Package['AppDynamics .NET Agent']
    }

  } # Close If condition

  #### Machine Agent
  $machine_agent_binary_file        = "${machine_agent_install_dir}\\${win_machine_agent_binary_file}"
  $win_machine_controller_info_file = "${machine_agent_install_dir}\\conf\\controller-info.xml"

  # Machine Agent Install Directory
  file{$machine_agent_install_dir:
    ensure => directory
  }

  # Copy Machine Agent Binary File
  file { $machine_agent_binary_file:
    ensure  => 'present',
    source  => $win_machine_agent_source,
    backup  => false,
    require => File[$machine_agent_install_dir],
  }

  # Extract Machine Agent ZIP file
  $zipfile = $machine_agent_binary_file
  $destination = $machine_agent_install_dir

  ahead_appd::windows::unzip { $zipfile:
    destination => $destination,
    creates     => $win_machine_controller_info_file,
    require     => File[$machine_agent_binary_file],
    notify      => Exec['Install MachineAgent as a Service']
  }

  # Config Controller File
  file { $win_machine_controller_info_file:
    ensure  => 'file',
    content => epp("${module_name}/win_controller-info.xml.epp",
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
    require => Ahead_appd::Windows::Unzip[$zipfile] #, Exec["Unzip ${machine_agent_binary_file}"],
  }

  # Install MachineAgent as service
  exec { 'Install MachineAgent as a Service':
    command  => 'cscript InstallService.vbs',
    cwd      => $machine_agent_install_dir,
    provider => 'powershell',
    onlyif   => '$result = Test-Path -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Appdynamics Machine Agent";if ($result -eq "True") { Exit 1 } else { Exit 0 };', # lint:ignore:140chars
    require  => File[$win_machine_controller_info_file],
  }

  service { 'Appdynamics Machine Agent':
    ensure    => 'running',
	enable    => true,
    subscribe => File[$win_machine_controller_info_file],
    require   => Exec['Install MachineAgent as a Service'],
  }

}

##
# Document: Function to start.stop windows services
###
#
define ahead_appd::windows::service_action(
  $service,
  $status
) {

  notify {"${status} service: ${service}": }

  case $status {
                  'stop': {
                              exec {"${name} ${status} ${service}":
                                command  => "Stop-Service -Name ${service} -Force",
                                provider => 'powershell'
                              }
                          }

                  'start': {
                            exec {"${name} - ${status} ${service}":
                              command  => "Start-Service -Name ${service}",
                              provider => 'powershell'
                            }
                          }

                  default: { fail("Un-Supported Operation ${status} ${service}") }
                }

}

##
# Document: function to unzip on widnows via powershell command
##
define ahead_appd::windows::unzip(
  $destination,
  $creates          = undef,
  $refreshonly      = false,
  $unless           = undef,
  $zipfile          = $name,
  $provider         = 'powershell',
  $options          = '20',
  $timeout          = 300,
) {
  validate_absolute_path($destination)

  # Command templaet file
  $command_template = 'windows/unzip.ps1.erb'

  if (! $creates and ! $refreshonly and ! $unless){
    fail("Must set one of creates, refreshonly, or unless parameters.\n")
  }

  exec { "unzip-${name}":
    command     => template($command_template),
    creates     => $creates,
    refreshonly => $refreshonly,
    unless      => $unless,
    provider    => $provider,
    timeout     => $timeout,
  }
}

## END CLASS ##