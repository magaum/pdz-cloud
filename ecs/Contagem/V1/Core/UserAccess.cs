namespace Contagem.V1.Core
{
    public class UserAccess
    {
        public UserAccess() { }

        public UserAccess(string username)
        {
            Username = username;
        }

        public string Username { get; private set; } = "anonymous";

        public int Access { get; set; } = 1;
    }
}
