from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass(frozen=True)
class Summary:
    summary_en: str
    summary_ko: str


SYSTEM_PROMPT = (
    "You are a financial news editor for busy Korean finance professionals. "
    "You will be given a news headline and snippet. Produce a 2-3 sentence summary "
    "in English AND a 2-3 sentence summary in Korean. Focus on WHY it matters to "
    "markets (tickers, sectors, macro). No fluff. No intro phrases like 'This article'. "
    "Return strictly this JSON shape and nothing else:\n"
    '{"summary_en": "...", "summary_ko": "..."}'
)


class Summarizer(ABC):
    """Provider-agnostic summarizer interface.

    Given a headline + snippet, returns bilingual summaries. Implementations
    select model/endpoint via env config. Failures should raise — the pipeline
    falls back to headline-only on exception.
    """

    @abstractmethod
    def summarize(self, headline: str, snippet: str, source: str) -> Summary: ...
