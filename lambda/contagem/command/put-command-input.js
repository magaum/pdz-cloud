const updateCommandInput = (username) => {
  return {
    TableName: process.env.TABLE_NAME,
    Item: {
      username: {
        S: username,
      },
      access: {
        N: "1",
      },
    },
  };
};

module.exports = updateCommandInput;
