const {
  DynamoDBClient,
  GetItemCommand,
  PutItemCommand,
  UpdateItemCommand,
} = require("@aws-sdk/client-dynamodb");
const { unmarshall  } = require("@aws-sdk/util-dynamodb");

const response = require("./response");
const getUsername = require("./get-username");
const updateCommandInput = require("./update-command-input");
const getCommandInput = require("./get-command-input");
const putCommandInput = require("./put-command-input");

const handler = async (event) => {
  console.log("Lambda iniciada no ambiente: ", process.env.NODE_ENV);
  console.log(event);

  const username = getUsername(event);

  let dynamoResponse;
  let access = 1;

  try {
    console.log("gerando novo client", username);
    const client = new DynamoDBClient({ region: process.env.REGION });
    console.log("buscando usuario", username);
    const getCommand = new GetItemCommand(getCommandInput(username));
    const { Item } = await client.send(getCommand);
    console.log("usuario encontrado", JSON.stringify(Item));

    if (!Item) {
      console.log("adicionando usuario");
      const putCommand = new PutItemCommand(putCommandInput(username));
      dynamoResponse = await client.send(putCommand);
    } else {
      console.log("atualizando acesso");
      const updateCommand = new UpdateItemCommand(updateCommandInput(username));
      dynamoResponse = await client.send(updateCommand);
      const { Attributes } = dynamoResponse;
      const newDoc = unmarshall(Attributes);
      console.log("Attributes", Attributes);
      console.log("Unmarshall", newDoc);
      access = newDoc.access;
    }
  } catch (erro) {
    console.error(erro);
  }

  console.log("dynamo response", JSON.stringify(dynamoResponse));

  return response(username, access);
};

module.exports = {
  handler,
};
