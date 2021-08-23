const storageKey = "HiddenDetails";

const Hook = {
  mounted() {
    this.detailsUuid = this.el.dataset.uuid;

    const summary = this.el.querySelector("summary");
    const storageData = localStorage.getItem(storageKey);
    this.hiddenDetails = {};
    this.setInitialState = () => {
      const initialState = this.hiddenDetails[this.detailsUuid]?.isOpen;
      this.el.open = !!(initialState === undefined || initialState);
    };
    if (storageData) {
      try {
        this.hiddenDetails = JSON.parse(storageData);
      } catch {
        console.warn("Failed to load hidden details from localStorage.");
      }
    }

    this.setInitialState();

    summary.addEventListener("click", (ev) => {
      const open = !this.el.open;
      this.el.open = open;
      this.hiddenDetails[this.detailsUuid] = {
        isOpen: open,
      };
      localStorage.setItem(storageKey, JSON.stringify(this.hiddenDetails));
      ev.preventDefault();
    });
  },
  updated() {
    this.setInitialState();
  },
};

export default Hook;
