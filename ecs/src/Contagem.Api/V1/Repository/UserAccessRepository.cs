using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Contagem.Common;
using Contagem.V1.Core;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Contagem.V1.Repository
{
    public class UserAccessRepository : IUserAccessRepository
    {
        private readonly AmazonDynamoDBClient _client;
        private readonly string TABLE_NAME;

        public UserAccessRepository(AmazonDynamoDBClient client)
        {
            TABLE_NAME = Environment.GetEnvironmentVariable(CustomEnvironmentVariables.TABLE_NAME);
            _client = client;
        }

        public async Task<GetItemResponse> GetByUsername(string username)
        {
            return await _client.GetItemAsync(new GetItemRequest(
                tableName: TABLE_NAME,
                key: new Dictionary<string, AttributeValue>() {
                    {
                        "username", new AttributeValue(username)
                    }
                }));

        }

        public async Task<PutItemResponse> Insert(UserAccess access)
        {
            return await _client.PutItemAsync(new PutItemRequest(
                tableName: TABLE_NAME,
                item: new Dictionary<string, AttributeValue>() {
                    {
                        "username", new AttributeValue(access.Username)
                    },
                    {
                        "access", new AttributeValue()
                        {
                            N = "1"
                        }
                    }
                })
            );
        }

        public async Task<UpdateItemResponse> UpdateTotalAccess(UserAccess user)
        {
            return await _client.UpdateItemAsync(new UpdateItemRequest()
            {
                TableName = TABLE_NAME,
                Key = new Dictionary<string, AttributeValue>() {
                    {
                        "username", new AttributeValue(user.Username)
                        }
                    },
                UpdateExpression = "SET access = access + :increment",
                ExpressionAttributeValues = new Dictionary<string, AttributeValue>() {
                    {
                            ":increment", new AttributeValue()
                            {
                                N = "1"
                            }
                        }
                    },
                ReturnValues = ReturnValue.ALL_NEW
            });
        }
    }
}
