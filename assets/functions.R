cytofDemo <- function(version,routeKey,rawPath,rawQueryString,headers,requestContext,body,isBase64Encoded) {
  library(httr)
  library(jsonlite)
  library(stringr)

  print("START")

  # Define the request URL
  pennsieve_url <- "https://api.pennsieve.io"
  cognito_url <- "https://cognito-idp.us-east-1.amazonaws.com/"
  api_secret <- Sys.getenv("PENNSIEVE_API_SECRET")
  api_key <- Sys.getenv("PENNSIEVE_API_KEY")
  dataset <- "N:dataset:a709cbba-a112-4bfe-91c2-21addeac9e31"

  target_file_url <- "https://api.pennsieve.io/packages/N%3Apackage%3A2fdd18b5-df44-4bd4-b488-426099c97f9f/files/159250"
  
  # Authenticate
  cognito_info <- get_cognito_info(pennsieve_url)
  client_id = cognito_info$cognito_app_client_id
  session_token = get_session_token(cognito_url,api_key,api_secret,client_id)


  # Get file from Pennsieve
  queryString <- list(api_key = session_token)
  response <- VERB(
    "GET",
    target_file_url,
    query = as.list(queryString),
    content_type("application/json"),
    accept("*/*")
  )
  
  json_string = content(response, "text")
  json <- fromJSON(json_string)
  pre_signed_url <- json$url # Presigned URL than can be downloaded

  # Download and modify the file
  dest_file <- "/tmp/saved_s3_file.txt"
  modified_file_path <- "/tmp/modified_files"
  modified_file_name <- "modified_file.txt"
  download.file(pre_signed_url, dest_file)

  modify_file(pre_signed_url,dest_file, modified_file_path,modified_file_name)

  setup_pennsieve(dataset)
  manifest_id = make_manifest(modified_file_path)
  upload_to_pennsieve(manifest_id)

  

}
get_session_token <- function(cognito_url, api_key, api_secret,client_id) {
  print("GET SESSION TOKEN")
  # Define the request headers
  headers <- c(
    "X-Amz-Target" = "AWSCognitoIdentityProviderService.InitiateAuth",
    "Content-Type" = "application/x-amz-json-1.1"
  )

  # Define the request body
  body <- list(
    AuthFlow = "USER_PASSWORD_AUTH",
    AuthParameters = list(
      PASSWORD = api_secret,
      USERNAME = api_key
    ),
    ClientId = client_id

  )

  # Send the POST request
  response <- POST(cognito_url, body = toJSON(body,auto_unbox = TRUE), encode = "json", add_headers(.headers = headers))
  # Check the response status
  if (http_status(response)$category == "Success") {
    response_content <- content(response, as = "text")
    
    response_data <- fromJSON(response_content)
    
    access_token <- response_data$AuthenticationResult$AccessToken
    return(access_token)
    # Process the response content as needed
  } else {
    # Error response
    error_message <- http_error(response)
    return(error_message)
  }
}

get_cognito_info <- function(url) {
  print("GET COGNITO INFO")
  auth_config_url <- paste0(url, "/authentication/cognito-config")
  
  response <- GET(auth_config_url)
  stop_for_status(response)
  
  json_data <- content(response, "parsed")
  cognito_app_client_id <- json_data$tokenPool$appClientId
  cognito_region <- json_data$region
  
  return(list(
    cognito_app_client_id = cognito_app_client_id,
    cognito_region = cognito_region
  ))
}

modify_file <- function(url,input,path,file){
  
  
  # Make folder for output
  mkdir_cmd <- paste0("mkdir ", path)
  result <- system(mkdir_cmd, intern = TRUE)

  # Read the content of the original file
  original_content <- readLines(input)
  
  # Append text to the original content
  modified_content <- c(original_content, "<NEW DATA GOES HERE>")

  current_time <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  modified_content <- c(modified_content, current_time)
  
  # Write the modified content to the new file
  writeLines(modified_content, paste0(path, "/", file))

  # Open the file in read mode
  file <- file(paste0(path, "/", file), "r+")

  # Read and print the file contents
  file_contents <- readLines(file)
  print(file_contents)
  close(file)

}

setup_pennsieve <- function(dataset){
  # Set home path. You can only write to /tmp in AWS lambda
  Sys.setenv(HOME = "/tmp")

  start_agent_cmd <- "pennsieve agent"
  result <- system(start_agent_cmd, intern = TRUE)
  print("STARTING AGENT")
  print(result)

  set_dataset_cmd <- paste0("pennsieve dataset use ", dataset)
  result <- system(set_dataset_cmd, intern = TRUE)
  print("SET DATASET")
  print(result)
}

make_manifest <- function(location){

  setup_config_cmd <- paste0("pennsieve manifest create ", location)
  result <- system(setup_config_cmd, intern = TRUE)
  print(result)
  manifest_id <- str_extract(result, "(?<=Manifest ID: )\\d+")
  print("MANIFEST ID")
  print(manifest_id)

  return(manifest_id)

}
upload_to_pennsieve <- function(id){
  print("MANIFEST UPLOAD START")
  upload_cmd <- paste0("pennsieve upload manifest ", id)
  setup_config_cmd <- upload_cmd
  print(upload_cmd)
  result <- system(setup_config_cmd, intern = TRUE)
  print("MANIFEST UPLOAD RESULT")
  print(result)

}