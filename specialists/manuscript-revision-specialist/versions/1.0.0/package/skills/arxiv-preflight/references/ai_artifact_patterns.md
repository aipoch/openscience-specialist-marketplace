# AI-Artifact Pattern Library

Patterns are grouped by what they reveal. Each pattern lists: regex (Python-compatible, case-insensitive unless noted), default severity, and a short note. Scripts read this file as data — keep the table format stable.

A hit is only meaningful if it appears in **manuscript body, abstract, figure/table caption, or bibliography**. Hits inside fenced code blocks, `\begin{lstlisting}` ... `\end{lstlisting}`, `\begin{verbatim}` ... `\end{verbatim}`, or `% ... \n` LaTeX comments should be suppressed.

---

## 1. LLM meta-commentary (direct evidence of unedited model output)

| ID | Regex | Severity | Notes |
| --- | --- | --- | --- |
| META-01 | `\bas an? (?:(?:ai|artificial intelligence)\s+)?(?:(?:large )?language\s+)?(?:model|assistant)\b` | BLOCKER | "As an AI model", "as an AI language model", "as a large language model", "as an AI assistant". Pipes inside backticks. |
| META-02 | `\b(i (cannot|can'?t|am unable to|don'?t have access)|i (am|'m) sorry,? but)\b` | BLOCKER | First-person assistant refusal/apology. |
| META-03 | `\bhere(?:'s| is) (?:a |the |an )?(?:\w+\s+){0,2}(?:summary|rewrite|version|draft|outline|paragraph|response|answer)\b` | BLOCKER | Assistant hand-off phrasing. Allows up to two adjectives between the article and the noun ("here is a polished version", "here is the quick revised draft"). |
| META-04 | `\b(would you like me to|let me know if you|happy to (?:help|revise)|feel free to ask)\b` | BLOCKER | Assistant offer to continue. |
| META-05 | `\b(certainly!|sure!|of course!|great question)\b` | HIGH | Assistant pleasantries. Often a true hit but occasionally appears in dialogue datasets — review context. |
| META-06 | `\b(in this (?:response|answer|reply)|the (?:answer|response) (?:is|above))\b` | HIGH | Response framing. |
| META-07 | `\b(based on (?:the|your) (?:prompt|instructions?|input))\b` | BLOCKER | Acknowledges a prompt. |
| META-08 | `\b(i hope this helps|hope (?:that|this) (?:helps|answers))\b` | BLOCKER | Conversational closer. |
| META-09 | `\b(note:?\s+as an ai|disclaimer:?\s+i am an ai)\b` | BLOCKER | Self-disclosure. |
| META-10 | `\b(regenerate response|stop generating)\b` | BLOCKER | UI text leak. |

## 2. Prompt residue (the prompt itself ended up in the text)

| ID | Regex | Severity | Notes |
| --- | --- | --- | --- |
| PROMPT-01 | `\b(write (?:a|the) (?:paragraph|section|abstract|introduction))\s+(?:about|on)\b` | BLOCKER | Instruction phrasing. |
| PROMPT-02 | `\b(rewrite|paraphrase|summari[sz]e) the (?:following|above)\b` | HIGH | Could appear in legit text — check sentence subject. |
| PROMPT-03 | `\b(?:user|assistant|system)\s*:\s*` | HIGH | Chat turn markers. Suppress inside dialogue-data tables. |
| PROMPT-04 | `\bplease (?:provide|generate|produce|create)\b` | MEDIUM | Common in instructions; check whether the verb subject is the reader or the model. |
| PROMPT-05 | `<\|(?:im_start|im_end|endoftext|user|assistant|system)\|>` | BLOCKER | Tokenizer special tokens leaked. |
| PROMPT-06 | `\[INST\]|\[/INST\]|<<SYS>>|<</SYS>>` | BLOCKER | Llama-family chat tags. |

## 3. Placeholders and unfilled content

| ID | Regex | Severity | Notes |
| --- | --- | --- | --- |
| PLACE-01 | `\b(TODO|TBD|FIXME|XXX)\b` | BLOCKER | All-caps; case-sensitive. |
| PLACE-02 | `\b(to be (?:filled|added|determined|completed))\b` | BLOCKER |  |
| PLACE-03 | `\binsert (?:\w+\s+){0,2}(?:citation|reference|figure|table|number|proof|results?|data|text|equation|here)\b` | BLOCKER | "Insert citation", "INSERT FORMAL PROOF HERE", "insert real numbers". Allows up to two intervening words between "insert" and the noun. |
| PLACE-04 | `\b(placeholder|dummy data|fake data|sample data)\b` | BLOCKER | Promoted from HIGH: in body text or captions this denotes unfilled content. Acceptable usages ("dummy variable" in stats methodology) are a known false-positive class — author can justify. |
| PLACE-05 | `\b(illustrative (?:only|purposes?)|for illustration)\b` | BLOCKER | Promoted from HIGH: caption text "illustrative only" means the table is not real results. |
| PLACE-06 | `\bXX(?=[\s.%,;:!?\\]|$)` | BLOCKER | Promoted from HIGH: "XX%" / "XX." / "XX " is an unambiguous unfilled placeholder. |
| PLACE-07 | `\b(lorem ipsum|consectetur adipiscing)\b` | BLOCKER | Filler text. |
| PLACE-08 | `\bN/?A\b` repeated ≥ 4× in one table | MEDIUM | Many "N/A" cells in a results table suggests incomplete experiments. Detected at table level, not regex level. |
| PLACE-09 | `0\.00(?:\s|$|&)` repeated ≥ 3× in one table row/column | MEDIUM | All-zero results column. Detected at table level. |
| PLACE-10 | `\b(citation needed|reference needed|cite (?:this|here))\b` | BLOCKER | Wikipedia-style markers. |
| PLACE-11 | `\b(intentionally left blank|this section is empty|this section will be (?:filled|completed)|to be written)\b` | BLOCKER | A section the author has not yet written. |

## 4. Authorship and disclosure red flags

| ID | Regex | Severity | Notes |
| --- | --- | --- | --- |
| AUTH-01 | author list contains `(ChatGPT|GPT-?\d|Claude|Gemini|LLaMA|Llama|Bard|Copilot)` as a name | BLOCKER | AI listed as author. Detected by parsing `\author{}` or PDF metadata, not body regex. |
| AUTH-02 | `\b(co-?authored by (?:chatgpt|gpt|claude|gemini))\b` | BLOCKER |  |
| DISC-01 | manuscript mentions `(ChatGPT|GPT-4|Claude|Gemini|Copilot|LLM)` in body but Acknowledgments/Methods have no disclosure | HIGH | Detected by cross-reference at scan time, not pure regex. |

## 5. Citation-formatting tells (paired with reference verification)

These do not alone constitute a finding; they raise the prior that a reference is fabricated. The reference verifier should treat these as confidence-lowering signals.

| ID | Heuristic | Severity contribution |
| --- | --- | --- |
| CITE-FORM-01 | DOI string structurally invalid (does not match `10\.\d{4,9}/.+`) | +1 toward HIGH |
| CITE-FORM-02 | Year in the future or > current year + 1 | +1 toward HIGH |
| CITE-FORM-03 | Page range invalid (start > end, both equal to "1") | +1 toward MEDIUM |
| CITE-FORM-04 | Venue is generic ("Proceedings of the International Conference on Machine Learning and Deep Learning") without specific year/volume | +1 toward MEDIUM |
| CITE-FORM-05 | All authors share an unusual initials pattern (e.g., all "X. Y. Author") | +1 toward MEDIUM |

## How to extend

When a new failure mode shows up (e.g., a new chat tag leaks from a future model), add a row to the relevant section with a unique ID. Keep severities calibrated: a single false `BLOCKER` is more damaging than a missed `MEDIUM`. Prefer `HIGH` when uncertain.

## Scope guard

These patterns target evidence of **unchecked AI output**, not authorial voice. Do not add patterns that flag long sentences, em-dashes, bulleted lists, or "delve" / "tapestry" / "in conclusion". Such patterns produce style-based false positives and contradict the skill's contract.
