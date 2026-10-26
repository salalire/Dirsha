import type { AiGenerateRequest, AiProvider } from './types.js';

export class BedrockAiProvider implements AiProvider {
  readonly name = 'bedrock';
  readonly simulated = false;
  constructor(private readonly modelId: string, private readonly region: string, private readonly timeoutMs: number) {}
  async generate(request: AiGenerateRequest): Promise<string> {
    const { BedrockRuntimeClient, ConverseCommand } = await import('@aws-sdk/client-bedrock-runtime');
    const client = new BedrockRuntimeClient({ region: this.region });
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);
    try {
      const result = await client.send(new ConverseCommand({
        modelId: this.modelId,
        system: [{ text: request.systemPrompt }],
        messages: [...request.history.map((turn) => ({
          role: turn.role,
          content: [{ text: turn.content }],
        })), {
          role: 'user',
          content: [{ text: `USER_MESSAGE:\n${request.message}\nDIRSHA DATA:\n${request.context}` }],
        }],
        inferenceConfig: { maxTokens: 600, temperature: 0.2 },
      }), { abortSignal: controller.signal });
      const text = result.output?.message?.content?.find((item) => item.text)?.text;
      if (!text) throw new Error('empty provider response');
      return text;
    } finally {
      clearTimeout(timer);
    }
  }
}
