from .. import config
from .openai_compat import OpenAICompatSummarizer


class GeminiSummarizer(OpenAICompatSummarizer):
    def __init__(self) -> None:
        super().__init__(
            base_url="https://generativelanguage.googleapis.com/v1beta/openai",
            api_key=config.GEMINI_API_KEY,
            model=config.GEMINI_MODEL,
        )
