const path = require("path");
const fs = require("fs-extra");
const { items } = require("../items");
const { logger } = require("../utils/logger");
const { getRemoteTemplateRoot } = require("../utils/templateSource");

const DEFAULT_FOLDERS = ["components", "hooks", "lib"];

async function collectFilesRecursively(rootDir) {
  const output = [];
  const entries = await fs.readdir(rootDir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(rootDir, entry.name);
    if (entry.isDirectory()) {
      const nested = await collectFilesRecursively(fullPath);
      output.push(...nested);
    } else {
      output.push(fullPath);
    }
  }

  return output;
}

async function resolveTargetLayout(projectRoot) {
  const packageJsonPath = path.join(projectRoot, "package.json");
  const hasPackageJson = await fs.pathExists(packageJsonPath);
  let isNextProject = false;

  if (hasPackageJson) {
    const packageJson = await fs.readJson(packageJsonPath);
    const deps = packageJson.dependencies || {};
    const devDeps = packageJson.devDependencies || {};
    isNextProject = Boolean(deps.next || devDeps.next);
  }

  const hasSrcDir = await fs.pathExists(path.join(projectRoot, "src"));
  const targetRoot = hasSrcDir ? path.join(projectRoot, "src") : projectRoot;

  return {
    isNextProject,
    targetRoot
  };
}

async function resolveTemplateDir(itemName, remoteInput) {
  if (!remoteInput) {
    const item = items[itemName];
    return {
      cleanup: async () => {},
      sourceDir: item.sourceDir
    };
  }

  const { tempRoot, templateRoot } = await getRemoteTemplateRoot(remoteInput);
  return {
    cleanup: async () => {
      await fs.remove(tempRoot);
    },
    sourceDir: path.join(templateRoot, itemName)
  };
}

function getPlaceholderReplacements(options) {
  return {
    __AUTH_API_URL__: options.authApiUrl || process.env.AUTH_API_URL || "http://localhost:8000"
  };
}

function injectConfig(content, replacements) {
  let result = content;
  for (const [placeholder, value] of Object.entries(replacements)) {
    result = result.replaceAll(placeholder, value);
  }
  return result;
}

async function copyWithGuard({
  sourceDir,
  targetDir,
  force,
  dryRun,
  replacements
}) {
  const sourceFiles = await collectFilesRecursively(sourceDir);
  const conflicts = [];
  const unchanged = new Set();

  for (const sourceFile of sourceFiles) {
    const relativePath = path.relative(sourceDir, sourceFile);
    const destination = path.join(targetDir, relativePath);
    const sourceRaw = await fs.readFile(sourceFile, "utf8");
    const transformedSource = injectConfig(sourceRaw, replacements);

    if ((await fs.pathExists(destination)) && !force) {
      const existingRaw = await fs.readFile(destination, "utf8");
      if (existingRaw === transformedSource) {
        unchanged.add(relativePath);
      } else {
        conflicts.push(relativePath);
      }
    }
  }

  if (conflicts.length > 0) {
    const list = conflicts.map((file) => `- ${file}`).join("\n");
    throw new Error(
      [
        "Some files already exist and were not overwritten:",
        list,
        "",
        "Re-run with --force to overwrite existing files."
      ].join("\n")
    );
  }

  if (dryRun) {
    const wouldCopy = sourceFiles
      .map((file) => path.relative(sourceDir, file))
      .filter((file) => !unchanged.has(file));
    logger.warn("Dry run enabled. No files were written.");
    for (const file of wouldCopy) {
      logger.info(`Would copy: ${file}`);
    }
    for (const file of unchanged) {
      logger.info(`Skipping unchanged: ${file}`);
    }
    return;
  }

  for (const sourceFile of sourceFiles) {
    const relativePath = path.relative(sourceDir, sourceFile);
    const destination = path.join(targetDir, relativePath);
    const sourceRaw = await fs.readFile(sourceFile, "utf8");

    if (!force && unchanged.has(relativePath)) {
      continue;
    }

    await fs.ensureDir(path.dirname(destination));
    fs.copySync(sourceFile, destination, {
      overwrite: Boolean(force),
      errorOnExist: !force
    });

    await fs.writeFile(destination, injectConfig(sourceRaw, replacements), "utf8");
  }

  for (const file of unchanged) {
    logger.info(`Skipping unchanged: ${file}`);
  }
}

async function installItem(itemName, options) {
  const projectRoot = process.cwd();
  const item = items[itemName];

  if (!item) {
    throw new Error(
      `Unknown item "${itemName}". Available items: ${Object.keys(items).join(", ")}`
    );
  }

  logger.info(`Detected project root: ${projectRoot}`);
  const layout = await resolveTargetLayout(projectRoot);
  const folders = layout.isNextProject
    ? [...DEFAULT_FOLDERS, "app"]
    : DEFAULT_FOLDERS;

  if (layout.isNextProject) {
    logger.info(
      `Detected Next.js project. Installing under ${path.relative(projectRoot, layout.targetRoot) || "."}`
    );
  }

  for (const folder of folders) {
    logger.info(`Creating ${folder}...`);
    await fs.ensureDir(path.join(layout.targetRoot, folder));
  }

  logger.info(`Installing ${itemName} UI...`);

  const { sourceDir, cleanup } = await resolveTemplateDir(itemName, options.remote);
  try {
    if (!(await fs.pathExists(sourceDir))) {
      throw new Error(
        `Template "${itemName}" was not found at ${sourceDir}.`
      );
    }

    await copyWithGuard({
      sourceDir,
      targetDir: layout.targetRoot,
      force: options.force,
      dryRun: options.dryRun,
      replacements: getPlaceholderReplacements(options)
    });
  } finally {
    await cleanup();
  }

  logger.success("Done!");
}

module.exports = {
  installItem
};
