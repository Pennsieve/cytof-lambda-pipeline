from aws_cdk import (
    # Duration,
    aws_lambda as _lambda,
    Stack,
    core
    # aws_sqs as sqs,
)
from constructs import Construct

class AwsLambdaContainerCdkRStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # The code that defines your stack goes here
        function = _lambda.DockerImageFunction(self, "lambda_function",code=_lambda.DockerImageCode.from_image_asset("./assets"))

