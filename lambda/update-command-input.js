const updateCommandInput = (username) => {
  return {
    TableName: process.env.TABLE_NAME,
    Key: {
      username: {
        S: username,
      },
    },
    UpdateExpression: "SET access = access + :increment",
    ExpressionAttributeValues: {
      ":increment": {
        N: "1",
      },
    },
    ReturnValues: "ALL_NEW",
  };
};

module.exports = updateCommandInput;
