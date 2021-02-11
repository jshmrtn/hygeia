import {
  init as sentryInit,
  showReportDialog as sentryShowReportDialog,
  setUser as sentrySetUser,
} from "@sentry/browser";

export function init(dataset) {
  sentryInit({ dsn: dataset.sentryDsn });
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