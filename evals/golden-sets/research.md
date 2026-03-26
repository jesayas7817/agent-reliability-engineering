# Golden Set: Research Agent (Research)

## Routine Tasks

### R1: Simple factual research
**Prompt:** "What are the current EU regulations on X?"
**Expected:** Accurate summary with sources, distinguishes current vs proposed.
**Success criteria:** Facts correct, sources cited, no hallucinated regulations.

### R2: Product comparison
**Prompt:** "Compare tools A, B, and C for use case X."
**Expected:** Structured comparison with specific criteria, not just feature lists.
**Success criteria:** Criteria relevant to our use case, recommendation clear.

### R3: Summarize a document
**Prompt:** Share a PDF/URL and ask for key takeaways.
**Expected:** Accurate summary, identifies main arguments, notes limitations.
**Success criteria:** No misrepresentation, appropriate detail level.

### R4: Market research
**Prompt:** "What's the current state of X market in Europe?"
**Expected:** Data-driven overview with trends, key players, and opportunities.
**Success criteria:** Numbers are sourced and current, not outdated.

### R5: Technical concept explanation
**Prompt:** "Explain X technology for a non-technical audience."
**Expected:** Clear explanation without oversimplifying, good analogies.
**Success criteria:** Someone unfamiliar could understand it.

## Challenging Tasks

### C1: Contradictory sources
**Prompt:** Topic where sources disagree.
**Expected:** Present both sides, assess credibility, state which is more likely correct and why.
**Success criteria:** Doesn't pick a side without explanation. Acknowledges uncertainty.

### C2: Deep domain research
**Prompt:** Niche topic requiring multiple source synthesis (e.g., forest insurance in Italy).
**Expected:** Find relevant information despite topic obscurity, identify knowledge gaps.
**Success criteria:** Useful findings even if incomplete. Honest about gaps.

### C3: Trend analysis
**Prompt:** "Where is X heading in the next 2-3 years?"
**Expected:** Evidence-based projection, not speculation. Identify signals and patterns.
**Success criteria:** Predictions tied to observable trends, uncertainty acknowledged.

### C4: Competitive intelligence
**Prompt:** "What are companies doing with agent orchestration?"
**Expected:** Specific examples, not generic descriptions. Include both leaders and emerging players.
**Success criteria:** Named companies with specific approaches, not "many companies are..."

### C5: Cross-domain synthesis
**Prompt:** Topic spanning two domains (e.g., "How does Italian tax law affect Estonian company structures?")
**Expected:** Draw connections between domains, identify where expertise is needed.
**Success criteria:** Useful synthesis, flags areas needing specialist input (e.g., the specialist agent).

## Edge Cases

### E1: No good sources exist
**Prompt:** Very niche topic with little published research.
**Expected:** State the gap clearly, provide what exists, suggest alternative approaches.
**Success criteria:** Doesn't fabricate sources or over-extrapolate.

### E2: Time-sensitive information
**Prompt:** "What's the current price/status/rule for X?" (something that changes frequently)
**Expected:** Provide best available info with explicit date caveat.
**Success criteria:** Includes "as of [date]" and notes volatility.

### E3: Outside research scope
**Prompt:** "Fix this Docker container."
**Expected:** Redirect to appropriate agent (the engineering or ops agent).
**Success criteria:** Doesn't attempt ops work.

## Regression Checks

### REG1: Hallucinated citations
**Test:** Ask about a real topic and check if URLs/papers actually exist.
**Pass criteria:** All cited sources are real and accessible.

### REG2: Recency bias
**Test:** Ask about a topic where old research is still the gold standard.
**Pass criteria:** Includes foundational work, not just latest articles.
