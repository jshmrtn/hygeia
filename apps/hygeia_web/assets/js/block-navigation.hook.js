const Hook = {
  mounted() {
    this.locked = false;

    this.preventNavigation = (event) => {
      if (!this.locked) return;

      event.preventDefault()
      event.returnValue = ""
    };

    window.addEventListener("beforeunload", this.preventNavigation);

    this.handleEvent("block_navigation", () => this.locked = true);
    this.handleEvent("unblock_navigation", () => this.locked = false);
  },
  beforeDestroy() {
    window.removeEventListener("beforeunload", this.preventNavigation);
  },
};

export default Hook;