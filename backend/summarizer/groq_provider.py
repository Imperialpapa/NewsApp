from .. import config
from .openai_compat import OpenAICompatSummarizer


class GroqSummarizer(OpenAICompatSummarizer):
    def __init__(self) -> None:
        super().__init__(
            base_url="https://api.groq.com/openai/v1",
            api_key=config.GROQ_API_KEY,
            model=config.GROQ_MODEL,
        )
