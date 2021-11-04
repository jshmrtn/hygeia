const Hook = {
  mounted() {
    this.handleEvent("new_value", ({ input_id, value }) => {
      if (this.el.id !== input_id) {
        return;
      }
      const changeEvent = new Event("change", { bubbles: true });
      const input = this.el.querySelector("input");
      input.value = value;
      input.dispatchEvent(changeEvent);
    });
  },
};

export default Hook;
