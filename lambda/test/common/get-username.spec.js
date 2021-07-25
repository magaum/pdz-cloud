const { getUsername } = require("../../contagem/common");

describe("GetUsername tests", () => {
  it("should return anonymous when path doesn't exists in event", () => {
    //Arrange
    const event = {
      type: "alb",
    };
    const expectedUsername = "anonymous";

    //Act
    const username = getUsername(event);

    //Assert
    expect(username).toEqual(expectedUsername);
  });
});
