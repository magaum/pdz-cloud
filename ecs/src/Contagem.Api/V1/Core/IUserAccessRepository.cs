using Amazon.DynamoDBv2.Model;
using System.Threading.Tasks;

namespace Contagem.V1.Core
{
    //TODO improve
    public interface IUserAccessRepository
    {
        Task<GetItemResponse> GetByUsername(string username);

        Task<PutItemResponse> Insert(UserAccess access);

        Task<UpdateItemResponse> UpdateTotalAccess(UserAccess access);
    }
}
