const path = require("path");

const templateRoot = path.resolve(__dirname, "..", "templates");

const items = {
  login: {
    name: "login",
    sourceDir: path.join(templateRoot, "login"),
    description: "Basic login form with hook + auth client."
  },
  register: {
    name: "register",
    sourceDir: path.join(templateRoot, "register"),
    description: "Basic register form with hook + auth client."
  }
};

module.exports = {
  items
};
