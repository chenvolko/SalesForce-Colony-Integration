@isTest
public class Colony_TestClass_V2 
{    
    @isTest(SeeAllData=true)
    static void Create_new_account_and_contact()
    {   
        string account_name = 'this_is_sparta';
        string email = 'danis@mail.com';
        string colony_id = 'fdsfdsf32fef32df';
        
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
        
        //get the master opprtinuty plan        
        list <OpportunityLineItem> olis = new list<OpportunityLineItem>([Select productcode,Line_Item_Start_Date__c, Support_Subscription_calc_end_date__c,
                                                                         product2.family, product2.name
                                                                         From OpportunityLineItem where opportunity.name =: colony_manager.colony_trial_opportunity]); 
        

        
        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon', email ,'089899898','Israel','bahama','');        
        List <Colony_CAS_Product_DM_V2> products = cas.Products;
        
        system.debug('cas:' + cas);
        
        system.assertEquals(null, cas.Suspended_reason);
        system.assertEquals(false, cas.Is_suspended);
        system.assertEquals(false, cas.Is_deleted);
        system.assertEquals(colony_manager.plan_trial, cas.Plan_id);
        system.assertEquals(colony_id, cas.Colony_id);
        system.assertEquals(account_name, cas.Account_name);
        system.assertEquals(Date.today().addDays(30), cas.License_expiration_date);        
        system.assertEquals(1, cas.products.size());
        system.assertEquals('CO-AE', cas.products[0].product_code );
        
        Contact contact = [select id from contact where email =: email];
        list <OpportunityContactRole> contactRoles = new list <OpportunityContactRole>([select id from OpportunityContactRole 
                                                                                        Where contactid =: contact.id And isPrimary = true]);
        
        system.assertEquals(1, contactRoles.size());
        
    }    
    
    @isTest(SeeAllData=true)
    static void Create_new_colony_with_exsiting_contact()
    {
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
        
        Account account = [select id from account limit 1];        
        system.debug('original account:' + account);
        
        string contact_last_name  = 'vardi';
        string contact_first_name = 'amnon';
        string email = 'leeod@mai2l.com';
        string colony_id = '125434r313df5324f';
        
        Contact contact = new Contact(
                Lastname = contact_last_name,
                Firstname = contact_first_name,
                AccountId = account.id,
                Email = email,                
                Company__c  = 'company');
        
        insert contact;
        
        string account_name = 'this_is_sparta';
        string AE_product_code = 'CS-SBOX';
        integer initial_trial_AE_quantity = 5;
        
        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon', email ,'089899898','Israel','bahama','');        
        List <Colony_CAS_Product_DM_V2> products = cas.Products;
        system.debug('cas:' + cas);
        
        Account colony_account = [select id from account Where colony_id__c =: colony_id];
        system.debug('new colony_account account:' + account);
        
        list<AccountContactRelation> account_contact_relation = new list<AccountContactRelation>([select accountid, contactid From AccountContactRelation 
                                                                                                  Where contactid =: contact.id 
                                                                                                  And accountid =: colony_account.id]);
        
        system.assertEquals(1, account_contact_relation.size());
        
    }
        
    @isTest(SeeAllData=true)
    static void premium_to_team()
    {
        Quali_Automation__c quali_automation = [select Run_MRR__c, Run_MFS__c from Quali_Automation__c];
        quali_automation.Run_MRR__c = false;
        quali_automation.Run_MFS__c = false;
        update quali_automation;
            
        //1. create opportunity with team plan, 120 days perid 
        //2. add premium plan 60 days period
        
        
        //3.1 make sure plan is premium & period = 60 days 
        //4. remove the premium plan
        //4.1 make sure the plan is team and period = 120 days
        
        string account_name = 'account_name';
        string colony_id = '23r23f423534few234r';
        
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
                
        RestContext.request = req;
        RestContext.response= res;
        
        req.addParameter('id', colony_id);
        
        //create trial
        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon', 'dani.s@mail.com','089899898','Israel','bahama','');
        system.assertEquals(colony_manager.plan_trial, cas.Plan_id);
        
        //this call will update the Account object plan_id value
        Colony_Account_V2.Get_accounts();        
        
        //start permium opportunity creation
        Account account = [select id , Colony_Plan__c From Account Where colony_id__c =: colony_id];
        Contact contact = [select id From Contact Where accountid =: account.id];
                
                
        //create new opportunity                
        Opportunity o = new Opportunity
            (
                is_colony__c= true,
                Territory__c = 'N.America',
                Country__c = 'Brazil',
                Primary_Contact__c = contact.id,
                Name = 'test opportunity',            
                AccountID = account.id, 
                CloseDate = Date.newInstance(2017,8,23),                                    
                Type = 'New Business',          
                Forcast__c = 'Commit',
                CurrencyIsoCode = 'USD',
                Product_Category__c = 'Cloud',
                Net_Order_to_QualiSystems__c = 100000,
                Subscription_License_Amount__c = 100000,
                Priority__c = 'High',
                LeadSource = 'Web',                         
                StageName = 'Closed Won Approved'       
            );
        //create the Opportunity
        insert o;
                
        //Pricebook
        Pricebook2 pricebook = [select id, name From Pricebook2 where name =: colony_manager.colony_pricebook ];
        system.debug('>>pricebook:' + pricebook.name);
        
		string team_plan_product_code = Colony_manager.team_product_code;        
        
        //PricebookEntry - team plan
        PricebookEntry team_plan = [select id from PricebookEntry where Pricebook2Id =: pricebook.id And productcode =: team_plan_product_code limit 1];
        system.debug('>>PricebookEntry: ' + team_plan);
        
        //Create oli               
        system.debug('>>Start TEAM creation');   
        
        opportunityLineItem oli = new opportunityLineItem
            (        
                opportunityId = o.id,                        
                PricebookEntryId = team_plan.id,            
                UnitPrice=200,
                New_Renewal__c = 'New', 
                Line_Item_Start_Date__c = Date.today(),
                Support_Subscription_end_date__c = Date.today().adddays(120),
                Quantity = 1,
                Line_Item_Type__c  = 'Monthly Subscription'
                
        );
        
        insert oli;
        
        //Create premium  plan        
        string premium_plan_product_code = Colony_manager.premium_product_code;
        system.debug('>>premium_plan_product_code: ' + premium_plan_product_code);
                
        //PricebookEntry - Premium
        PricebookEntry premium_plan = [select id from PricebookEntry where Pricebook2Id =: pricebook.id 
                                       And productcode =: premium_plan_product_code limit 1];
        system.debug('>>PricebookEntry: ' + premium_plan);
        
        //Create oli               
        system.debug('>>Start primum creation');   
        
        opportunityLineItem oli2 = new opportunityLineItem
            (        
                opportunityId = o.id,                        
                PricebookEntryId = premium_plan.id,            
                UnitPrice=200,
                New_Renewal__c = 'New', 
                Line_Item_Start_Date__c = Date.today(),
                Support_Subscription_end_date__c = Date.today().adddays(60),
                Quantity = 2,
                Line_Item_Type__c  = 'Monthly Subscription'
        );
        
        insert oli2;
        system.debug('>>After insert oli2');
               
        List <Colony_account_status_v2 > cas_res = Colony_Account_V2.Get_accounts();        
        system.debug('>>cas_res res: ' + cas_res);
        system.assertEquals(colony_manager.plan_premium , cas_res[0].plan_id );        
		system.assertEquals(Date.today().adddays(60) , cas_res[0].License_expiration_date );        
        
        
        //delete the premium oli 
        delete oli2;
        
        cas_res = Colony_Account_V2.Get_accounts();        
        system.debug('>>after  delete premium - cas_res res: ' + cas_res);
        system.assertEquals(colony_manager.plan_team , cas_res[0].plan_id );        
        system.assertEquals(Date.today().adddays(120) , cas_res[0].License_expiration_date ); 
        
        account = [select id , Colony_Plan__c, Colony_Plan_End_Date__c From Account Where colony_id__c =: colony_id];
        system.assertEquals(account.Colony_Plan__c , colony_manager.plan_team);
        system.assertEquals(Date.today().adddays(120), account.Colony_Plan_End_Date__c);
       
    }
        
    @isTest(SeeAllData=true)
    static void trial_to_team()
    {
        //1. create trial 
        //2. add opportunity with Team product
        //3. cheack if the CAS planid =? TEAM
        
        string account_name = 'account_name';
        string colony_id = '23r23f423534few234r';
        
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
        
        //create trial
        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon', 'dani.s@mail.com','089899898','Israel','bahama','');
        system.assertEquals(colony_manager.plan_trial, cas.Plan_id);
                
        
        //start opportunity creation
        Account account = [select id From Account Where colony_id__c =: colony_id];
        Contact contact = [select id From Contact Where accountid =: account.id];
                
        //create new opportunity                
        Opportunity o = new Opportunity
            (
                is_colony__c = true,
                Territory__c = 'N.America',
                Country__c = 'Brazil',
                Primary_Contact__c = contact.id,
                Name = 'test opportunity',            
                AccountID = account.id, 
                CloseDate = Date.newInstance(2017,8,23),                                    
                Type = 'New Business',          
                Forcast__c = 'Commit',
                CurrencyIsoCode = 'USD',
                Product_Category__c = 'Cloud',
                Net_Order_to_QualiSystems__c = 100000,
                Subscription_License_Amount__c = 100000,
                Priority__c = 'High',
                LeadSource = 'Web',                         
                StageName = 'Closed Won Approved'       
            );          
        
        //create the Opportunity
        insert o;
        
        OpportunityContactRole ocr = new OpportunityContactRole
            (
                role = 'Evaluator',
                contactid = contact.id,
                opportunityid = o.id,
                isPrimary = True
            );
        insert ocr;
        system.debug('>>Insert Contact Role: ' + ocr);
        
        string team_plan_product_code = Colony_manager.team_product_code;
        system.debug('>>team_plan_product_code: ' + team_plan_product_code);
        
        Product2 p1 = [select id from product2 where productcode =: team_plan_product_code limit 1]; 
        system.debug('>>Insert Product sucsess: ' + p1);        
    
        //Pricebook
        Pricebook2 pricebook = [select id, name From Pricebook2 where name =: colony_manager.colony_pricebook ];
        system.debug('>>pricebook:' + pricebook.name);
        
        //PricebookEntry - Team plan
        PricebookEntry entry = [select id from PricebookEntry where Pricebook2Id =: pricebook.id And productcode =: team_plan_product_code limit 1];
        system.debug('>>PricebookEntry: ' + entry);                
        
        //Create Team Plan oli               
        system.debug('>>Start OLI creation');   
        
        Date year_from_now = Date.today().addyears(1);
        
        opportunityLineItem oli = new opportunityLineItem
            (        
                opportunityId = o.id,                        
                PricebookEntryId = entry.id,            
                UnitPrice=200,
                New_Renewal__c = 'New', 
                Line_Item_Start_Date__c = Date.today(),
                Support_Subscription_end_date__c = year_from_now,
                Quantity = 2,
                Line_Item_Type__c  = 'Monthly Subscription'
        );
        
        insert oli;
        
        RestRequest req = new RestRequest(); 
        RestContext.request = req;        
        req.addParameter('id', colony_id);
                
        system.debug('>>Before call to rest');        
        List <Colony_account_status_v2 > cas_res = Colony_Account_V2.Get_accounts();
        
        system.debug('>>colony_manager.plan_team: ' + colony_manager.plan_team);
        system.debug('>>cas_res res: ' + cas_res);
        system.assertEquals(colony_manager.plan_team , cas_res[0].plan_id );
        system.assertEquals(1,  cas_res.size());               
        
    }
    
    @isTest(SeeAllData=true)
    static void create_account_with_exsiting_colony_id()
    {
        string colony_id = '23454dddssd';
        string account_name = 'this_is_sparta';        
        
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
        
        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon', 'dani.s@mail.com','089899898','Israel','bahama','');        
        system.debug('>>After create first account');
        
        Test.Starttest();
        try
        {
            cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon', 'dani.s@mail.com','089899898','Israel','bahama','');        
        }
        catch (Salesforce_API_Exception ex)
        {
            system.debug('>>create_account_with_exsiting_colony_id exception: ' + ex.getMessage());
            system.assertEquals ('ErrorId: 101. Fail create account with colony_id: '+ colony_id +', This colony_id already exsits in Salesforce' , ex.getMessage());
            return;
        }
        Test.StopTest();
        system.assertEquals(account_name, cas.Account_name); //this line should failS
    }
    
    @isTest(SeeAllData=true)
    static void Get_accounts()
    {        
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
        
        string account_name = 'ShayKeren';
        string account_name2 = 'ShayKeren';
        
        string colony_id = '23454dddssd';
        string colony_id2 = '243454dddssd';
                       
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
                
        RestContext.request = req;
        RestContext.response= res;
        
        string account_1_plan = '';
        string account_2_plan = '';        
                
        Colony_Account_V2.Create_new_trial_accout(colony_id , account_name , 'dani', 'danon', 'dani.s@mail.com','089899898','Israel','bahama','');
        Colony_Account_V2.Create_new_trial_accout(colony_id2, account_name2 , 'dani', 'danon', 'dani2.s@mail.com','089899898','Israel','bahama','');
        
        list<Colony_account_status_v2> new_account_list = Colony_Account_V2.Get_accounts();
        for(Colony_account_status_v2 cas :new_account_list )
        {
            if(cas.Colony_id == colony_id)
            account_1_plan = cas.Plan_id;
            if(cas.Colony_id == colony_id2)
            account_2_plan = cas.Plan_id;
        }
            
        system.assertEquals(account_1_plan, 'TRIAL'); 
        system.assertEquals(account_2_plan, 'TRIAL');     
    }
    
    @isTest(SeeAllData=true)
    static void Get_single_account()
    {
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
        string account_name = 'this account name';
        string colony_id = '1234578456132';
                       
        RestRequest req = new RestRequest(); 
        req.addParameter('id', colony_id);
        RestContext.request = req;        
        
        list<Colony_account_status_v2> accounts = Colony_Account_V2.Get_accounts();
        system.assertEquals(0, accounts.size());
        
        Test.starttest();
        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon', 'dani.s@mail.com','089899898','Israel','bahama','');        
        accounts = Colony_Account_V2.Get_accounts();        
        Test.stopTest();
        
        system.debug('>>Get_single_account result: ' +  accounts);
        system.assertEquals(1, accounts.size());
        system.assertEquals(colony_id, accounts[0].Colony_id);   
        
    }
    
    
    @isTest(SeeAllData=true)
    static void Get_accounts_by_plan()
    {        
        Quali_Automation__c quali_automation = [select Run_MRR__c, Run_MFS__c from quali_automation__c limit 1];
        quali_automation.Run_MRR__c = false;
        update quali_automation;

        
        RestRequest req = new RestRequest();                         
        Test.starttest();                
        
        
        list <Account> colony_accounts = new list <Account>([select id, colony_id__c, Colony_Plan__c from Account where is_colony__c = true
                                                             And Colony_Plan__c = 'Trial' 
                                                             And Opportunities__c > 0 limit 1 ]);
        Account account;
        
        if(colony_accounts.size() == 0)
        {
            system.debug('>>No account found');
            return;
        }
        else {account = colony_accounts[0];}
        system.debug('>>Exsiting account: '  + account);
                
        
        //Add TEAM plan
        Opportunity opp = [select id from opportunity where accountid =: account.id];
    
        //Pricebook
        Pricebook2 pricebook = [select id, name From Pricebook2 where name =: colony_manager.colony_pricebook ];        
        
        //PricebookEntry
        PricebookEntry entry = [select id from PricebookEntry where Pricebook2Id =: pricebook.id And productcode =: colony_manager.team_product_code limit 1];
        
        //Create oli               
        system.debug('>>Start OLI creation');           
        opportunityLineItem oli = new opportunityLineItem
            (        
                opportunityId = opp.id,                        
                PricebookEntryId = entry.id,            
                UnitPrice=200,
                New_Renewal__c = 'New', 
                Line_Item_Start_Date__c = Date.today(),
                Support_Subscription_end_date__c = Date.today().addyears(1),
                Quantity = 1,
                Line_Item_Type__c  = 'Monthly Subscription'
        );
        
        insert oli;
        system.debug('>>Insert Team oli');
                
        
        req.addParameter('plan', Colony_Manager.plan_team);
        RestContext.request = req;
                
        //this call will save the new oli
        list <Colony_account_status_v2> accounts = Colony_Account_V2.Get_accounts();
        
        boolean found_account = false;
        
        for(Colony_account_status_v2 team_account : accounts)
        {
            if(team_account.Colony_id == account.colony_id__c)
            {
                system.assertEquals(Colony_Manager.plan_team ,team_account.plan_id);
                found_account = true;
            }
        }
        
        if(!found_account)
        {
            system.assertEquals('' ,account.id);//will always fail
        }
        Test.stopTest();

    }    
    
    @isTest(SeeAllData=true)
    static void Update_account_url()
    {
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
        string account_name = 'this account name2';
        string email = 'This.is@america.com2';
        string colony_id = '1234578456132';
        
        
        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon', email ,'089899898','Israel','bahama','');        
        
        RestRequest req = new RestRequest();
        req.httpMethod = 'PUT';        
        
        
        string input = '{'
        +'"colony_id": "'+colony_id+'",'
        +'"event_type": "'+colony_manager.event_update_account_details+'",'
        +'"event_parameters":{"name":"aws11"}'
        +'}';            
            
        req.requestBody = Blob.valueof(input);        
        RestContext.request = req;
        
        string res = Colony_Account_V2.Update_Account_event();
        
    }
    
    @isTest(SeeAllData=true)
    static void Update_account_cloud_provider()
    {
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
        string account_name = 'this account name2';
        string email = 'This.is@america.com2';
        string colony_id = '1234578456132';
        
        
        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon', email ,'089899898','Israel','bahama','');        
        
        RestRequest req = new RestRequest();
        req.httpMethod = 'PUT';        
        
        
        string input = '{'
        +'"colony_id": "'+colony_id+'",'
        +'"event_type": "'+colony_manager.event_cloud_provider_set+'",'
        +'"event_parameters":{"provider":"aws"}'
        +'}';            
            
        req.requestBody = Blob.valueof(input);        
        RestContext.request = req;
        
        string res = Colony_Account_V2.Update_Account_event();
        
    }
    
    @isTest(SeeAllData=true)
    static void Update_account_upgrade()
    {
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
        string account_name = 'this account name2';
        string email = 'This.is@america.com2';
        string colony_id = '1234578456132';
        
        
        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon', email ,'089899898','Israel','bahama','');        
        
        RestRequest req = new RestRequest();
        req.httpMethod = 'PUT';        
        
        
        string input = '{'
        +'"colony_id": "'+colony_id+'",'
        +'"event_type": "upgrade",'
        +'"event_parameters":{"first_name":"Donald","last_name": "Trump","email":"'+email+'","phone":"046536889"}'
        +'}';            
            
        req.requestBody = Blob.valueof(input);        
        RestContext.request = req;
        
        string expected = 'Upgarde request Task open for:';
        string res = Colony_Account_V2.Update_Account_event();
        system.assert(true, res.contains(expected));
                
        
    }
    
    @isTest(SeeAllData=true)
    static void Is_deleted()
    {
        //1. create account - make sure 'is deleted' = false
        //2. call to Update_Account_event - with 'remove account' event
        //3. get account - make sure 'is deleted' = true
        
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
        string account_name = 'this account name2';
        string email = 'This.is@america.com2';
        string colony_id = '1234578456132';
        
        
        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon', email ,'089899898','Israel','bahama','');        
        system.assertEquals( false, cas.Is_deleted);
        
        RestRequest req = new RestRequest();
        req.httpMethod = 'PUT';        
        
        string input = '{'
        +'"colony_id": "'+colony_id+'",'
        +'"event_type": "remove_account",'
        +'"event_parameters":{}'
        +'}';            
            
        req.requestBody = Blob.valueof(input);        
        RestContext.request = req;
                
        string expected = 'Account colonoy state set to \'Deleted\'';
        string res = Colony_Account_V2.Update_Account_event();
        system.assertEquals(expected, res);        
         
        req.addParameter('id', colony_id);         
        
        list<Colony_account_status_v2> accounts = Colony_Account_V2.Get_accounts();
        system.assertEquals(1, accounts.size());
        system.assertEquals(true, accounts[0].Is_deleted);
        
        
    }
    
    @isTest(SeeAllData=true)
    static void Is_suspended()
    {
        //1. create account - make sure 'Is_suspended' = false
        //2. Turn on the Is_suspended CB
        //3. get account - make sure 'Is_suspended' = true
        
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
        string account_name = 'this account name2';
        string email = 'This.is@america.com2';
        string colony_id = '1234578456132';
        
        
        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon', email ,'089899898','Israel','bahama','');        
        system.assertEquals( false, cas.Is_suspended);
        
        
        Account account = [select Is_suspended__c from account where colony_id__c =: colony_id];
        account.Is_suspended__c = true;
        update account;
        
        
        RestRequest req = new RestRequest();                        
        req.addParameter('id', colony_id);              
        RestContext.request = req;        
        
        
        list<Colony_account_status_v2> accounts = Colony_Account_V2.Get_accounts();
        system.assertEquals(1, accounts.size());
        system.assertEquals( true, accounts[0].Is_suspended);
        
    }
    
    @isTest(SeeAllData=true)
    static void move_contact_from_marketig()
    {
        //1.find Quali Marketing contact 
        //2. Create new colony account with the contact email
        //3. make sure the contact moved to the new contact
        
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
        
        Account marketing = [select id from Account Where name = 'Quali Marketing'];
        List <Contact> contacts = new list<contact>([select id, email from Contact where accountid =: marketing.id limit 1]);
        if(contacts.size() == 0 ){return;}
        string account_name = 'this account name';
        string colony_id = '1234578456132';
        RestRequest req = new RestRequest(); 
                        
        Test.starttest();                

        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon', contacts[0].email,'089899898','Israel','bahama','');                
        system.debug('>>New CAS: ' + cas);
        
        Contact new_contact = [select accountid, account.name from contact where email =: contacts[0].email];
        Account new_accounrt = [select id from Account where colony_id__c =: colony_id];
        
        system.debug('>>Assert both account is equal');
        system.assertEquals(new_contact.accountid, new_accounrt.id);
        
        list <AccountContactRelation> acrs = new list <AccountContactRelation> ([select id from AccountContactRelation where contactid =: contacts[0].id ]);
        system.assertEquals(1,acrs.size());
        
        
        Test.stopTest();              
        
    }
    static void new_contact_exclude_to_new_account()
    {
        //1.find Quali Marketing contact 
        //2. Create new colony account with the contact email
        //3. make sure the contact moved to the new contact
        Infra infra = new infra();
        infra.turnOffTriggers();

        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
        string colony_id = '1234578456132';
        Account colonyAccount = infra.createColonyAccount('test_new_contact_exclude_to_new_account',colony_id);                        
        Account marketing = [select id from Account Where name = 'Quali Marketing'];
        
        Contact contact = infra.createContact('move_contact_from_marketig',marketing.id);
        contact colonyContact = infra.createContact('excludeContact',colonyAccount.id);
        
        Test.starttest();                
        
        System.assertEquals(colonyAccount.id,colonyContact.accountid);
        
        Test.stopTest();              
        
    }
    @isTest(SeeAllData=true)
    static void assign_contact_to_campaign()
    {
        //1.Create trial with campain
        //2. make sure the contact has campaign member + the contact is primary
        
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
        
        string campaign_name;
        string account_name = 'this account name';
        string colony_id = '1234578456132';
        string email = 'not_real_mail_address@fake.col';
                       
        RestRequest req = new RestRequest(); 
        
        Campaign campaign = new Campaign(Name='Test_assign_contact_to_campaign', isactive =true);
        insert campaign;


        //list <Campaign> campaign =  new list <Campaign>([select id, name from campaign where isactive = true limit 1]);
        // if(campaign.size() == 0){return;}
        // system.debug('>>Found campaign: ' + campaign[0]);
                        
        Test.starttest();                
        
        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon',email ,'089899898','Israel','bahama',campaign.name);                
        system.debug('>>New CAS: ' + cas);
        
        Contact new_contact = [select id, accountid, account.name from contact where email =: email];
        
        CampaignMember member = [select Is_Primary_Campaign__c, campaignid from CampaignMember Where contactid =: new_contact.id];
        
        system.assertEquals(member.Is_Primary_Campaign__c,true);
        system.assertEquals(member.campaignid, campaign.id);
        Test.stopTest();               
        
    }
    
    @isTest(SeeAllData=true)
    static void Ignore_expiration_date()        
    {
        //1. Create Trial account - make sure:
        //1.1: cas.plan = Trial  && ignore expiration date  = false
        //1.2: account.colony_plan__c = Trial
        
        //2. Change the plan start date so it will be expierd, make sure
        //2.1: cas.Plan = FREEMIMUIM & Ignore expiration date  = true        
        
        //3. Change the plan start date back to today         
        //3.1: make sure: plan = Trial & Ignore_expiration_date = false
        
        
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
                
        string account_name = 'this account name';
        string colony_id = '1234578456132';
        string email = 'not_real_mail_address@fake.col'; 
        Date past_date = Date.today().addDays(-100); 
        
        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon',email ,'089899898','Israel','bahama','');        
        system.debug('>>New CAS: ' + cas);        
        system.assertEquals(cas.Plan_id , colony_manager.plan_trial );
        
        Account account = [select id,Colony_Plan__c From Account Where colony_id__c =: colony_id];
        system.assertEquals(colony_manager.plan_trial, account.colony_plan__c); 
        
        //2. set the plan start date
        Opportunity opp =  [select CloseDate from opportunity where accountid =: account.id];
        opp.CloseDate = past_date;
        update opp;
        
        OpportunityLineItem plan = [Select id, Line_Item_Start_Date__c from OpportunityLineItem Where account__c =: account.id 
                                    And product2.Family = 'Colony Plan'];
        
        system.debug('>>plan: ' + plan);        
                        
        plan.Line_Item_Start_Date__c = past_date;
        plan.Support_Subscription_end_date__c = past_date.addDays(30);
        update plan;
        
        Test.starttest();        
        RestRequest req = new RestRequest(); 
        req.addParameter('id', colony_id);              
        RestContext.request = req;     
        
        list<Colony_account_status_v2> accounts = Colony_Account_V2.Get_accounts();
        system.assertEquals(colony_manager.plan_freemium, accounts[0].plan_id );
        system.assertEquals(true, accounts[0].Ignore_expiration_date);
        
        account = [select Colony_Plan__c from Account where colony_id__c =: colony_id ];
        system.assertEquals(colony_manager.plan_freemium, account.colony_plan__c); 
        
        
        //3 change back start date to today
        plan.Line_Item_Start_Date__c = Date.today();
        plan.Support_Subscription_end_date__c = Date.today().addDays(30);
        update plan;
        
        accounts = Colony_Account_V2.Get_accounts();
        system.assertEquals(colony_manager.plan_trial, accounts[0].plan_id );
        system.assertEquals(false, accounts[0].Ignore_expiration_date);
        
        account = [select Colony_Plan__c from Account where colony_id__c =: colony_id ];
        system.assertEquals(colony_manager.plan_trial, account.colony_plan__c);        
        
        
        Test.stopTest();
        
    }
    
    
    @isTest(SeeAllData=true)
    static void aggragate_trials_plan_end_date()        
    {
        //Verify that API return the latest plan enddate         
        //1. Create Trial account - make sure:
        //1.1: cas.plan = Trial , End date is 30 days 
        //2. Create new Trial Opportunity where  endate > first plan end date 
        //2.1 Make sure the account enddate taken from the 2nd plan
      
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
                
        string account_name = 'this account name';
        string colony_id = '1234578456132';
        string email = 'not_real_mail_address@fake.col'; 
                
        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon',email ,'089899898','Israel','bahama','');        
        Account account = [select id from Account Where colony_id__c =: colony_id Limit 1];
        Contact con =  [Select id From Contact Where email =: email Limit 1];
        
        //created 2nd Opportunity
        Opportunity trial_opp = [select id, Pricebook2.id, account.id, name, StageName from Opportunity 
                                 Where name =: colony_manager.colony_trial_opportunity limit 1];
        
        Opportunity new_trial_opp = trial_opp.clone(false,true,false,false);
        new_trial_opp.name = 'extended opp';
        new_trial_opp.AccountId = account.id;
        new_trial_opp.Primary_Contact__c = con.id;               
        new_trial_opp.CloseDate = Date.today();
        new_trial_opp.is_colony__c = true;        
        insert new_trial_opp;        
        
        
        //Clone Opportunities Oli's
        list<opportunityLineitem> trial_olis = new list<opportunityLineitem>([select product2.name, opportunity.account.name, New_Renewal__c, TotalPrice, Line_Item_Start_Date__c,
                                                                              Support_Subscription_end_date__c, product2.family, Support_Subscription_calc_end_date__c,
                                                                              opportunity.account.Colony_id__c, opportunity.account.Colony_State__c, opportunity.account.Colony_Suspended_Reason__c,
                                                                              ProductCode, product2.id, Line_Item_Type__c, Quantity, Limit_Delta__c, Environment_1__c
                                                                              FROM opportunitylineitem 
                                                                              Where opportunityId =: trial_opp.id]);
        
        list<opportunityLineitem> new_trial_olis = new list<opportunityLineitem>();        
        
        Date trial_end_date = Date.today().adddays(60);
        
        for(opportunityLineitem oli: trial_olis)        
        {
            opportunityLineitem new_oli = oli.clone(false,true,false,false);
            new_oli.OpportunityId = new_trial_opp.id;           
            new_oli.Line_Item_Start_Date__c = Date.today();
            new_oli.Support_Subscription_end_date__c = trial_end_date;                     
                       
            system.debug('>>source oli:' + oli);
            system.debug('>>new oli:' + new_oli );
            
            new_trial_olis.add(new_oli);
        }
        
        insert new_trial_olis;
        list<opportunityLineitem> inserted_olis = new list<opportunityLineitem> ([select ProductCode, product2.name,Line_Item_Start_Date__c,Support_Subscription_end_date__c,Support_Subscription_calc_end_date__c 
                                                                                 From opportunityLineitem Where opportunityId =: new_trial_opp.id ]);
        system.debug('>>2nd new_trial_olis: ' + inserted_olis);
        
        RestRequest req = new RestRequest();                        
        req.addParameter('id', colony_id);              
        RestContext.request = req;        
                
        list<Colony_account_status_v2> accounts = Colony_Account_V2.Get_accounts();
        system.debug('>>aggragate_plan_end_date CAS: ' + accounts);
        system.assertEquals(1, accounts.size());
        system.assertEquals(trial_end_date, accounts[0].License_expiration_date);                       
        
    }
        
    @isTest(SeeAllData=true)
    static void concatinate_2_plans()        
    {
        //If an account has 2 concatinate plans , make sure the account end date would be the end of the longest plan
        //
        //1. Create Trial account - cas.plan = Trial , EndDate is 30 days 
        //2. Create new Opportunity with plan. the plan start date is 31 days from today and will last 60 days
        //2.1 Make sure the account enddate is 90 days period
      
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
                
        string account_name = 'this account name';
        string colony_id = '1234578456132';
        string email = 'not_real_mail_address@fake.col'; 
                
        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon',email ,'089899898','Israel','bahama','');        
        Account account = [select id from Account Where colony_id__c =: colony_id Limit 1];
        Contact con =  [Select id From Contact Where email =: email Limit 1];
        
        //created 2nd Opportunity        
        Date next_trial_start_date = Date.today().adddays(31);
        Date next_trial_end_date = next_trial_start_date.addDays(60);
        system.debug('>>next_trial_start_date: ' + next_trial_start_date + ', next_trial_end_date: ' + next_trial_end_date);
        
        Opportunity trial_opp = [select id, Pricebook2.id, account.id, name, StageName from Opportunity 
                                 Where name =: colony_manager.colony_trial_opportunity limit 1];
        
        Opportunity new_trial_opp = trial_opp.clone(false,true,false,false);
        new_trial_opp.name = 'extended opp';
        new_trial_opp.AccountId = account.id;
        new_trial_opp.Primary_Contact__c = con.id;               
        new_trial_opp.CloseDate = next_trial_start_date;
        new_trial_opp.is_colony__c = true;        
        insert new_trial_opp;        
        
        
        //Find Trial product and Clone it
        opportunityLineitem trial_oli = [select 
                                         product2.name,                                                                              
                                         OpportunityId,                                                                       
                                         Line_Item_Start_Date__c,
                                         Support_Subscription_end_date__c,                                             
                                         Quantity,
                                         New_Renewal__c,
                                         TotalPrice,
                                         Line_Item_Type__c
                                         FROM opportunitylineitem 
                                         Where opportunityId =: trial_opp.id And ProductCode = 'CO-TR' Limit 1
                                        ];
        
        opportunityLineitem new_oli = trial_oli.clone(false,true,false,false);
        new_oli.OpportunityId = new_trial_opp.id;           
        new_oli.Line_Item_Start_Date__c = next_trial_start_date;
        new_oli.Support_Subscription_end_date__c = next_trial_end_date;
                
        system.debug('>>new oli:' + new_oli );
        insert new_oli;
        system.debug('>>2nd new_trial_olis: ' + new_oli);
        
        RestRequest req = new RestRequest();                        
        req.addParameter('id', colony_id);              
        RestContext.request = req;        
                
        list<Colony_account_status_v2> accounts = Colony_Account_V2.Get_accounts();
        system.debug('>>concatinate_2_plans CAS: ' + accounts);
        system.assertEquals(1, accounts.size());
        system.assertEquals(next_trial_end_date, accounts[0].License_expiration_date);                       
        
    }
    
    @isTest(SeeAllData=true)
    static void concatenate_2_plans_one_is_future()        
    {
        //If an account has 2 concatinate plans as there is 'GAP' between them - we shuld ignore future plan 
        //
        //1. Create Trial account - cas.plan = Trial , EndDate is 30 days 
        //2. Create new Opportunity with plan. the plan start date is 40 days from today - there is 10 days Gap
        //2.1 The CAS result should be the enddate of the 1st plan
      
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
                
        string account_name = 'this account name';
        string colony_id = '1234578456132';
        string email = 'not_real_mail_address@fake.col'; 
                
        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon',email ,'089899898','Israel','bahama','');        
        Account account = [select id from Account Where colony_id__c =: colony_id Limit 1];
        Contact con =  [Select id From Contact Where email =: email Limit 1];
        
        //created 2nd Opportunity        
        
        Date next_trial_start_date = Date.today().adddays(40);
        Date next_trial_end_date = next_trial_start_date.addDays(60);
        system.debug('>>next_trial_start_date: ' + next_trial_start_date + ', next_trial_end_date: ' + next_trial_end_date);
        
        Opportunity trial_opp = [select id, Pricebook2.id, account.id, name, StageName from Opportunity 
                                 Where name =: colony_manager.colony_trial_opportunity limit 1];
        
        Opportunity new_trial_opp = trial_opp.clone(false,true,false,false);
        new_trial_opp.name = 'extended opp';
        new_trial_opp.AccountId = account.id;
        new_trial_opp.Primary_Contact__c = con.id;               
        new_trial_opp.CloseDate = next_trial_start_date;
        new_trial_opp.is_colony__c = true;        
        insert new_trial_opp;        
        
        
        //Find Trial product and Clone it
        opportunityLineitem trial_oli = [select 
                                         product2.name,                                                                              
                                         OpportunityId,                                                                       
                                         Line_Item_Start_Date__c,
                                         Support_Subscription_end_date__c,                                             
                                         Quantity,
                                         New_Renewal__c,
                                         TotalPrice,
                                         Line_Item_Type__c
                                         FROM opportunitylineitem 
                                         Where opportunityId =: trial_opp.id And ProductCode = 'CO-TR' Limit 1
                                        ];
        
        opportunityLineitem new_oli = trial_oli.clone(false,true,false,false);
        new_oli.OpportunityId = new_trial_opp.id;           
        new_oli.Line_Item_Start_Date__c = next_trial_start_date;
        new_oli.Support_Subscription_end_date__c = next_trial_end_date;
                
        //system.debug('>>new oli:' + new_oli );        
        insert new_oli;
        system.debug('>>2nd new_trial_olis: ' + new_oli);
        
        RestRequest req = new RestRequest();                        
        req.addParameter('id', colony_id);              
        RestContext.request = req;        
                
        list<Colony_account_status_v2> accounts = Colony_Account_V2.Get_accounts();
        system.debug('>>concatinate_2_plans CAS: ' + accounts);
        system.assertEquals(1, accounts.size());
        system.assertEquals(Date.today().adddays(30), accounts[0].License_expiration_date);
        
    }
    
    
    @isTest(SeeAllData=true)
    static void make_sure_scheduler_change_plan()        
    {
        //If an account has 2 concatinate plans , make sure the account end date would be the end of the longest plan
               
      
        Test.setMock(HttpCalloutMock.class, new Zendesk_sync_HTTP_mocker());
                
        string account_name = 'this account name';
        string colony_id = '1234578456132';
        string email = 'not_real_mail_address@fake.col'; 
        
        Date this_date = Date.today();
        Date start_date = this_date.addDays(-60);
        Date end_date = this_date.addDays(-30);
                
        Colony_account_status_v2 cas = Colony_Account_V2.Create_new_trial_accout(colony_id, account_name , 'dani', 'danon',email ,'089899898','Israel','bahama','');        
        Account account = [select id, Colony_Plan__c, Colony_Plan_End_Date__c from Account Where colony_id__c =: colony_id ];
        Contact con =  [Select id From Contact Where email =: email Limit 1];
        
        system.assertEquals(Colony_Manager.plan_trial, account.Colony_Plan__c);
        system.debug('>>Account 1: ' + account);
                
                
        //Find Trial oli
        opportunityLineitem plan_oli = [select Line_Item_Start_Date__c, Support_Subscription_end_date__c
                                        From opportunitylineitem 
                                        Where opportunity.accountId =: account.id
                                        And ProductCode = 'CO-TR' Limit 1
                                        ];
        
        
        plan_oli.Line_Item_Start_Date__c = start_date; 
        plan_oli.Support_Subscription_end_date__c = end_date;
        update plan_oli; //that will run the colony trigger and will change plan to FREEMIUM
        
        account = [select id, Colony_Plan_End_Date__c, Colony_Plan__c from Account Where colony_id__c =: colony_id ];
        system.debug('>>Account 2: ' + account);
        
        account.Colony_Plan_End_Date__c = this_date.addDays(-1);//force the plan end date to be 'expierd' yesterday
        account.Colony_Plan__c = Colony_Manager.plan_trial;// make sure the plan value remain Trial
        update account;
               
        RestRequest req = new RestRequest(); 
        RestContext.request = req;
        req.addParameter('id', colony_id);
        
        //verify the account plan is indeed yesterday
		List <Colony_account_status_v2 > cas_res = Colony_Account_V2.Get_accounts();
        system.assertEquals(this_date.addDays(-1) , cas_res[0].License_expiration_date );
        system.assertEquals(Colony_Manager.plan_trial , cas_res[0].Plan_id );
              
        
        //The daily scheduler should find that this account epierd yesterday and update the account plan
        Colony_daily_scheduler cs = new Colony_daily_scheduler();
        cs.execute(null);     
        
               
        account = [select id, Colony_Plan_End_Date__c, Colony_Plan__c from Account Where colony_id__c =: colony_id ]; 
        system.debug('>>Account 3' + account);
        system.assertEquals(Colony_Manager.plan_freemium, account.Colony_Plan__c);                     
        
    }
    

}