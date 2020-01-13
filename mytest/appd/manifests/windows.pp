##
# Doc
##

class appd_agent::windows(
  $fileserver                        = $appd_agent::fileserver,
  $app_name                          = $appd_agent::app_name,
  $tier_name                         = $appd_agent::tier_name,
  $controller_host                   = $appd_agent::controller_host,
  $controller_port                   = $appd_agent::controller_port,
  $controller_ssl_enabled            = $appd_agent::controller_ssl_enabled,
  $orchestration_enabledd            = $appd_agent::orchestration_enabledd,
  $account_name                      = $appd_agent::account_name,
  $account_acces_key                 = $appd_agent::account_acces_key,
  $sim_enabled                       = $appd_agent::sim_enabled,
  $win_java_agent_binary_file        = $appd_agent::win_java_agent_binary_file,
  $win_dot_net_agent_binary_file     = $appd_agent::win_dot_net_agent_binary_file,
  $win_machine_agent_binary_file     = $appd_agent::win_machine_agent_binary_file,
  $win_drive_letter                  = $appd_agent::win_drive_letter,
  $win_binary_dir                    = $appd_agent::win_binary_dir,
  $win_app_agent_install_dir         = $appd_agent::win_app_agent_install_dir,
  $win_machine_agent_install_dir     = $appd_agent::win_machine_agent_install_dir,
) {

  # Validate Drive exist ?
  validate_absolute_path("${win_drive_letter}:\\")

  # Validate Drive have min 4000 MB free space
  $free_space = inline_template('<% val=@win_drive_letter %><%= @win_disk_space.grep(/#{val}/)[0].split(":")[-1].to_i  %>')

  if $free_space.scanf('%d')[0] < 4000 {
    fail("Fail: free space on /opt is ${free_space}M less than 4G")
  }

  # Binary Directory 
  $msi_file_source                = "puppet:///${fileserver}/${win_dot_net_agent_binary_file}" # lint:ignore:puppet_url_without_modules
  $win_java_agent_source          = "puppet:///${fileserver}/${win_java_agent_binary_file}"    # lint:ignore:puppet_url_without_modules
  $win_machine_agent_source       = "puppet:///${fileserver}/${win_machine_agent_binary_file}" # lint:ignore:puppet_url_without_modules

  $binary_dir                     = "${win_drive_letter}:\\${win_binary_dir}"
  $app_agent_install_dir          = "${binary_dir}\\${win_app_agent_install_dir}"
  $app_dotnet_agent_folder        = "${binary_dir}\\${win_app_agent_install_dir}"
  $machine_agent_install_dir      = "${binary_dir}\\${win_machine_agent_install_dir}"
  $machine_agent_binary_file      = "${machine_agent_install_dir}\\${win_machine_agent_binary_file}"

  # Create Directory
  $appd_agent_dirs = unique([ $binary_dir, $app_agent_install_dir, $app_dotnet_agent_folder ])

  file { $appd_agent_dirs:
    ensure => directory
  }

  #### Install App Agent
  ## Determine Java Agent OR .Net Agent to be installed 
  if $facts['apache_tomcat_installed_status'] == 'Installed' {
    $java_agent_binary_file              = "${app_agent_install_dir}\\${win_java_agent_binary_file}"
    $win_java_agent_controller_info_file = "${app_agent_install_dir}\\conf\\controller-info.xml"

    # Copy Machine Agent Binary File  
    file { $java_agent_binary_file:
      ensure  => 'present',
      source  => $win_java_agent_source,
      backup  => false,
      require => File[$appd_agent_dirs],
    }

    # Extract Java Agent ZIP file   
    appd_agent::windows::unzip { $java_agent_binary_file:
      destination => $app_agent_install_dir,
      creates     => $win_java_agent_controller_info_file,
      require     => File[$machine_agent_binary_file],
      notify      => File[$win_java_agent_controller_info_file]
    }

    # Set controller config file 
    file { $win_java_agent_controller_info_file:
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
      require => Appd_agent::Windows::Unzip[$java_agent_binary_file]
    }

  } else {

    $msi_name                       = $win_dot_net_agent_binary_file.split('-')[0]
    $msi_version                    = regsubst($win_dot_net_agent_binary_file.split('-')[1], '^(.+)\.msi$', '\1')
    $msi_file_path                  = "${app_agent_install_dir}\\${win_dot_net_agent_binary_file}"
    $msi_agent_installer_log_file   = "${app_agent_install_dir}\\AgentInstaller.log"
    $ad_config_file                 = "${app_agent_install_dir}\\AD_Config.xml"

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
      source  => $msi_file_source,
      require => File[$appd_agent_dirs]
    }

    # Downlaod install msi 
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
  $win_machine_controller_info_file = "${machine_agent_install_dir}\\conf\\controller-info.xml"
  file { $machine_agent_install_dir:
    ensure => directory
  }

  # Copy Machine Agent Binary File  
  file { $machine_agent_binary_file:
    ensure  => 'present',
    source  => "puppet:///modules/${module_name}/${win_machine_agent_binary_file}", # lint:ignore:puppet_url_without_modules
    backup  => false,
    require => File[$machine_agent_install_dir],
  }

  # Extract Machine Agent ZIP file 
  $zipfile = $machine_agent_binary_file
  $destination = $machine_agent_install_dir

  appd_agent::windows::unzip { $zipfile:
    destination => $destination,
    creates     => $win_machine_controller_info_file,
    require     => File[$machine_agent_binary_file],
    notify      => Exec['Install MachineAgent as a Service']
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
    require => Appd_agent::Windows::Unzip[$zipfile] #, Exec["Unzip ${machine_agent_binary_file}"],
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

##
# Document:
## 
define appd_agent::windows::unzip(
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