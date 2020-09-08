public class Colony_CAS_Product_DM_V2 
{
    public Colony_CAS_Product_DM_V2(){}
    
    public Colony_CAS_Product_DM_V2(CAS_product__c cas)
    {
        this.product_code = cas.Code__c;
        this.quantity = cas.Quantity__c.intValue();
        this.delta_limit = cas.Limit_Delta__c.intValue();
    }
    
    public string product_code;
    public integer quantity;
    public integer delta_limit;            
    
    
}