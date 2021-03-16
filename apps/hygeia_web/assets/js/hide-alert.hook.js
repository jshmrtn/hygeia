const storageKey = "HiddenAlerts";

const Hook = {
  alertId() {
    return this.el.dataset.alertId;
  },
  mounted() {
    this.target = this.el.dataset.phxComponent;
    this.clickCallbacks = {};

    const storageData = localStorage.getItem(storageKey);
    this.hiddenAlerts = [];
    if (storageData) {
      try {
        this.hiddenAlerts = JSON.parse(storageData);
      } catch {
        console.warn("Failed to load hidden alerts from localStorage.");
      }
    }
    this.pushEventTo(this.target, "hide_alerts", { alertIds: this.hiddenAlerts });
    this.hideAlert = (event) => {
      this.hiddenAlerts.push(event.target.dataset.alertId);
      localStorage.setItem(storageKey, JSON.stringify(this.hiddenAlerts));
      this.pushEventTo(this.target, "hide_alerts", { alertIds: this.hiddenAlerts });
    };
  },
  updated() {
    this.el.querySelectorAll("button").forEach((b) => {
      b.removeEventListener("click", this.hideAlert);
      b.addEventListener("click", this.hideAlert);
    });
  },
};

export default Hook;
