const Hook = {
  mounted() {
    const input = this.el.querySelector("input");

    this.changeListener = input.addEventListener("change", (ev) => {
      if (ev.bubbles === true) {
        return;
      }
      const changeEvent = new Event("change", { bubbles: true });
      input.dispatchEvent(changeEvent);
    });
  },
};

export default Hook;
