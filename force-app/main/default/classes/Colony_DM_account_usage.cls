public class Colony_DM_account_usage
{    
    public Integer count;
    public String next, previous;

    public AccountUsage[] accounts_usage;
    public class AccountUsage{
        public string colony_id;
    	public integer active_environment_usage;    	
    }
        
    public static Colony_DM_account_usage parse(String jsonString) 
    {
        return (Colony_DM_account_usage)JSON.deserialize(jsonString, Colony_DM_account_usage.class);
    }

}