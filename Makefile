.EXPORT_ALL_VARIABLES:
BUCKET = $(shell aws ssm get-parameter --name /account/app-bucket | jq -r .Parameter.Value)
ACCOUNT = $(shell aws sts get-caller-identity | jq --raw-output .Account)
.PHONY: create_repository
create_repository: 
	aws ecr create-repository --repository-name container-lambda --image-scanning-configuration scanOnPush=true

.PHONY: build
build: 
	@sam build

.PHONY: test
test: 
	@aws lambda invoke --function-name "ContainerFunction" --payload '{}' out.json && cat out.json && rm out.json

.PHONY: package
package: build
	@sam package --s3-bucket $$BUCKET --image-repository $$ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/container-lambda

.PHONY: deploy
deploy: build
	@sam deploy \
		--s3-bucket $$BUCKET \
		--image-repository $$ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/container-lambda \
		--stack-name LambdaContainers-mike \
		--capabilities CAPABILITY_NAMED_IAM \
		--no-fail-on-empty-changeset --tags logical_name=LambdaContainers-mike
