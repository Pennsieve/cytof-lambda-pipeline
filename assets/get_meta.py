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



# Get session token
session_token = authenticate(pennsieve_url, api_key, api_secret)
print("Got Token")

# Get all files in the dataset: this part works
url = pennsieve_url + "/datasets/" + dataset_id + "/packages?api_key=" + session_token
headers = {"accept": "*/*"}
response = requests.get(url, headers=headers)
print("Got all files")

pack_list = json.loads(response.text).get("packages")
fcs_content = [pack.get("content").get("nodeId") for pack in pack_list if pack.get("extension")=="fcs"]
pack_id = fcs_content[0].replace(":","%3A") # select package id for a single file
print("Select package ID for a single file")


# Get metadata for a file: this doesn't work
pennsieve_url = "https://api2.pennsieve.io"
url = pennsieve_url + "/metadata/package?dataset_id=" + dataset_id + "&package_id=" + pack_id
headers = {
    "accept": "application/json",
    "Authorization": session_token
}
print(url)
print(headers)
response = requests.get(url, headers=headers)
print(response.text)



