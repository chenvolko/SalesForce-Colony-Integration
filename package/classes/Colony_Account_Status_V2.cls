global class Colony_Account_Status_V2
{
    public Colony_Account_Status_V2(){}
    public Colony_Account_Status_V2(Account account)
    {
        this.Colony_id = account.colony_id__c;
        this.Account_name = account.name;
        this.Plan_id = account.Colony_Plan__c;
        this.Suspended_reason = account.Colony_Suspended_Reason__c;
        this.Is_deleted = account.Is_Deleted__c;
        this.Is_suspended = account.Is_Suspended__c;
        this.Ignore_expiration_date = account.Ignore_expiration_date__c;     
        this.License_expiration_date = account.Colony_Plan_End_Date__c;
        
        list<Colony_CAS_Product_DM_V2> products = new list<Colony_CAS_Product_DM_V2>();
        
        for(CAS_product__c cas : account.Cas_Products__r)
        {
            products.add(new Colony_CAS_Product_DM_V2(cas));
        }        
        this.Products = products;        
                
    }
    
    
    public string Colony_id;//uqniqe id    
    public string Account_name;//account name in Salesforce        
    public string Plan_id;//TRIAL, FREEMIUM,  TEAM,  PREMIUM   
    public list<Colony_CAS_Product_DM_V2> Products;
    public string Suspended_reason; 
    public boolean Is_deleted;
    public boolean Is_suspended;
    public boolean Ignore_expiration_date;
    public Date License_expiration_date;    
}