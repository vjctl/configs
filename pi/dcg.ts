import { execFile } from "node:child_process";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";

const DCG_BIN = process.env.DCG_BIN ?? "dcg";
const TIMEOUT_MS = 5000;
const BLOCK = "Block";
const ALLOW_ONCE = "Allow once";

function dcgBlockReason(command: string): Promise<string | undefined> {
  return new Promise((resolve) => {
    execFile(
      DCG_BIN,
      ["--robot", "test", "--dialect", "posix", command],
      { timeout: TIMEOUT_MS },
      (err, stdout) => {
        if ((err as { code?: unknown } | null)?.code !== 1) return resolve(undefined);
        let reason = "blocked by dcg";
        try {
          const parsed = JSON.parse(stdout);
          if (parsed?.reason) reason = parsed.reason;
          if (parsed?.rule_id) reason += ` [${parsed.rule_id}]`;
        } catch {
          // Non-JSON output: keep the default reason.
        }
        resolve(reason);
      },
    );
  });
}

async function checkCommand(command: string, ctx: ExtensionContext): Promise<string | undefined> {
  const reason = await dcgBlockReason(command);
  if (!reason) return;

  // No UI (print/RPC mode): nobody to ask, deny outright.
  const choice = ctx.hasUI
    ? await ctx.ui.select(`DCG:\n\n  ${reason}\n\n  command: ${command}\n`, [BLOCK, ALLOW_ONCE])
    : BLOCK;
  return choice === ALLOW_ONCE ? undefined : reason;
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (!isToolCallEventType("bash", event)) return;
    const command = event.input.command;
    if (!command?.trim()) return;

    const reason = await checkCommand(command, ctx);
    if (reason) return { block: true, reason };
  });

  pi.on("user_bash", async (event, ctx) => {
    const command = event.command;
    if (!command.trim()) return;

    const reason = await checkCommand(command, ctx);
    if (!reason) return;

    return {
      result: { output: `${reason}\n`, exitCode: 1, cancelled: false, truncated: false },
    };
  });
}
