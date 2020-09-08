@RestResource(urlMapping='/ColonyAccount/*')
global class Colony_Account_V2
{
    @HttpPost
    global static Colony_account_status_v2 Create_new_trial_accout (string colony_id, string account_name, string contact_first_name, string contact_last_name, string contact_email, string phone, string country, string state, string utm_campaign)
    {
        Salesforce_API_Exception ex;
               
        system.debug('>>start Create_new_trial account v2');
        
        //validations
        if (String.isBlank(account_name))
        {
            ex = new Salesforce_API_Exception(102, 'account name cannot be empty');
            throw ex;
        }        
        if ( String.isBlank(colony_id))
        {
            ex = new Salesforce_API_Exception(103, 'colony_id cannot be empty');            
            throw ex;
        }
        if ( String.isBlank(contact_email))
        {
            ex = new Salesforce_API_Exception(104, 'contact_email cannot be empty');
            throw ex;
        }        
        if (String.isBlank(contact_last_name))
        {
            ex = new Salesforce_API_Exception(105, 'contact_last_name cannot be empty');
            throw ex;
        }
        //cheack if colony id exsits
        list<Account> accounts = new list<Account> ([select id from Account where Colony_id__c =: colony_id]);
        if(accounts.size() > 0)
        {
            ex = new Salesforce_API_Exception(101,'Fail create account with colony_id: '+ colony_id +', This colony_id already exsits in Salesforce');
            throw ex;            
        }        
        
        //find name for the acount
        string trial_account_name = Colony_manager.find_avaliable_account_name(account_name);
        system.debug('>>trial_account_name: ' + trial_account_name);
        
        //find Master trial account
        Account parent_account = [select id, name from Account where name =: Colony_manager.Colony_master][0]; //Master trial account
        
        Blob b = Crypto.GenerateAESKey(128);
        String colony_obj_version = EncodingUtil.ConvertTohex(b);
        
        Date trial_end_date = Date.today().adddays(30);//30 days trial
        
        //Create new account
        Account trial_account = new Account(
            name = trial_account_name,
            ParentId = parent_account.id,
            Is_Colony__c = true,
            Is_Deleted__c = false,
            Is_suspended__c = false,
            Colony_id__c = colony_id,
            Colony_State__c = Colony_manager.trial_provisioned,
            colony_obj_version__c = colony_obj_version,
            Colony_Plan__c = colony_manager.plan_trial,
            Colony_Suspended_Reason__c = '',
            Ignore_expiration_date__c = false,
            Colony_Plan_End_Date__c = trial_end_date            
            );
        insert trial_account;
                
        //find or create contact
        Contact contact = colony_manager.set_account_contact(contact_first_name, contact_last_name, contact_email, trial_account.id, account_name, phone, country ,state);
       
        //Set clone opportunity
        list<Opportunity> trial_opp = new list<Opportunity>([select id, Pricebook2.id, account.id, name, StageName from Opportunity 
                                                             Where name =: colony_manager.colony_trial_opportunity]);
        if(trial_opp.size() == 0)
        {
            Quali_services.open_support_ticket_via_email('SHOWSTOPPER SHOWSTOPPER SHOWSTOPPER FATAL Exception fail find "Colony Master Trial Account"!!!.', 
                                                         'Colony Salesforce API - create new trial account fail. make sure the "Colony Master Trial Account" is available');
            ex = new Salesforce_API_Exception(701, 'FATAL Exception fail find Colony_master_trial account!!!.');
            throw ex;
        }
        
        Opportunity new_trial_opp = trial_opp[0].clone(false,true,false,false);
        new_trial_opp.name = trial_account_name + ' Trial';
        new_trial_opp.AccountId = trial_account.id;
        new_trial_opp.Primary_Contact__c = contact.id;               
        new_trial_opp.CloseDate = Date.today();
        new_trial_opp.is_colony__c = true;        
        insert new_trial_opp;        
        
        system.debug('>>New Trial opportunity: ' +  new_trial_opp);       
        
        //Clone Opportunities Oli's
        list<opportunityLineitem> trial_olis = new list<opportunityLineitem>([select product2.name, opportunity.account.name, New_Renewal__c, TotalPrice, Line_Item_Start_Date__c,
                                                                              Support_Subscription_end_date__c, product2.family, Support_Subscription_calc_end_date__c,
                                                                              opportunity.account.Colony_id__c, opportunity.account.Colony_State__c, opportunity.account.Colony_Suspended_Reason__c,
                                                                              ProductCode, product2.id, Line_Item_Type__c, Quantity, Limit_Delta__c, Environment_1__c
                                                                              FROM opportunitylineitem where opportunityId =: trial_opp[0].id]);
        
        list<opportunityLineitem> new_trial_olis = new list<opportunityLineitem>();        
        opportunityLineitem new_oli;        
                
        for(opportunityLineitem oli: trial_olis)
        {
            new_oli = oli.clone(false,true,false,false);
            new_oli.OpportunityId = new_trial_opp.id;           
            new_oli.Line_Item_Start_Date__c = Date.today();
            new_oli.Support_Subscription_end_date__c = trial_end_date;
                        
            system.debug('>>source oli:' + oli);
            system.debug('>>new oli:' + new_oli );
            
            new_trial_olis.add(new_oli);
        }        
        integer retries = 3;
        while(true){
            try{
                insert new_trial_olis;
                break;
            }
            catch(Exception ex1){
                retries --;
                if(retries == 0){
                   throw ex1;
                }
                else{
                    Quali_services.wait(2000);
                }
            }
        }
        
        system.debug('>>insert new_trial_olis.');

        
        //Add contact to Campaign
        if (!String.isBlank(utm_campaign))
        {            
            try
            {
                //if contact alredy belong other campign
                list <CampaignMember> old_campaign = new list <CampaignMember>([select id from CampaignMember where contactid =: contact.id 
                                                                                AND Is_Primary_Campaign__c = true]);
                if(old_campaign.size() > 0)
                {
                    for(CampaignMember member : old_campaign)
                    {
                        member.Is_Primary_Campaign__c = false;
                    }
                    update old_campaign;
                    system.debug('>>set as non primary in ols campaigns');
                }
                
                list <campaign> campaign = new list <campaign>([select id from campaign where isactive = true AND name =: utm_campaign]);
                
                if(campaign.size() > 0)//such campaign exsits
                {
                    system.debug('>>Assign contact to campaign: ' + utm_campaign);
                    
                    CampaignMember member = new CampaignMember(                    
                        Is_Primary_Campaign__c = true,
                        contactid = contact.id,
                        campaignid = campaign[0].id 
                    );
                    insert member;
                    
                    contact.belong_to_campaign__c = true;
                    update contact;
                    
                    system.debug('>>Assign contact to campaign');
                }
                
            }
            catch (Exception e)
            {
                Quali_services.open_support_ticket_via_email('Colony, Error set contact to campaign','On register new account, - Error set the campaign,'
                                                             +'\nNew account:' + trial_account.name 
                                                             +'\nContact: ' + contact
                                                             +'\nCampaign: ' + utm_campaign  );
            }
            
            
        }      
        
        Account new_account = [Select name, Colony_Plan__c, colony_id__c , Colony_Plan_End_Date__c,Colony_Suspended_Reason__c,
                                         Is_Deleted__c, Is_Suspended__c,Ignore_expiration_date__c,
                                         (Select Limit_Delta__c, Code__c, Quantity__c From Cas_Products__r) 
                                         From Account Where id =: trial_account.id ];
        
        system.debug('>>new_account: ' + new_account);
        
        return new Colony_account_status_v2 (new_account);
                
    }
    
	@HttpGet    	
	global static list <Colony_Account_Status_V2> get_accounts()
    {
        list <account> accounts_list = new list<Account>();
        list <Colony_Account_Status_V2> cas_list = new list<Colony_Account_Status_V2>();
        
        list<string> private_accounts = new list<string>();
        private_accounts.add(Colony_manager.Colony_master);          
        
        String colony_id = RestContext.request.params.get('id');
        String state_filter = RestContext.request.params.get('state');
        String plan_filter = RestContext.request.params.get('plan');
        
        if(RestContext.request.params.size() > 0)
        {
            if(String.isEmpty(colony_id ) && String.isEmpty(state_filter ) && String.isEmpty(plan_filter ))
            {
                Throw new Salesforce_API_Exception(301, 'Get function supports only one of the following inputs: id, state, plan.' );     
            }
        } 
        
		//Get all accounts
        if(String.isEmpty(colony_id) && String.isEmpty(state_filter) && string.isEmpty(plan_filter))
        {
            system.debug('>>Before start for loop');
            system.debug('>>Limits.getHeapSize:'  + Limits.getHeapSize());           
            system.debug('>>Limits.getLimitCpuTime:'  + Limits.getLimitCpuTime());
            
            
            for(list<Account> accounts :[Select name, Colony_Plan__c, colony_id__c , Colony_Plan_End_Date__c,Colony_Suspended_Reason__c,
                                         Is_Deleted__c, Is_Suspended__c,Ignore_expiration_date__c,
                                         (Select Limit_Delta__c, Code__c, Quantity__c From Cas_Products__r) 
                                         From Account
                                         Where is_colony__c = true
                						 And name not in: private_accounts])
            {
                accounts_list.addAll(accounts);
            }
            
        }
         else if(!String.isEmpty(colony_id )) // this request has an id input
        {
            system.debug('>>Start Get_colony_accounts_v2, input parameters:'  + RestContext.request.params );
            List <Account> accounts =  new list <Account>([Select name, Colony_Plan__c, colony_id__c , Colony_Plan_End_Date__c,Colony_Suspended_Reason__c,
                                         Is_Deleted__c, Is_Suspended__c,Ignore_expiration_date__c,
                                         (Select Limit_Delta__c, Code__c, Quantity__c From Cas_Products__r) 
                                         From Account
                                         Where colony_id__c =: colony_id]);
			
            accounts_list.addall(accounts);
            
            
        }
        else //if(!String.isEmpty(plan_filter )) // this request has an plan input
        {
            system.debug('>>Start Get_colony_accounts_v2, input parameters:'  + RestContext.request.params );
            List <Account> accounts =  new list <Account>([Select name, Colony_Plan__c, colony_id__c , Colony_Plan_End_Date__c,Colony_Suspended_Reason__c,
                                         Is_Deleted__c, Is_Suspended__c,Ignore_expiration_date__c,
                                         (Select Limit_Delta__c, Code__c, Quantity__c From Cas_Products__r) 
                                         From Account
                                         Where Colony_Plan__c =: plan_filter AND (name not in: private_accounts) ]);
			
            accounts_list.addall(accounts);
            
        }
        
        system.debug('>>accounts_list: ' + accounts_list);
        
        for (Account account: accounts_list)
        {
            cas_list.add(new Colony_Account_Status_V2(account) );
        }
        return cas_list;
        
    }
    
    @HttpPut
    global static string Update_Account_event()
    {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
                
        String jsonInput = request.requestBody.toString().trim();
        system.debug('>>jsonInput' + jsonInput);
        
        Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(jsonInput);     
        
        string colony_id = m.get('colony_id').ToString();
        string event_type = m.get('event_type').ToString();
        
        List <account> account;
        string result;
        
        //validations
        {
            if (String.isBlank(colony_id))
            {                
                Throw new Salesforce_API_Exception (201,'ColonyID canno\'t be blank');
            }
            account = new list<Account> ([Select id, ownerid, Cloud_Provider__c, Colony_State__c From Account Where Colony_id__c =: colony_id]);
            if(account.size()==0)
            {
                Throw new Salesforce_API_Exception  (202,'No Account exsits with id: ' + colony_id);
            }
            if (String.isBlank(event_type))
            {
                Throw new Salesforce_API_Exception  (203,'event_type canno\'t be blank');
            }
            if(!colony_manager.colony_events.contains(event_type))
            {            
                Throw new Salesforce_API_Exception (204,'\'' + event_type + '\' is not legal event, supported events are: ' + colony_manager.colony_events);
            }
            if(account[0].Colony_State__c == colony_manager.deleted)
            {
                Throw new Salesforce_API_Exception (206, 'Edit this account is not legal - Account: '+  colony_id +  ' was deleted.');
            }
        }
        
        Map<string,Object> m2 = (Map<string,Object>)m.get('event_parameters');
        
        //Upgrade case - need to pass contact details
        if(event_type == colony_manager.event_upgrade)
        {            
            string first_name, last_name, contact_email, phone;
            
            try
            {
                first_name = m2.get('first_name').tostring();
                last_name = m2.get('last_name').tostring();
                contact_email = m2.get('email').tostring();
                phone = m2.get('phone').tostring();
                
            }
            catch(Exception ex)
            {
                Throw new Salesforce_API_Exception(206,'Request: upgarde - Error find requested method parameters, make sure your body request contains:first_name, last_name, email & phone.');
            }
            
            
            if(string.isBlank(contact_email))
            {
                Throw new Salesforce_API_Exception(207,'Email canno\'t be blank');
            }
            
                        
            Contact contact;
            list <Contact> account_contacts = [Select id,Ownerid from contact Where email =: contact_email limit 1];
            system.debug('>>event type = update, account_contacts:' + account_contacts);
            
            if(account_contacts.size() == 1)//contact alredy exsits;
            {
                contact = account_contacts[0];
            }
            else
            {
                contact = new Contact(
                Lastname = last_name,
                Firstname = first_name,
                AccountId = account[0].id,
                Email = contact_email);                        
                insert contact;                
            }
            
            Task task = new Task();            
            task.WhoId = contact.id;
            task.ownerid = account[0].ownerid;
            task.Subject = 'Connect';               
            task.status = 'In progress';
            task.description = 'Please connect with contact: ' + contact_email + ' , he might be your first Colony customer!';
            insert task;
            
            User owner = [select email,lastname,firstname from user where id =: account[0].ownerid];
            result = 'Upgarde request Task open for: ' + owner.firstname + ' ' +owner.lastname + ', task id: ' + task.id;
                
        }
        
        //cloud provider set
        else if(event_type == colony_manager.event_cloud_provider_set)
        {
            string provider;
            
            try
            {
                provider = m2.get('provider').tostring();                
            }
            catch(Exception ex)
            {
                Throw new Salesforce_API_Exception(221,'Request: upgarde - Error find requested method parameters, make sure your body request contains: provider.');
            }            
            
            system.debug('>>event type = cloud provider set, provider:' + provider);
            
            if(account[0].Cloud_Provider__c == null)
            {
                account[0].Cloud_Provider__c = datetime.now() + ' : ' + provider;            
            }
            
            account[0].Cloud_Provider__c += '\n' + datetime.now() + ' : ' + provider;
            account[0].Colony_State__c = 'Trial Active';
            update account;            
            
        }
        
        //remove account
        else if(event_type == colony_manager.event_remove_account || event_type == 'Remove Account')
        {
            account[0].colony_state__c = colony_manager.deleted;
            account[0].is_deleted__c = true;
            update account;
            
            result = 'Account colonoy state set to \'Deleted\'';            
        }
      
        //update account details 
        else if(event_type == colony_manager.event_update_account_details)
        {
            string new_name,url;
            result ='';
            
            for(string key : m2.KeySet())
            {
                if (key == 'name')
                {
                    new_name = m2.get('name').tostring();     
                    
                    if (string.isblank(new_name))
                    {               
                        result = 'Account name is empty - name remains';
                    }
                    else
                    {
                        list <account> exsting_accounts = new list<account>([Select id from Account where name =: new_name]);            
                        if(exsting_accounts.size() > 0)
                        {
                            response.statusCode = 401;
                            result += new_name + ' already in use pls select other name';                
                        }
                        else
                        {
                            account[0].name = new_name;
                            update account;
                            result += 'Account name set successfully to: \''+new_name+ +'\'';
                        }
                        
                    }
                }
                if(key == 'url')
                {
                    url = m2.get('url').tostring();
                    
                    if (string.isblank(url))
                    {               
                        result += '\nURL is empty - url remains';
                    }
                    else
                    {
                        result += '\nURL set';
                    }
                    
                }
            }
           
            
        }
        
        return result;
        
       
    }
    

}