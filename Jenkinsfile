pipeline {

    // agent 
    agent { label 'EC2_Node1' }
    
    // this is my file    
    environment {
        AWS_ACCESS_KEY_ID = credentials('jenkins_AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('jenkins_AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION='us-west-2'
    }
    
    // Run perodically daily at 9pm 
    // To specific branch     cron(env.BRANCH_NAME == 'development' ? 'H 21 * * *' : '')
    // triggers {
    //    cron('H 21 * * *')
    // }
      
    stages {
   
        // Clone Repo
        stage('Clone-Repo') {
            steps {
                checkout scm
            }
        }
   
        // Initial Setup 
        stage('Build-ready') {        
            steps {
                // Pre-Requisite set 
                sh ''' 
                    # Install PIP if not installed
                    if ! which pip || ! which zip || ! which unzip >/dev/null 2>&1; then
                        echo 'Install python-pip not present'
                        yum -y install epel-release && yum -y install --enablerepo="epel" python-pip zip unzip && yum clean all
                    fi
                    
                    # Install awscli if not present
                    if ! which aws; then
                        echo 'Install awscli not present'
                        pip install awscli --upgrade --user
                    fi
                    
                    # Pre-Requisite set 
                    echo 'Run requirements.txt'
                    cd PSPSProject; pip install -r requirements.txt || exit 1
                    
                    # Check Chromedriver installed 
                    echo 'Chromedriver installed?'
                    #pip freeze | grep -i chromedriver || pip install chromedriver
                '''
            }
            post {
                success {
                    echo 'Pre-Requisite stage success'
                }
                failure {
                    echo 'Pre-Requisite stage failed'
                }
            }
        }
        
        // Unit Test
        stage('Unit-test') {        
            steps {
                script {
                    retry(2) {
                        sh ''' 
                            # Unit testing 
                            echo 'Unit Test'
                            cd PSPSProject/src/Tests; py.test -v -s --html=./repots.html TEST_UnitTestResults.py || exit 1
                        '''
                    }
                }
            }
            post {
                success {
                    echo 'Unit Test success'
                    // Stage to upload to AWS S3 bucket 
                }
                failure {
                    echo 'Unit Test failed'
                }
            }
        }

        // Zip Artifact and upload to S3
        stage('Build-Upload-AF') {
            steps {
                sh '''
                    AF="/tmp/AF_$(date +%d%b%Y_%k:%m%p).zip"
                    zip -r ${AF} *
                    #aws s3api put-object --bucket psps-geomartcloud-dev --key artifacts/automation/$AF --body $AF
                '''
            }
        }

        // test-1
        stage('Build-test-1') {
            steps {
                script {
                    retry(2) {
                        // sh 'cd PSPSProject/src/Tests; ./py.test -v -s -n2'
                        sh 'cd PSPSProject/src/Tests; ./py.test -v -s --html=./reports.html -n1'
                    }
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
                    retry(2) {
                        // sh 'cd PSPSProject/src/Tests; ./py.test -v -s -n2'
                        sh 'cd PSPSProject/src/Tests; ./py.test -v -s --html=./reports.html -n2'
                    }
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
        
   }
}

// END 
