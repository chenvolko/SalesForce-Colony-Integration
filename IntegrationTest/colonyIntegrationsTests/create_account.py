import requests
import os
import json
import json_parser
import logging
import account_generator
JSON_TEMPLATE = {
    "body" : {
            "colony_id" :"",
            "account_name" :"",
            "contact_first_name" :"Integration Test",
            "contact_last_name" :"",
            "contact_email" :"mail@mail.com",
            "phone" : "086596045",
            "country": "Israel",
            "state" : ""
        }}

__file__ = 'sfdcEnivornments.json'

def post_account(access_token,url):
    print('posting account')
    body = JSON_TEMPLATE
    email,account_name,last_name,colony_id = genarate_body()
    body['body']['contact_email'] = email
    body['body']['account_name'] = account_name
    body['body']['contact_last_name'] = last_name
    body['body']['colony_id'] = colony_id
    headers={"content-type":"application/json", "Authorization":"Bearer {}".format(access_token)}
    response = requests.post(url=url,data=json.dumps(body["body"]),headers=headers)
    logging.debug(response)
    return response,colony_id

def genarate_body():
    email = account_generator.contact_email_genarator()
    account_name = account_generator.account_name_genarator()
    last_name = account_generator.last_name_genarator()
    colony_id = account_generator.colony_id_genarator()
    return email,account_name,last_name,colony_id    


