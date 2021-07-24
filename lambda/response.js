const response = (username, access) => {
  return {
    isBase64Encoded: false,
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: `${username}, vc fez um acesso via Lambda, este é seu acesso numero ${access}!`,
    }),
  };
};

module.exports = response;
