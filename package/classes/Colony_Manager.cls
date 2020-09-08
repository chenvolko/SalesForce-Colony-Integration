public class Colony_Manager 
{
    public static boolean debug = true;
    
    final public static string trial_provisioned = 'Trial Provisioned';
    final public static string trial_active = 'Trial Active';    
    final public static string free = 'Free';
    final public static string paying_basic = 'Paying Basic';
    final public static string paying_premium = 'Paying Premium';
    final public static string suspended = 'Suspended';
    final public static string deleted = 'Deleted';
    final public static list<String> colony_states = new list<String> {trial_provisioned,trial_active, free, paying_basic, paying_premium, suspended, deleted};
    
    final public static string event_upgrade = 'upgrade';
    final public static string event_cloud_provider_set = 'cloud_provider_set';
    final public static string event_remove_account = 'remove_account';       
    final public static string event_update_account_details = 'update_account_details';
    final public static list<String> colony_events = new list<String> {event_upgrade, event_cloud_provider_set,event_remove_account,event_update_account_details ,'Remove Account'};
    
    final public static string colony_master = 'Colony Master Trial Account';
    final public static string colony_trial_opportunity = 'Colony Trial';        
        
    final public static string end_user_role = 'End User';
    final public static string administrator_role = 'Administrator';
    
    final public static string plan_trial = 'TRIAL';
    final public static string plan_freemium = 'FREEMIUM';
    final public static string plan_team = 'TEAM';
    final public static string plan_premium = 'PREMIUM';
    
    final private static string colony_plan_family = 'Colony Plan';
    
    static integer x_go_to_freemuim;
    static integer y_freemium_period;
    
    
    final public static string trial_product_code  = 'CO-TR';
    final public static string team_product_code  = 'CO-TM';
    final public static string premium_product_code  = 'CO-PR';
    final public static string ae_product_code  = 'CO-AE'; 
	final public static list<String> plans_product_codes_list = new list<String> {trial_product_code,team_product_code,premium_product_code};
        
    final public static string colony_pricebook = 'Colony 2019';
    
        
    
    //V3 - Get list of olis and store them as Cas_producs
    public static void aggregate_olis_to_CAS_products(string accountid, List<OpportunityLineItem> olis)
    {
        system.debug('>>start aggregate_olis_to_CAS_products');
        
        colony_API_settings__c colony_configuration = colony_API_settings__c.getvalues('Colony configuration');
        x_go_to_freemuim = colony_configuration.grace_days__c.IntValue();
        y_freemium_period = colony_configuration.freemium_period__c.IntValue();        
        system.debug('>>colony api configuration: x_go_to_freemuim: '+ x_go_to_freemuim + ', y_freemium_period:' + y_freemium_period);
        
        if(olis.size() == 0){return;}
        
                
        //calculate the plan
        Colony_Plan plan = calculate_cas_expiration(olis);
        system.debug('>>CAS Colony_Plan result: ' + plan); 
                     
        if(plan == null)
        {
            Quali_services.open_support_ticket_via_email('Error: Colony-Salesforce API, aggregate olis to CAS products', 
                                                        'Account: ' + accountid +
                                                         '\nColony_Plan result: ' + plan +
                                                        '\nfunction input: ' + olis);
            return;
            
        }
        
        //update account if needed
        Account account = [Select Colony_Plan__c, Colony_Plan_End_Date__c, Ignore_expiration_date__c 
                           From Account Where id =: accountid];
        
        system.debug('>>current account params: ' + account);
        
        if (account.Colony_Plan__c != plan.Plan || 
            account.Colony_Plan_End_Date__c != plan.Plan_end_date|| 
            account.Ignore_expiration_date__c != plan.Ignore_expiration_date)
            {
                system.debug('>>Update the account with the new plan parameters ,plan: '+plan.plan + 
                             ' plan.Plan_end_date: ' + plan.Plan_end_date +
                             'plan.Ignore_expiration_date: ' + plan.Ignore_expiration_date); 
                             
                
                account.Colony_Plan__c = plan.Plan;
            	account.Colony_Plan_End_Date__c = plan.Plan_end_date;
            	account.Ignore_expiration_date__c = plan.Ignore_expiration_date;
                update account;
            }
        
        system.debug('>>Aggragate the products');        
        List<Cas_Product__c> products = new list<Cas_Product__c>();
        
        
        //3. Cretae <productcode map,olis> map --> product_code, list <olis>
        map<string,list<Opportunitylineitem>> account_products_map = new map<string,list<Opportunitylineitem>>();
        
        for(Opportunitylineitem oli : olis)
        {
            if(oli.product2.family == colony_plan_family )
            {
                continue;
            }
            
            if(!account_products_map.containsKey(oli.ProductCode))
            {
                list<Opportunitylineitem> accout_olis = new list<Opportunitylineitem>();
                accout_olis.add(oli);
                account_products_map.put(oli.ProductCode, accout_olis);
            }
            else
            {
                account_products_map.get(oli.ProductCode).add(oli);
            }
        }
        system.debug('>>account_products_map' + account_products_map);
        
        
        //4. create products list
        for(string product_code : account_products_map.KeySet())
        {
            Cas_Product__c product = new Cas_Product__c();
            product.account__c  = accountid;
            
            boolean cas_product_created;
            cas_product_created = false;
            
            for(Opportunitylineitem oli : account_products_map.get(product_code))
            {   
                system.debug('>>create product list - current oli:' + oli + '\nCurrent Product: ' + product);
                                
                if(!cas_product_created)
                {
                    product.Code__c = product_code;
                    product.name =  product_code;
                    product.Quantity__c = oli.quantity == null ? 0 : oli.quantity.IntValue();
                    product.Limit_Delta__c = oli.Limit_Delta__c == null ? 0 : oli.Limit_Delta__c.IntValue(); 
                    
                    system.debug('>>product created product.Quantity__c: ' + product.Quantity__c);                    
                    cas_product_created = true;
                }
                else //cas_product alredy exsits
                {
                    system.debug('>>product alredy exsits, ' + oli.quantity);
                    
                    if(oli.quantity != null)
                    {
                        product.Quantity__c += oli.Quantity.IntValue();
                        system.debug('>>new product quntity: ' +product.Quantity__c);
                    }
                    if(oli.Limit_Delta__c != null)
                    {
                        product.Limit_Delta__c =  Math.max(oli.Limit_Delta__c.IntValue(), product.Limit_Delta__c);                               
                    }
                    
                }
                
            }
            products.add(product);
        }
        
        system.debug('>>create product list:' + products);
        insert products;        
        
    }
    
    public static string find_avaliable_account_name(string account_name)
    {
        string suggesst_name = account_name;
        boolean name_is_busy = true;
        string base_name;
        
        List<Account> accounts = new List<Account>([Select name From Account Where name =: suggesst_name]); 
        if(accounts.size() == 0)
        {
            return suggesst_name; 
        }
        else
        {
            base_name = suggesst_name;
            
            while(name_is_busy)
            {
                suggesst_name += '_' + generateRandomString(5);
                
                accounts = new List<Account>([select name from Account where name =: suggesst_name]); 
                
                if(accounts.size() == 0)
                {
                    name_is_busy = false;                    
                }
                else
                {
                    suggesst_name = base_name;
                }                
            }            
            return suggesst_name;
        }
        
    }
    
    //Create colony admin contact or find exsiting
    public static Contact set_account_contact(string contact_first_name, string contact_last_name, string contact_email, id account_id, string company_name,
                                              string phone, string country, string state)
    {
        
        Quali_Automation__c quali_automation = Quali_Automation__c.getvalues('Quali SF Automation');    
        system.debug('>>quali_automation quali_marketing_id__c: ' +  quali_automation.quali_marketing_id__c);
        string Colony_marketing_account_id = quali_automation.quali_marketing_id__c;

        
        List<Lead> leads = new list<Lead>([select name, email from Lead Where email =: contact_email]);
        //Set Contact
        List<Contact> contacts = new list<Contact>([select name, email, colony_Role__c, Colony_Account_Reference__c, accountid, account.Customer_Support_Subscription_active__c From Contact where email =: contact_email]);
        
        system.debug('>>set_account_contact: contact ' + contacts);
        
        if(contacts.size() == 0 && leads.size() > 0) //convert the lead (Lead exists)
        {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leads[0].id);
            lc.setAccountId(account_id);
            
            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
            lc.setConvertedStatus(convertStatus.MasterLabel);            
            system.debug('>>convertStatus '+ convertStatus);
            
            lc.setDoNotCreateOpportunity(true);
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            
            system.debug('>>lead convert res:' + lcr);
            System.assert(lcr.isSuccess());
            system.debug('>>lcr new contact id: '+  lcr.getContactId() );
            
            contacts = new list<Contact>([select name, email, colony_Role__c, Colony_Account_Reference__c, accountid, 
                                          account.Customer_Support_Subscription_active__c From Contact 
                                          where id =: lcr.getContactId() ]);
            return contacts[0];
        }
        
        //Contact does not exists
        else if(contacts.size() == 0)
        {
            contacts.add(new Contact(
                Lastname = contact_last_name,
                Firstname = contact_first_name,
                AccountId = account_id,
                Email = contact_email,
                Colony_Role__c = administrator_role,
                Company__c  = company_name));
                        
            insert contacts;
            system.debug('>>After create new contact, id: ' + contacts[0].id);
            return contacts[0];
        }
        //Contact exists on quali marketing
        else if(contacts[0].accountid == Colony_marketing_account_id)
        {
            system.debug('>>Contact exsits in Quali marekting');
            contacts[0].accountid = account_id;
            update contacts[0];            
            
            //remove entry from AccountContactRelation 
            list<AccountContactRelation> acrs = new list<AccountContactRelation>([select id from AccountContactRelation
                                                                                  Where AccountId =: Colony_marketing_account_id 
                                                                                  and contactid =: contacts[0].id]);
            if (acrs.size() > 0 ){delete acrs; }
            
            return contacts[0];
            
        }
        else 
        {
            AccountContactRelation account_contact_relation = new AccountContactRelation();
            account_contact_relation.AccountId = account_id;
            account_contact_relation.contactid = contacts[0].id;                
            insert account_contact_relation;
            
            contacts[0].Colony_Role__c = administrator_role;
            update contacts[0];
            
            return contacts[0];            
            
        }
        
    } 
    
    //This methos get *sorted* olis list order by the oli start date -
    //all the olis belong to the same plan
    private static Colony_Plan aggragate_account_olis_by_plan (list<Opportunitylineitem> plan_olis_input, string plan)
    {
        system.debug('>>Start aggragate_account_olis_by_plan: ' + plan + ' plan_olis_input: ' + plan_olis_input);
        list<Opportunitylineitem> plan_olis = new list<Opportunitylineitem>();
        
        //filter the relevent olis
        for (Opportunitylineitem oli : plan_olis_input)
        {
            system.debug('>>aggragate_account_olis_by_plan oli: ' + oli);
            
            //there is one active oli
            if(Date.today() >= oli.Line_Item_Start_Date__c && Date.today() <= oli.Support_Subscription_calc_end_date__c )
            {
                system.debug('>>found active oli: ' +  oli);
                
                plan_olis = new list<Opportunitylineitem>();
                plan_olis.add(oli);
                
            }//future oli + there is one active oli
            if(Date.today() <= oli.Support_Subscription_calc_end_date__c && plan_olis.size() > 0 )
            {
                //system.debug('>>concatinate oli: ' +  oli);
                plan_olis.add(oli);
            }            
        }
        if(plan_olis.size() == 0) 
        {
            system.debug('>>Aggragate_account_olis_by_plan for no active plan for plan: ' +  plan);
            return null;
        }
        
        system.debug('>>Found active plan for plan: ' + plan  + ' plan_olis:' +plan_olis);
        
        //build the end date (in case we have at least 1 active plan)        
        Date plan_end_date = null;
        
        for (Opportunitylineitem oli : plan_olis)
        {
            if(plan_end_date == null)
            {
                plan_end_date = oli.Support_Subscription_calc_end_date__c;
            }
            else
            {
                if(plan_end_date < oli.Support_Subscription_calc_end_date__c &&
                   oli.Line_Item_Start_Date__c <= plan_end_date.addDays(1)
                  )
                {
                    plan_end_date = oli.Support_Subscription_calc_end_date__c;
                }
                
            }
        }
        
        Colony_Plan result = new Colony_Plan();
        result.plan = plan;
        result.plan_end_date = plan_end_date;
        result.Ignore_expiration_date = false;
        
        system.debug('>>Colony_Plan res: ' + result);
        
        return result;
        
            
   }
	
    //this function get SORTED list of olis order by oli.startdate and return Colony plan obj
    //return null if no plan found 
    private static Colony_Plan calculate_cas_expiration(list<Opportunitylineitem> account_olis)
    {
        system.debug('>>start calculate_cas_expiration, olis: ' + account_olis);
        
        Colony_Plan colony_plan_res;
        
        list <Opportunitylineitem> preemuim_plan_olis = new list<Opportunitylineitem>();
        list <Opportunitylineitem> team_plan_olis = new list<Opportunitylineitem>();
        list <Opportunitylineitem> trial_plan_olis = new list<Opportunitylineitem>();        
        
        Date today = Date.today();       
        
        //seek for plan product
        for(Opportunitylineitem oli : account_olis)
        {
            if(oli.product2.family == colony_plan_family)
            {
                system.debug('>>oli ' +oli.product2.name +' is plan');
                
                string oli_plan = get_oli_plan(oli);
                if(oli_plan == null)
                {
                    Throw new Salesforce_API_Exception(401,'Plan belongs to colony_plan_family but product code is not one of the legal plans codes (CO-TR , CO-TM, CO-PR)'
                                                    +'\naccountid: ' + oli.opportunity.accountid);
                }
				
                if(oli_plan == plan_premium)
                {
                    preemuim_plan_olis.add(oli);
                }
                else if(oli_plan == plan_team)
                {
                    team_plan_olis.add(oli);
                }
                else if(oli_plan == plan_trial)
                {
                    trial_plan_olis.add(oli);
                }               
                
            }
                
        }//end of for
        system.debug('>>preemuim_plan_olis: ' +preemuim_plan_olis);
        system.debug('>>team_plan_olis: ' + team_plan_olis);
        system.debug('>>trial_plan_olis: ' + trial_plan_olis);
        
        if(preemuim_plan_olis.size() > 0)
        {
            system.debug('>>preemuim_plan_olis.size() > 0');
            colony_plan_res = aggragate_account_olis_by_plan(preemuim_plan_olis, plan_premium);
            
            system.debug('>>premium colony_plan_res:' + colony_plan_res);            
            
            if(colony_plan_res != null)
            {                
                return colony_plan_res;
            }
                
        }
        if(team_plan_olis.size() > 0)
        {
            system.debug('>>team_plan_olis.size() > 0');
            colony_plan_res = aggragate_account_olis_by_plan(team_plan_olis, plan_team);
            
            system.debug('>>team colony_plan_res:' + colony_plan_res);
            if(colony_plan_res != null)
            {                
                return colony_plan_res;
            }
        }
        if(trial_plan_olis.size() > 0)
        {
            system.debug('>>trial_plan_olis.size() > 0');
            colony_plan_res = aggragate_account_olis_by_plan(trial_plan_olis, plan_trial);
            
            system.debug('>>trial colony_plan_res:' + colony_plan_res);
            if(colony_plan_res != null)
            {
                return colony_plan_res;
            }        
        }
       
        //if we here - no active plan found - we should return the latest plan 
        {
            system.debug('>>No active plans found');            
            OpportunityLineItem lateset_not_active_plan = null;
            
            //get lasteset not active plan
            for(OpportunityLineItem oli : account_olis)
            {
                if(oli.product2.family != colony_plan_family)
                {
                    continue;
                }
                
                if(lateset_not_active_plan == null)
                {
                    lateset_not_active_plan = oli;
                }
                else if (oli.Support_Subscription_calc_end_date__c > lateset_not_active_plan.Support_Subscription_calc_end_date__c)
                {
                    lateset_not_active_plan = oli;
                }
            }
            
            system.debug('>>lateset_not_active_plan: ' + lateset_not_active_plan);
            
            //this account has at least one non active plan            
            if(lateset_not_active_plan != null)
            {
                colony_plan_res = new Colony_Plan();
                
                Integer num_of_days_between_today = (lateset_not_active_plan.Support_Subscription_calc_end_date__c).daysBetween(Date.valueOf(date.today()));
                system.debug('>>num_of_days_between_today:' + num_of_days_between_today);                
                
                if(num_of_days_between_today > x_go_to_freemuim)
                {
                    if(num_of_days_between_today >  y_freemium_period)//when to kill the freemuim plan - account expierd
                    {                        
                        string plan = get_oli_plan(lateset_not_active_plan);
                        colony_plan_res.plan = plan;
                        colony_plan_res.plan_end_date = lateset_not_active_plan.Support_Subscription_calc_end_date__c;
                        colony_plan_res.Ignore_expiration_date = false;                        
                    }
                    else //we support freemuim when account trial expierd
                    {
                        colony_plan_res.plan = plan_freemium;
                        colony_plan_res.Ignore_expiration_date = true;
                        colony_plan_res.plan_end_date = lateset_not_active_plan.Support_Subscription_calc_end_date__c;
                    }
                }
                else //plan expreation reached + we dont extend the plan anymore
                {
                    string plan = get_oli_plan(lateset_not_active_plan);
                    colony_plan_res.plan = plan;
                    colony_plan_res.plan_end_date = lateset_not_active_plan.Support_Subscription_calc_end_date__c;
                    colony_plan_res.Ignore_expiration_date = false;                    
                }                
                system.debug('>>No Active plans - colony_plan_res:' + colony_plan_res);
                return colony_plan_res;
                
            }//we shold never reach here
            else
            {
                return null;
            }
            
        }
        
    }
    
    
    //return null if the oli is not plan product
    private static string get_oli_plan(Opportunitylineitem oli)
    {
        system.debug('>>start get_oli_plan result for:' + oli); 
        string result_plan='';    
        
        
        if(!plans_product_codes_list.contains(oli.ProductCode))
        {
            return null;
        }        
        
        if(oli.ProductCode == trial_product_code )
        {
            result_plan = plan_trial;
        }
        else if(oli.ProductCode == team_product_code)
        {
            result_plan = plan_team;
        }
        else if(oli.ProductCode == premium_product_code)        
        {
            result_plan = plan_premium;
        }
        
        system.debug('>>get_oli_plan result: ' + result_plan + ', input oli: ' + oli); 
        
        return result_plan;
    }        
 
    
    private static String generateRandomString(Integer len)
    {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
    
    
   

}