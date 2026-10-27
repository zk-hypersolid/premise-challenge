# Premise Challenge

**Rebuild a solution from what it really stands on. Verify the constraints with first-hand evidence, keep every part they require, and list the rest for removal, or confirm that the current solution holds. It is built to dig only where it matters and to stop when more digging would not change the answer.**

[中文版](README.zh-CN.md)

An agent skill for Claude Code and Codex. You switch it on by hand (`/premise-challenge` in Claude Code, `$premise-challenge` in Codex). Give it a problem, or a conclusion that has already been settled: a decision, a spec, a plan, or a *foundation* (the document that states what a product is and the rules it rests on). For each load-bearing premise it asks: *why does this hold, and what does it stand on?* It digs past platform facts into math, data, empirical laws, industry practice and common sense, verifies what it finds, and reports which layer is wrong. Then it rebuilds the solution from the verified constraints only, and compares part by part: a part no constraint requires is listed for removal; if every part has a constraint behind it, the current solution is confirmed. The recommendation goes back to the *owner*, the person who made the decision.

## The problem

During execution, decisions and foundation documents must be treated as authority, or work never converges. The cost is that once a premise is written down, nobody checks it again. Premises are layered, and when a lower layer is wrong, everything above it is wrong in a complete and self-consistent way. Optimizing on top of it only makes the wrong direction better.

```mermaid
flowchart TB
    D["Product decision<br/>e.g. 'promise a 99.99% SLA'"] --> C["Platform and technical constraints"]
    C --> E["Empirical laws and data"]
    E --> M["Mathematics and basic facts"]
    M -. "an error here" .-> X["propagates up silently:<br/>every layer above looks correct"]
    style X fill:#fde2e2,stroke:#d33
```

*Arrows read "stands on".* This skill is the switch that says: *stop executing, start checking the ground.* It stays off by default so that it never turns everyday work into endless doubt.

## When to use it

| Use it when | Example |
|---|---|
| An important decision is about to land, or will be built on | `/premise-challenge the SLA in design.md` |
| A conclusion rests on "everyone does it" | `/premise-challenge our "all writes go through a queue" rule` |
| A vendor or a document says "impossible" or "required" | `/premise-challenge the vendor's claim that X is impossible` |
| Before launch, on core claims or risk assumptions | `/premise-challenge the guarantees on the pricing page` |
| A fix adds handling for a bad state | `/premise-challenge the repair-job plan` |
| Something feels wrong but you cannot say what | `/premise-challenge <the conclusion>` and ask for the premise table |

Do not use it for everyday edits, copywriting or brainstorming (divergent work should not stop for premises), or to clarify what *you* want. It questions conclusions, not the person asking.

## Install

It uses the open [Agent Skills](https://agentskills.io) format and works in **Claude Code** and **Codex**. It is invoked by hand only and never starts on its own.

**Claude Code**

```sh
git clone https://github.com/zk-hypersolid/premise-challenge.git ~/.claude/skills/premise-challenge
```

Run `/premise-challenge <target>`. For one project only, copy the files into that project's `.claude/skills/premise-challenge` instead.

For the cold-start step, also install the bundled subagent, which is set to skip CLAUDE.md files (`omitClaudeMd: true`):

```sh
cp ~/.claude/skills/premise-challenge/agents/cold-designer.md ~/.claude/agents/
```

**Codex**

```sh
git clone https://github.com/zk-hypersolid/premise-challenge.git ~/.agents/skills/premise-challenge
```

Run `$premise-challenge <target>`, or pick it from `/skills`. For one project only, put it in that repository's `.agents/skills/premise-challenge`. The cold-start subagent is a Claude Code feature; in Codex, `cold-start.md` tells the agent to say so instead of running that step with a substitute.

**Chinese version.** Keep a source copy and install the Chinese files from it. Replace `<skills-dir>` with `~/.claude/skills` (Claude Code) or `~/.agents/skills` (Codex):

```sh
git clone https://github.com/zk-hypersolid/premise-challenge.git ~/src/premise-challenge
mkdir -p <skills-dir>/premise-challenge
cp ~/src/premise-challenge/zh-CN/*.md <skills-dir>/premise-challenge/
cp -R ~/src/premise-challenge/scripts ~/src/premise-challenge/agents <skills-dir>/premise-challenge/
```

**Updating.** Run `git -C <skills-dir>/premise-challenge pull`. For the Chinese version, pull `~/src/premise-challenge` and run the copy commands again. If you already have a skill named `premise-challenge`, move it away first.

**How "manual only" works.** Claude Code reads `disable-model-invocation: true` in `SKILL.md`; Codex reads `allow_implicit_invocation: false` in `agents/openai.yaml`. Other tools that support Agent Skills can load `SKILL.md` too, but may start it on their own unless they offer a similar setting; those tools have not been tested.

## How it works

```mermaid
flowchart TB
    T["1 State the problem<br/>break the solution into parts"] --> K["2 Each part: constraint or choice?<br/>verify load-bearing constraints"]
    K -- "cannot verify, or unsafe to test" --> UK["Mark unknown<br/>+ cheapest check"]
    K --> R["3 Rebuild from zero<br/>from verified constraints only"]
    R --> C["4 Compare part by part<br/>no constraint requires it: removal candidate"]
    C --> S{"5 Could a remaining unknown<br/>change the recommendation?"}
    S -- "yes, and it is safe and worth checking" --> K
    S -- "yes, worth checking but not safe to check:<br/>key unknown blocks" --> O
    S -- "no, or not worth checking" --> O["Output: verdict · solution and removals ·<br/>premise table · unknowns"]
    UK --> O
```

1. **State the problem and break down the current solution** into parts (steps, states, mechanisms, jobs), in the order they were added.
2. **Sort constraints from choices.** A constraint is something you cannot change: math, the actual behavior of external systems, data, empirical laws. It is labeled by layer and verified. A choice is something you can change: your code, configuration, order of operations, the owner's decisions. Industry practice and common sense are not constraints. Only load-bearing items are verified.
3. **Rebuild from zero** from verified constraints only. Every part must name the constraint that requires it: without the part, a bad state with evidence would occur. Keeping a bad state from occurring comes before handling it. A worry with no evidence goes under risks; it does not become a new part.
4. **Compare part by part.** A current part that no constraint requires is no longer treated as a premise; it becomes a removal candidate, with the bad state it patched and why that state no longer occurs.
5. **Close.** Keep the current solution when every part has a constraint behind it, or when the new one is not better by more than the cost of switching. Stop when no remaining unknown could change the recommendation; check an unknown only when being wrong costs more than checking, and if that check is not safe to run, the verdict is "a key unknown blocks the decision", with a solution for each outcome.

Simplicity is the result, not the target: every part a constraint requires stays, however many there are.

## The layers: hardness, not depth

```mermaid
flowchart TB
    subgraph BASE["Can serve as a base once verified"]
        L1["L1 Math and logic<br/>formulas · theorems · definitions<br/>derive or compute; check conditions and units"]
        L2["L2 External hard constraints<br/>platforms · protocols · APIs · physics · legal text<br/>first-hand docs or tests; tests beat docs; record date"]
        DA["Data<br/>logs · metrics · measurements<br/>recompute from raw data"]
        L3["L3 Empirical laws<br/>economics · statistics · reliability · behavior<br/>state the conditions; check them with data"]
    end
    subgraph DIG["Not a base"]
        L4["L4 Industry practice<br/>'everyone does it'"]
        L5["L5 Common sense<br/>'everybody knows'"]
    end
    DIG -- "if load-bearing, dig down to L1–L3 or data" --> BASE
    style DIG fill:#fff4e0,stroke:#e0a020
    style BASE fill:#e6f4ea,stroke:#2e7d32
```

| Layer | Includes | How to verify |
|---|---|---|
| **L1** Math and logic | Formulas, theorems, definitions | Derive it, or compute it with this case's numbers. Check the formula is the real theorem, its conditions hold, and units match. Citing is not verifying. |
| **L2** External hard constraints | Platform, protocol and API behavior; physical limits; legal text | First-hand docs, specs, source, logs, tests. Record date and version. Tests beat docs. |
| **Data** | Logs, metrics, measurements, test records | Recompute from raw data; state source and window. |
| **L3** Empirical laws | Economics, statistics, reliability engineering, behavior | State the conditions; check with data that they hold here. |
| **L4** Industry practice · **L5** Common sense | What others do; what "everybody knows" | Not a base. State where it came from and when it holds; if load-bearing, dig down to L1–L3 or data. |

Outside the layers: **internal choices** (the owner's decisions, your own code, config and order of operations, which can change) and **inferences**. L4 and L5 alone can never overturn L1–L3, data or tests. Theorems, physical laws and legal texts are never questioned themselves, only whether they are cited and applied correctly.

## Worked example

A design document says: *"The service runs on 3 replicas, each 99% available. Replica failures are independent, so the service is available 1 − 0.01³ = 99.9999% of the time. Therefore we can promise a 99.99% SLA. Basis: redundancy is common knowledge."*

```mermaid
flowchart TB
    C["Conclusion: promise a 99.99% SLA"]
    C --> P1["Availability = 1 − 0.01³"]
    C --> P2["Replica failures are independent"]
    C --> P3["'Redundancy is common knowledge'"]
    P1 --> A1["L1 · the formula is right<br/>only if failures are independent<br/>⚠️ a condition to check"]
    P2 --> A2["Data · incident log: 60% of replica downtime<br/>hit all three at once (shared database)<br/>❌ premise false"]
    P2 --> A3["L3 · common-cause failure: parts that share<br/>a dependency fail together ✅ holds"]
    P3 --> A4["L5 · not a base → dig down"]
    A4 -.-> A1
    A4 -.-> A2
    A4 -.-> A3
    A1 --> R["Rebuild from verified nodes:<br/>the shared cause alone gives 0.6 × 1% = 0.6% downtime<br/>availability ≈ 99.4%, far below 99.99%"]
    A2 --> R
    A3 --> R
    R --> OUT["Recommendation to the owner:<br/>do not promise 99.99%; set the SLA with margin<br/>below the ≈ 99.4% the data supports,<br/>or remove the shared database first and measure again"]
    style A1 fill:#fff4e0,stroke:#e0a020
    style A2 fill:#fde2e2,stroke:#d33
    style A4 fill:#fff4e0,stroke:#e0a020
    style OUT fill:#e3f2fd,stroke:#1565c0
```

The formula was never wrong; its condition was. Citing a correct formula is not verifying it. The same method handles industry practice. "All writes go through a message queue, because decoupling with a queue is best practice" digs down to the conditions a queue needs to pay off: high or bursty write volume, or several independent consumers. If the data shows about 40 writes a day and one consumer, the queue adds a moving part, another failure point and extra latency, and the practice does not apply here.

**Remove before you patch.** A sign-up flow creates a storage bucket, starts copying starter files into it, then turns on versioning. About 3% of buckets end up without versioning, and the team plans a nightly repair job. Digging shows that the provider refuses to turn on versioning once a bucket holds any file, and every failure in the logs is a bucket whose files arrived first. The bad state comes from the order of two steps. Turning on versioning first (about 80 ms) stops the state from happening. The buckets already affected still need a one-time move to new buckets with versioning on; no nightly job is needed. (The provider here is made up; real storage services differ.)

## Example output

A real run of the published skill (Claude Opus, Claude Code 2.1.287), trimmed, on a made-up repository that matches the "remove before you patch" example above. In it, `design.md` records the current flow as decision D-0409 and the repair-job plan as P-12. Prompt: `/premise-challenge P-12 in design.md`.

<details>
<summary>Show the output</summary>

**Problem:** about 3% of new workspaces end up "active, versioning off", so restore is broken for them. **Verdict: change it to: turn on versioning before seeding starts.** Don't add a nightly job. Fix the workspaces that are already stuck with a one-off backfill.

#### Solution
- **Reorder D-0409:** create the bucket → `PUT versioning` → start seeding. This stops the bad state from happening, so nothing needs repairing afterwards.
- **One-off backfill for the workspaces already stuck** (about 31 per 1,000 created in September). Use P-12's move step once: new bucket → turn on versioning → copy objects → repoint the workspace → delete the old bucket. This is the only path the evidence supports, because a bucket that already has objects never accepts versioning.

**Remove:**
- **Nightly repair job** · patched new stuck workspaces · after the reorder, versioning is always called on an empty bucket, and that returned 200 every time in the probe (20/20) and in production data (969/969).
- **Admin "retry versioning" button** · patched the idea that the error was temporary · retrying on a non-empty bucket returns 409 every time (probe run C: 5 of 5 over 10 minutes). The button could never work.

**What it stands on:** the provider returns 409 once the bucket has objects; the versioning call is fast (p99 140 ms); and the owner's 1.5 s first-load target still has room (1.24 s + 0.14 s ≈ 1.38 s worst case).

**Risks:**
- The backfill's copy step was not probed directly. The cheapest check is to run it once in the provider sandbox on a bucket from run B.
- If a 409 ever shows up on an empty bucket, nothing in this solution handles it. There is no evidence that it happens.

**Reversibility:** the reorder is a one-line ordering change and easy to undo. The backfill deletes old buckets, so check the object counts before deleting.

*(premise table and unknowns trimmed)*

</details>

## Safety boundaries

- **No edits.** The skill instructs the agent never to edit documents, decisions or code; the recommended solution goes to the owner. This is an instruction, not a permission setting, so keep your agent's tool approvals on.
- **Safe testing only.** Tests use read-only actions or test environments (sandboxes, staging, local fixtures). Anything that writes to production systems or data, moves real money, uses production credentials or secrets, deploys, or sends messages to real people is not run; it is marked *unknown* and handed back. Existing repository scripts are run only after the agent reads them and confirms they do none of these.
- **Brakes against invented doubt.** Overturning needs evidence: a derivation, a first-hand source, a test or data. "It may have changed" or "the doc is old" is not evidence.

## What's included

- [SKILL.md](SKILL.md): the method, layers, stop rules and output format.
- [cold-start.md](cold-start.md): how to get an unanchored version before comparing.
- [scripts/make-clean-room.sh](scripts/make-clean-room.sh): exports a git ref and removes the listed agent instruction files, docs, design notes and decision records.
- [agents/cold-designer.md](agents/cold-designer.md): a Claude Code subagent that designs from a brief without loading CLAUDE.md files.
- [agents/openai.yaml](agents/openai.yaml): Codex settings; keeps Codex from starting the skill on its own.
- [zh-CN/](zh-CN/): Chinese versions of SKILL.md and cold-start.md.

## How it was tested (informal)

These are the author's informal local tests. The cases, transcripts and rubric are not published, so treat the results as anecdotal.

- Setup: isolated runs with no other instruction files, on four models; a separate model graded each run against a fixed rubric without knowing which condition produced it.
- Cases: a false premise about an external platform behind a product decision; a sound foundation that should be left alone; a formula whose conditions did not hold, plus contradicting data; a sound formula that should not be doubted; an industry practice whose conditions did not hold.
- Previous, critique-first version, strongest models: passed every case but one. In that case it raised an edge-case concern about a sound claim, which the rubric counted as a miss.
- Current, solution-first version, on two strong models, using the author's local Chinese draft of this version (not the files in this repository), graded the same way: on the five cases above, one run per case and model, it scored the same as the previous version (9/10 each, one edge-case miss each). Two new cases were added in which a planned fix handled a bad state that an ordering choice created; in one the request was to review the fix, in the other to make the fix faster. Over 2 cases × 2 models × 3 runs, both versions recommended changing the order every time (24 of 24 runs, 12 per version). So in short, single-task runs the new wording shows no gain; it is aimed at drift in long sessions, which these tests do not reproduce. The current version's output led with a recommended solution in 21 of its 22 runs (counted by a text search for that section) and was 5–20% longer than the previous version's. The stop rules were then reworded after an outside review (only check an unknown when being wrong costs more than checking; for a reversible decision, being wrong costs what it takes to change back). On a new case with a load-bearing unknown that was slow to check but cheap to undo, both wordings recommended going ahead with a canary rather than waiting, in 12 of 12 runs; three older cases still passed (6 of 6). So this change removes a contradiction in the text, but the tests did not show the old wording causing a problem.
- Subtraction round (the method above: break the solution into parts, rebuild from constraints, compare). New case: a weekly email sent twice, patched over four rounds with a lock, a lock heartbeat, a dedup table and a retry queue. In the hard condition the model first proposed those patches itself, turn by turn, and they were accepted; then the provider gained an idempotency key and the skill was called. Both versions found the key (Opus and Fable, the author's local Chinese draft). The previous version gave a complete removal list in 2 of 6 runs and added no extra mechanism in 2 of 6. This version gave a complete removal list in 5 of 6 and added no extra mechanism in 6 of 6; it passed 5 of 6 overall, the one miss being a run that kept the lock and its heartbeat as "optional" instead of removing them. A case meant to catch over-removal turned out to have a simpler valid answer, so it measured nothing. On the older cases this version scored as before, except one more miss on the "sound foundation" case (1 of 3 Opus runs).
- The previously published text (the English and Chinese files before the subtraction round), on Opus and Fable, one run per case over the eight cases above: 29 of 32 passed. All three misses were on the sound-formula case: the rubric expects "holds", and the skill answered "a key unknown blocks the decision", arguing from the sample size that the data could not rule out the condition the formula needs. We count them as misses, though the argument has a real basis. The files now in this repository have had three runs on Opus (English on the ordering case and the duplicate-email case, Chinese on the ordering case), all passed; the example output above is one of them. They have not had a wider run.
- An earlier version vs. the plain prompt "challenge these premises", 8 runs each: found the false premise 7/8 vs 5/8; left the sound premise alone 7/8 vs 4/8. Neither difference is statistically significant at this sample size. Neither later version was compared with the plain prompt.
- What we did not see: the layers did not make strong models dig deeper; they already do when asked. The skill is meant to add braking (fewer invented doubts), a recommendation built on verified premises, and a consistent output; the results above hint at the first but do not establish it. The safety boundary was not tested.
- Smaller models invented doubts more often. Use a strong model.
- Codex CLI 0.162.1, skill installed in the user skills folder, one task that matches the skill's description without naming it: Codex started the skill on its own in 2 of 2 runs without `agents/openai.yaml` and in 0 of 2 runs with it. Called by name with `$premise-challenge`, it loaded the skill, followed its output format and changed no files.
- The cold-designer subagent was checked once with a canary on Claude Code 2.1.287: a project CLAUDE.md told every reply to start with a marker word, and the subagent's reply did not contain it. Only CLAUDE.md was checked; other context such as MCP server instructions or hook output was not. Check again on your version.

## License

MIT. See [LICENSE](LICENSE).
