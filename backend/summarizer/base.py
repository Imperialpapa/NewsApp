from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass(frozen=True)
class Summary:
    summary_en: str
    summary_ko: str | None = None


SYSTEM_PROMPT = (
    "You are a financial news editor for busy global finance professionals. "
    "You will be given a news headline and snippet. Produce a concise "
    "2-3 sentence summary in English. Focus on WHY it matters to markets "
    "(tickers, sectors, macro). No fluff. No intro phrases like 'This article'. "
    "Return strictly this JSON shape and nothing else:\n"
    '{"summary_en": "..."}'
)


class Summarizer(ABC):
    """Provider-agnostic summarizer interface.

    Given a headline + snippet, returns an English summary. Implementations
    select model/endpoint via env config. Failures should raise — the pipeline
    falls back to headline-only on exception.
    """

    @abstractmethod
    def summarize(self, headline: str, snippet: str, source: str) -> Summary: ...
