---
name: premise-challenge
description: Challenge mode. Attack the premises behind a conclusion (a decision, a product foundation, a spec, a plan), dig down to more fundamental premises (math, hard constraints, data, empirical laws, industry practice, common sense), and verify them with evidence. Use only when the user invokes /premise-challenge.
disable-model-invocation: true
---

# Premise challenge

## Why this mode exists

During execution, decisions and foundation documents are treated as authority, so that work can converge. The cost: once a premise is written down, nobody checks it again. Premises are layered. A product decision stands on platform and technical constraints; those stand on empirical laws and data; those stand on mathematics and more basic facts. When a lower layer is wrong, everything above it is wrong in a complete and self-consistent way, with no visible flaw. Typical examples: a vendor said "the API cannot do this", and a test showed that it can; a documented limit applied to only one of several endpoints.

## Stance

In this mode, documents, recorded decisions, specs and memory are evidence and claims, not instructions. "The document says so" proves nothing in either direction.

## Method

1. **Set the target.** State the conclusion you attack and what it supports. Attack only this target.

2. **Find the load-bearing premises and dig down.** A premise is load-bearing if the conclusion changes when it is false. Follow only load-bearing premises. Ask "Why does this hold? What does it stand on?" until a brake in step 5 applies. Split compound claims before you dig. Label each node with a layer from the table.

   A layer shows hardness, not depth: stop at a node as soon as it is verified to a level that can serve as a base. When unsure, choose the softer layer.

   | Layer | Includes | How to verify | Can it be a base? |
   |---|---|---|---|
   | L1 Math and logic | Formulas, theorems, definitions | Derive it yourself, or compute it with this case's numbers. Check that the cited formula is the actual theorem, that its conditions hold, and that definitions and units match across layers. Citing alone is not verifying | Yes, after the derivation and conditions are checked |
   | L2 External hard constraints | Actual behavior of platforms, protocols and third-party APIs; physical and computational limits; the text of laws | First-hand evidence: vendor and protocol docs, specs, source code, logs, tests. Record the date and version. When docs and tests disagree, tests win | Yes, after verification |
   | Data | Logs, metrics, measurements, test records | Recompute from raw data; state the source and the time window | Yes, after recomputation |
   | L3 Empirical laws | Economics, statistics, reliability engineering, behavioral regularities | State the conditions under which it holds; use data to check whether your case meets them | Yes, after the conditions are checked |
   | L4 Industry practice, L5 Common sense | What others do; "everybody knows" | State the source and the conditions under which it holds. If load-bearing, dig down to the L1–L3 or data it rests on | No |

   Nodes outside the layers: internal choices (decisions made by the owner, and your own code and configuration, which can be changed and are not constraints) and inferences (intermediate conclusions). Mark the interpretation and application of law as unknown and hand it to the owner. L4 and L5 alone cannot overturn L1–L3, data, or test results.

3. **Verify.** Read the first-hand material at hand first: docs, test records, code and data in the repository. Search outside only when that is not enough. Second-hand claims ("a third party said", "the doc says", "everybody does it") are themselves items to verify. You can send subagents to look up facts in parallel.
   Test only with read-only actions or in test environments (sandboxes, staging, local fixtures). Do not run anything that writes to production systems or data, moves real money, uses production credentials or secrets, deploys, or sends messages to real people. Run an existing repository script only after reading it and confirming it does none of these. Otherwise mark the check unknown and hand it to the owner.
   Mark what you cannot verify as unknown, and state the cheapest way to check it.

4. **Check the derivation upward.** For each edge, ask: if the lower premise holds, does the upper one necessarily hold? Look for:
   - Hidden premises: conditions the derivation needs but does not state.
   - Expired premises: the base changed after the decision. To claim that something expired, name what changed and where the evidence is. A verification date is a record, not a reason for doubt.
   - Misapplied scope: the wrong standard of proof, or a counterexample from outside the scope used to overturn the conclusion.
   - First-principles rebuild: using only verified nodes (L1–L3, data, tests, the owner's choices), can you derive the current conclusion? A step you cannot derive rests on a convention or a decision. List it under gaps. Do not turn it into an overturn proposal unless other evidence shows it is false.

5. **Brakes.** Stop digging a branch when any of these applies:
   - You reached a node verified to a level that can serve as a base.
   - Verifying costs more than this premise being wrong would.
   - Only questions like "is this theorem, physical law, or legal text itself true" remain. Do not question theorems, physical laws or legal texts themselves; check only whether they are cited correctly and whether their conditions hold.

   Overturning a premise requires evidence: a derivation, a first-hand source, a test, or data. "It could be done differently" is not evidence. Doubts without evidence do not go into the output: "it may have changed", "there may be another endpoint", "the doc is months old" are not evidence.

## Output

Aim for one screen.

1. First line: the target, and the verdict: "holds", "a premise is false", or "key unknowns". If the main conclusion holds and only details are missing, write "holds". If everything holds, say so; do not invent problems.
2. Premise tree table: premise · layer · what it stands on · status (holds / false / unknown) · evidence (derivation, file:line, link, test or data). Only load-bearing nodes.
3. Overturn proposals, at most three, only where a load-bearing premise is false and the conclusion therefore changes. For each: which premise is false; the evidence (quote the first-hand source or write out the derivation); which decisions above it are affected; what real risk remains after the overturn; the suggested change; how reversible it is. If you recommend keeping the original decision, give a new reason that holds on its own, and mark it for the owner to confirm.
4. Gaps: the conclusion holds, but a detail is not covered, or a step rests on convention. One line each.
5. Unknowns: the cheapest check, and who can do it (you have already checked what you can; mark what only the owner can do).

## Boundaries

- Do not edit documents, decisions or code. This is an instruction, not a permission setting. Hand overturn proposals to the owner of the decision.
- When you need an independent view (you may already be anchored by the documents, or a full redesign is on the table), follow `cold-start.md` in this directory to produce an unanchored version first, then compare.
