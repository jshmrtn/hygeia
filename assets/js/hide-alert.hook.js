const storageKey = "HiddenAlerts";

const Hook = {
  alertId() {
    return this.el.dataset.alertId;
  },
  mounted() {
    const target = this.el.dataset.phxComponent;
    const storageData = localStorage.getItem(storageKey);
    this.hiddenAlerts = [];
    if (storageData) {
      try {
        this.hiddenAlerts = JSON.parse(storageData);
      } catch {
        console.warn("Failed to load hidden alerts from localStorage.");
      }
    }

    this.pushEventTo(target, "hide_alerts", { alertIds: this.hiddenAlerts });

    this.handleEvent("hide_alert", ({ id }) => {
      this.hiddenAlerts.push(id);
      localStorage.setItem(storageKey, JSON.stringify(this.hiddenAlerts));
      this.pushEventTo(target, "hide_alerts", { alertIds: this.hiddenAlerts });
    });
  },
};

export default Hook;
