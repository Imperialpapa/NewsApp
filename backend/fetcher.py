"""Fetch RSS feeds, dedupe across sources, return ranked top stories.

Clustering strategy (simple but effective for 6 finance sources):
- Extract significant tokens from headline (uppercase words, tickers, numbers,
  words >= 4 chars, stopwords removed).
- Two items cluster together if they share >= MIN_SHARED significant tokens.
- Cluster rank score = (#distinct sources) * 10 + (inverse age in hours).
  Cross-source coverage dominates; recency breaks ties.
"""
from __future__ import annotations

import concurrent.futures
import html
import logging
import re
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone

import feedparser
from dateutil import parser as dtparser

from .sources import SOURCES, Source

log = logging.getLogger(__name__)

MAX_AGE_HOURS = 24
MIN_SHARED_TOKENS = 2

_STOPWORDS = frozenset(
    """a an the of to in on for with by as is are was were be been being this that these those
    it its from at or and but if into over under after before up down new latest news report
    says said reports reuters bloomberg cnbc marketwatch yahoo financial times ft market markets
    stock stocks share shares today year week month day top breaking just now live update updates
    how why what when where who can could will would may might should would""".split()
)

_TOKEN_RE = re.compile(r"[A-Za-z][A-Za-z0-9.\-]{2,}")


@dataclass
class Article:
    source: Source
    headline: str
    url: str
    snippet: str
    published_at: datetime

    @property
    def tokens(self) -> set[str]:
        return _significant_tokens(self.headline + " " + self.snippet[:200])


@dataclass
class Cluster:
    articles: list[Article] = field(default_factory=list)

    @property
    def sources(self) -> set[str]:
        return {a.source.key for a in self.articles}

    @property
    def lead(self) -> Article:
        # Prefer summarizable sources over headline-only ones for the lead,
        # then most recent.
        return max(
            self.articles,
            key=lambda a: (a.source.summarize, a.published_at),
        )

    def score(self, now: datetime) -> float:
        age_h = max(1.0, (now - self.lead.published_at).total_seconds() / 3600)
        return len(self.sources) * 10.0 + (1.0 / age_h)


def _significant_tokens(text: str) -> set[str]:
    text = html.unescape(text).lower()
    return {
        t for t in _TOKEN_RE.findall(text)
        if t not in _STOPWORDS and not t.isdigit()
    }


def _parse_published(entry) -> datetime:
    for key in ("published", "updated", "pubDate"):
        raw = entry.get(key)
        if raw:
            try:
                dt = dtparser.parse(raw)
                if dt.tzinfo is None:
                    dt = dt.replace(tzinfo=timezone.utc)
                return dt.astimezone(timezone.utc)
            except (ValueError, TypeError):
                continue
    return datetime.now(timezone.utc)


def _fetch_source(source: Source, cutoff: datetime) -> list[Article]:
    try:
        feed = feedparser.parse(source.rss_url)
    except Exception as e:
        log.warning("Failed to fetch %s: %s", source.key, e)
        return []
    articles: list[Article] = []
    for entry in feed.entries[:30]:
        published = _parse_published(entry)
        if published < cutoff:
            continue
        headline = html.unescape(entry.get("title", "")).strip()
        url = entry.get("link", "")
        snippet = html.unescape(
            re.sub(r"<[^>]+>", "", entry.get("summary", ""))
        ).strip()
        if not headline or not url:
            continue
        articles.append(Article(
            source=source,
            headline=headline,
            url=url,
            snippet=snippet[:1000],
            published_at=published,
        ))
    return articles


def fetch_all() -> list[Article]:
    """Fetch all sources in parallel, filter to last 24h."""
    cutoff = datetime.now(timezone.utc) - timedelta(hours=MAX_AGE_HOURS)
    articles: list[Article] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=len(SOURCES)) as pool:
        futures = {pool.submit(_fetch_source, s, cutoff): s for s in SOURCES}
        for fut in concurrent.futures.as_completed(futures):
            articles.extend(fut.result())
    log.info("Fetched %d articles across %d sources", len(articles), len(SOURCES))
    return articles


def cluster(articles: list[Article]) -> list[Cluster]:
    """Group articles covering the same story using shared-token heuristic."""
    clusters: list[Cluster] = []
    for art in articles:
        tokens = art.tokens
        if len(tokens) < MIN_SHARED_TOKENS:
            continue
        placed = False
        for c in clusters:
            # Merge if any existing article in the cluster shares enough tokens.
            if any(len(tokens & other.tokens) >= MIN_SHARED_TOKENS for other in c.articles):
                c.articles.append(art)
                placed = True
                break
        if not placed:
            clusters.append(Cluster(articles=[art]))
    return clusters


def top_stories(top_n: int) -> list[Cluster]:
    articles = fetch_all()
    clusters = cluster(articles)
    now = datetime.now(timezone.utc)
    clusters.sort(key=lambda c: c.score(now), reverse=True)
    return clusters[:top_n]


def per_source_top(per_source_limit: int = 5) -> dict[str, list[Article]]:
    """For each source, return the N most recent articles (deduped by URL).

    Returns at most `per_source_limit` per source; may return fewer if the
    source's feed had less than N items in the MAX_AGE_HOURS window. Sources
    are guaranteed to be keys in the result dict even if empty.
    """
    articles = fetch_all()
    buckets: dict[str, list[Article]] = {s.key: [] for s in SOURCES}
    seen_urls: dict[str, set[str]] = {s.key: set() for s in SOURCES}
    # Sort newest first so .append + cap = top-N by recency.
    articles.sort(key=lambda a: a.published_at, reverse=True)
    for art in articles:
        key = art.source.key
        if art.url in seen_urls[key]:
            continue
        if len(buckets[key]) >= per_source_limit:
            continue
        buckets[key].append(art)
        seen_urls[key].add(art.url)
    return buckets
