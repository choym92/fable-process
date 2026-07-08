export const meta = {
  name: 'fanout',
  description: 'Generic Fable-style fan-out: decompose task, parallel Sonnet workers, Opus adversarial verify, synthesize',
  whenToUse: 'Audits, broad research, sweeps — any task decomposable into independent angles whose findings deserve adversarial verification',
  phases: [
    { title: 'Decompose', detail: 'Opus splits the task into independent angles' },
    { title: 'Work', detail: 'one Sonnet worker per angle' },
    { title: 'Verify', detail: 'Opus adversarial refutation per finding' },
  ],
}

const task = typeof args === 'string' ? args : (args && args.task) || ''
if (!task) throw new Error('Pass the task as args: a string or {task: "..."}')

const ANGLES_SCHEMA = {
  type: 'object',
  required: ['angles'],
  properties: {
    angles: {
      type: 'array',
      minItems: 2,
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
      items: {
        type: 'object',
        required: ['claim', 'evidence'],
        properties: {
          claim: { type: 'string', description: 'one falsifiable statement' },
          evidence: { type: 'string', description: 'file:line refs, URLs, or command output backing it' },
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
  `Decompose this task into 2-7 INDEPENDENT work angles. Independence test: each angle must be completable without any other angle's result. Each angle's prompt must be fully self-contained (the worker sees nothing else — include paths, context, and exactly what to return).\n\nTask: ${task}`,
  { label: 'decompose', model: 'opus', schema: ANGLES_SCHEMA }
)

log(`${plan.angles.length} angles: ${plan.angles.map((a) => a.key).join(', ')}`)

const results = await pipeline(
  plan.angles,
  (a) =>
    agent(
      `${a.prompt}\n\nReturn dense factual findings as falsifiable claims with concrete evidence (file:line, URLs, command output). Also report what you did NOT cover.`,
      { label: a.key, phase: 'Work', model: 'sonnet', schema: FINDINGS_SCHEMA }
    ),
  (r, a) =>
    parallel(
      ((r && r.findings) || []).map((f) => () =>
        agent(
          `Adversarially verify this claim — your job is to REFUTE it, not confirm it. Hunt for counter-evidence first (contradicting code, superseding docs, breaking inputs). Default to UNCERTAIN when evidence is thin.\n\nClaim: ${f.claim}\nStated evidence: ${f.evidence}`,
          { label: `verify:${a.key}`, phase: 'Verify', model: 'opus', effort: 'xhigh', schema: VERDICT_SCHEMA }
        ).then((v) => ({ angle: a.key, ...f, verdict: v }))
      )
    ).then((verified) => ({
      angle: a.key,
      notCovered: (r && r.notCovered) || '',
      findings: verified.filter(Boolean),
    }))
)

const perAngle = results.filter(Boolean)
const all = perAngle.flatMap((r) => r.findings)
const confirmed = all.filter((f) => f.verdict && f.verdict.verdict === 'CONFIRMED')
const uncertain = all.filter((f) => f.verdict && f.verdict.verdict === 'UNCERTAIN')
const refuted = all.filter((f) => f.verdict && f.verdict.verdict === 'REFUTED')
const coverageGaps = perAngle.map((r) => ({ angle: r.angle, notCovered: r.notCovered })).filter((g) => g.notCovered)

log(`confirmed ${confirmed.length} / uncertain ${uncertain.length} / refuted ${refuted.length}`)

return { task, confirmed, uncertain, refuted, coverageGaps }
