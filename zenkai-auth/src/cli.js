const { Command } = require("commander");
const { installItem } = require("./installers/addItem");
const { items } = require("./items");
const { logger } = require("./utils/logger");

async function run() {
  const program = new Command();

  program
    .name("zenkai-auth")
    .description("Install editable auth UI source into your project.")
    .version("0.1.0");

  program
    .command("add")
    .description("Add an auth UI block into your project")
    .argument("<item>", `Item name (${Object.keys(items).join(", ")})`)
    .option("-f, --force", "Overwrite existing files")
    .option("--dry-run", "Preview copied files without writing")
    .option(
      "--remote <repo>",
      "Optional GitHub repo slug/url for templates (e.g. owner/repo#main)"
    )
    .option(
      "--auth-api-url <url>",
      "Replace AUTH_API_URL placeholder in copied templates"
    )
    .action(async (item, options) => {
      try {
        await installItem(item, options);
      } catch (error) {
        logger.error(error.message);
        process.exitCode = 1;
      }
    });

  await program.parseAsync(process.argv);
}

module.exports = {
  run
};
