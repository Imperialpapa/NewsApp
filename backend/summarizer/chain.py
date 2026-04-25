"""Fallback chain across multiple LLM providers.

Useful when the primary provider (e.g. Groq free tier) hits rate limits.
Tries providers in order; on any exception, logs and tries the next.
Raises only if every provider fails.
"""
import logging

from .base import Summarizer, Summary

log = logging.getLogger("digest")


class ChainSummarizer(Summarizer):
    def __init__(self, providers: list[tuple[str, Summarizer]]) -> None:
        if not providers:
            raise ValueError("ChainSummarizer needs at least one provider")
        self._providers = providers

    def summarize(self, headline: str, snippet: str, source: str) -> Summary:
        last_exc: Exception | None = None
        for name, provider in self._providers:
            try:
                return provider.summarize(headline, snippet, source)
            except Exception as e:
                log.warning(
                    "Provider %s failed (%s); trying next in chain", name, e
                )
                last_exc = e
        assert last_exc is not None
        raise last_exc
