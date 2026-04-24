"""Shared base for OpenAI-compatible providers (Groq, GLM).

Both expose a chat-completions endpoint matching OpenAI's schema. Only the
base URL, API key, and model ID differ.
"""
import json

import httpx

from .base import SYSTEM_PROMPT, Summarizer, Summary


class OpenAICompatSummarizer(Summarizer):
    def __init__(self, *, base_url: str, api_key: str, model: str) -> None:
        self._url = base_url.rstrip("/") + "/chat/completions"
        self._headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        }
        self._model = model

    def summarize(self, headline: str, snippet: str, source: str) -> Summary:
        user_content = (
            f"Source: {source}\nHeadline: {headline}\n\nSnippet:\n{snippet}"
        )
        body = {
            "model": self._model,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user_content},
            ],
            "max_tokens": 600,
            "response_format": {"type": "json_object"},
        }
        with httpx.Client(timeout=60.0) as client:
            resp = client.post(self._url, headers=self._headers, json=body)
            resp.raise_for_status()
            payload = resp.json()
        text = payload["choices"][0]["message"]["content"]
        data = json.loads(_strip_fences(text))
        return Summary(summary_en=data["summary_en"], summary_ko=data["summary_ko"])


def _strip_fences(text: str) -> str:
    cleaned = text.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.strip("`")
        if cleaned.lower().startswith("json"):
            cleaned = cleaned[4:]
        cleaned = cleaned.strip()
    return cleaned
