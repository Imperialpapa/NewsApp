"""Daily digest pipeline entrypoint.

  fetch RSS → per-source top 5 → summarize (non-BBG/FT) → upsert to Supabase.

Run:  python -m backend.main
"""
from __future__ import annotations

import logging
import sys
from datetime import date, datetime
from zoneinfo import ZoneInfo

from . import config, fetcher, storage
from .sources import SOURCES
from .summarizer import get_summarizer

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
log = logging.getLogger("digest")

KST = ZoneInfo("Asia/Seoul")
PER_SOURCE_LIMIT = 5


def run() -> int:
    log.info("Starting digest. Provider=%s", config.LLM_PROVIDER)
    summarizer = get_summarizer()

    by_source = fetcher.per_source_top(per_source_limit=PER_SOURCE_LIMIT)
    total = sum(len(v) for v in by_source.values())
    if total == 0:
        log.error("No articles fetched from any source. Aborting.")
        return 1
    log.info(
        "Collected %d articles (%s)",
        total,
        ", ".join(f"{k}:{len(v)}" for k, v in by_source.items()),
    )

    rows: list[storage.ArticleRow] = []
    for src in SOURCES:
        items = by_source.get(src.key, [])
        for rank, art in enumerate(items, start=1):
            summary_en = None
            summary_ko = None
            if src.summarize:
                try:
                    s = summarizer.summarize(art.headline, art.snippet, src.name)
                    summary_en, summary_ko = s.summary_en, s.summary_ko
                except Exception as e:
                    log.warning(
                        "Summarize failed for %s #%d: %s", src.key, rank, e
                    )
            snippet = art.snippet.strip() if src.show_snippet and art.snippet else None
            rows.append(storage.ArticleRow(
                source=src.key,
                headline=art.headline,
                original_url=art.url,
                published_at=art.published_at,
                summary_en=summary_en,
                summary_ko=summary_ko,
                rank=rank,
                snippet=snippet,
            ))
            log.info(
                "  [%s] #%d %s%s",
                src.key, rank,
                "(headline-only) " if not src.summarize else "",
                art.headline[:70],
            )

    today_kst = datetime.now(KST).date()
    storage.upsert_digest(today_kst, config.LLM_PROVIDER, rows)
    log.info("Upserted digest for %s (%d rows)", today_kst, len(rows))
    return 0


if __name__ == "__main__":
    sys.exit(run())
