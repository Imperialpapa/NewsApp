from .. import config
from .openai_compat import OpenAICompatSummarizer


class GLMSummarizer(OpenAICompatSummarizer):
    def __init__(self) -> None:
        super().__init__(
            base_url="https://open.bigmodel.cn/api/paas/v4",
            api_key=config.GLM_API_KEY,
            model=config.GLM_MODEL,
        )
