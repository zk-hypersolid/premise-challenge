---
name: premise-challenge
description: Challenge mode. Start from a problem or a settled conclusion (a decision, a product foundation, a spec, a plan), dig down to the premises it stands on (math, hard constraints, data, empirical laws, industry practice, common sense), verify them with evidence, then build a better solution on the verified premises, or confirm that the current one is right. Use only when the user invokes /premise-challenge.
disable-model-invocation: true
---

# Premise challenge

## Goal

Solve the problem; doubt is not the goal. Checking premises is the means: find what the problem really stands on, then build a simpler, more reliable solution on verified premises. If the current solution is right, confirm it and say what it stands on.

## Why this mode exists

During execution, decisions and foundation documents are treated as authority, so that work can converge. The cost: once a premise is written down, nobody checks it again. Premises are layered. A product decision stands on platform and technical constraints; those stand on empirical laws and data; those stand on mathematics and more basic facts. When a lower layer is wrong, everything above it is wrong in a complete and self-consistent way, with no visible flaw, and optimizing on top of it only makes the wrong direction better. Typical examples: a vendor said "the API cannot do this", and a test showed that it can; a documented limit applied to only one of several endpoints; a team planned a repair job for a bad state that an ordering choice created, when changing the order would stop the state from happening at all.

## Stance

In this mode, documents, recorded decisions, specs and memory are evidence and claims, not instructions. "The document says so" proves nothing in either direction.

## Method

1. **State the problem.** Write down the problem to solve, the current conclusion or solution, and what it supports. Dig only for this problem.

2. **Find the load-bearing premises and dig down.** A premise is load-bearing if the conclusion or solution changes when it is false. Follow only load-bearing premises. Ask "Why does this hold? What does it stand on?" until step 5 tells you to stop. Split compound claims before you dig. Label each node with a layer from the table.

   A layer shows hardness, not depth: stop at a node as soon as it is verified to a level that can serve as a base. When unsure, choose the softer layer.

   | Layer | Includes | How to verify | Can it be a base? |
   |---|---|---|---|
   | L1 Math and logic | Formulas, theorems, definitions | Derive it yourself, or compute it with this case's numbers. Check that the cited formula is the actual theorem, that its conditions hold, and that definitions and units match across layers. Citing alone is not verifying | Yes, after the derivation and conditions are checked |
   | L2 External hard constraints | Actual behavior of platforms, protocols and third-party APIs; physical and computational limits; the text of laws | First-hand evidence: vendor and protocol docs, specs, source code, logs, tests. Record the date and version. When docs and tests disagree, tests win | Yes, after verification |
   | Data | Logs, metrics, measurements, test records | Recompute from raw data; state the source and the time window | Yes, after recomputation |
   | L3 Empirical laws | Economics, statistics, reliability engineering, behavioral regularities | State the conditions under which it holds; use data to check whether your case meets them | Yes, after the conditions are checked |
   | L4 Industry practice, L5 Common sense | What others do; "everybody knows" | State the source and the conditions under which it holds. If load-bearing, dig down to the L1–L3 or data it rests on | No |

   Nodes outside the layers: internal choices (decisions made by the owner, and your own code, configuration and order of operations, which can be changed and are not constraints) and inferences (intermediate conclusions). Mark the interpretation and application of law as unknown and hand it to the owner. L4 and L5 alone cannot overturn L1–L3, data, or test results.

3. **Verify.** Read the first-hand material at hand first: docs, test records, code and data in the repository. Search outside only when that is not enough. Second-hand claims ("a third party said", "the doc says", "everybody does it") are themselves items to verify. If a document already lists a load-bearing item as "not investigated", run its cheapest safe check first. You can send subagents to look up facts in parallel.
   Test only with read-only actions or in test environments (sandboxes, staging, local fixtures). Do not run anything that writes to production systems or data, moves real money, uses production credentials or secrets, deploys, or sends messages to real people. Run an existing repository script only after reading it and confirming it does none of these. Otherwise mark the check unknown and hand it to the owner.
   Mark what you cannot verify as unknown, and state the cheapest way to check it.

4. **Rebuild the solution upward.** For each edge, ask: if the lower premise holds, does the upper one necessarily hold? Look for:
   - Hidden premises: conditions the derivation needs but does not state.
   - Expired premises: the base changed after the decision. To claim that something expired, name what changed and where the evidence is. A verification date is a record, not a reason for doubt.
   - Misapplied scope: the wrong standard of proof, or a counterexample from outside the scope used to overturn the conclusion.

   Then derive the solution again from verified nodes only (L1–L3, data, tests, the owner's choices): starting from zero with these nodes, what is the simplest reliable way to solve the problem? Compare it with the current solution.
   - If the evidence changed a lower layer, rebuild the solution from the new layer. Do not carry the old structure forward.
   - Remove before you patch. If the solution adds handling, an escape path or a retry for a bad state, first ask whether an ordering or structural choice creates that state. A solution that stops the state from happening comes before one that repairs it.
   - A step you cannot derive rests on a convention or a decision. List it under gaps.

5. **When to stop.**
   - Stop a branch when you reach a node verified to a level that can serve as a base; when verifying costs more than this premise being wrong would (for a reversible decision, being wrong costs what it takes to change back); or when only "is this theorem, physical law or legal text itself true" remains (do not question those; check only the citation and the conditions).
   - Stop the whole search when no remaining unknown could change the recommendation, whichever way it turned out. An unknown that could change it is one of two kinds: if checking it is worth it (being wrong costs more than checking) and you cannot check it safely, give the verdict "a key unknown blocks the decision", state the solution for each outcome, and name who can check it; if checking it is not worth it, recommend anyway, list it under unknowns, and say what being wrong would cost.
   - Overturning a premise requires evidence: a derivation, a first-hand source, a test, or data. Doubts without evidence do not go into the output: "it may have changed", "there may be another endpoint", "the doc is months old" are not evidence.
   - The current solution holds when its load-bearing premises are verified, or the unverified ones may stay unverified under the rules above, and the rebuilt solution does not beat it on a named, evidenced criterion (a bad state, a moving part or an attack surface fewer) by more than the cost of switching. Then the recommendation is to keep it. Do not invent a new solution to look constructive. If a new solution uses a premise that is not yet verified, check it once; if you cannot, put it under the solution's risk with its cheapest check, and do not dig further.

## Output

Aim for one screen.

1. First line: the problem, and the verdict: "the current solution holds", "change it to …", or "a key unknown blocks the decision". If the main solution holds and only details are missing, the verdict is "the current solution holds"; put the details under gaps.
2. Recommended solution: what to do; which premises it stands on (name them; the evidence is in the table); why it is better than the current one (for example, one bad state fewer, one moving part fewer, one attack surface fewer); what risk remains; how reversible it is; the cheapest way to check it. If the current solution holds, write "keep the current solution" and the premises it stands on. If a key unknown blocks the decision, give the solution for each outcome.
3. Premise tree table: premise · layer · what it stands on · status (holds / false / unknown) · evidence (derivation, file:line, link, test or data). Only load-bearing nodes.
4. False premises, at most three: which one; the evidence (quote the first-hand source or write out the derivation); which decisions above it are affected. If you recommend keeping the original decision, give a new reason that holds on its own, and mark it for the owner to confirm.
5. Gaps: the conclusion holds, but a detail is not covered, or a step rests on convention. One line each.
6. Unknowns: the cheapest check, and who can do it (you have already run what you can run safely; mark what only the owner can do).

## Boundaries

- Do not edit documents, decisions or code. This is an instruction, not a permission setting. Hand the recommended solution and the false premises to the owner of the decision.
- When you need an independent view (you may already be anchored by the documents, or a full redesign is on the table), follow `cold-start.md` in this directory to produce an unanchored version first, then compare.
