pipeline {

    //agent {
    //    docker {
    //        image 'centos:latest'
    //        args '-u root:root'
    //    }
    //}
      
    agent { label 'EC2_Node1' }
	
    environment {
        AWS_ACCESS_KEY_ID = credentials('jenkins_AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('jenkins_AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION='us-west-2'
    }
	
	// Run perodically daily at 9pm 
	// To specific branch     cron(env.BRANCH_NAME == 'development' ? 'H 21 * * *' : '')
	triggers {
        cron('H 21 * * *')
    }
    
    stages {
   
        // Clone Repo
        stage('Clone-Repo') {
            steps {
                checkout scm
            }
        }
   
        // Initial
        stage('Build-ready') {        
            steps {
                // Pre-Requisite set 
                sh '''                
                    echo 'Operating System: /etc/os-release'
                    hostname; uname -a; ls -l
                    cat /etc/os-release
                    
                    # Install PIP if not installed
                    if ! which pip >/dev/null 2>&1; then 
                        echo 'Install python-pip not present'
                        if [ "$(. /etc/os-release; echo $NAME)" = "Ubuntu" ]; then
                            apt-get update && apt-get install -y php5-mcrypt python-pip
                        else
                            yum -y install epel-release && yum -y install --enablerepo="epel" python-pip zip unzip && yum clean all
                        fi
                    fi
					
                    echo 'Run requirements.txt'
                    sh requirements.txt || exit 1
                    
                    echo 'Run chromedriver.exe'
                    ./chromedriver.exe || exit 1
                    
                    echo 'Compile all'
                    #python -m compileall || exit 1
                '''
            }
        }
        
        // test-1
        stage('Build-test-1') {
            steps {
                script {
                    // try {
                        retry(2) {
                            // sh 'python --version'
                            sh 'cd scripts; ./py.test -v -s -n1'
                            sh 'cd scripts; ./py.test -v -s -html=./reports.html -n1'
                        }
                    //} catch(error) {
                    //    echo "First build failed, let's retry if accepted"
                    //}
                }
            }
            post {
                success {
                    echo 'test-1-successfull'
                }
                failure {
                    echo 'test-1-failed'
                }
            }
        }

        // test-2
        stage('Build-test-2') {
            steps {
                script {
                    // try {
                        retry(2) {
                            // sh 'python --version'
                            // try {
							  sh 'cd scripts; ./py.test2 -v -s -n2'
                              sh 'cd scripts; ./py.test2 -v -s -html=./reports.html -n2'
							//} catch(error) {
							//  sh 'cp -rp scripts scripts1'
							//}
                        }
                    //} catch(error) {
                    //    echo "First build failed, let's retry if accepted"
                    //}
                }
            }
            post {
                success {
                    echo 'test-2-successfull'
                }
                failure {
                    echo 'test-2-failed'
                }
            }
        }
        
        // Zip Artifact and upload to S3
        stage('Build-AF-Upload') {
            steps {
                sh '''
                    env | grep -i aws
                    FLD="/tmp/AF_$(date +%m%b%Y%T)"
                    mkdir $FLD
                    zip -r  $FLD/AF.zip *
                    ls -lrth $FLD/AF.zip && unzip -l $FLD/AF.zip
                    #aws s3api put-object --bucket ${params.S3_BUCKET_NAME} --key $FLD/AF.zip
                '''
            }
        }

    }
}

// END 
