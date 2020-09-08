public class Colony_DM_contact_V2
{
    public Integer count;
    public String next, previous;
    public string colony_id;
    public Contact[] Contacts;
    public class Contact{
        public string first_name;
    	public string last_name;
    	public string email;
    	public string phone;
    	public string role;        
    }
        
    public static Colony_DM_contact_V2 parse(String jsonString) 
    {
        return (Colony_DM_contact_V2)JSON.deserialize(jsonString, Colony_DM_contact_V2.class);
    }
}