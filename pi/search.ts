import { Type } from "@earendil-works/pi-ai";
import { defineTool, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

function createSearchTool(pi: ExtensionAPI) {
	return defineTool({
		name: "web_search",
		label: "Web Search",
		description: "Search the web with Ketch. Returns JSON results with titles, URLs, and snippets",
		parameters: Type.Object({
			query: Type.String({ description: "Search query" }),
			limit: Type.Optional(Type.Number({ description: "Max results (default 5)" })),
		}),
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const result = await pi.exec(
				"ketch",
				["search", params.query, "--limit", String(params.limit ?? 5), "--json"],
				{ signal, timeout: 30_000, cwd: ctx.cwd },
			);

			if (result.code !== 0) {
				const detail = result.stderr.trim() || `exit code ${result.code}`;
				throw new Error(`Ketch search failed: ${detail}`);
			}

			return { content: [{ type: "text", text: result.stdout.trim() || "No results" }] };
		},
	});
}

export default function (pi: ExtensionAPI) {
	pi.registerTool(createSearchTool(pi));
}
