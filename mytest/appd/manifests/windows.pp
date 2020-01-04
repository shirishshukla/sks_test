##
# Doc
##

class appd_agent::windows(
  $appName                       = $appd_agent::appName,
  $tierName                      = $appd_agent::tierName,
  $controllerHost                = $appd_agent::controllerHost,
  $controllerPort                = $appd_agent::controllerPort,
  $controllerSSLEnabled          = $appd_agent::controllerSSLEnabled,
  $orchestrationEnabled          = $appd_agent::orchestrationEnabled,
  $accountName                   = $appd_agent::accountName,
  $accountAccesKey               = $appd_agent::accountAccesKey,
  $simEnabled                    = $appd_agent::simEnabled,
  $win_DriveLetter               = $appd_agent::win_DriveLetter,
  $win_BinaryDir                 = $appd_agent::win_BinaryDir,
  $win_AppAgentInstallDir        = $appd_agent::win_AppAgentInstallDir,
  $win_AppAgentBinaryFile        = $appd_agent::win_AppAgentBinaryFile,
  $win_MachineAgentInstallDir    = $appd_agent::win_MachineAgentInstallDir,
  $win_MachineAgentInstallBinary = $appd_agent::win_MachineAgentInstallBinary
) {

  # Validate Drive exist ?
  validate_absolute_path("${win_DriveLetter}:\\")

  # Binary Directory 
  $msiName                   = $win_AppAgentBinaryFile.split('-')[0]
  $msiVer                    = regsubst($win_AppAgentBinaryFile.split('-')[1], '^(.+)\.msi$', '\1')
  $binaryDir                 = "${win_DriveLetter}:\\${win_BinaryDir}"
  $msiFilePath               = "${binaryDir}\\${win_AppAgentBinaryFile}"
  $msiAgentInstallerLogFile  = "${binaryDir}\\AgentInstaller.log"
  $appAgentInstallDir        = "${binaryDir}\\${win_AppAgentInstallDir}"
  $appAgentDotNetAgentFolder = "${binaryDir}\\${win_AppAgentInstallDir}"
  $ad_config_file            = "${binaryDir}\\AD_Config.xml"
  $machineAgentInstallDir    = "${binaryDir}\\${win_MachineAgentInstallDir}"
  $machineAgentBinaryFile    = "${binaryDir}\\${win_MachineAgentInstallBinary}"

  # Create Directory
  $appdAgentDirs = unique([ $binaryDir, $appAgentInstallDir, $appAgentDotNetAgentFolder ])

  file { $appdAgentDirs :
    ensure => directory
  }

  #### Install App Agent 
  # AD_Config file 
  file { $ad_config_file:
    ensure  => 'file',
    content => epp("${module_name}/AD_Config_IIS.xml.epp",
      {
        'controller_host'        => $controllerHost,
        'account_name'           => $accountName,
        'account_access_key'     => $accountAccesKey,
        'controller_port'        => $controllerPort,
        'controller_ssl_enabled' => $controllerSSLEnabled,
      }
    ),
    require => File[$appdAgentDirs],
  }

  # Copy APP Agent MSI FILE
  file { $msiFilePath:
    source => "puppet:///modules/${module_name}/${win_AppAgentBinaryFile}",
  require  => File[$appdAgentDirs]
  }

  package { 'AppDynamics .NET Agent':
    ensure          => $msiVer,
    provider        => 'windows',
    source          => $msiFilePath,
    install_options => [
      '/lv', $msiAgentInstallerLogFile,
      { 'INSTALLDIR'        => $appAgentInstallDir        },
      { 'DOTNETAGENTFOLDER' => $appAgentDotNetAgentFolder },
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
  $win_machine_controller_info_file = "${machineAgentInstallDir}\\conf\\controller-info.xml"

  file { $machineAgentInstallDir:
    ensure => directory
  }

  # Copy Machine Agent Binary File 
  file { $machineAgentBinaryFile:
    ensure  => 'present',
    source  => "puppet:///modules/${module_name}/${win_MachineAgentInstallBinary}", # lint:ignore:puppet_url_without_modules
    backup  => false,
    require => File[$machineAgentInstallDir],
  }

  # Extract Machine Agent ZIP file 
  exec { "Unzip ${machineAgentBinaryFile}":
    command => "unzip ${machineAgentBinaryFile} -d ${machineAgentInstallDir}",
    creates => $win_machine_controller_info_file,
    require => File[$machineAgentBinaryFile],
    notify  => Exec['Install MachineAgent as a Service'],
  }

  # Cofnig Controller File 
  file { $win_machine_controller_info_file:
    ensure  => 'file',
    content => epp("${module_name}/windows-controller-info.xml.epp",
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
    require => Exec["Unzip ${machineAgentBinaryFile}"],
  }

  # Install MachineAgent as service
  exec { 'Install MachineAgent as a Service':
    command  => 'cscript InstallService.vbs',
    cwd      => $machineAgentInstallDir,
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
