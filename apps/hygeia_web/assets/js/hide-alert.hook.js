const storageKey = "HiddenAlerts";

const Hook = {
  alertId() {
    return this.el.dataset.alertId;
  },
  mounted() {
    const storageData = localStorage.getItem(storageKey);
    this.hiddenAlerts = [];
    try {
      if (storageData) {
        this.hiddenAlerts = JSON.parse(storageData);
      }
    } catch {
      console.warn("Failed to load hidden alerts from localStorage.");
    }
    this.pushEvent("hide_alerts", { alertIds: this.hiddenAlerts });

    this.el.querySelectorAll("button").forEach((b) => {
      b.addEventListener("click", () => {
        this.hiddenAlerts.push(b.dataset.alertId);
        localStorage.setItem(storageKey, JSON.stringify(this.hiddenAlerts));
        this.pushEvent("hide_alerts", { alertIds: this.hiddenAlerts });
      });
    });
  },
};

export default Hook;
