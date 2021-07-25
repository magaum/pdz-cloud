using Amazon.DynamoDBv2.Model;
using Contagem.Common;
using Contagem.V1.Core;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Threading.Tasks;

namespace Contagem.V1.Controllers
{
    [ApiController]
    public class ContagemController : ControllerBase
    {
        private readonly ILogger<ContagemController> _logger;
        private readonly IUserAccessRepository _repository;

        public ContagemController(ILogger<ContagemController> logger, IUserAccessRepository repository)
        {
            _logger = logger;
            _repository = repository;
        }

        [HttpGet("{username}")]
        public async Task<IActionResult> UpdateAccessCount(string username)
        {
            _logger.LogInformation("Username received {0}", username);

            _logger.LogInformation("Generating new DbClient");

            UserAccess user = new(username);

            try
            {
                _logger.LogInformation("Getting access");

                GetItemResponse getResponse = await _repository.GetByUsername(username);

                _logger.LogInformation(JsonConvert.SerializeObject(getResponse));

                if (!getResponse.IsItemSet)
                {
                    _logger.LogInformation("Adding first access");

                    PutItemResponse response = await _repository.Insert(user);

                    _logger.LogInformation(JsonConvert.SerializeObject(response));
                }
                else
                {
                    _logger.LogInformation("Updating access count");

                    UpdateItemResponse response = await _repository.UpdateTotalAccess(user);

                    _logger.LogInformation(JsonConvert.SerializeObject(response));

                    user.Access = int.Parse(response.Attributes["access"].N);
                }

            }
            catch (Exception e)
            {
                _logger.LogError("Error while fetching data from dynamo object {0} {1}", JsonConvert.SerializeObject(e), e.Message);
            }

            return Ok(new Response()
            {
                Message = $"{username}, vc fez um acesso via ECS, este é seu acesso numero {user.Access}!"
            });
        }
    }
}