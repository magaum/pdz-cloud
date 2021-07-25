const updateCommandInput = (username) => {
  return {
    TableName: process.env.TABLE_NAME,
    Key: {
      username: {
        S: username,
      },
    }
  }
};

module.exports = updateCommandInput;
