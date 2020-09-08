import requests
import json
import os
__file__ = 'sfdcEnivornments.json'

if __name__ == "__main__":
    pass

def get_access_token(env,client_id,client_secret,refresh_token):
    json = get_json()
    env1 = json['SFDC envs'][env]
    url = env1['url']
    body = genarate_body(client_id,client_secret,refresh_token)
    return authenticate(url,body)

def get_json():
    file = os.path.join(os.path.dirname(__file__),__file__) 
    with open(file,'r') as json_file:
        return json.load(json_file)
         
def authenticate(url,body):
    answer = requests.post(url=url,data=body)
    access_token = json.loads(answer.content)['access_token']
    return access_token


def genarate_body(client_id,client_secret,refresh_token):
    body = {
            "grant_type" : "refresh_token",
            "client_id":client_id,
            "client_secret":client_secret,
            "refresh_token":refresh_token 
            }
    return body        
