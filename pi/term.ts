import { readFile, readdir } from "node:fs/promises";
import { homedir } from "node:os";
import { basename, join } from "node:path";
import { Type } from "@earendil-works/pi-ai";
import { defineTool, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

const DIR = join(homedir(), ".pi/term");
const ANSI = /\x1b\[[0-9;?]*[ -\/]*[@-~]|\x1b\][^\x07]*\x07|\r/g;

export default function (pi: ExtensionAPI) {
	pi.registerTool(
		defineTool({
			name: "terminal_output",
			label: "Terminal output",
			description:
				"List terminal logs in ~/.pi/term for the current directory. Pass a listed filename as `file` to read it.",
			promptGuidelines: [
				"Call terminal_output without `file` to list logs, ask the user which to read, then call again with that exact filename.",
			],
			parameters: Type.Object({
				file: Type.Optional(Type.String({ description: "Filename from the list" })),
			}),
			async execute(_id, params, _signal, _onUpdate, ctx) {
				const prefix = `${basename(ctx.cwd)}.`;
				const logs = (await readdir(DIR).catch(() => [] as string[]))
					.filter((n) => n.startsWith(prefix) && n.endsWith(".log"))
					.sort();

				if (!params.file) {
					const text = logs.length ? logs.join("\n") : `No terminal logs for ${prefix} in ${DIR}`;
					return { content: [{ type: "text", text }] };
				}

				if (!logs.includes(params.file)) {
					throw new Error(`Unknown log file: ${params.file}. Available: ${logs.join(", ") || "none"}`);
				}

				const text = await readFile(join(DIR, params.file), "utf8");
				return { content: [{ type: "text", text: text.replace(ANSI, "") }] };
			},
		}),
	);
}
