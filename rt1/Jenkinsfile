// ------------------------------------------------ //
// Description: 
// 
// ------------------------------------------------ //

pipeline {

    // Agent Node
    agent any
   
	// Environment Variables 
    environment {
        REGION = 'us-west-2'
        AWS_ACCOUNT = '467317188419'
		// ECS 
	    ECRREPONM = 'customerupload'
	    ECRREPOVER  = 'latest'
		// Task Definition Values ContainerPORT, CPU and Memory Value 
		// Refer: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ecs-taskdefinition.html for desired values combination 
		CONTAINERPORT = '2132'
    	CPU = '256'
	    MEMORY = '512'
		// Lambda Function Name will be $LAMBDAFUN_NAME-$ENV_NAME
		LAMBDAFUN_NAME='psps-meterology-LAMBDA'
	    //S3AFPATH = 's3://psps-geomartcloud-dev/artifacts/batch/buildartifacts/'
		S3AFPATH = 's3://jnkins/artifacts/batch/buildartifacts/'
		// AWS Credentials 
        AWS_ACCESS_KEY_ID = credentials('jenkins_AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('jenkins_AWS_SECRET_ACCESS_KEY')
    }

	// Stages 
    stages {
        
        // PULL CODE
        stage('Clone') {
            steps {
                checkout scm
            }
        }
		
        // Set Branch Specific Environment Variables
        stage('Setup Environment variables') {
            steps {
                script {
                
                    echo "Branch: $env.BRANCH_NAME"
                    // echo "Build Target: $env.target"
                    
                    // Branch Develop
                    if (env.BRANCH_NAME == 'develop') {    
                        env.AWS_ACCOUNT =  env.AWSDEVACCOUNT
                        env.STACK_PREFIX = 'PSPS-METROLOGY-DEV'
                        env.ENV_NAME = 'DEV'
                        //  env.PROFILE = ''
                        env.NAME = 'PSPS-METROLOGYJOBS'
                        env.DEPLOY = 'true'
                    }
                    
                    // Branch Master
                    else if (env.BRANCH_NAME == 'master') {
                        env.AWS_ACCOUNT =  env.AWSPRODACCOUNT
                        env.STACK_PREFIX = 'PSPS-METROLOGY-PROD'
                        env.ENV_NAME = 'PROD'
                        //  env.PROFILE = ''
                        env.NAME = 'PSPS-METROLOGYJOBS'
                        env.DEPLOY = 'true'
                    }
                    
                    // Branch QA 
                    else if (env.BRANCH_NAME == 'qa') {
                        env.AWS_ACCOUNT =  env.AWSQAACCOUNT
                        env.STACK_PREFIX = 'PSPS-METROLOGY-QA'
                        env.ENV_NAME = 'QA'
                        //  env.PROFILE = ''
                        env.NAME = 'PSPS-METROLOGYJOBS'
                        env.DEPLOY = 'true'
                    }

                    // Branch TEST 
                    else if (env.BRANCH_NAME == 'test') {
                        env.AWS_ACCOUNT =  env.AWSTESTACCOUNT
                        env.STACK_PREFIX = 'PSPS-METROLOGY-TEST'
                        env.ENV_NAME = 'TEST'
                        //  env.PROFILE = ''
                        env.NAME = 'PSPS-METROLOGYJOBS'
                        env.DEPLOY = 'true'
                    }
                    
                    // else 
                    else {
                        env.DEPLOY = 'false'
                        // currentBuild.result = 'FAILED'
                        // error("env.BRANCH_NAME not match to allowed value")
                    }
                    
                }
            }
        }
    
        // Create and push docker image to AWS ECR
        stage('Docker Image push') {
            steps {
                sh '''
				    echo "--> $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY"
					#aws ec2 describe-regions --region $REGION
					ECRURL="$AWS_ACCOUNT.dkr.ecr.$REGION.amazonaws.com"
					echo "ECR: $ECRURL "
                    cd awsecrpspsmeteorology
                    ## Build docker image from dockerfile
                    [[ -s Dockerfile ]] && docker build -t $ECRREPONM . || exit 1
                    
                    ## Tag new image
                    docker tag $ECRREPONM:$ECRREPOVER $ECRURL/$ECRREPONM:$ECRREPOVER
                    
                    ## Upload new image
                    
					# login to aws ecr
                    $(aws ecr get-login --no-include-email --region $REGION >/dev/null 2>&1)
	                
					# Create Repository if not already exist
                    if ! aws ecr describe-repositories --repository-name $ECRREPONM --region $REGION >/dev/null 2>&1; then 
                        echo "Creating repository  $ECRURL/$ECRREPONM"
		                aws ecr create-repository --repository-name $ECRREPONM --region $REGION || true
                    else 
                        echo "repository $ECRURL/$ECRREPONM already exist"
                    fi

                    ## push image to ECR, delete if already exist with same tag
                    if  aws ecr describe-images --repository-name $ECRREPONM --image-ids imageTag=$ECRREPOVER --region $REGION >/dev/null 2>&1; then 
                        echo "Deleting image $ECRURL/$ECRREPONM:$ECRREPOVER"
	                    aws ecr batch-delete-image --repository-name $ECRREPONM --image-ids imageTag=$ECRREPOVER --region $REGION || true
                    fi
                    
					docker push $ECRURL/$ECRREPONM:$ECRREPOVER
                    echo "image pushed to  $ECRURL/$ECRREPONM:$ECRREPOVER"
		    
                '''
            }
        }
                        
        // Create Infrastructure
        stage('Create Infrastructure') {
            
            environment {
                AWS_DEFAULT_REGION='us-west-2'
            }
            
            steps {
                script {
                    if (env.DEPLOY == 'true') {
                        
                        sh '''
							ECRURLIN="${AWS_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${ECRREPONM}:${ECRREPOVER}"
							LAMBDAFUNNAME="${LAMBDAFUN_NAME}_${ENV_NAME}"						
                            if [[ -d ci ]]; then 
                                cd ci/ && chmod -R 777 *
                                if [[ -s create-infra.sh ]]; then
                                    ./create-infra.sh ${REGION} ${AWS_ACCOUNT} ${STACK_PREFIX} ${ENV_NAME} ${NAME} ${ECRURLIN} ${CONTAINERPORT} ${CPU} ${MEMORY} ${LAMBDAFUNNAME}
									echo "Infrastructure creation done"
                                fi
                            fi
							
                        '''
						
                    }
                }
            }
        }
		
        // zip lambda function code and update function 
        stage('Zip the code') {
            steps {                    //Replacing with environment settings.
                script {
                    if (env.DEPLOY == 'true') {
                        sh '''
			                # zip code 
                            cd awslambdameteorology && chmod -R 777 * && zip -r deploy.zip * && ls -lart
	                        # update lambda codes
    			            cd ../
							# check if lambda function exist 
							LAMBDAFUNNAME="${LAMBDAFUN_NAME}_${ENV_NAME}"
							if aws lambda get-function --function-name $LAMBDAFUNNAME --query 'Functions[*].FunctionName' --region $REGION >/dev/null 2>&1; then
								aws lambda update-function-code --function-name $LAMBDAFUNNAME --zip-file fileb://awslambdameteorology/deploy.zip --region $REGION  >/dev/null 2>&1
							else
								echo -e "Lambda Function $LAMBDA-$ENV_NAME not exist in region $REGION"
								exit 1
							fi
                            echo "lambda function code updated"
                        '''
                    }
                }
            }
        }

        // Upload newly created artifact at $S3AFPATH
        stage('Upload artifacts to S3 Bucket') {
            steps {
                script {
                    if (env.DEPLOY == 'true') {
                        echo "AWS Account: $AWS_ACCOUNT"
                        echo 'Validating Result'
                        sh '''
                            cd awslambdameteorology && cp deploy.zip build-${BUILD_NUMBER}.zip
                            aws s3 cp build-${BUILD_NUMBER}.zip ${S3AFPATH}
                        '''
                    }
                }
            }
        }
    
    }

  // post {
  //   always {
  //       echo 'Sending Email Notifications'
  //       emailext attachLog: true,
  //       body:"${currentBuild.currentResult}: job ${env.JOB_NAME}<br/> build ${env.BUILD_NUMBER}<br/> MoreInfo at:${env.BUILD_URL}console",
  //       subject: "jenkins Build Notification ${currentBuild.currentResult}: ${env.JOB_NAME}",
  //       mimeType: "text/html",
  //       to: "RTPB@pge.com"  
  //     }
  // }
  
}

// END PIPELINE 