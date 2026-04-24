"""News source registry + licensing policy.

LICENSING: Bloomberg and FT are aggressive rights holders — we only store
headlines and link out. All other sources can be AI-summarized (short, with
prominent link back) under standard RSS/fair-use norms. Revisit if traffic
scales enough to justify Reuters Connect / Bloomberg / FT syndication deals.
"""
from dataclasses import dataclass


@dataclass(frozen=True)
class Source:
    key: str
    name: str
    rss_url: str
    summarize: bool       # False = do not send to LLM
    show_snippet: bool    # True = store publisher's RSS description for display


SOURCES: tuple[Source, ...] = (
    Source(
        key="bloomberg",
        name="Bloomberg",
        rss_url="https://feeds.bloomberg.com/markets/news.rss",
        summarize=False,      # headline-only policy (no LLM rewrite)
        show_snippet=True,    # publisher's own RSS teaser is OK to display
    ),
    Source(
        key="reuters",
        name="Reuters",
        # Reuters killed official RSS; Google News proxy as a workaround.
        rss_url="https://news.google.com/rss/search?q=site:reuters.com+when:1d&hl=en-US&gl=US&ceid=US:en",
        summarize=True,
        show_snippet=False,
    ),
    Source(
        key="ft",
        name="Financial Times",
        rss_url="https://www.ft.com/rss/home",
        summarize=False,
        show_snippet=True,
    ),
    Source(
        key="cnbc",
        name="CNBC",
        rss_url="https://search.cnbc.com/rs/search/combinedcms/view.xml?partnerId=wrss01&id=10000664",
        summarize=True,
        show_snippet=False,
    ),
    Source(
        key="yahoo",
        name="Yahoo Finance",
        # Yahoo's native feed updates slowly (entries often >24h old).
        # Google News proxy gives us fresh yahoo.com articles, same pattern as Reuters.
        rss_url="https://news.google.com/rss/search?q=site:finance.yahoo.com+when:1d&hl=en-US&gl=US&ceid=US:en",
        summarize=True,
        show_snippet=False,
    ),
    Source(
        key="marketwatch",
        name="MarketWatch",
        rss_url="http://feeds.marketwatch.com/marketwatch/topstories/",
        summarize=True,
        show_snippet=False,
    ),
)

SOURCES_BY_KEY = {s.key: s for s in SOURCES}
