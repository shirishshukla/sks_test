##
# Doc
##

class appd_agent::windows(
  $app_name                       = $appd_agent::app_name,
  $tier_name                      = $appd_agent::tier_name,
  $controller_host                = $appd_agent::controller_host,
  $controller_port                = $appd_agent::controller_port,
  $controller_ssl_enabled          = $appd_agent::controller_ssl_enabled,
  $orchestration_enabledd          = $appd_agent::orchestration_enabledd,
  $account_name                   = $appd_agent::account_name,
  $account_acces_key               = $appd_agent::account_acces_key,
  $sim_enabled                    = $appd_agent::sim_enabled,
  $win_drive_letter               = $appd_agent::win_drive_letter,
  $win_binary_dir                 = $appd_agent::win_binary_dir,
  $win_app_agent_install_dir        = $appd_agent::win_app_agent_install_dir,
  $win_app_agent_binary_file        = $appd_agent::win_app_agent_binary_file,
  $win_machine_agent_install_dir    = $appd_agent::win_machine_agent_install_dir,
  $win_machine_agent_install_binary = $appd_agent::win_machine_agent_install_binary
) {

  # Validate Drive exist ?
  validate_absolute_path("${win_drive_letter}:\\")

  # Binary Directory 
  $msi_name                   = $win_app_agent_binary_file.split('-')[0]
  $msi_version                    = regsubst($win_app_agent_binary_file.split('-')[1], '^(.+)\.msi$', '\1')
  $binary_dir                 = "${win_drive_letter}:\\${win_binary_dir}"
  $msi_file_path               = "${binary_dir}\\${win_app_agent_binary_file}"
  $msi_agent_installer_log_file  = "${binary_dir}\\AgentInstaller.log"
  $app_agent_install_dir        = "${binary_dir}\\${win_app_agent_install_dir}"
  $app_dotnet_agent_folder = "${binary_dir}\\${win_app_agent_install_dir}"
  $ad_config_file            = "${binary_dir}\\AD_Config.xml"
  $machine_agent_install_dir    = "${binary_dir}\\${win_machine_agent_install_dir}"
  $machine_agent_binary_file    = "${binary_dir}\\${win_machine_agent_install_binary}"

  # Create Directory
  $appd_agent_dirs = unique([ $binary_dir, $app_agent_install_dir, $app_dotnet_agent_folder ])

  file { $appd_agent_dirs :
    ensure => directory
  }

  #### Install App Agent 
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
    require => File[$appd_agent_dirs],
  }

  # Copy APP Agent MSI FILE
  file { $msi_file_path:
    source => "puppet:///modules/${module_name}/${win_app_agent_binary_file}",
  require  => File[$appd_agent_dirs]
  }

  package { 'AppDynamics .NET Agent':
    ensure          => $msi_version,
    provider        => 'windows',
    source          => $msi_file_path,
    install_options => [
      '/lv', $msi_agent_installer_log_file,
      { 'INSTALLDIR'        => $app_agent_install_dir        },
      { 'DOTNETAGENTFOLDER' => $app_dotnet_agent_folder },
      { 'AD_SetupFile'      => $ad_config_file            },
    ],
    require         => File[$ad_config_file]
  }
  ~> exec { 'iisreset for appd':
    command     => 'iisreset',
    refreshonly => true,
    path        => $facts['path'],
  }

  # net start AppDynamics.Agent.Coordinator_service
  service { 'AppDynamics.Agent.Coordinator_service':
    ensure  => 'running',
    enable  => true,
    require => Package['AppDynamics .NET Agent']
  }

  #### Machine Agent 
  $win_machine_controller_info_file = "${machine_agent_install_dir}\\conf\\controller-info.xml"

  file { $machine_agent_install_dir:
    ensure => directory
  }

  # Copy Machine Agent Binary File 
  file { $machine_agent_binary_file:
    ensure  => 'present',
    source  => "puppet:///modules/${module_name}/${win_machine_agent_install_binary}", # lint:ignore:puppet_url_without_modules
    backup  => false,
    require => File[$machine_agent_install_dir],
  }

  # Extract Machine Agent ZIP file 
  exec { "Unzip ${machine_agent_binary_file}":
    command => "unzip ${machine_agent_binary_file} -d ${machine_agent_install_dir}",
    creates => $win_machine_controller_info_file,
    require => File[$machine_agent_binary_file],
    notify  => Exec['Install MachineAgent as a Service'],
  }

  # Cofnig Controller File 
  file { $win_machine_controller_info_file:
    ensure  => 'file',
    content => epp("${module_name}/windows-controller-info.xml.epp",
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
    require => Exec["Unzip ${machine_agent_binary_file}"],
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
    subscribe => File[$win_machine_controller_info_file],
    require   => Exec['Install MachineAgent as a Service'],
  }

}

## END FILE 
