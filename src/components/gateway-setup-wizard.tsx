'use client'

import { useEffect } from 'react'
import { AnimatePresence, motion } from 'motion/react'
import { HugeiconsIcon } from '@hugeicons/react'
import {
  CloudIcon,
  CheckmarkCircle02Icon,
  Alert02Icon,
  Settings02Icon,
} from '@hugeicons/core-free-icons'
import { useGatewaySetupStore } from '@/hooks/use-gateway-setup'
import { Button } from '@/components/ui/button'

function GatewayStepContent() {
  const { testStatus, testError, connectionOk, testConnection, proceed } =
    useGatewaySetupStore()

  const handleTest = async () => {
    const ok = await testConnection()
    if (ok) {
      // Auto-proceed after short delay so user sees the success state
      setTimeout(() => proceed(), 800)
    }
  }

  return (
    <div className="w-full">
      <div className="mb-6 flex flex-col items-center text-center">
        <div className="mb-4 flex size-20 items-center justify-center rounded-2xl bg-gradient-to-br from-accent-500 to-accent-600 text-white shadow-lg">
          <HugeiconsIcon icon={CloudIcon} className="size-10" strokeWidth={1.5} />
        </div>
        <h2 className="mb-3 text-2xl font-semibold text-primary-900">
          Connect to Gateway
        </h2>
        <p className="max-w-md text-base leading-relaxed text-primary-600">
          ClawSuite needs an OpenClaw gateway to work. Make sure it's running
          and configured in your <code className="rounded bg-primary-100 px-1.5 py-0.5 text-xs font-medium">.env</code> file.
        </p>
      </div>

      {/* Setup instructions */}
      <div className="mb-5 rounded-lg border border-primary-200 bg-primary-50 p-4">
        <h3 className="mb-2 text-sm font-semibold text-primary-900">
          Quick Setup
        </h3>
        <ol className="space-y-2 text-sm text-primary-700">
          <li className="flex gap-2">
            <span className="font-semibold text-primary-400">1.</span>
            <span>
              Copy the example config:{' '}
              <code className="rounded bg-primary-100 px-1 py-0.5 text-xs">
                cp .env.example .env
              </code>
            </span>
          </li>
          <li className="flex gap-2">
            <span className="font-semibold text-primary-400">2.</span>
            <span>
              Set your gateway token in <code className="rounded bg-primary-100 px-1 py-0.5 text-xs">.env</code>:
            </span>
          </li>
          <li className="ml-5 rounded bg-primary-100 p-2 font-mono text-xs text-primary-800">
            CLAWDBOT_GATEWAY_TOKEN=your_token_here
          </li>
          <li className="flex gap-2">
            <span className="font-semibold text-primary-400">3.</span>
            <span>
              Find your token:{' '}
              <code className="rounded bg-primary-100 px-1 py-0.5 text-xs">
                openclaw config get gateway.auth.token
              </code>
            </span>
          </li>
          <li className="flex gap-2">
            <span className="font-semibold text-primary-400">4.</span>
            <span>Restart ClawSuite, then click Test Connection below</span>
          </li>
        </ol>
      </div>

      {/* Status messages */}
      {testError && (
        <div className="mb-4 flex items-start gap-2 rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800">
          <HugeiconsIcon
            icon={Alert02Icon}
            className="mt-0.5 size-4 shrink-0"
            strokeWidth={2}
          />
          <div>
            <p>{testError}</p>
            <p className="mt-1 text-xs text-red-600">
              Make sure OpenClaw gateway is running and your .env has the correct
              CLAWDBOT_GATEWAY_URL and CLAWDBOT_GATEWAY_TOKEN.
            </p>
          </div>
        </div>
      )}

      {testStatus === 'success' && (
        <div className="mb-4 flex items-start gap-2 rounded-lg border border-green-200 bg-green-50 p-3 text-sm text-green-800">
          <HugeiconsIcon
            icon={CheckmarkCircle02Icon}
            className="mt-0.5 size-4 shrink-0"
            strokeWidth={2}
          />
          <span>Connected to gateway!</span>
        </div>
      )}

      <div className="flex gap-3">
        <Button
          variant="secondary"
          onClick={() => void handleTest()}
          disabled={testStatus === 'testing'}
          className="flex-1"
        >
          {testStatus === 'testing' ? 'Testing...' : 'Test Connection'}
        </Button>
        <Button
          variant="default"
          onClick={proceed}
          disabled={!connectionOk}
          className="flex-1 bg-accent-500 hover:bg-accent-600"
        >
          Continue
        </Button>
      </div>
    </div>
  )
}

function ProviderStepContent() {
  const { skipProviderSetup, completeSetup } = useGatewaySetupStore()

  return (
    <div className="w-full">
      <div className="mb-6 flex flex-col items-center text-center">
        <div className="mb-4 flex size-20 items-center justify-center rounded-2xl bg-gradient-to-br from-purple-500 to-purple-600 text-white shadow-lg">
          <HugeiconsIcon
            icon={Settings02Icon}
            className="size-10"
            strokeWidth={1.5}
          />
        </div>
        <h2 className="mb-3 text-2xl font-semibold text-primary-900">
          Configure Providers
        </h2>
        <p className="max-w-md text-base leading-relaxed text-primary-600">
          You'll need at least one AI provider (OpenAI, Anthropic, or
          OpenRouter) to start chatting.
        </p>
      </div>

      <div className="mb-5 rounded-lg border border-primary-200 bg-primary-50 p-4">
        <h3 className="mb-2 text-sm font-semibold text-primary-900">
          Add a provider:
        </h3>
        <ol className="space-y-2 text-sm text-primary-700">
          <li className="flex gap-2">
            <span className="font-semibold text-primary-400">1.</span>
            <span>
              Run{' '}
              <code className="rounded bg-primary-100 px-1 py-0.5 text-xs">
                openclaw providers list
              </code>{' '}
              to see available providers
            </span>
          </li>
          <li className="flex gap-2">
            <span className="font-semibold text-primary-400">2.</span>
            <span>
              Add your API key:{' '}
              <code className="rounded bg-primary-100 px-1 py-0.5 text-xs">
                openclaw providers add
              </code>
            </span>
          </li>
          <li className="flex gap-2">
            <span className="font-semibold text-primary-400">3.</span>
            <span>Or configure providers in ClawSuite's Settings page</span>
          </li>
        </ol>
      </div>

      <div className="flex gap-3">
        <Button variant="secondary" onClick={skipProviderSetup} className="flex-1">
          Skip for Now
        </Button>
        <Button
          variant="default"
          onClick={completeSetup}
          className="flex-1 bg-accent-500 hover:bg-accent-600"
        >
          Done
        </Button>
      </div>

      <p className="mt-3 text-center text-xs text-primary-500">
        You can always configure providers later from Settings
      </p>
    </div>
  )
}

export function GatewaySetupWizard() {
  const { isOpen, step, initialize } = useGatewaySetupStore()

  useEffect(() => {
    void initialize()
  }, [initialize])

  if (!isOpen) return null

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2 }}
          className="fixed inset-0 z-[110] flex items-center justify-center bg-ink/80 backdrop-blur-sm"
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            className="relative w-[min(520px,92vw)] min-w-[320px] overflow-hidden rounded-2xl border border-primary-200 bg-primary-50 shadow-2xl"
          >
            <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-accent-500/5 via-transparent to-transparent" />

            <div className="relative px-8 pb-8 pt-10">
              <AnimatePresence mode="wait">
                <motion.div
                  key={step}
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -20 }}
                  transition={{ duration: 0.2 }}
                >
                  {step === 'gateway' && <GatewayStepContent />}
                  {step === 'provider' && <ProviderStepContent />}
                </motion.div>
              </AnimatePresence>
            </div>

            <div className="border-t border-primary-200 bg-primary-100/50 px-6 py-3">
              <p className="text-center text-xs text-primary-500">
                Need help?{' '}
                <a
                  href="https://docs.openclaw.ai"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-accent-600 underline hover:text-accent-700"
                >
                  Documentation
                </a>
              </p>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
