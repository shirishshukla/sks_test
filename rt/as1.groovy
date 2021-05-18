////
//
////

// function to run powershell script
def runPowershellScript(def AGENT, def CMD) {
  node(AGENT) {
    echo "Running Powershell script on Agent: $AGENT !!"
    def stdout = powershell(returnStdout: true, script: CMD )
	  echo "Run complete!!"
    return stdout
  }
}

// main pipeliness
pipeline {

  // default node agent label
  agent {
      label 'master'
    }

  // environment
  environment {
    NODE = 'master'
    scriptDisableF5PoolMembers        = 'script_disable_f5_pool_member.ps1'
    scriptEnableDisableSitescopeAlert = 'script_enable_disable_sitescope.ps1'
    scriptPauseTPService              = 'script_pause_tp_service.ps1'
    scriptMonitorTPCount              = 'script_monitor_tp_count.ps1'
	  scriptExtractWebNode              = 'script_extract_web_nodes.ps1'
	  WINDOWSCRED                       = credentials('ServerAdmin')
  }

  // parameters
  parameters {
    // serversName comma seperated) & ChangeTask & Recycle(IISReset)/Reboot(Server Restart)
    string(name: 'serversName',  defaultValue: '', description: 'Enter comma seperated list of servers')
    string(name: 'changeTask',   defaultValue: '', description: 'Enter Change Task ID')
    choice(name: 'Action',       choices: ['Recycle(IIS Reset)', 'Reboot(Server Restart)'], description: 'Select Desired Action')
    //string(name: 'AdminUser',    defaultValue: 'correctme', description: 'Enter widnows login user name')
    //password(name: 'AdminPass',  description: 'Enter widnows login user password')
  }

  // stages main
  stages {

        // validate serverlist -> disable server is F5 pool -> disable sitescope alerts -> pause TP service
        stage('Prepare Environment') {
          steps {
            script {
                // get cred
                env.AdminUser  = WINDOWSCRED_USR
                env.AdminPass  = WINDOWSCRED_PSW

                // List of TP Servers
                env.serversList = serversName.split(',')
                env.serversListFailed = []
                env.serverListFinal = []
                echo "Servers List: $serversList"
            }
          }
        }

        // Ensure all provided server list is TP Server
        stage('1.1 - Validate Server List of TP servers only.') {
          steps {
		        script {
              echo "Validate server list.."
			        def loadScript = readFile file: scriptExtractWebNode
              serversList.each { SERVER ->
			            echo "-- $SERVER ---"
                  env.serverName = $SERVER
				          // find respective web_node
					        def OP = runPowershellScript(NODE, loadScript)
					        if(OP) {
					            serverListFinal.add(OP)
					        } else {
					            error("ERROR: to extract respective WEB server for $TP Server: $SERVER")
					        }
              }
			      }
          }
        } // end  1.1

        // Disable F5 member
        stage('1.2 - disable server is F5 pool.') {
          steps {
		        script {
		          NODE = 'master'
			        env.BigIPToggledState='disabled'
              echo "disable server is F5 pool."
              def loadScript = readFile file:  scriptDisableF5PoolMembers
              serverListFinal.each { SERVER ->
                env.serverNameTP = SERVER.tokanize(':')[0].trim()
                env.serverNameWEB = SERVER.tokanize(':')[-1].trim()
                echo "Disable server $serverNameTP & $serverNameWEB in F5 pool member"
                def OP = runPowershellScript(NODE, loadScript)
                if(OP == 'Failed'){
                  echo "FAILED: to disable from F5 member list, server: $SERVER"
                  serverListFinal.remove(SERVER)
                  serversListFailed.add(serverNameTP + ': Failed to disable from F5 pool')
                }
              }
			      }
          }
        }

        // Disable sitescope alert
        stage('1.3 - disable sitescope alerts.') {
          steps {
		        script {
		          NODE = 'master'
              echo "disable sitescope alerts"
              def loadScript = readFile file:  scriptEnableDisableSitescopeAlert
              serverListFinal.each { SERVER ->
                env.serverNameTP = SERVER.tokanize(':')[0].trim()
                env.serverNameWEB = SERVER.tokanize(':')[-1].trim()
                echo "Disable server $serverNameTP & $serverNameWEB sitescope alerts"
				        env.Action = 'DISABLE'
                def OP = runPowershellScript(NODE, loadScript)
                if(OP == 'Failed'){
                  echo "FAILED: to disable sitescope alert  for either  servers $serverNameTP or  $serverNameWEB"
                  serverListFinal.remove(SERVER)
                  serversListFailed.add(serverNameTP + ': Failed to disable sitescope alert ..')
                }
		          }
            }
          }
        }

        // pause TP service
        stage('1.4 - pause TP service.') {
          steps {
		        script {
              echo "pause TP service"
              def loadScript = readFile file:  scriptPauseTPService
              serverListFinal.each { SERVER ->
                env.serverNameTP = SERVER.tokanize(':')[0].trim()
                echo "Pause TP service on $serverNameTP"
                def OP = runPowershellScript(NODE, loadScript)
                if(OP == 'Failed'){
                  echo "FAILED: to pause TP service, server: $serverNameTP"
                  serverlist.remove(SERVER)
                  serversListFailed.add(serverNameTP + ': Failed to pause TP service')
                }
              }
			      }
          }
        }

        // Monior TP Count ...
        stage("2. Validate TP Count") {
          steps {
		        script {
	            env.anyFailure = 'false'
              def loadScript = readFile file:  scriptMonitorTPCount
              serverListFinal.each { SERVER ->
                env.serverNameTP = SERVER.tokanize(':')[0].trim()
                echo "Monitor TP Count on $serverNameTP"
                def OP = runPowershellScript(NODE, loadScript)
                if(OP == 'Failed'){
			            env.anyFailure = 'true'
			            echo "FAILED: To Reduce TP count in desired wait time, server: $serverNameTP"
			            serverListFinal.remove(SERVER)
                  serversListFailed.add(serverNameTP + ': FAILED To Reduce TP count in desired wait time')
                }
              }
		          if(anyFailure == 'true'){
		             error('stop ..')
		          }
		        }
          }
        }

        //  Then preparing files with forced offline  and hard coding the VLB policies
        stage('3.1 - Force offline pool member') {
          steps {
		        script {
               echo "Validate server list.."
			      }
          }
        }

        // Ensure all provided server list is TP Server
        stage('3.2 - disable or Upgrade Policy') {
          steps {
		        script {
                echo "disable or Upgrade Policy.."
			      }
          }
        }

  } // end stages
  post {
    always{
      script {
        if(serversListFailed.lenght() > 0){
          println("Failed list")
          serversListFailed.each { failSRV ->
		      echo "=> $failSRV"
		  }
        } else {
          println('Success..!!')
        }
      }
    }
  }

}

// END
