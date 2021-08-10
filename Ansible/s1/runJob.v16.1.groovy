  // Run shell command in non-debug mode
def runShellCmd(cmd) {
    steps.sh (script: '#!/bin/sh -e\n'+ cmd,returnStdout: true)
}

// Run job
def runBuild(agent, artifactID, version, buildStatus, deployType, DEPLOYMENT_JOB) {
    def artifactVersion=artifactID+"_"+version
    DEPLOYMENT_JOB=JOB_PATH + '/' + artifactID
    //def DEPLOYMENT_JOB=JOB_PATH

    dir(env.WORKSPACE + "/" + artifactVersion) {
        def buildRun=""
        def result=""

        node(agent){
            buildRun=build job: "${DEPLOYMENT_JOB}", parameters: [
                string(name: 'ARTIFACT_ID',value: artifactID),
                string(name: 'ARTIFACT_VERSION',value: artifactVersion),
                string(name: 'VERSION',value: version),
                string(name: 'ENABLE_STAGGERED',value: ENABLE_STAGGERED)
            ], propagate: false
        }

        def buildResult=buildRun.getResult()

        println('Job: ' + artifactID + ' - ' + buildRun.result)

        result= artifactID + ', ' + version + ', ' + buildRun.absoluteUrl + 'console' + ', ' + buildRun.result

        // Failed Entries
        if (!buildStatus){
            runShellCmd("echo $SERVICE >> $FAILED_REPORT_FILE")
        }

        // Writing Result to report csv file
        def CMD="""
            result='''+result+'''
            echo -e "${result}" | tee -a $REPORT_CSV_FILE
        """
        runShellCmd(CMD)

    }
    return buildStatus
}
return this

// end

