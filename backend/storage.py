"""Supabase upsert. Idempotent per digest_date — reruns overwrite same day."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime

from supabase import Client, create_client

from . import config


def client() -> Client:
    return create_client(config.SUPABASE_URL, config.SUPABASE_SERVICE_KEY)


@dataclass
class ArticleRow:
    source: str
    headline: str
    original_url: str
    published_at: datetime | None
    summary_en: str | None
    summary_ko: str | None
    rank: int
    snippet: str | None = None


def upsert_digest(
    digest_date: date,
    provider: str,
    articles: list[ArticleRow],
) -> None:
    db = client()
    # Delete prior digest for this date (cascades to articles), then insert fresh.
    db.table("digests").delete().eq("digest_date", digest_date.isoformat()).execute()
    inserted = (
        db.table("digests")
        .insert({
            "digest_date": digest_date.isoformat(),
            "provider": provider,
            "article_count": len(articles),
        })
        .execute()
    )
    digest_id = inserted.data[0]["id"]
    rows = [
        {
            "digest_id": digest_id,
            "source": a.source,
            "headline": a.headline,
            "original_url": a.original_url,
            "published_at": a.published_at.isoformat() if a.published_at else None,
            "summary_en": a.summary_en,
            "summary_ko": a.summary_ko,
            "rank": a.rank,
            "snippet": a.snippet,
        }
        for a in articles
    ]
    if rows:
        db.table("articles").insert(rows).execute()
