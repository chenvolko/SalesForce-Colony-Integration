import create_account as post_account
import authentication as auth
import update_account
import sys
import json
import account_generator
import update_account
import email_sender
from multiprocessing.pool import ThreadPool
from  json_parser import json_parser
from threading import Lock

ZENDESK_SANDBOX_URL = 'support@qualisystemscom1579013504.zendesk.com'
result_list = []
   
def main_loop(access_token,url,smtp_user,smtp_pass):
    for i in range(10):
        response,colony_id  = post_account.post_account(access_token,url)
        if(response.status_code == 200):
            print('great success')
            log_result(colony_id)
        else:
            send_email(response,smtp_user,smtp_pass)            
        
    for colony_id in result_list:
        response = update_account.update_account (access_token,colony_id,url)
        if(response.status_code != 200):
            send_email(response,smtp_user,smtp_pass)            
        response = update_account.set_cloud_provider(access_token,colony_id,url)
        if(response.status_code != 200):
            send_email(response,smtp_user,smtp_pass)            

def log_result(result):
    result_list.append(result)

#Get Request's resonse object.
def send_email(response,smtp_user,smtp_pass):
    email_sender.send_email(smtp_user,smtp_pass,ZENDESK_SANDBOX_URL,'Colony Integration Test Failed','Response content: ' + str(response.content,'utf-8'),False)

def main(args):
    env_name = args[0]
    file_name = args[1]
    client_id = args[2]
    refresh_token = args[3]
    client_secret = args[4]
    smtp_user = args[5]
    smtp_pass = args[6]
    access_token = auth.get_access_token('Ampr',client_id,client_secret,refresh_token)
    parser = json_parser(file_name,env_name)
    post_body,post_url = parser.get_post_body_url()
    main_loop(access_token,post_url,smtp_user,smtp_pass)

if __name__ == "__main__":
    main(sys.argv[1:8])

