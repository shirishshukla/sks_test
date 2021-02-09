#!/usr/bin/env groovy
​
pipeline {

  environment {
		  ro_credentials_id = "9381ae1a-02d4-4378-9435-7c2caf9e4cd5"
		  source_repo = "https://github.com/Univar/ecommerce-magento-ci.git"
		  magento_snapshot_repo_url = "git@github.com:Univar/ecommerce-magento-snapshot.git"
	      //Slack definitions
		  MessageColor = '#FF0000'
		  ChannelId = "#jenkins"
	}
​
	agent {
		label 'master'
	}
​
	stages {

		stage('Cleanup') {

			agent {
				label 'master'
			}

			steps {
				deleteDir()
        script {
          currentBuild.displayName = "${env.BUILD_NUMBER}-${SITE}-${env.ENVIRONMENT}"
        }
			}

		}
​
		stage('Checkout') {
			agent {
        label 'master'
			}
​
			steps {
				checkout([
					$class: 'GitSCM',
					branches: [[name: "${env.BUILD_FROM}"]],
					userRemoteConfigs: [[credentialsId: "${env.ro_credentials_id}", name: 'source', url: "${env.source_repo}"]]
				])
			}
		}
​
		stage('Create DB Backup - DEVELOPMENT') {
	    when {
			    expression { "${env.ENVIRONMENT}" == 'development' }
			}

      environment {
				ANSIBLE_CONFIG = "${env.WORKSPACE}/ansible/ansible.cfg"
			}
​
			agent {
				label 'master'
			}
​
			steps {
				script {
					if ( "${env.ENVIRONMENT}" == 'development' ) {
						ansible_extra_vars = "--extra-vars=@ansible/group_vars/${params.SITE}-development.yml"
					}
					else {
						error "ansible_extra_vars is not defined"
					}
​
				}
​
                ansiColor('xterm') {
                    ansiblePlaybook(
                        installation: "/bin/ansible",
                        playbook: "ansible/plays/create_db_backup.yml",
                        extras: "${ansible_extra_vars}",
                        colorized: true
                    )
				}
			}
		}
​
		stage('Create DB Backup - QA') {
	    	when {
			    expression { "${env.ENVIRONMENT}" == 'qa' }
			}
			environment {
				ANSIBLE_CONFIG = "${env.WORKSPACE}/ansible/ansible.cfg"
​
			}
​
			agent {
				label 'master'
			}
​
			steps {
				script {
					if ( "${env.ENVIRONMENT}" == 'qa' ) {
						ansible_extra_vars = "--extra-vars=@ansible/group_vars/${params.SITE}-qa.yml"
					}
					else {
						error "ansible_extra_vars is not defined"
					}
​
				}
​
                ansiColor('xterm') {
                    ansiblePlaybook(
                        installation: "/bin/ansible",
                        playbook: "ansible/plays/create_db_backup.yml",
                        extras: "${ansible_extra_vars}",
                        colorized: true
                    )
				}
			}
		}
​
		stage('Create DB Backup - PRODUCTION') {
	    	when {
			    expression { "${env.ENVIRONMENT}" == 'production' }
			}
			environment {
				ANSIBLE_CONFIG = "${env.WORKSPACE}/ansible/ansible.cfg"
​
			}
​
			agent {
				label 'master'
			}
​
			steps {
				script {
					if ( "${env.ENVIRONMENT}" == 'production' ) {
						ansible_extra_vars = "--extra-vars=@ansible/group_vars/${params.SITE}-production.yml"
					}
					else {
						error "ansible_extra_vars is not defined"
					}
​
				}
​
                ansiColor('xterm') {
                    ansiblePlaybook(
                        installation: "/bin/ansible",
                        playbook: "ansible/plays/create_db_backup.yml",
                        extras: "${ansible_extra_vars}",
                        colorized: true
                    )
				}
​
			}
		}
​
	}
}
