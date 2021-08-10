#!/usr/bin/groovy

def agentName="SPRx2.0_DEPLOY-ONLY"

//Get email DL
def getEMail_DL(def emailTo, def emailDLPropsFile){
    emailDLProperties=readProperties file: emailDLPropsFile
    emailDL=emailDLProperties.get(emailTo)
    emailDL
}

// Run shell command in non-debug mode
def runShellCmd(cmd) {
    steps.sh (script: '#!/bin/sh -e\n'+ cmd,returnStdout: true)
  }

// Get number of lines in onlyschedulersFile,commonServicesFile,excludeServicesFile
int getLineCountInfile(def filePath) {
    fileExist=sh(script:"stat -c%F $filePath || true >/dev/null 2>&1", returnStdout: true)
    if(fileExist){
      def servicesFile=readProperties file: filePath
      def fileLines=servicesFile.size()
      count=fileLines
    } else {
      count=0
    }
    return count
}

// Deployment of each service
def deployFromProps(agent, def servicesfile, deployType){
    def index=0
    boolean buildStatus=true
    def applDeployJobsArray=[:]
    def Map modules=[:]
    deployType  = deployType.trim()

    // read service prop file
    services = readProperties file: servicesfile

    println("Deploy Type: "+ deployType + "\nServices: \n" + services + '\nNumber of services: '+ services.size() )

    services.each { artifactID,version ->

        modules.runjob=load "runJob.groovy"
        if (buildStatus && deployType == 'SERIAL') {
            buildStatus=modules.runjob.runBuild(agent, artifactID, version, buildStatus, deployType, JOB_PATH)
        }

        if(deployType == 'PARALLEL') {
            applDeployJobsArray["${index}"]= {
                buildStatus=modules.runjob.runBuild(agent, artifactID, version, buildStatus, deployType, JOB_PATH)
            }
        }
        index++

    } // End Loop

    if (deployType == 'PARALLEL') {
        parallel applDeployJobsArray
    }

    return buildStatus
}

// Pipeline
pipeline{

    agent{
        label agentName
    }

    environment{
        REPORT_CSV_FILE="${env.WORKSPACE}/report.csv"
        HTML_REPORT_FILE="${env.WORKSPACE}/report.html"
        time_wait="${env.SLEEP_TIME_BTWN_COMMON_AND_REGULAR_SERVICES}" // wait for seconds between common and regular
        credentialId= '3e38e78b-df56-4861-95f1-f084e03f93f5'
        FAILED_REPORT_FILE="${env.WORKSPACE}/FAILED_REPORT.properties"
        EMAIL_REPORT_HEADER="${ENVIRONMENT} : BULK DEPLOYMENTS COMMUNICATION"
        NOTIFY_SUBJECT="BULK Deployments"
        EMAIL_TO="${EMAILTO}"
        emailDLPropertiesFile="E-MAIL_DL_SUCCESS.properties"
        servicesCount=0
        ReportSize=0
        boolean NOTIFIED=false
        boolean DEPLOY_RESULT_STATUS=true
        boolean EMAIL_NOTIFICATION=true
    }

    stages{

        // Clean  WORKSPACE
        stage("Clean WS") {
            steps{
                step([$class: 'WsCleanup'])
            }
        }

        // Checkout GIT REPO
        stage("Checkout") {
            steps{
                checkout scm
            }
        }

        stage("Initialization"){
            steps{
                script{
                    SUCCESS_EMAIL_LIST=getEMail_DL(EMAIL_TO, emailDLPropertiesFile)
                }
            }
        }

        // Validate all properties file
        stage("Validate PropFile and running schedulers") {
            steps {
              script {
                  def confFile='env-jobs.properties'
                  confPropFile=readProperties file: confFile

                  serviceDeployModeFile='services-deployment_mode.config'
                  env.JOB_PATH=confPropFile."${ENVIRONMENT}_JOBS"               // child job path
                  env.PROP_GIT_REPO=confPropFile.'DEFAULT_SERVICE_GIT_REPO'     // repo url
                  env.PROP_GIT_BRANCH="${ENVIRONMENT}"                          // branch to co
                  env.PROP_GIT_CO_DIR="${WORKSPACE}/services_prop_git_repo/"    // dir whr to co repo
                  // prop files
                  env.ONLY_SCHEDULERS_PROPSFILE=PROP_GIT_CO_DIR+'ONLY_SCHEDULERS_appldeploy.properties' // parallel
                  env.COMMON_SERVICES_PROPSFILE=PROP_GIT_CO_DIR+'COMMON-SERVICES_appldeploy.properties' // serial
                  env.EXCLUDE_SCHEDULERS_FILE_PREFIX=PROP_GIT_CO_DIR+'EXCLUDE_SCHEDULERS_REG_SET'  // '01_appldeploy.properties' parallel

                  // Checkout repo for properties files
                  checkout([
                        $class: 'GitSCM',
                        branches: [[name: "${env.PROP_GIT_BRANCH}"]],
                        extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: "${env.PROP_GIT_CO_DIR}"]],
                        userRemoteConfigs: [[credentialsId: "${env.credentialId}", url: "${env.PROP_GIT_REPO}" ]]
                  ])

                  env.EXCLUDE_SCHEDULERS_PROPFILES=sh(script: "ls  ${EXCLUDE_SCHEDULERS_FILE_PREFIX}* |sort -n",returnStdout: true).trim()

                  println("Job Path: " + JOB_PATH)
                  println("Environment: " + ENVIRONMENT)
                  println("PROP GIT REPO: " + PROP_GIT_REPO)
                  println("PROP GIT BRANCH: " + PROP_GIT_BRANCH)
                  println("ONLY SCHEDULERS PROPS FILE: " + ONLY_SCHEDULERS_PROPSFILE)
                  println("COMMON SERVICES PROPS FILE: " + COMMON_SERVICES_PROPSFILE)
                  println("EXCLUDE SCHEDULERS PROP FILES: " + EXCLUDE_SCHEDULERS_PROPFILES)

                  // Validate prop files should exist and not empty ??

                  // ***** Service Count in each files ***** //
                  deployMode = readProperties file: serviceDeployModeFile

                  // service count in ONLY_SCHEDULERS_PROPSFILE
                  onlySchedulerServiceListCount=getLineCountInfile(ONLY_SCHEDULERS_PROPSFILE)
                  onlySchedulerServiceMode=deployMode.get('ONLY_SCHEDULERS_appldeploy')
                  if(!onlySchedulerServiceMode){
                      onlySchedulerServiceMode='PARALLEL'
                  }
                  if (onlySchedulerServiceListCount > 0 ) {
                      println("Only Scheduler Service List Count: " + onlySchedulerServiceListCount )
                  } else {
                      println("!! No Schedulers for Deployment: Schedulers file is empty !!")
                  }

                  // service count in COMMON_SERVICES_PROPSFILE
                  commonServiceListCount=getLineCountInfile(COMMON_SERVICES_PROPSFILE)
                  commonServiceMode=deployMode.get('COMMON-SERVICES_appldeploy')
                  if(!commonServiceMode){
                      commonServiceMode='SERIAL'
                  }
                  if (commonServiceListCount > 0 ) {
                      println("Common Service List Count: " + commonServiceListCount )
                  } else {
                      println("!! No Common Service for Deployment: Common Service file is empty !!")
                  }

                  // service count in EXCLUDE_SCHEDULERS_PROPFILES files ..
                  excludeSchdSvcCount = 0
                  excludeSchdSvcMode=deployMode.get('EXCLUDE_SCHEDULERS_FILE_PREFIX')
                  if(!excludeSchdSvcMode){
                      excludeSchdSvcMode='PARALLEL'
                  }
                  if (EXCLUDE_SCHEDULERS_PROPFILES.split().length > 0 ){
                      EXCLUDE_SCHEDULERS_PROPFILES.split().each { EXCLSCHDFILE ->
                          def excludeSchdServiceListCount=getLineCountInfile(EXCLSCHDFILE)
                          if (excludeSchdServiceListCount > 0 ) {
                              excludeSchdSvcCount=excludeSchdServiceListCount
                              println("$EXCLSCHDFILE Count: " + excludeSchdServiceListCount )
                          } else {
                              println("!! $EXCLSCHDFILE is empty !!")
                          }
                      }
                  }
              }
            }
          }

          // Preperation, adding header to the CSV file
          stage("Report Prepration") {
              when {
                  expression { onlySchedulerServiceListCount > 0 || commonServiceListCount > 0 || excludeSchdSvcCount > 0 }
              }
              steps{
                  script {
                      def ReportHeader='ServiceName, Version, JenkinsBuildConsoleOutputURL, BuildResult'
                      runShellCmd("echo $ReportHeader > $REPORT_CSV_FILE")
                  }
              }
          }

          //  only scheduler
          stage("Run: ONLY SCHEDULERS SERVICES") {
              when {
                  expression { onlySchedulerServiceListCount > 0 }
              }
              steps {
                  script {
                      dir(env.WORKSPACE) {
                              def deployType="$onlySchedulerServiceMode"
                              //def onlySchedulerServiceFile=readFile file: ONLY_SCHEDULERS_PROPSFILE
                              //onlySchedulerServiceList=onlySchedulerServiceFile.readLines()
                              def deployResult=deployFromProps(agentName, ONLY_SCHEDULERS_PROPSFILE, deployType)
                              if (!deployResult) {
                                  DEPLOY_RESULT_STATUS=false
                                  println('Some only scheduler parallel job Failed !!')
                              } else{
                                  println('All Only Scheduler-Parallel Jobs are Successful !!')
                                  sleep time_wait.toInteger()
                              }
                      }
                  }
              }
          }

          // Serial .. common Services ..
          stage("Run: COMMON SERVICES") {
              when {
                  expression { commonServiceListCount > 0 && DEPLOY_RESULT_STATUS }
              }
              steps {
                  script {
                      dir(env.WORKSPACE) {
                          def deployType   = "$commonServiceMode"
                          //def commonServiceFile=readFile file: COMMON_SERVICES_PROPSFILE
                          //def commonServiceList=commonServiceFile.readLines()
                          //commonServiceList.each { common_serial_service ->
                          //    common_serial_serviceList = common_serial_service.split()
                              def deployResult=deployFromProps( agentName, COMMON_SERVICES_PROPSFILE, deployType)
                              if (!deployResult) {
                                  DEPLOY_RESULT_STATUS=false
                                  println("Common Serial service $common_serial_service Failed!!")
                              }
                          //}
                      }
                  }
              }
          }

          //  ... Exclude Scheduler services ...
          stage("Run: EXCLUDE SCHEDULERS SERVICES") {
              when {
                  expression { excludeSchdSvcCount > 0 && DEPLOY_RESULT_STATUS }
              }
              steps {
                  script {
                      dir(env.WORKSPACE) {
                          def deployType="$excludeSchdSvcMode"
                          EXCLUDE_SCHEDULERS_PROPFILES.split().each { EXCLSCHDFILE ->
                              def excludeSchdServiceList=readProperties file: EXCLSCHDFILE
                              def excludeSchdServiceListCount=excludeSchdServiceList.size()
                              if (excludeSchdServiceListCount > 0 ) {
                                  println("Run Exclude Scheduler Service in File $EXCLSCHDFILE Count: " + excludeSchdServiceListCount )
                                  //def excludeSchedulerServiceFile = readFile file: EXCLSCHDFILE
                                  //def excludeSchedulerServiceList=excludeSchedulerServiceFile.readLines()
                                  def deployResult=deployFromProps(agentName, EXCLSCHDFILE, deployType)
                                  if (!deployResult) {
                                      DEPLOY_RESULT_STATUS = false
                                      println('Few regular services File $EXCLSCHDFILE parallel job Failed !!')
                                  } else{
                                      println('All regular services Parallel Jobs are Successful !!')
                                  }
                               }
                            }
                         }
                  }
              }
        }

        // Generate HTML Report File
        stage("Generate HTML Report File") {
            when {
                expression { onlySchedulerServiceListCount > 0 || commonServiceListCount > 0 || excludeSchdSvcCount > 0 }
            }
            steps{
                dir(env.WORKSPACE) {
                    script {
                        // Validate csv file
                        def reportSize=readFile file: REPORT_CSV_FILE
                        ReportSize=reportSize.readLines().size()
                        if (ReportSize > 0) {
                            runShellCmd("cat ${REPORT_CSV_FILE}")
                        } else {
                            println('Result is null no SERVICES')
                        }

                        // Generate html report file
                        def CMD = '''
                           sh generate_html_report.sh ${REPORT_CSV_FILE} ${HTML_REPORT_FILE}
                        '''
                        runShellCmd(CMD)
                      }
                }
            }
        }

        // Sent email Notification
        stage("Notification") {
            steps {
                script {
                      REPORT_HEADER_HTML="""
                        <html>
                          <style>
                          pre, ul, li, body {
                                        font-family: 'Calibri';
                                        font-size: 12px;
                                }
                          .par {
                                  font-family: 'Calibri';
                                  font-size: 12px;
                              }
                          .title {
                                        font-family: 'Rockwell Extra Bold';
                                        font-size: 20px;
                                        color:red;
                                        background-color: gold;
                                        text-align: center;
                                  }
                          .foot {
                                        font-family: 'Calibri';
                                        font-size: 15px;
                                        color:black;
                                        background-color: #ffad99;
                                        text-align: center;
                                 }
                          .foot1 {
                                        font-family: 'Calibri';
                                        font-size: 18px;
                                        color:black;
                                        background-color: lightblue;
                                        text-align: center;
                                 }
                      <!--  Table 1: Style  Start here -->
                          table {
                                        width: 100%;
                                        text-align: center;
                                        border-collapse: collapse;
                                 }
                              th {
                                        padding: 10px 5px;
                                        font-family: 'Calibri';
                                        border: 1px solid #fff23df;
                                 }
                              td {
                                        padding: 5px 10px;
                                        border-collapse: collapse;
                                        text-align: center;
                                        font-family: 'Calibri';
                                        font-size: 14px;
                                 }
                       tbody, td {
                                        background: #D0E4F5;
                                 }
                       thead, th {
                                        font-size: 16px;
                                        font-weight: bold;
                                        color: #AED6F1;
                                        background: #1C6EA4;
                                        background: -moz-linear-gradient(top, #5592bb 0%, #327cad 66%, #1C6EA4 100%);
                                        background: -webkit-linear-gradient(top, #5592bb 0%, #327cad 66%, #1C6EA4 100%);
                                        background: linear-gradient(to bottom, #5592bb 0%, #327cad 66%, #1C6EA4 100%);
                                 }
                         </style>
                         <body>
                     """

                      REPORT_FOOTER="""
                           </ul>
                           <br></br>
                           <p class='foot1'>[ This is an auto generated email, please do not reply. If you have any queries, please email to <a href='mailto:specialty_platform_engg@CVSHealth.com?subject=${NOTIFY_SUBJECT}'>Platform Engg</a> ]</p>
                           </body>
                           </html>
                      """

                      // Report have data
                      if(onlySchedulerServiceListCount > 0 || commonServiceListCount > 0 || excludeSchdSvcCount > 0 ) {
                          REPORT_HEADER='<h2 style="text-align:center"><font style="background-color:lightblue;color:black">' + "${EMAIL_REPORT_HEADER}" + '</font></h2>'
                          REPORT_BODY=sh(script: "cat ${HTML_REPORT_FILE}", returnStdout: true).trim()
                      }

                      // Report is Blank i.e no SERVICES
                      else {
                        REPORT_HEADER="<h2 align='center'>SERIAL DEPLOYMENTS COMMUNICATION</h2>"
                        REPORT_BODY="""
                                  <h1 style="background-color:#FFC300 ;">!! No deployments planned in this window !!</h1>
                        """
                      }

                      EMAIL_CONTENT=REPORT_HEADER_HTML + "<body><center>" +
                                      REPORT_HEADER +
                                      """
                                        <br></br>
                                        <ul style="color:#3B240B">
                                      """ +
                                      REPORT_BODY + "</center><br>" +
                                      REPORT_FOOTER

                } // end scripts
          } // end steps
      } // end stage
    } // end stages

    post{
        success {
            script {
                   //return final status
                   if(!DEPLOY_RESULT_STATUS ) {
                        if(EMAIL_NOTIFICATION ) {
                            NOTIFY_SUBJECT='Failed : ' + "${ENVIRONMENT} -" + NOTIFY_SUBJECT
                            emailext(
                              attachmentsPattern: FAILED_REPORT_FILE,
                              mimeType: 'text/html',
                              body: EMAIL_CONTENT,
                              subject: NOTIFY_SUBJECT,
                              to: SUCCESS_EMAIL_LIST
                            )
                            NOTIFIED=true
                        }
                        currentBuild.result='FAILED'
                   } else {
                        if(EMAIL_NOTIFICATION ) {
                            emailext mimeType: 'text/html',
                            body: EMAIL_CONTENT,
                            subject: 'Success: ' + "${ENVIRONMENT} -" + NOTIFY_SUBJECT,
                            to: SUCCESS_EMAIL_LIST
                            NOTIFIED=true
                       }
                   }
            }
        }

        failure {
            script {
                      println("!!!!!!!!!!!!!!!!!!!!!  FAILED  FAILED  FAILED  FAILED  FAILED  FAILED !!!!!!!!!!!!!!!!!!!!!")
                        if(NOTIFIED  && EMAIL_NOTIFICATION && DEPLOY_RESULT_STATUS) {
                          NOTIFY_SUBJECT=NOTIFY_SUBJECT + ": --- FAILED ---"
                          emailext mimeType: 'text/html',
                          body: 'DEPLOYMENT FAILED !!',
                          subject: NOTIFY_SUBJECT,
                          to: SUCCESS_EMAIL_LIST
                         }
            }
        }

        always {
                println('Archiveingall *.properties file')
                archiveArtifacts artifacts: '*.properties'
        }
     }
}

// END


