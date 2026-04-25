"""Fallback chain across multiple LLM providers.

Tries providers in order. Falls through to the next on either (a) an
exception (e.g. 429), or (b) malformed output that fails quality checks.
Raises only if every provider fails or returns junk.
"""
import logging
import time

from .base import Summarizer, Summary

log = logging.getLogger("digest")

# Cooldown before each fallback attempt. Fallback is usually triggered by a
# 429 from the primary, and the secondary may also be near its own RPM
# ceiling if we hammer it instantly.
FALLBACK_SLEEP_SEC = 1.0


def _quality_reject(s: Summary) -> str | None:
    """Return reason string if output is malformed, else None.

    Catches Llama-via-Groq's tendency to collapse the requested 3 bullets
    into a single paragraph. KO contamination checks were removed when
    Korean generation was paused — see user.md for re-enable plan.
    """
    en_lines = [ln for ln in s.summary_en.split("\n") if ln.strip()]
    if len(en_lines) < 2:
        return f"EN has {len(en_lines)} line(s), expected ~3 bullets"
    return None


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
                result = provider.summarize(headline, snippet, source)
            except Exception as e:
                log.warning(
                    "Provider %s threw (%s); trying next in chain", name, e
                )
                last_exc = e
                continue
            reject_reason = _quality_reject(result)
            if reject_reason is None:
                return result
            log.warning(
                "Provider %s output rejected (%s); trying next in chain",
                name, reject_reason,
            )
            last_exc = ValueError(f"{name} output rejected: {reject_reason}")
        assert last_exc is not None
        raise last_exc
