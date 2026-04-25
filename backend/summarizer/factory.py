from .. import config
from .base import Summarizer
from .chain import ChainSummarizer


def get_summarizer() -> Summarizer:
    """Build a Summarizer from LLM_PROVIDER.

    Single value (e.g. "groq"): returns that provider directly.
    Comma-separated (e.g. "groq,glm"): returns a ChainSummarizer that
    tries providers in order and falls back on exceptions.
    """
    names = [p.strip() for p in config.LLM_PROVIDER.split(",") if p.strip()]
    if not names:
        raise ValueError("LLM_PROVIDER is empty")
    if len(names) == 1:
        return _build_one(names[0])
    return ChainSummarizer([(n, _build_one(n)) for n in names])


def _build_one(provider: str) -> Summarizer:
    if provider == "anthropic":
        from .anthropic_provider import AnthropicSummarizer
        return AnthropicSummarizer()
    if provider == "groq":
        from .groq_provider import GroqSummarizer
        return GroqSummarizer()
    if provider == "glm":
        from .glm_provider import GLMSummarizer
        return GLMSummarizer()
    raise ValueError(
        f"Unknown LLM provider {provider!r}. Expected: anthropic | groq | glm"
    )
