###
# $ init.pp
# Description: Manage installtion of appdynamics app-agent and machine-agent on Linux and Windows OS 
# 
###
class appd_agent(
  String $appName               = 'test',
  String $tierName              = 'test',
  String $accountName           = 'test',
  String $controllerHost        = 'testvm',
  String $accountAccesKey       = 'test',
  Integer $controllerPort       = 8090,
  Boolean $controllerSSLEnabled = true,
  Boolean $orchestrationEnabled = true,
  Boolean $simEnabled           = true,
  # Linux                       
  String $appInstallBinary             = 'AppServerAgent-4.5.17.28908.zip',
  String $machineInstallBinary         = 'machineagent-bundle-64bit-linux-4.5.16.2357.zip',
  String $baseAppdDir                  = '/opt/appdynamics',
  String $appInstallDir                = "${baseAppdDir}/app-agent",
  String $appAgentOwner                = 'appd',
  String $appAgentGroup                = 'appd',
  String $machineInstallDir            = "${baseAppdDir}/machine-agent",
  String $machineAgentOwner            =  'root',
  String $machineAgentGroup            =  'root',
  # Windows 
  Optional[Pattern[/^[A-Z]$/]] $win_DriveLetter  = 'D',
  String $win_BinaryDir                          = 'AppDynamics',
  String $win_AppAgentInstallDir                 = 'DotNetAgent',
  String $win_AppAgentBinaryFile                 = 'dotNetAgentSetup64-4.5.18.1.msi',
  String $win_MachineAgentInstallDir             = 'machineagent',
  String $win_MachineAgentInstallBinary          = 'machineagent-bundle-64bit-windows-4.5.16.2357.zip'
) {

  $osKernel = $facts['kernel']

  case $osKernel {
                    'Linux': { include appd_agent::linux  }
                  'windows': { include appd_agent::windows  }
                    default: { fail("Un-Supported OS: ${osKernel}") }
  }

} ## END CLASS 
