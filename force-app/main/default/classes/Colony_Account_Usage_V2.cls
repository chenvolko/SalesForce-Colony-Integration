@RestResource(urlMapping='/ColonyAccountUsage/*')
global class Colony_Account_Usage_V2
{    
    @HttpPost
	global static string update_accounts_usage()
    {   
        //Map<id,Account> colony_ids = new map<id,Account>([select id, colony_id__c From Account Where Is_Colony__c = true]);        
        //system.debug('>>accounts id map:' + colony_ids);
        
        system.debug('>>start update_accounts_usage');
        string result;
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        
        String jsonInput = request.requestBody.toString().trim();
        system.debug('>>jsonInput' + jsonInput);
        List<Colony_Account_Usage__c> accounts_to_update = new list<Colony_Account_Usage__c>();
        
        Colony_DM_account_usage r = Colony_DM_account_usage.parse(jsonInput);
        
        Account account;
        
        for(Colony_DM_account_usage.AccountUsage usage : r.accounts_usage)
        {
            account = [select id from Account Where colony_id__c =: usage.colony_id];
            
            Colony_Account_Usage__c temp_usage = new Colony_Account_Usage__c();
            temp_usage.Number_Of_Active_Environment__c = usage.active_environment_usage;
            temp_usage.Account__c = account.id;
            accounts_to_update.add(temp_usage);
            
        }
        
        insert accounts_to_update;
        
        
        return result;
     
    }

}