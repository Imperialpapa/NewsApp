from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass(frozen=True)
class Summary:
    summary_en: str
    summary_ko: str | None = None


SYSTEM_PROMPT = (
    "You are a financial news editor for busy global finance professionals. "
    "You will be given a news headline and snippet. Produce exactly 3 short "
    "bullet points in English AND the same 3 bullets translated into natural, "
    "concise Korean. Each bullet is one sentence focused on WHY it matters to "
    "markets (tickers, sectors, macro). No fluff. No intro phrases like 'This "
    "article' or '이 기사는'. Do NOT prepend dashes, asterisks, or bullet "
    "characters — the client renders bullets. Join the 3 bullets with a single "
    "newline (\\n) inside each string. The Korean bullets must convey the "
    "same content as the English ones, in matching order. "
    "Return strictly this JSON shape and nothing else:\n"
    '{"summary_en": "en bullet 1\\nen bullet 2\\nen bullet 3",'
    ' "summary_ko": "ko bullet 1\\nko bullet 2\\nko bullet 3"}'
)


class Summarizer(ABC):
    """Provider-agnostic summarizer interface.

    Given a headline + snippet, returns an English summary. Implementations
    select model/endpoint via env config. Failures should raise — the pipeline
    falls back to headline-only on exception.
    """

    @abstractmethod
    def summarize(self, headline: str, snippet: str, source: str) -> Summary: ...
