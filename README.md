
# CYTOF R lang demo

This project prooves that we can run R code in a docker container, upload it to a lambda an then trigger it as an integration.

This should allow any public lambda URL to be triggered

## Setup

 * To run locally, add a .env file into the assets folder with `PENNSIEVE_API_KEY`, `PENNSIEVE_API_SECRET` and `REGION`

 * Navigate to the assets folder and run `docker build -t <IMAGE_NAME> . &&  docker run --name <CONTAINER_NAME> --env-file .env -p 8080:808 <IMAGE_NAME>`

 * Test execution of your code by running `curl -X GET "http://localhost:8080/2015-03-31/functions/function/invocations" -d '{"version":"1","routeKey":"","rawPath":"","rawQueryString":"","headers":"","requestContext":"","body":"","isBase64Encoded":""}'`

 * After code is tested and runs locally, you can push it up to lambda with the the following commands:

   * `aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_NUMBER>.dkr.ecr.us-east-1.amazonaws.com`

   * `docker build -t <CONTAINER_NAME> .`

   * `docker tag <CONTAINER_NAME> :latest <AWS_ACCOUNT_NUMBER>.dkr.ecr.us-east-1.amazonaws.com/<CONTAINER_NAME> :latest`

   * `docker push <AWS_ACCOUNT_NUMBER>.dkr.ecr.us-east-1.amazonaws.com/<CONTAINER_NAME>:latest`

* Add the `PENNSIEVE_API_KEY`, `PENNSIEVE_API_SECRET` and `REGION` environment variables to your lambda, and enable a function URL.

* With that function URL you can now trigger your R code
