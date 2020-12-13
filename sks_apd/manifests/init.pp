###
# $ init.pp
# Description: Manage installtion of appdynamics app-agent and machine-agent on Linux and Windows OS 
# 
###
class ahead_appd(
  # Controller Configs 
  String $app_name                         = 'test',
  String $tier_name                        = 'test',
  String $account_name                     = 'test',
  String $controller_host                  = 'testvm',
  String $account_acces_key                = 'test',
  Integer $controller_port                 = 8090,
  Boolean $controller_ssl_enabled          = true,
  Boolean $orchestration_enabledd          = true,
  Boolean $sim_enabled                     = true,
  # Puppet fileserver
  String $fileserver                       = 'fileserver/appd',
  # Linux                                  
  String $base_appd_dir                    = '/opt/appdynamics',
  String $app_agent_install_dir            = "${base_appd_dir}/appagent",
  String $app_agent_owner                  = 'appd',
  String $app_agent_group                  = 'appd',
  String $machine_agent_install_dir        = "${base_appd_dir}/machineagent",
  String $machine_agent_owner              =  'root',
  String $machine_agent_group              =  'root',
  String $app_agent_binary                 = 'AppServerAgent-4.5.17.28908.zip',
  String $machine_agent_binary             = 'machineagent-bundle-64bit-linux-4.5.16.2357.zip',
  # Windows 
  Optional[Pattern[/^[A-Z]$/]] $win_drive_letter     = 'D',
  String $win_binary_dir                             = 'AppDynamics',
  String $win_db_agent_install_dir                   = 'dbagent',
  Optional $win_db_agent_install_jvm_options         = '',
  String $win_app_agent_install_dir                  = 'appagent',
  String $win_machine_agent_install_dir              = 'machineagent',
  String $win_db_agent_binary_file                   = 'db-agent-64bit-windows-4.5.16.1568.zip',
  String $win_java_agent_binary_file                 = 'AppServerAgent-4.5.17.28908.zip',
  String $win_dot_net_agent_binary_file              = 'dotNetAgentSetup64-4.5.18.1.msi',
  String $win_machine_agent_binary_file              = 'machineagent-bundle-64bit-windows-4.5.16.2357.zip',
  Boolean $win_iisappenabled                         = true,
) {

  $os_kernel = $facts['kernel']

  case $os_kernel {
                    'Linux': { include ahead_appd::linux  }
                  'windows': { include ahead_appd::windows  }
                    default: { fail("Un-Supported OS: ${os_kernel}") }
  }

} ## END CLASS 
