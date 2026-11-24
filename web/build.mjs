import { copyFile, mkdir, writeFile } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { build } from "esbuild";

const root = fileURLToPath(new URL("..", import.meta.url));
const output = resolve(root, "dist");
const url = process.env.SUPABASE_URL?.trim() ?? "";
const key = process.env.SUPABASE_PUBLISHABLE_KEY?.trim() ?? "";
if (!url.startsWith("https://") || !key.startsWith("sb_publishable_") ||
    url === "https://your-project.supabase.co" || key === "sb_publishable_replace_me") {
  throw new Error("Configura SUPABASE_URL e uma chave publicável real para gerar o jogo com login.");
}

await mkdir(output, { recursive: true });
await Promise.all([
  writeFile(resolve(output, ".gdignore"), ""),
  writeFile(resolve(root, "node_modules", ".gdignore"), ""),
]);
const godot = process.env.GODOT_BIN || "godot";
for (const args of [["--editor", "--import"], ["--export-release", "Web", resolve(output, "index.html")]]) {
  const result = spawnSync(godot, ["--headless", "--path", root, ...args], { cwd: root, stdio: "inherit" });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}

await build({
  entryPoints: [resolve(root, "web/portal.js")],
  outfile: resolve(output, "portal.js"),
  bundle: true,
  format: "esm",
  minify: true,
  define: { __SUPABASE_URL__: JSON.stringify(url), __SUPABASE_KEY__: JSON.stringify(key) },
});
await copyFile(resolve(root, "web/portal.css"), resolve(output, "portal.css"));
