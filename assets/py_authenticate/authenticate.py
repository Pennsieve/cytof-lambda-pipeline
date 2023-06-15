import boto3
import requests
import json

pennsieve_url = "https://api.pennsieve.io"
api_key = "133ad5cb-9533-4d7a-adf1-d1e5043cb941"
api_secret = "77ce74b2-3914-4b48-9f05-cb43cbc632bf"
dataset_id = "N%3Adataset%3A01f391bd-9f49-4551-9644-a943ff7701a4"

# Function to get session token using API key
def authenticate (url, api_key, api_secret):
  r = requests.get(f"{url}/authentication/cognito-config")
  r.raise_for_status()

  cognito_app_client_id = r.json()["tokenPool"]["appClientId"]
  cognito_region = r.json()["region"]

  cognito_idp_client = boto3.client(
    "cognito-idp",
    region_name=cognito_region,
    aws_access_key_id=api_key,
    aws_secret_access_key=api_secret,
  )
          
  login_response = cognito_idp_client.initiate_auth(
    AuthFlow="USER_PASSWORD_AUTH",
    AuthParameters={"USERNAME": api_key, "PASSWORD": api_secret},
    ClientId=cognito_app_client_id,
  )

  session_token = login_response["AuthenticationResult"]["AccessToken"]

  r = requests.get(f"{url}/user", headers={"Authorization": f"Bearer {session_token}"})
  r.raise_for_status()

  return session_token

