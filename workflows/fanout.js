export const meta = {
  name: 'fanout',
  description: 'Fable-style fan-out: decompose task, parallel Sonnet workers, capped Opus verification of load-bearing findings, synthesize',
  whenToUse: 'Audits, migrations, multi-module research — tasks decomposable into independent angles whose key findings deserve adversarial verification',
  phases: [
    { title: 'Decompose', detail: 'Opus splits the task into independent angles' },
    { title: 'Work', detail: 'one Sonnet worker per angle' },
    { title: 'Verify', detail: 'Opus refutation, load-bearing findings only, hard cap' },
  ],
}

const task = typeof args === 'string' ? args : (args && args.task) || ''
if (!task) throw new Error('Pass the task as args: a string or {task: "..."} — the workflow cannot see the conversation, so materialize the full task first')

const MAX_VERIFIES = 20

const ANGLES_SCHEMA = {
  type: 'object',
  required: ['angles'],
  properties: {
    angles: {
      type: 'array',
      minItems: 1,
      maxItems: 7,
      items: {
        type: 'object',
        required: ['key', 'prompt'],
        properties: {
          key: { type: 'string', description: 'short kebab-case label' },
          prompt: { type: 'string', description: 'fully self-contained worker prompt' },
        },
      },
    },
  },
}

const FINDINGS_SCHEMA = {
  type: 'object',
  required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      maxItems: 8,
      items: {
        type: 'object',
        required: ['claim', 'evidence', 'loadBearing'],
        properties: {
          claim: { type: 'string', description: 'one falsifiable statement' },
          evidence: { type: 'string', description: 'file:line refs, URLs, or command output backing it' },
          loadBearing: { type: 'boolean', description: 'true ONLY if this claim changes the overall conclusion or gates a risky action' },
        },
      },
    },
    notCovered: { type: 'string', description: 'what this worker did NOT cover' },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  required: ['verdict', 'reason'],
  properties: {
    verdict: { type: 'string', enum: ['CONFIRMED', 'REFUTED', 'UNCERTAIN'] },
    reason: { type: 'string' },
  },
}

phase('Decompose')
const plan = await agent(
  `Decompose this task into 1-7 INDEPENDENT work angles. Independence test: each angle must be completable without any other angle's result. Return a SINGLE angle if the task does not genuinely decompose — never invent angles to fill a quota. Each angle's prompt must be fully self-contained (the worker sees nothing else — include paths, context, and exactly what to return).\n\nTask: ${task}`,
  { label: 'decompose', model: 'opus', schema: ANGLES_SCHEMA }
)

log(`${plan.angles.length} angle(s): ${plan.angles.map((a) => a.key).join(', ')} — Opus verification capped at ${MAX_VERIFIES} total`)

let verifiesLaunched = 0

const results = await pipeline(
  plan.angles,
  (a) =>
    agent(
      `${a.prompt}\n\nReturn at most 8 findings as falsifiable claims with concrete evidence (file:line, URLs, command output). Set loadBearing=true ONLY where the claim changes the overall conclusion or gates a risky action — mechanical results (file lists, renames) are loadBearing=false. Also report what you did NOT cover.`,
      { label: a.key, phase: 'Work', model: 'sonnet', schema: FINDINGS_SCHEMA }
    ),
  (r, a) => {
    if (!r) return null
    const loadBearing = (r.findings || []).filter((f) => f.loadBearing)
    const toVerify = []
    for (const f of loadBearing) {
      if (verifiesLaunched >= MAX_VERIFIES) break
      verifiesLaunched++
      toVerify.push(f)
    }
    const capped = loadBearing.length - toVerify.length
    if (capped > 0) log(`${a.key}: verify cap reached — ${capped} load-bearing finding(s) reported unverified`)
    return parallel(
      toVerify.map((f) => () =>
        agent(
          `Adversarially verify this claim — your job is to REFUTE it, not confirm it. Hunt for counter-evidence first (contradicting code, superseding docs, breaking inputs). Default to UNCERTAIN when evidence is thin.\n\nClaim: ${f.claim}\nStated evidence: ${f.evidence}`,
          { label: `verify:${a.key}`, phase: 'Verify', model: 'opus', effort: 'xhigh', schema: VERDICT_SCHEMA }
        ).then((v) => ({ angle: a.key, ...f, verdict: v }))
      )
    ).then((verified) => ({
      angle: a.key,
      notCovered: (r.notCovered || '').trim(),
      verified: verified.filter(Boolean),
      cappedLoadBearing: loadBearing.slice(toVerify.length).map((f) => ({ angle: a.key, ...f })),
      contextOnly: (r.findings || []).filter((f) => !f.loadBearing).map((f) => ({ angle: a.key, ...f })),
    }))
  }
)

const perAngle = plan.angles.map((a, i) =>
  results[i] || { angle: a.key, failed: true, notCovered: 'worker failed or returned nothing', verified: [], cappedLoadBearing: [], contextOnly: [] }
)

const all = perAngle.flatMap((r) => r.verified)
const confirmed = all.filter((f) => f.verdict && f.verdict.verdict === 'CONFIRMED')
const refuted = all.filter((f) => f.verdict && f.verdict.verdict === 'REFUTED')
const uncertain = all.filter((f) => f.verdict && f.verdict.verdict === 'UNCERTAIN')
const unverified = perAngle
  .flatMap((r) => r.cappedLoadBearing)
  .concat(all.filter((f) => !f.verdict || !f.verdict.verdict))
const contextFindings = perAngle.flatMap((r) => r.contextOnly)
const coverageGaps = perAngle
  .filter((r) => r.failed || r.notCovered)
  .map((r) => ({ angle: r.angle, notCovered: r.notCovered }))

log(`confirmed ${confirmed.length} / uncertain ${uncertain.length} / refuted ${refuted.length} / unverified ${unverified.length} / context-only ${contextFindings.length}`)

return { task, confirmed, uncertain, refuted, unverified, contextFindings, coverageGaps }
