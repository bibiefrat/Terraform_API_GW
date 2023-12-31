# Amazon Coginito:

https://medium.com/carlos-hernandez/user-control-with-cognito-and-api-gateway-4c3d99b2f414

# Cognito Register User:
1. register user --> aws cognito-idp sign-up --client-id 2shdrg54eo8hengpe0iu18tv7q  --username bibiefrat --password a3bAcd01~ --user-attributes Name=name,Value="bibi" Name=email,Value="bibi.efrat@gmail.com"
2. skip email auth --> aws cognito-idp admin-confirm-sign-up  --user-pool-id eu-west-1_CNcmtPD5E --username bibiefrat
3. get the token -->  aws cognito-idp initiate-auth --client-id 6ugqk05u6lh14hcarfmi06h7ej  --auth-flow USER_PASSWORD_AUTH --auth-parameters USERNAME=bibiefrat,PASSWORD=a3bAcd01~ --query 'AuthenticationResult.IdToken' --output text

# Amazon API Gateway to AWS Lambda to Amazon DynamoDB

This pattern explains how to deploy a sample application using Amazon API Gateway, AWS Lambda, and Amazon DynamoDB with terraform. When an HTTP POST request is made to the Amazon API Gateway endpoint, the AWS Lambda function is invoked and inserts an item into the Amazon DynamoDB table.

Learn more about this pattern at [Serverless Land Patterns](https://serverlessland.com/patterns/apigw-lambda-dynamodb-terraform).

Important: this application uses various AWS services and there are costs associated with these services after the Free Tier usage - please see the [AWS Pricing page](https://aws.amazon.com/pricing/) for details. You are responsible for any AWS costs incurred. No warranty is implied in this example.

## Requirements

* [Create an AWS account](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html) if you do not already have one and log in. The IAM user that you use must have sufficient permissions to make necessary AWS service calls and manage AWS resources.
* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) installed and configured
* [Git Installed](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started) installed

## Deployment Instructions

1. Create a new directory, navigate to that directory in a terminal and clone the GitHub repository:
    ``` 
    git clone https://github.com/aws-samples/serverless-patterns
    ```
1. Change directory to the pattern directory:
    ```
    cd serverless-patterns/apigw-lambda-dynamodb-terraform
    ```
1. From the command line, initialize terraform to download and install the providers defined in the configuration:
    ```
    terraform init
    ```
1. From the command line, apply the configuration in the main.tf file:
    ```bash
   cd /media/bibi/Volume/Share/Pycharm/Terraform/api_gw_lambda
   terraform apply
    ```
1. During the prompts:
    * Enter yes
1. Note the outputs from the deployment process, these contain the resource names and/or ARNs which are used for testing.

## How it works

When an HTTP POST request is sent to the Amazon API Gateway endpoint, the AWS Lambda function is invoked and inserts an item into the Amazon DynamoDB table.

## Testing

Once the stack is deployed, retrieve the HttpApiEndpoint value from the outputs of the terraform apply, then make a call the /movies endpoint using curl or Postman.
Check the dynamodb table to make sure new items have been created.


```

# Send an HTTP POST request without a request body and the lambda function will add a default item to the dynamodb table

curl -X POST '<your http api endpoint>'/movies

#sample output

{
  "message": "Successfully inserted data!"
}
```

```
# Send an HTTP POST request an include a request body in the format below and the lambda function will create a new item in the dynamodb table

we need to send the request with the token we got fron cognito   ---> see above cognito token

curl -X POST '<your http api endpoint>'/movies --header 'Content-Type: application/json' -d '{"year":1977, "title":"Starwars"}' 

#sample output

{
  "message": "Successfully inserted data!"
}
```


```
# Get  an HTTP Get request an include a request body in the format below and the lambda function will create a new item in the dynamodb table

curl -X GET '<your http api endpoint>'/movies_get

#sample output

{
 "message": "[{'year': Decimal('2023'), 'title': 'Oppenheimer'}]"
}
```

```
# Delete an HTTP Delete request an include a request body in the format below and the lambda function will create a new item in the dynamodb table

curl -X DELETE '<your http api endpoint>'/movies_delete  --header 'Content-Type: application/json' -d '{"year":2023, "title":"Oppenheimer"}'

#sample output

{
  "message": {"ResponseMetadata": {"RequestId": "BRILF66SGTFT2QE73CVTG3DDTNVV4KQNSO5AEMVJF66Q9ASUAAJG", "HTTPStatusCode": 200, "HTTPHeaders": {"server": "Server", "date": "Sun, 06 Aug 2023 17:40:26 GMT", "content-type": "application/x-amz-json-1.0", "content-length": "2", "connection": "keep-alive", "x-amzn-requestid": "BRILF66SGTFT2QE73CVTG3DDTNVV4KQNSO5AEMVJF66Q9ASUAAJG", "x-amz-crc32": "2745614147"}, "RetryAttempts": 0}}
}
```



## Cleanup
 
1. Change directory to the pattern directory:
    ```bash
    cd /media/bibi/Volume/Share/Pycharm/Terraform/api_gw_lambda
    ```
1. Delete all created resources
    ```bash
    terraform destroy
    ```
1. During the prompts:
    * Enter yes
1. Confirm all created resources has been deleted
    ```bash
    terraform show
    ```
----
Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.

SPDX-License-Identifier: MIT-0


