const Hook = {
  mounted() {
    this.close_dropdown = (e) => {
      if (this.el.contains(e.relatedTarget)) return;

      this.pushEventTo(this.el.getAttribute("phx-target"), "close_dropdown");
    };
    this.el.addEventListener("focusout", this.close_dropdown);
  },
  beforeDestroy() {
    this.el.removeEventListener("focusout", this.close_dropdown);
  },
};

export default Hook;
