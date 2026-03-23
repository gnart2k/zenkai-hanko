const fs = require("fs-extra");
const https = require("https");
const os = require("os");
const path = require("path");
const tar = require("tar");

function parseGitHubInput(input) {
  const trimmed = input.trim();
  const refSplit = trimmed.split("#");
  const base = refSplit[0];
  const ref = refSplit[1] || "main";

  if (base.includes("github.com")) {
    const parts = base.replace(/^https?:\/\/github\.com\//, "").split("/");
    if (parts.length < 2) {
      throw new Error(`Invalid GitHub URL: ${input}`);
    }

    return {
      owner: parts[0],
      repo: parts[1].replace(/\.git$/, ""),
      ref
    };
  }

  const slugParts = base.split("/");
  if (slugParts.length !== 2) {
    throw new Error(
      `Invalid GitHub repo format "${input}". Use owner/repo or full GitHub URL.`
    );
  }

  return {
    owner: slugParts[0],
    repo: slugParts[1],
    ref
  };
}

function download(url, destFile) {
  return new Promise((resolve, reject) => {
    const fileStream = fs.createWriteStream(destFile);
    https
      .get(url, (response) => {
        if (response.statusCode >= 300 && response.statusCode < 400 && response.headers.location) {
          fileStream.close();
          fs.remove(destFile).catch(() => {});
          return resolve(download(response.headers.location, destFile));
        }

        if (response.statusCode !== 200) {
          fileStream.close();
          fs.remove(destFile).catch(() => {});
          return reject(new Error(`Failed downloading templates (HTTP ${response.statusCode}).`));
        }

        response.pipe(fileStream);
        fileStream.on("finish", () => {
          fileStream.close(resolve);
        });
      })
      .on("error", (error) => {
        fileStream.close();
        fs.remove(destFile).catch(() => {});
        reject(error);
      });
  });
}

async function getRemoteTemplateRoot(repoInput) {
  const { owner, repo, ref } = parseGitHubInput(repoInput);
  const tempRoot = await fs.mkdtemp(path.join(os.tmpdir(), "zenkai-auth-"));
  const archiveFile = path.join(tempRoot, "repo.tar.gz");
  const extractDir = path.join(tempRoot, "extract");

  const archiveUrl = `https://codeload.github.com/${owner}/${repo}/tar.gz/refs/heads/${ref}`;

  await download(archiveUrl, archiveFile);
  await fs.ensureDir(extractDir);
  await tar.x({
    file: archiveFile,
    cwd: extractDir
  });

  const unpacked = await fs.readdir(extractDir);
  if (unpacked.length === 0) {
    throw new Error("Remote template archive is empty.");
  }

  return {
    tempRoot,
    templateRoot: path.join(extractDir, unpacked[0], "templates")
  };
}

module.exports = {
  getRemoteTemplateRoot
};
