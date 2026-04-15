import { NodeSDK } from '@opentelemetry/sdk-node'
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node'
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http'
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-http'
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics'
import { resourceFromAttributes } from '@opentelemetry/resources'

const endpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT ?? 'http://localhost:4318'
const serviceName = process.env.OTEL_SERVICE_NAME ?? 'nuxt-app'
const serviceVersion = process.env.OTEL_SERVICE_VERSION ?? '0.0.0'

const sdk = new NodeSDK({
  resource: resourceFromAttributes({
    'service.name': serviceName,
    'service.version': serviceVersion,
    'service.namespace': 'devparana',
  }),

  traceExporter: new OTLPTraceExporter({
    url: `${endpoint}/v1/traces`,
  }),

  metricReaders: [
    new PeriodicExportingMetricReader({
      exporter: new OTLPMetricExporter({
        url: `${endpoint}/v1/metrics`,
      }),
      // Export metrics every 60 seconds
      exportIntervalMillis: 60_000,
    }),
  ],

  instrumentations: [
    getNodeAutoInstrumentations({
      // Disable fs instrumentation — too noisy, generates high-cardinality spans
      '@opentelemetry/instrumentation-fs': { enabled: false },
    }),
  ],
})

try {
  sdk.start()
  console.log(`[otel] SDK started — service="${serviceName}" endpoint="${endpoint}"`)
} catch (error) {
  console.error('[otel] Failed to start SDK', error)
}

function shutdown() {
  sdk
    .shutdown()
    .then(() => process.exit(0))
    .catch((error: unknown) => {
      console.error('[otel] Graceful shutdown failed', error)
      process.exit(1)
    })
}

// Graceful shutdown hooks — flush pending spans/metrics before exit
process.on('SIGTERM', shutdown)
process.on('SIGINT', shutdown)
