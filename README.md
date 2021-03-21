# TF Code
 `Terraform module for deploying Infrastructre for streaing logs from S3 to Elasticsearch`

### AWS Elasticsearch module

### AWS Lambda Function
*Lambda Function to stream logs received in S3 bucket to Elasticsearch domain*

#### Lambda layers "requests"
`Create Lambda layer for python "requests" module.`

#### IAM role for lambda function
`IAM role with policies needed for lambda function`

#### Lambda Function "Stream logs to ES"
`Create Lambda function for below functions`
- Get triggered when object(Cloudtrail logs file) added in S3 bucket 
- Download s3 object 
- Read events in file 
- Stream logs to elasticsearch 
