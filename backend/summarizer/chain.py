"""Fallback chain across multiple LLM providers.

Tries providers in order; on any exception (e.g. 429), logs and tries
the next. Raises only if every provider throws.

Quality validation (e.g. bullet-format checks) lives in the app widget
now — the chain accepts whatever a provider returns so coverage stays
high even when the primary's formatting is inconsistent.
"""
import logging
import time

from .base import Summarizer, Summary

log = logging.getLogger("digest")

# Cooldown before each fallback attempt. Fallback is usually triggered by a
# 429 from the primary, and the secondary may also be near its own RPM
# ceiling if we hammer it instantly.
FALLBACK_SLEEP_SEC = 1.0


class ChainSummarizer(Summarizer):
    def __init__(self, providers: list[tuple[str, Summarizer]]) -> None:
        if not providers:
            raise ValueError("ChainSummarizer needs at least one provider")
        self._providers = providers

    def summarize(self, headline: str, snippet: str, source: str) -> Summary:
        last_exc: Exception | None = None
        for i, (name, provider) in enumerate(self._providers):
            if i > 0:
                time.sleep(FALLBACK_SLEEP_SEC)
            try:
                return provider.summarize(headline, snippet, source)
            except Exception as e:
                log.warning(
                    "Provider %s threw (%s); trying next in chain", name, e
                )
                last_exc = e
        assert last_exc is not None
        raise last_exc
