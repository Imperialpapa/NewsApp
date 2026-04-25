import os
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_SERVICE_KEY = os.environ["SUPABASE_SERVICE_KEY"]

LLM_PROVIDER = os.getenv("LLM_PROVIDER", "groq").lower()

ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
ANTHROPIC_MODEL = os.getenv("ANTHROPIC_MODEL", "claude-haiku-4-5")

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
GROQ_MODEL = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile")

GLM_API_KEY = os.getenv("GLM_API_KEY")
GLM_MODEL = os.getenv("GLM_MODEL", "glm-4-flash")

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
# gemini-2.0-flash was retired for new API keys in early 2026; use 2.5-flash.
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

TOP_N = int(os.getenv("TOP_N", "5"))
