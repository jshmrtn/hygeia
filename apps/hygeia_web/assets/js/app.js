// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html";
import { Socket } from "phoenix";
import NProgress from "nprogress";
import { LiveSocket } from "phoenix_live_view";
import BSN from "bootstrap.native";
import BlockNavigation from "./block-navigation.hook";
import PostMessage from "./post-message.hook";
import Chart from "./chart.hook";
import Dropdown from "./dropdown.hook";
import HideAlert from "./hide-alert.hook";
import Input from "./input.hook";
import { init as sentryInit } from "./sentry";
import browserFeatures from "./feature-detect";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken, browser_features: browserFeatures },
  hooks: { BlockNavigation, Chart, Dropdown, HideAlert, Input, PostMessage },
});

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", (info) => NProgress.start());
window.addEventListener("phx:page-loading-stop", (info) => {
  BSN.initCallback(document.body);

  document.querySelectorAll(".stop-propagation").forEach((d) => {
    d.addEventListener("click", (e) => e.stopPropagation());
  });

  NProgress.done();
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// Sentry Setup
if (document.documentElement.dataset.sentryEnabled === "true") {
  sentryInit(document.documentElement.dataset);
}
