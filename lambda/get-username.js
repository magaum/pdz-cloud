const getUsername = ({ path }) => {
  const pathParameters = path
    ? path.split("/").filter((pathParameter) => pathParameter)
    : [];

  return pathParameters.length
    ? pathParameters[pathParameters.length - 1]
    : "anonymous";
};

module.exports = getUsername;
