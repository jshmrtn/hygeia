import BSN from "bootstrap.native";

const {
  Alert,
  Button,
  Carousel,
  Collapse,
//   Dropdown,
//   Modal,
//   Offcanvas,
  Popover,
//   ScrollSpy,
//   Tab,
//   Toast,
  Tooltip,
} = BSN;

const componentsInit = {
  Alert: Alert.init,
  Button: Button.init,
  Carousel: Carousel.init,
  Collapse: Collapse.init,
//   Dropdown: Dropdown.init,
//   Modal: Modal.init,
//   Offcanvas: Offcanvas.init,
  Popover: Popover.init,
//   ScrollSpy: ScrollSpy.init,
//   Tab: Tab.init,
//   Toast: Toast.init,
  Tooltip: Tooltip.init,
};

function initializeDataAPI(Konstructor, collection) {
  Array.from(collection).forEach((x) => new Konstructor(x));
}

export function init() {
  Object.keys(componentsInit).forEach((comp) => {
    const { constructor, selector } = componentsInit[comp];
    initializeDataAPI(constructor, document.body.querySelectorAll(selector));
  });
}
