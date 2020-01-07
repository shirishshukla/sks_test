###
# $ init.pp
# Description: Manage installtion of appdynamics app-agent and machine-agent on Linux and Windows OS 
# 
###
class appd_agent(
  String $app_name                 = 'test',
  String $tier_name                = 'test',
  String $account_name             = 'test',
  String $controller_host          = 'testvm',
  String $account_acces_key        = 'test',
  Integer $controller_port         = 8090,
  Boolean $controller_ssl_enabled  = true,
  Boolean $orchestration_enabledd  = true,
  Boolean $sim_enabled             = true,
  # Linux                       
  String $app_agent_binary           = 'AppServerAgent-4.5.17.28908.zip',
  String $machine_agent_binary       = 'machineagent-bundle-64bit-linux-4.5.16.2357.zip',
  String $base_appd_dir              = '/opt/appdynamics',
  String $app_agent_install_dir      = "${base_appd_dir}/app-agent",
  String $app_agent_owner            = 'appd',
  String $app_agent_group            = 'appd',
  String $machine_agent_install_dir  = "${base_appd_dir}/machine-agent",
  String $machine_agent_owner        =  'root',
  String $machine_agent_group        =  'root',
  # Windows 
  Optional[Pattern[/^[A-Z]$/]] $win_drive_letter  = 'D',
  String $win_binary_dir                          = 'AppDynamics',
  String $win_machine_agent_install_binary        = 'machineagent-bundle-64bit-windows-4.5.16.2357.zip',
  String $win_app_agent_binary_file               = 'dotNetAgentSetup64-4.5.18.1.msi',
  String $win_app_agent_install_dir               = 'DotNetAgent',
  String $win_machine_agent_install_dir           = 'machineagent'
) {

  $os_kernel = $facts['kernel']

  case $os_kernel {
                    'Linux': { include appd_agent::linux  }
                  'windows': { include appd_agent::windows  }
                    default: { fail("Un-Supported OS: ${os_kernel}") }
  }

} ## END CLASS 
