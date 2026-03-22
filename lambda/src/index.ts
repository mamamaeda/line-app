import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { validateSignature, WebhookEvent } from "@line/bot-sdk";
import { messagingApi } from "@line/bot-sdk";

const channelSecret = process.env.CHANNEL_SECRET!;
const channelAccessToken = process.env.CHANNEL_ACCESS_TOKEN!;

const client = new messagingApi.MessagingApiClient({ channelAccessToken });

export async function handler(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  const body = event.body ?? "";
  const signature = event.headers["x-line-signature"] ?? "";

  if (!validateSignature(body, channelSecret, signature)) {
    return { statusCode: 401, body: "Invalid signature" };
  }

  const parsed = JSON.parse(body);
  const events: WebhookEvent[] = parsed.events;

  await Promise.all(events.map(handleEvent));

  return { statusCode: 200, body: "OK" };
}

async function handleEvent(event: WebhookEvent): Promise<void> {
  if (event.type !== "message" || event.message.type !== "text") {
    return;
  }

  await client.replyMessage({
    replyToken: event.replyToken,
    messages: [{ type: "text", text: event.message.text }],
  });
}
