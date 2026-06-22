import Chalk from "chalk";
import FileSystem from "fs";
import Path from "path";
import * as Vite from "vite";
import compileTs from "./private/tsc.ts";
// ^ Extension can't be omitted because Node expects it
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = Path.dirname(__filename);

function buildRenderer() {
    return Vite.build({
        configFile: Path.join(__dirname, "..", "vite.config.ts"),
        base: "./",
        mode: "production",
    });
}

function buildMain() {
    const mainPath = Path.join(__dirname, "..", "src", "main");
    return compileTs(mainPath);
}

async function main() {
    FileSystem.rmSync(Path.join(__dirname, "..", "build"), {
        recursive: true,
        force: true,
    });

    console.log(Chalk.blueBright("Transpiling renderer & main..."));

    const buildResults = await Promise.allSettled([buildRenderer(), buildMain()]);
    const failedBuild = buildResults.find(result => result.status === "rejected");

    if (failedBuild?.status === "rejected") {
        throw failedBuild.reason;
    }

    console.log(
        Chalk.greenBright(
            "Renderer & main successfully transpiled! (ready to be built with electron-builder)",
        ),
    );
}

main().catch(error => {
    console.error(Chalk.redBright("Build failed:"));
    console.error(error);
    process.exit(1);
});
