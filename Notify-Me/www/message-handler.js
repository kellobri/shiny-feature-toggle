// This recieves messages of type "confirm-request" from the server.
Shiny.addCustomMessageHandler("confirm-request",
  function(message) {
    alert(JSON.stringify(message));
  }
);