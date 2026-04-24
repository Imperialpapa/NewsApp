import json

import anthropic

from .. import config
from .base import SYSTEM_PROMPT, Summarizer, Summary


class AnthropicSummarizer(Summarizer):
    def __init__(self) -> None:
        self._client = anthropic.Anthropic(api_key=config.ANTHROPIC_API_KEY)
        self._model = config.ANTHROPIC_MODEL

    def summarize(self, headline: str, snippet: str, source: str) -> Summary:
        user_content = (
            f"Source: {source}\nHeadline: {headline}\n\nSnippet:\n{snippet}"
        )
        response = self._client.messages.create(
            model=self._model,
            max_tokens=600,
            system=[
                {
                    "type": "text",
                    "text": SYSTEM_PROMPT,
                    "cache_control": {"type": "ephemeral"},
                }
            ],
            messages=[{"role": "user", "content": user_content}],
        )
        text = next(b.text for b in response.content if b.type == "text")
        data = _parse_json(text)
        return Summary(summary_en=data["summary_en"])


def _parse_json(text: str) -> dict:
    # Models sometimes wrap JSON in ```json ... ``` fences
    cleaned = text.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.strip("`")
        if cleaned.lower().startswith("json"):
            cleaned = cleaned[4:]
        cleaned = cleaned.strip()
    return json.loads(cleaned)
