#!/usr/bin/env python3

# Import Modules
import os
import requests
import sys
import argparse

# Manually Define Variables - These will be individually overriden if matching argument is passed from commandline.
real_server_ip = ""
api_url = ""
kemp_username = ""
kemp_password = ""

# Import Arguments
parser=argparse.ArgumentParser()
parser.add_argument("--realserverip", help="Real Server IP Address to be enabled")
parser.add_argument("--kempapiurl", help="Kemp API URL to connect to")
parser.add_argument("--kempusername", help="Kemp Username")
parser.add_argument("--kemppassword", help="Kemp Password")
args=parser.parse_args()

# Set Variables
if args.realserverip != None:
    real_server_ip = args.realserverip
if args.kempapiurl != None:
    api_url = args.kempapiurl
if args.kempusername != None:
    kemp_username = args.kempusername
if args.kemppassword != None:
    kemp_password = args.kemppassword

# Variable Verification
if real_server_ip == None:
    sys.exit("ERROR: Required variable 'realserverip' was not provided.")
if api_url == None:
    sys.exit("ERROR: Required variable 'kempapiurl' was not provided.")
if kemp_username == None:
    sys.exit("ERROR: Required variable 'kempusername' was not provided.")
if kemp_password == None:
    sys.exit("ERROR: Required variable 'kemppassword' was not provided.")

# Variable Initialisation
realservers = {}
cmd = {}
creds = {
    "apiuser": kemp_username,
    "apipass": kemp_password
}
# Define Functions
def data():
    # Combine fields required to build the "Body" of the Kemp API request.
    data = dict(cmd)
    data.update(creds)
    return data

def kemppost():
    # Execute data() function to build request body.
    body = data()
    # Query Kemp API and store results.
    response = requests.post(api_url, json=body)
    # Confirm Kemp Connection was successful
    if response.status_code == 200:
        print("Kemp API connection successfull, Status Code %d" % response.status_code)
    else:
        sys.exit("Kemp API connection was unsuccessfull, Status Code %d" % response.status_code)
    # Return result
    return response

# This dictionary will be combined with the "creds" dictionary, to build a "data" dictionary (see "data()" function).
cmd = {
    "cmd": "enablers",
    "rs": (real_server_ip)
}

# Globally Enable Real Server
print("Enabling Real Server %s" % real_server_ip)
kemp_response = kemppost()