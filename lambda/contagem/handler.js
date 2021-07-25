const {
  DynamoDBClient,
  GetItemCommand,
  PutItemCommand,
  UpdateItemCommand,
} = require("@aws-sdk/client-dynamodb");
const { unmarshall } = require("@aws-sdk/util-dynamodb");

const { getUsername, response } = require("./common");
const {
  getCommandInput,
  updateCommandInput,
  putCommandInput,
} = require("./command");

const handler = async (event) => {
  console.log("Lambda iniciada no ambiente: ", process.env.NODE_ENV);

  let access = 1;
  
  const username = getUsername(event);

  const client = new DynamoDBClient({ region: process.env.REGION });

  try {
    console.log("searching user access", username);

    const getCommand = new GetItemCommand(getCommandInput(username));

    const { Item } = await client.send(getCommand);

    console.log("received user access", JSON.stringify(Item));

    if (!Item) {
      console.log("add new user access");

      const putCommand = new PutItemCommand(putCommandInput(username));

      await client.send(putCommand);
    } else {
      console.log("update user total access");

      const updateCommand = new UpdateItemCommand(updateCommandInput(username));

      const { Attributes } = await client.send(updateCommand);

      const newDoc = unmarshall(Attributes);

      console.log("Unmarshalled", newDoc);

      access = newDoc.access;
    }
  } catch (erro) {
    console.error(erro);
  }

  return response(username, access);
};

module.exports = handler;
