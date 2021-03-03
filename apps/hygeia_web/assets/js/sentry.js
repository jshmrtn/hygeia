import {
  init as sentryInit,
  showReportDialog as sentryShowReportDialog,
  setUser as sentrySetUser,
} from "@sentry/browser";
import { Integrations as TracingIntegrations } from "@sentry/tracing";

export function init(dataset) {
  sentryInit({
    dsn: dataset.sentryDsn,
    integrations: [new TracingIntegrations.BrowserTracing()],
    tracesSampleRate: 0.1
  });
  sentrySetUser(JSON.parse(dataset.sentryUser));
  document.addEventListener(
    "DOMContentLoaded",
    () => {
      const element = document.getElementById("sentry-report");

      if (!element) return;

      sentryShowReportDialog({
        user: JSON.parse(dataset.sentryUser),
        ...JSON.parse(element.dataset.reportOptions),
      });
    },
    false
  );
}