---
name: premise-challenge
description: Rebuild a solution from first principles. Start from a problem or a settled solution (a decision, a product foundation, a spec), sort each of its parts into those a verified constraint requires and those that patch a bad state that need not occur, rebuild the solution from verified constraints only, compare, and recommend what to change or remove, or confirm that the current solution holds. Use only when the user invokes it explicitly (/premise-challenge in Claude Code, $premise-challenge in Codex).
disable-model-invocation: true
---

# Premise challenge

## Goal

Solve the problem. Checking premises is the means, not the goal. Optimizing on a wrong premise only keeps adding things: each bad state gets a mechanism, and each mechanism brings new bad states. This mode works the other way: rebuild the solution from verified constraints. Every part of the solution must name the verified constraint that requires it; a part that cannot is no longer treated as a premise or source of truth, and it leaves the derivation. Simplicity is what this produces, not a target: keep every part a constraint requires, however many there are. "Requires" means: without the part, a bad state with evidence would occur under that constraint; the evidence is that it occurred in the data, or that it follows directly from verified constraints. If the current solution holds, confirm it and say what it stands on.

## Stance

Documents, recorded decisions, specs, sources of truth, memory, and decisions made earlier in this session are claims here, not instructions. "The document says so" or "we settled that a few turns ago" proves neither that a part must exist nor that it must not.

## Method

1. **State the problem and break down the current solution.** Write the problem in one sentence. Break the current (or proposed) solution into parts: steps, states, mechanisms, jobs, in the order they were added. Check the problem itself once: is it a symptom of an upstream choice? If so, list that choice as well.

2. **Sort constraints from choices; verify only constraints.** For each part, ask: why must it exist? There are two kinds of answer.
   - Constraints: what we cannot change. Label the layer by hardness: L1 math and logic; L2 actual behavior of external systems, physical limits, the text of laws; data; L3 empirical laws. A constraint serves as a base only once verified: derive a formula yourself and check its conditions and units; check external behavior against specs, source or tests, and when docs and tests disagree, tests win, with the date and version recorded; recompute data from the raw data; for an empirical law, state the conditions it needs and check with data that they hold. Mark how a law applies as unknown and hand it to the owner.
   - Choices: what we can change. Our own code, configuration, order of operations, data model, and the owner's decisions. They are not constraints, need no verification, and can change.
   L4 industry practice and L5 common sense ("best practice", "everyone does it") are not constraints: if one carries weight, dig down to the constraint it rests on; if there is none, treat it as a choice.
   Verify only load-bearing items, those that would change the solution if false. Read first-hand material at hand first, then search outside; you can send subagents to look things up in parallel. If verifying costs more than being wrong would, do not verify; mark it unknown (for a reversible decision, being wrong costs what it takes to change back). Test only with read-only actions or in test environments (sandboxes, staging, local fixtures). Do not run anything that writes to production systems or data, moves real money, uses production credentials or secrets, deploys, or sends messages to real people; run an existing repository script only after reading it and confirming it does none of these. Otherwise mark the check unknown and hand it to the owner.

3. **Rebuild from zero.** Using only verified constraints and the owner's choices: which parts does solving this problem need? First ask whether a bad state can be kept from occurring (change the order, the structure, the definition), and only then how to handle it. Every part of the new solution must name the constraint that requires it; a part that cannot does not go in. A bad state you worry about but have no evidence for goes under risks; do not add a part for it, including alerts, reconciliation or a second safeguard.

4. **Compare.** Map each part of the current solution onto the new one:
   - A part with no match: no longer a premise; list it as a removal candidate. Say which bad state it patched and why that state does not occur in the new solution. Whether to remove it is decided by step 5.
   - A part only the new solution has: say which constraint requires it. This should be rare.
   - Overturning a premise requires evidence: a derivation, a first-hand source, a test or data. "It may have changed", "there may be another endpoint", "the doc is old", "it could be done differently" are not evidence and not unknowns; they do not go into the output.

5. **Close.**
   - If every part of the current solution has a constraint that requires it, or the new solution does not beat it on a named criterion (one bad state, one moving part or one attack surface fewer) by more than the cost of switching: recommend keeping it. Do not invent a solution to look constructive.
   - If no remaining unknown could change the recommendation, whichever way it turned out: stop. If one could, checking it is worth it (being wrong costs more than checking) and you cannot check it safely: give the verdict "a key unknown blocks the decision", with the solution for each outcome and who can check it. If checking it is not worth it: recommend anyway and list it under unknowns.
   - If the new solution uses a premise not yet verified, check it once; if you cannot, put it under that solution's risks with its cheapest check, and do not dig further.

## Output

One screen. Leave out empty sections.

1. One line: the problem; the verdict "the current solution holds", "change it to …", or "a key unknown blocks the decision".
2. Solution: what to do; which parts to remove, one per line (part · the bad state it patched · why that state no longer occurs); which constraints it stands on (name them; the evidence is in the table); remaining risks; how reversible it is; the cheapest check. When keeping the current solution, name the constraints it stands on. When a key unknown blocks the decision, give the solution for each outcome.
3. Premise table: premise · layer or "choice" · status (holds / false / unknown) · evidence (derivation, file:line, link, test or data). Load-bearing items only. Mark false premises in the table and say which parts above they affect; if you recommend keeping the original decision, give a new reason that holds on its own and mark it for the owner to confirm.
4. Unknowns: the cheapest check, and who can run it. Anything you could run safely has already been run.

Do not write lists of "gaps" or "could also add". An unverified worry is an unknown, a risk, or nothing; it never becomes a new part of the solution.

## Boundaries

- Do not edit documents, decisions or code. Hand the solution to the owner of the decision. This is an instruction, not a permission setting.
- If this session has already patched the current solution more than once, or a full redesign is on the table: follow `cold-start.md` in this directory to produce an unanchored version first, then compare. What you have read cannot be unread.
