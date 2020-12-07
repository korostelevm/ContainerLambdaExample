### Minimal container lambda example


1. Minimal SAM template image function definition
   ```yaml
    AWSTemplateFormatVersion: '2010-09-09'
    Transform: AWS::Serverless-2016-10-31
    Description: Minimal lambda containers example

    Parameters:
        Namespace:
            Type: String
            Default: ''
        
    Resources:
        ContainerFunction:
            Type: AWS::Serverless::Function
            Metadata:
                Dockerfile: Dockerfile
                DockerContext: ./lambda
            Properties:
                FunctionName: !Sub "ContainerFunction${Namespace}"
                PackageType: Image
                Timeout: 900
                MemorySize: 10240
   ```

2. Dockerfile in the folder defined by `Metadata`
    ```
    .
    ├── Makefile
    ├── README.md
    ├── lambda
    │   ├── Dockerfile
    │   ├── index.js
    │   └── package.json
    └── template.yaml
    ```
    - can be in a different directory also

3. Dockerfile
    ```Dockerfile
    FROM public.ecr.aws/lambda/nodejs:12
    RUN yum install ImageMagick-devel -y
    COPY ./* ./
    RUN npm install
    CMD [ "./index.lambdaHandler"]
    ```
   - the dockerfile will reference an aws lambda container `FROM public.ecr.aws/lambda/nodejs:12` and extend it with own dependencies
   - `CMD [ "./index.lambdaHandler"]` runs the executable on lambda invoke
   

4. Build and Deploy
   1. `make create_repository` - run only once
   2. `make deploy` - builds and deploys
    
  
----
### The Makefile

1. `make create_repository` 
    ```shell
    account=$(aws sts get-caller-identity | jq --raw-output .Account)
    aws ecr create-repository --repository-name container-lambda --image-scanning-configuration scanOnPush=true
    ```
    - makes sure the ecr image repository exists in account
    - the `--repository-name` parameter set to the ecr repo you want to create, in this case `container-lambda`, you will use the repo url in the package and deploy SAM commands 

        
2. `make build`
   ```
   sam build
   ```
   - sam handles building the container with docker for you

3. `make package`
   ```
   sam package --s3-bucket $$BUCKET --image-repository $$ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/container-lambda
   ```
   - runs package the built files and stage in ecr and s3
  
4. `make deploy`
   ```shell
   sam deploy \
		--s3-bucket $$BUCKET \
		--image-repository $$ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/container-lambda \
		--stack-name LambdaContainers-mike \
		--capabilities CAPABILITY_NAMED_IAM \
		--no-fail-on-empty-changeset --tags logical_name=LambdaContainers-mike
   ```
   - runs sam deploy which launches the stack
   - the `--image-repository` is required for functions with `PackageType: Image`
   - the `--s3-bucket` is required for large templates (not in this case but leaving it in for extending in the future)
   - the `--tags` parameter with the `logical_name` tag tags the stack resources for cost explorer and is our convention

5. `make test`
   ```
   aws lambda invoke --function-name "ContainerFunction" --payload '{}' out.json && cat out.json && rm out.json
   ```
   - invokes lambda function and prints the response