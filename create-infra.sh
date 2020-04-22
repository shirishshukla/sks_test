#!/bin/sh

####
## Description: Launching AWS CloudFormation stack
## 
####

set -ex

REGION=$1
AWS_ACCOUNT=$2
STACK_PREFIX=$3
ENV_NAME=$4
NAME=$5
IMAGE_ID=$6
CONTAINER_PORT=$7
CPU=$8
MEMORY=$9
LAMBDA_FUNCTION_NAME=${10}

PROFILE=''

# Setting the cloudformation file
TEMPLATE_FILE='cloudformations-aws-jen.yml'
STACKSET_NAME="Stackset-GISCOE-$STACK_PREFIX"

function stackjenkins {

    # Check if stack set already exist 
    if aws cloudformation  describe-stack-set \
                --stack-set-name $STACKSET_NAME >/dev/null 2>&1; then
        echo "Stack Set $STACKSET_NAME already present, so update-stack-set"
        ACTION_SS='update-stack-set'
    else
        echo -e "Creating Stack-set $STACKSET_NAME"
        ACTION_SS='create-stack-set'
    fi

    # cloudformations-aws-jen.yml # create SQS and Lambda Resource
    aws cloudformation ${ACTION_SS}    \
            --template-body file://${TEMPLATE_FILE} \
            --stack-set-name ${STACKSET_NAME} \
            --description "${STACKSET_NAME}" \
            --parameters ParameterKey=pEnv,ParameterValue=${ENV_NAME} \
                ParameterKey=pApplicationName,ParameterValue=$NAME${ENV_NAME}  \
                ParameterKey=ServiceName,ParameterValue=$NAME${ENV_NAME} \
                ParameterKey=Image,ParameterValue=${IMAGE_ID} \
                ParameterKey=ContainerPort,ParameterValue=${CONTAINER_PORT} \
                ParameterKey=Cpu,ParameterValue=$CPU \
                ParameterKey=Memory,ParameterValue=$MEMORY \
                ParameterKey=QueueName,ParameterValue=$NAME${ENV_NAME} \
                ParameterKey=LambdaFunctionName,ParameterValue=${LAMBDA_FUNCTION_NAME} \
            --tags Key=Order,Value=70040464 Key=Owner,Value=RTPB \
            --capabilities CAPABILITY_NAMED_IAM \
            $PROFILE     

    echo "wait for 5 seconds to get stack-set created/updated."
    sleep 5

}

function stackjenkinsinstance {
    # Check if stack set already exist 
    if aws cloudformation describe-stack-instance \
                --stack-set-name ${STACKSET_NAME} \
                --stack-instance-region $REGION \
                --stack-instance-account ${AWS_ACCOUNT} >/dev/null 2>&1; then
        echo "Desired Stack Instance on stack-set $STACKSET_NAME already present, so update-stack-instance"
        ACTION_SI='update-stack-instances'
    else
        echo -e "Creating Stack-instance $STACKSET_NAME"
        ACTION_SI='create-stack-instances'    
    fi

    # Exit if already running stack from above stack set 
    VAL=$(aws cloudformation list-stacks \
        --query 'StackSummaries[?starts_with(StackStatus, `DELETE_COMPLETE`) != `true`].[StackName,StackStatus]' \
        --region $REGION --output text | grep $STACKSET_NAME)
    if [[ -z $VAL ]]; then 
        echo -e "$ACTION_SI for $STACKSET_NAME in region $REGION"
        aws cloudformation ${ACTION_SI} \
            --stack-set-name ${STACKSET_NAME} \
            --accounts ${AWS_ACCOUNT} --regions $REGION \
            $PROFILE 
    else
        SISTATUAS=$(aws cloudformation list-stacks \
            --query 'StackSummaries[?starts_with(StackStatus, `DELETE_COMPLETE`) != `true`].[StackName, StackStatus]' \
            --region $REGION --output text | grep $STACKSET_NAME | awk '{print $NF}')
        if [[ "$SISTATUAS" == "CREATE_COMPLETE" ]]; then 
            echo "Stack Status - $VAL"
        elif [[ "$SISTATUAS" == "CREATE_IN_PROGRESS" || "$SISTATUAS" =~ 'UPDATE' ]]; then  
            echo "Stack Status - $VAL"
            echo "wait for 120 seconds to get stacks created/updated completed."
            sleep 120
        else 
            echo -e "Failed: $ACTION_SI for $STACKSET_NAME in region $REGION Status: SISTATUAS"
            echo -e "Another Operation on StackSet \"$VAL\" is in progress! please wait for few minutes and try again"
            exit 1
        fi
    fi
}

echo "stackjenkins"
stackjenkins

echo "stackjenkinsinstance"
stackjenkinsinstance

## END ##