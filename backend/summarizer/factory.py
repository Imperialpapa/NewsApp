from .. import config
from .base import Summarizer


def get_summarizer() -> Summarizer:
    provider = config.LLM_PROVIDER
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
        f"Unknown LLM_PROVIDER={provider!r}. Expected: anthropic | groq | glm"
    )
