import {
  init as sentryInit,
  showReportDialog as sentryShowReportDialog,
  setUser as sentrySetUser,
} from "@sentry/browser";
import { Integrations as TracingIntegrations } from "@sentry/tracing";

function currentUrlWithoutParameters() {
  return location.pathname
    .replace(
      /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/gi,
      "<uuid>"
    )
    .replace(/\d{4}-\d{2}-\d{2}/g, "<date>");
}

export function init(dataset) {
  sentryInit({
    dsn: dataset.sentryDsn,
    integrations: [
      new TracingIntegrations.BrowserTracing({
        beforeNavigate: (context) => ({
          ...context,
          name: currentUrlWithoutParameters(),
        }),
      }),
    ],
    tracesSampleRate: 0.1,
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
