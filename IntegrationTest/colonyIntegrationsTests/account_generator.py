import json
import string
import random
import uuid



def contact_email_genarator():
    acclen = random.randint(1,20)
    winacc = ''.join(random.choice(string.ascii_lowercase + string.digits) for _ in range(acclen))
    full_address = winacc+"@"  + "testnomail.com"
    return full_address

def account_name_genarator():
    prefix = "qualidev-"
    suffix = ''.join(random.choice(string.digits) for _ in range(10))
    return prefix + suffix

def last_name_genarator():
    name_len = random.randint(2,7)
    last_name = ''.join(random.choice(string.ascii_lowercase) for _ in range(name_len))
    return last_name

def colony_id_genarator():
    return str(uuid.uuid4())


