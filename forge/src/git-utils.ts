import { execa } from "execa";

export async function getGitParentBranch(): Promise<string> {
  try {
    try {
      const graphiteParent = await getGraphiteParentBranch();
      if (graphiteParent) return graphiteParent;
    } catch {}

    const currentBranch = await getCurrentGitBranch();

    if (await doesBranchHaveItsOwnRootCommit(currentBranch)) {
      // If branch has its own root commit, it's not branched from anywhere in this repo
      return getGitDevBranch();
    }

    // Try to find the best guess parent branch
    const bestGuess = await findBestGuessParentBranch(currentBranch);
    if (bestGuess) return bestGuess;
  } catch {}
  // If everything fails, default to the development branch
  return getGitDevBranch();
}

async function doesBranchHaveItsOwnRootCommit(
  branch: string
): Promise<boolean> {
  const rootCommit = await getBranchRootCommit(branch);
  const headRoot = await getBranchRootCommit("HEAD");
  return rootCommit !== headRoot;
}

async function findBestGuessParentBranch(
  currentBranch: string
): Promise<string | undefined> {
  // Get local branches excluding the current one
  const branches = (await getLocalBranches()).filter(
    (branch) => branch && branch !== currentBranch
  );

  // Find the best candidate by looking for most recent common ancestor
  let bestBranch = "";
  let bestCount = Infinity;
  for (const branch of branches) {
    try {
      const base = await getMergeBase(currentBranch, branch);
      if (!base) continue;

      const count = await getNumberOfCommitsBetweenBranches(base, branch);

      // Use the branch that has the closest relationship (fewest commits since diverging)
      if (!isNaN(count) && count < bestCount) {
        bestBranch = branch;
        bestCount = count;
      }
    } catch {
      // Skip this branch if there's an error
      continue;
    }
  }

  return bestBranch;
}

/**
 * Get the number of commits between two branches.
 */
async function getNumberOfCommitsBetweenBranches(
  branch1: string,
  branch2: string
): Promise<number> {
  const { stdout } = await execa(
    "git",
    ["rev-list", "--count", `${branch1}..${branch2}`],
    {
      reject: false,
    }
  );
  return parseInt(stdout.trim(), 10);
}

/**
 * Get the merge base of two branches, i.e. the common ancestor of two branches.
 */
async function getMergeBase(branch1: string, branch2: string): Promise<string> {
  const { stdout } = await execa("git", ["merge-base", branch1, branch2], {
    reject: false,
  });
  return stdout.trim();
}

async function getGitDevBranch(): Promise<string> {
  const candidates = ["develop", "development", "dev", "main"];
  for (const branch of candidates) {
    try {
      const { stdout } = await execa("git", ["branch", "--list", branch], {
        reject: false,
      });
      if (stdout.trim()) return branch;
    } catch {}
  }
  return "master";
}

async function getCurrentGitBranch(): Promise<string> {
  const { stdout } = await execa("git", ["rev-parse", "--abbrev-ref", "HEAD"]);
  return stdout.trim();
}

/**
 * Get the root commit of a branch.
 *
 * A root commit is the very first commit in a branch's history—one that has no parent commits.
 * In git, this is the initial commit from which all other commits in that branch descend.
 */
async function getBranchRootCommit(branch: string): Promise<string> {
  const { stdout } = await execa(
    "git",
    ["rev-list", "--max-parents=0", branch],
    { reject: false }
  );
  return stdout.trim();
}

async function getGraphiteParentBranch(): Promise<string> {
  const { stdout } = await execa("gt", ["parent"], {
    reject: false,
  });
  return stdout.trim();
}

async function getLocalBranches(): Promise<string[]> {
  const { stdout } = await execa(
    "git",
    ["for-each-ref", "--format=%(refname:short)", "refs/heads/"],
    {
      reject: false,
    }
  );
  return stdout.trim().split("\n");
}

export async function getBranchChangedFiles(
  options: { baseBranch?: string; pattern?: string } = {}
): Promise<string[]> {
  const baseBranch = options.baseBranch || (await getGitParentBranch());
  const pattern = options.pattern;

  try {
    const changedSinceBase = await getChangedFilesAgainstBase(baseBranch);
    const stagedChanges = await getStagedFiles();
    const unstagedChanges = await getUnstagedFiles();

    // Combine all outputs and filter for modified/added files
    const allChanges = [changedSinceBase, stagedChanges, unstagedChanges]
      .join("\n")
      .split("\n")
      .filter((line) => line.trim())
      .map((line) => {
        const parts = line.split("\t");
        const status = parts[0];
        const filename = parts[parts.length - 1];
        return { status, filename };
      })
      .filter(({ status, filename }) => {
        // Filter out deleted files (status 'D')
        return status !== "D";
      })
      .map(({ filename }) => filename);

    // Remove duplicates
    const uniqueFiles = [...new Set(allChanges)];

    // Apply pattern filter if provided
    if (pattern) {
      const regex = new RegExp(pattern);
      return uniqueFiles.filter((file) => regex.test(file));
    }

    return uniqueFiles;
  } catch (error) {
    console.error("Error getting changed files:", error);
    return [];
  }
}

export async function getChangedFrontendFiles(
  baseBranch?: string
): Promise<string[]> {
  return getBranchChangedFiles({
    pattern: "\\.(js|jsx|ts|tsx|html|css|svelte|mjs)$",
    baseBranch,
  });
}

export async function getChangedJsTsFiles(
  baseBranch?: string
): Promise<string[]> {
  return getBranchChangedFiles({
    pattern: "\\.(js|jsx|ts|tsx|svelte|mjs)$",
    baseBranch,
  });
}

export async function showChangedFilesPreview(): Promise<void> {
  try {
    const changedFiles = await getBranchChangedFiles();
    const preview = changedFiles.join("\n");

    console.log("💅 Changed files to be validated:");
    console.log();
    console.log(preview);
  } catch (error) {
    console.error("Error showing changed files preview:", error);
  }
}

export async function getModifiedFiles(): Promise<string[]> {
  try {
    const { stdout } = await execa("git", ["status", "--porcelain"], {
      reject: false,
    });
    return stdout
      .split("\n")
      .filter((line) => line.trim())
      .map((line) => line.substring(3)); // Remove the status prefix
  } catch (error) {
    console.error("Error getting modified files:", error);
    return [];
  }
}

export async function showModifiedFiles(): Promise<void> {
  const modifiedFiles = await getModifiedFiles();
  if (modifiedFiles.length > 0) {
    console.log();
    console.log("The following files have been modified:");
    for (const file of modifiedFiles) {
      console.log(`  ${file}`);
    }
  }
}

export async function commitWithLint(
  autoCommit: boolean = false
): Promise<void> {
  if (!autoCommit) {
    console.log(
      "Validation successful. Run with --auto-commit to automatically commit changes."
    );
    return;
  }

  try {
    const modifiedFiles = await getModifiedFiles();
    if (modifiedFiles.length === 0) {
      console.log("No modified files to commit.");
      return;
    }

    await execa("git", ["add", ...modifiedFiles]);
    await execa("git", [
      "commit",
      "-m",
      "chore: apply linting and formatting fixes",
    ]);
    console.log("✅ Changes committed successfully");
  } catch (error) {
    console.error("Error committing changes:", error);
  }
}

async function getChangedFilesAgainstBase(baseBranch: string): Promise<string> {
  const { stdout } = await execa(
    "git",
    ["diff", "--name-status", `${baseBranch}...HEAD`],
    { reject: false }
  );
  return stdout;
}

async function getStagedFiles(): Promise<string> {
  const { stdout } = await execa("git", ["diff", "--name-status", "--cached"], {
    reject: false,
  });
  return stdout;
}

async function getUnstagedFiles(): Promise<string> {
  const { stdout } = await execa("git", ["diff", "--name-status"], {
    reject: false,
  });
  return stdout;
}
