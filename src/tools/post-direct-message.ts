import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import bolt from "@slack/bolt";
import { z } from "zod";

export class PostDirectMessage {
  constructor(private app: bolt.App, private memberId: string) {}

  register(server: McpServer) {
    server.tool(
      "post_direct_message",
      "Post a direct message to user via slack.",
      {
        message: z.string(),
        isMarkdown: z.boolean().optional().default(false),
      },
      async ({ message, isMarkdown }) => {
        try {
          const openConvResp = await this.app.client.conversations.open({
            users: this.memberId,
          });
          if (openConvResp.ok === false) {
            return {
              content: [
                {
                  type: "text",
                  text: openConvResp.error ?? "不明なエラーが発生しました",
                },
              ],
            };
          }

          const {
            channel: { id: channelId },
          } = openConvResp;
          if (channelId === undefined) {
            return {
              content: [
                {
                  type: "text",
                  text: "チャンネルIDの取得に失敗しました",
                },
              ],
            };
          }

          // Markdown messageを送信する
          const postMessageResp = await this.app.client.chat.postMessage({
            channel: channelId,
            text: message,
            mrkdwn: isMarkdown,
          });
          if (postMessageResp.ok === false) {
            return {
              content: [
                {
                  type: "text",
                  text: postMessageResp.error ?? "不明なエラーが発生しました",
                },
              ],
            };
          }

          return {
            content: [
              {
                type: "text",
                text: "メッセージを送信しました",
              },
            ],
          };
        } catch (error) {
          if (error instanceof Error) {
            return {
              content: [
                {
                  type: "text",
                  text: error.message ?? "不明なエラーが発生しました",
                },
              ],
            };
          }

          return {
            content: [
              {
                type: "text",
                text: "不明なエラーが発生しました",
              },
            ],
          };
        }
      }
    );
  }
}
