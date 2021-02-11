const PostMessage = {
  mounted() {
    const target = this.el.dataset.postMessageTarget ?? this.el.dataset.phxComponent;

    const pushEvent = target === null
      ? (payload) => this.pushEvent("received_post_message", { payload })
      : (payload) => this.pushEventTo(target, "received_post_message", { payload });

    this.onMessage = ({ origin, data }) => {
      if (!origin === window.location.origin) return;

      pushEvent(data);
    }

    window.addEventListener("message", this.onMessage, false);

    this.handleEvent("send_opener_post_messsage", data => {
      if (!window.opener) return;

      window.opener.postMessage(data);
    })

    this.handleEvent("close_window", () => window.close())
  },
  destroyed() {
    window.removeEventListener("message", this.onMessage);
  },
};

export default PostMessage;