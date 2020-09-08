import requests
import account_generator
import json
#__file__ = 'sfdcEnivornments.json'
UPGRADE_TEMPLATE = {
    "body" : {
        "colony_id": "",
        "event_type": "upgrade",
        "event_parameters":{"first_name":"Test","last_name": "","email":"","phone":"1"}
    }}
SET_PROVIDER_TEMPLATE = {
    "body" : {
        "colony_id": "",
        "event_type": "cloud_provider_set",
        "event_parameters":{"provider":"AWS"}
    }}
def update_account (access_token,colony_id,url):
    email,last_name = generate_body()
    body = UPGRADE_TEMPLATE
    print(body)
    body['body']['event_parameters']['last_name'] = last_name
    body['body']['event_parameters']['email'] = email
    body['body']['colony_id'] = colony_id
    headers={"content-type":"application/json", "Authorization":"Bearer {}".format(access_token)}
    return requests.put(url=url,data=json.dumps(body["body"]),headers=headers)

def set_cloud_provider(access_token,colony_id,url):
    body = SET_PROVIDER_TEMPLATE
    body['body']['colony_id'] = colony_id
    headers={"content-type":"application/json", "Authorization":"Bearer {}".format(access_token)}
    return requests.put(url=url,data=json.dumps(body["body"]),headers=headers)
    
def generate_body():
    email = account_generator.contact_email_genarator()
    last_name = account_generator.last_name_genarator()
    return email,last_name    

