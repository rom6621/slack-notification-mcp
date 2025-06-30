import { Hono } from "hono";
import { StreamableHTTPTransport } from "@hono/mcp";
import { serve } from "@hono/node-server";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import bolt from "@slack/bolt";

import { PostDirectMessage } from "./tools/post-direct-message.js";

export const server = new Hono();

server.all("/mcp", async (c) => {
  // Slack App
  const boltApp = new bolt.App({
    token: process.env.SLACK_BOT_TOKEN || "dummy-token",
    signingSecret: process.env.SLACK_SIGNING_SECRET || "dummy-signing-secret",
  });

  // MCP Server
  const mcpServer = new McpServer({
    name: "slack-notification",
    version: "0.0.1",
  });

  // Tools
  const memberId = c.req.header("X-Slack-Member-Id");
  const postMessage = new PostDirectMessage(boltApp, memberId);

  // DI
  postMessage.register(mcpServer);

  const transport = new StreamableHTTPTransport({
    sessionIdGenerator: undefined,
  });
  await mcpServer.connect(transport);
  return transport.handleRequest(c);
});

async function main() {
  serve(
    {
      fetch: server.fetch,
      port: 7070,
    },
    (info) => {
      console.log(`Server is running on http://localhost:${info.port}`);
    }
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
