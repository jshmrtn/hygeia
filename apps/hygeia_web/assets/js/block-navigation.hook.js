import {translate} from "./translation";

const Hook = {
  mounted() {
    this.locked = false;

    const confirmationMessage = translate("Do you really want to continue without saving?");

    this.preventNavigation = (event) => {
      if (!this.locked) return;

      event.preventDefault()
      event.returnValue = ""
    };

    this.preventLink = (event) => {
      if(!('phxLink' in event.target.dataset)) return;
      if (!this.locked) return;
      if(confirm(confirmationMessage)) return;

      event.preventDefault();
      event.stopPropagation();
    };
    
    document.addEventListener('click', this.preventLink);
    window.addEventListener("beforeunload", this.preventNavigation);

    this.handleEvent("block_navigation", () => this.locked = true);
    this.handleEvent("unblock_navigation", () => this.locked = false);
  },
  destroyed() {
    document.removeEventListener('click', this.preventLink);
    window.removeEventListener("beforeunload", this.preventNavigation);
  },
};

export default Hook;