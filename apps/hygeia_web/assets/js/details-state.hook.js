const storageKey = "HiddenDetails";

const Hook = {
  mounted() {
    const detailsUuid = this.el.dataset.uuid;

    const summary = this.el.querySelector("summary");
    const storageData = localStorage.getItem(storageKey);
    this.hiddenDetails = {};
    if (storageData) {
      try {
        this.hiddenDetails = JSON.parse(storageData);
      } catch {
        console.warn("Failed to load hidden details from localStorage.");
      }
    }

    const initialState = this.hiddenDetails[detailsUuid]?.isOpen;
    this.el.open = !!(initialState === undefined || initialState);

    summary.addEventListener("click", (ev) => {
      const open = !this.el.open;
      this.el.open = open;
      this.hiddenDetails[detailsUuid] = {
        isOpen: open,
      };
      localStorage.setItem(storageKey, JSON.stringify(this.hiddenDetails));
      ev.preventDefault();
    });
  },
};

export default Hook;
