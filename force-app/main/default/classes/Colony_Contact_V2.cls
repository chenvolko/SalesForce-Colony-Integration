@RestResource(urlMapping='/ColonyContact/*')
global class Colony_Contact_V2
{
    @HttpPut
    global static string Update_contact_details()
    {
        string result;
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        String jsonInput = request.requestBody.toString().trim();
        system.debug('>>jsonInput' + jsonInput);
        
        Colony_DM_contact_V2 r = Colony_DM_contact_V2.parse(jsonInput);
        
        string accountid = r.colony_id;
        List <Account> account = new list<Account>([Select id from Account Where Colony_id__c =: accountid]);
        if(account.size() == 0)
        {
            response.statusCode = 500;
            return ('No Account exsits with id: ' + accountid);
        }
                     
        list <Contact> temp_contact = new list <Contact>();        
        Contact new_contact;
        
        for(Colony_DM_contact_V2.Contact contact : r.Contacts) 
        {
            system.debug('>>Start parsing Colony_DM_contact_V2.Contact:' +  contact);
            
            temp_contact.clear(); 
            temp_contact = [select id, phone, email,firstname, lastname, Colony_Role__c from Contact Where email =: contact.email];
                        
            if(temp_contact.size() == 0)
            {
                //search if such phone exsits
                temp_contact.clear(); 
                temp_contact = [select id, phone,email,firstname, lastname, Colony_Role__c from Contact Where phone =: contact.phone];
                if(temp_contact.size() > 0)
                {
                    response.statusCode = 500;
                    return ('Can\'t create new user for: '+ contact.email + ' ,because phone: '+ contact.phone + ' exsits in Salesforce');
                }
                
                new_contact = new Contact(
                    firstname = contact.first_name,
                    lastname = contact.last_name,
                    email = contact.email,
                    phone = contact.phone,
                    Colony_Role__c = contact.role,
                    accountid = account[0].id
                    );
                system.debug('>>Before create new contact: ' + new_contact);
                insert new_contact;                
            }
            
            else if(temp_contact.size() == 1)
            {
                temp_contact[0].Colony_Role__c = contact.role;
                system.debug('>>Before update exsiting contact: ' + temp_contact);
                update temp_contact;                
            }              
            
        }         
        
        return ('Update contacts successfully');
    }   

}