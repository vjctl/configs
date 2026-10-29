import { spawn } from "node:child_process";
import type { ChildProcessWithoutNullStreams } from "node:child_process";
import { readFileSync } from "node:fs";
import { basename, extname, resolve } from "node:path";
import { homedir } from "node:os";
import { pathToFileURL } from "node:url";
import { Type } from "@earendil-works/pi-ai";
import { defineTool, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

type ServerConfig = { command: string; args?: string[] };
type Message = {
	id?: number | string | null;
	method?: string;
	params?: any;
	result?: any;
	error?: { message?: string };
};

const config = JSON.parse(readFileSync(resolve(homedir(), ".pi/agent/lsp.json"), "utf8")) as {
	servers: Record<string, ServerConfig>;
};

const languages: Record<string, { server: string; id: string }> = {
	".tf": { server: "terraform", id: "terraform" },
	".tfvars": { server: "terraform", id: "terraform-vars" },
	".py": { server: "python", id: "python" },
	".go": { server: "go", id: "go" },
	".rs": { server: "rust", id: "rust" },
	".ts": { server: "node", id: "typescript" },
	".tsx": { server: "node", id: "typescriptreact" },
	".js": { server: "node", id: "javascript" },
	".jsx": { server: "node", id: "javascriptreact" },
	".mts": { server: "node", id: "typescript" },
	".cts": { server: "node", id: "typescript" },
	".mjs": { server: "node", id: "javascript" },
	".cjs": { server: "node", id: "javascript" },
};

class LspClient {
	private child: ChildProcessWithoutNullStreams;
	private root: string;
	private buffer = Buffer.alloc(0);
	private nextId = 0;
	private pending = new Map<number | string | null, { resolve: (value: any) => void; reject: (error: Error) => void }>();
	private documents = new Map<string, number>();
	private diagnostics = new Map<string, unknown[]>();

	constructor(server: ServerConfig, root: string) {
		this.root = root;
		this.child = spawn(server.command, server.args ?? [], { cwd: root, stdio: "pipe" });
		this.child.stdout.on("data", (chunk: Buffer) => this.read(chunk));
		this.child.stderr.resume();
		this.child.on("error", (error) => this.fail(error));
		this.child.on("exit", (code) => this.fail(new Error(`LSP server exited (${code})`)));
	}

	private read(chunk: Buffer) {
		this.buffer = Buffer.concat([this.buffer, chunk]);
		while (true) {
			const boundary = this.buffer.indexOf("\r\n\r\n");
			if (boundary < 0) return;
			const header = this.buffer.subarray(0, boundary).toString();
			const length = Number(/content-length:\s*(\d+)/i.exec(header)?.[1]);
			if (this.buffer.length < boundary + 4 + length) return;
			const body = this.buffer.subarray(boundary + 4, boundary + 4 + length).toString();
			this.buffer = this.buffer.subarray(boundary + 4 + length);
			this.receive(JSON.parse(body));
		}
	}

	private receive(message: Message) {
		if (message.method === "textDocument/publishDiagnostics") {
			this.diagnostics.set(message.params.uri, message.params.diagnostics);
			return;
		}
		if (message.method && message.id !== undefined) {
			const result = message.method === "workspace/configuration"
				? message.params.items.map(() => ({}))
				: null;
			this.send({ jsonrpc: "2.0", id: message.id, result });
			return;
		}
		if (message.id !== undefined) {
			const request = this.pending.get(message.id);
			if (request) {
				this.pending.delete(message.id);
				message.error ? request.reject(new Error(message.error.message)) : request.resolve(message.result);
			}
		}
	}

	private send(message: object) {
		const body = Buffer.from(JSON.stringify(message));
		this.child.stdin.write(`Content-Length: ${body.length}\r\n\r\n`);
		this.child.stdin.write(body);
	}

	private fail(error: Error) {
		for (const request of this.pending.values()) request.reject(error);
		this.pending.clear();
	}

	private request(method: string, params: unknown) {
		const id = ++this.nextId;
		return new Promise<any>((resolve, reject) => {
			this.pending.set(id, { resolve, reject });
			this.send({ jsonrpc: "2.0", id, method, params });
		});
	}

	private notify(method: string, params: unknown) {
		this.send({ jsonrpc: "2.0", method, params });
	}

	async start() {
		const rootUri = pathToFileURL(this.root).href;
		await this.request("initialize", {
			processId: process.pid,
			rootUri,
			capabilities: { workspace: { configuration: true, workspaceFolders: true } },
			workspaceFolders: [{ uri: rootUri, name: basename(this.root) }],
		});
		this.notify("initialized", {});
	}

	open(uri: string, languageId: string, text: string) {
		this.diagnostics.delete(uri);
		const version = (this.documents.get(uri) ?? 0) + 1;
		this.documents.set(uri, version);
		if (version === 1) {
			this.notify("textDocument/didOpen", { textDocument: { uri, languageId, version, text } });
		} else {
			this.notify("textDocument/didChange", {
				textDocument: { uri, version },
				contentChanges: [{ text }],
			});
		}
	}

	getDiagnostics(uri: string) {
		return this.diagnostics.get(uri) ?? [];
	}

	async stop() {
		try {
			await this.request("shutdown", null);
		} finally {
			this.notify("exit", {});
			this.child.kill();
		}
	}

	query(method: string, params: unknown) {
		return this.request(method, params);
	}
}

const clients = new Map<string, LspClient>();
const pause = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const lspTool = defineTool({
	name: "lsp",
	label: "LSP",
	description: "Query configured language servers for diagnostics, hover, definitions, and references",
	parameters: Type.Object({
		action: Type.String({ description: "diagnostics, hover, definition, or references" }),
		file: Type.String({ description: "File path, relative to the workspace or absolute" }),
		line: Type.Optional(Type.Number({ description: "1-based line for hover, definition, or references" })),
		character: Type.Optional(Type.Number({ description: "1-based character for hover, definition, or references" })),
	}),
	async execute(_toolCallId, params) {
		const file = resolve(params.file);
		const language = languages[extname(file).toLowerCase()];
		if (!language) throw new Error(`No LSP mapping for ${extname(file)}`);
		const server = config.servers[language.server];
		if (!server) throw new Error(`No '${language.server}' server in ~/.pi/agent/lsp.json`);

		let client = clients.get(language.server);
		if (!client) {
			client = new LspClient(server, process.cwd());
			clients.set(language.server, client);
			await client.start();
		}

		const uri = pathToFileURL(file).href;
		client.open(uri, language.id, readFileSync(file, "utf8"));
		let result: unknown;
		if (params.action === "diagnostics") {
			await pause(750);
			result = client.getDiagnostics(uri);
		} else {
			if (params.line === undefined || params.character === undefined) {
				throw new Error(`${params.action} requires line and character`);
			}
			const position = { line: params.line - 1, character: params.character - 1 };
			const textDocument = { uri };
			const methods: Record<string, string> = {
				hover: "textDocument/hover",
				definition: "textDocument/definition",
				references: "textDocument/references",
			};
			const method = methods[params.action];
			if (!method) throw new Error(`Unknown LSP action: ${params.action}`);
			result = await client.query(method, {
				textDocument,
				position,
				...(params.action === "references" ? { context: { includeDeclaration: true } } : {}),
			});
		}

		return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }], details: result };
	},
});

export default function (pi: ExtensionAPI) {
	pi.registerTool(lspTool);
	pi.on("session_shutdown", async () => {
		await Promise.all([...clients.values()].map((client) => client.stop()));
		clients.clear();
	});
}
