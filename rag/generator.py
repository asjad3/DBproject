import os
import logging
from typing import List, Dict, Any
from groq import Groq
from dotenv import load_dotenv

# logging setup
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

load_dotenv()

class GenerationEngine:
    def __init__(self, model_name: str = "llama-3.3-70b-versatile"):
        api_key = os.getenv("GROQ_API_KEY")
        if not api_key:
            logger.critical("GROQ_API_KEY not found in environment variables!")
            raise ValueError("API Key is required.")

        self.client = Groq(api_key=api_key)
        self.model_name = model_name

        # system's instructions for AI's persona and operational rules
        self.system_instruction = (
            "You are the DisasterLink AI Assistant, a professional disaster response coordinator for Pakistan.\n"
            "Your goal is to provide accurate, concise, and actionable summaries based ONLY on provided reports.\n\n"
            "STRICT RULES:\n"
            "1. Use ONLY the provided sources. If the answer is not there, state: 'I do not have enough data to answer this.'\n"
            "2. MANDATORY CITATIONS: You must cite every fact using [Source X] notation.\n"
            "3. TONE: Professional, calm, and focused on logistics/safety.\n"
            "4. DO NOT speculate or provide general safety advice not found in the reports."
        )

    def _format_context(self, retrieved_docs: List[Dict[str, Any]]) -> str:
        context_parts = []
        for i, doc in enumerate(retrieved_docs):
            meta = doc["metadata"]
            context_parts.append(
                f"--- SOURCE {i+1} ---\n"
                f"REPORT_ID: {meta.get('report_id')}\n"
                f"LOCATION: {meta.get('district')}, {meta.get('province')}\n"
                f"SEVERITY: {meta.get('severity')}\n"
                f"ORG: {meta.get('org_name')}\n"
                f"CONTENT: {doc['text']}"
            )
        return "\n\n".join(context_parts)

    def generate_response(self, query: str, retrieved_docs: List[Dict[str, Any]]) -> Dict[str, Any]:
        if not retrieved_docs:
            return {
                "answer": "I'm sorry, but I couldn't find any relevant incident reports in our database to answer your question.",
                "sources": [],
                "status": "no_results"
            }

        try:
            # 1. Prepare the context
            context = self._format_context(retrieved_docs)

            # 2. Build the user prompt
            user_prompt = f"CONTEXT FROM REPORTS:\n{context}\n\nUSER QUESTION: {query}"

            # 3. Call Groq with System Instructions
            logger.info(f"Generating response for query: {query[:50]}...")
            response = self.client.chat.completions.create(
                model=self.model_name,
                messages=[
                    {"role": "system", "content": self.system_instruction},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0.2,
            )

            # 4. Package the response with metadata for the frontend
            return {
                "answer": response.choices[0].message.content,
                "sources": [
                    {
                        "id": d["metadata"].get("report_id"),
                        "location": f"{d['metadata'].get('district')}, {d['metadata'].get('province')}",
                        "score": d.get("score")
                    } for d in retrieved_docs
                ],
                "status": "success"
            }

        except Exception as e:
            logger.error(f"Groq API Failure: {e}")
            return {
                "answer": "An internal error occurred while generating the AI response.",
                "sources": [],
                "status": "error"
            }

if __name__ == "__main__":
    from retriever import RetrievalEngine

    try:
        retriever = RetrievalEngine()
        generator = GenerationEngine()

        test_query = "What is the medical situation in Sindh?"

        docs = retriever.retrieve(test_query)

        result = generator.generate_response(test_query, docs)

        print(f"\nAI RESPONSE:\n{result['answer']}")
        print("\nSOURCES CITED:")
        for s in result['sources']:
            print(f"- Report {s['id']} (Confidence: {s['score']})")

    except Exception as e:
        logger.error(f"Pipeline test failed: {e}")
