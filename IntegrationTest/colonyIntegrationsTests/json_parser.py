import os
import json
import logging

logging.basicConfig(level=logging.DEBUG)

class json_parser:
    def __init__(self,file_name,env_name):
        self.file_name = file_name
        self.env_name = env_name

    def get_post_body_url(self):
        file = os.path.join(os.path.dirname(self.file_name),self.file_name) 
        with open(file,'r') as json_file:
            json_object = json.load(json_file)
            return (json_object['Post Account']['body'],self.get_url(json_object,self.env_name,json_object['Post Account']))

    def get_update_body_url(self):
        file = os.path.join(os.path.dirname(self.file_name),self.file_name) 
        with open(file,'r') as json_file:
            json_object = json.load(json_file)
            return (json_object['PUT Upgrade Account']['body'],self.get_url(json_object,self.env_name,json_object['PUT Upgrade Account']))

    def get_set_provider_body_url(self):
        file = os.path.join(os.path.dirname(self.file_name),self.file_name) 
        with open(file,'r') as json_file:
            json_object = json.load(json_file)
            return (json_object['PUT Cloud Provide']['body'],self.get_url(json_object,self.env_name,json_object['PUT Cloud Provide']))
    
    def get_url(self,json,env_name,post_account_dict):
        env = json['SFDC envs'][env_name]
        prefix = env['prefix url']
        suffix = post_account_dict['url']
        url = prefix + suffix
        return url

