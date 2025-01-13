$(document).ready(function () {
  // Fetch the configuration
  $.getJSON("/config.json", function (config) {
    // Initially hide all rows
    $("tbody tr").hide();

    // Iterate over the applications in the config
    config.applications.forEach(function (app) {
      // Construct the row's ID and show it
      $("#row" + app).show();
    });
  }).fail(function () {
    console.error("Failed to load config.json");
  });

  // Event handler to stop ComfyUI
  $("#stopComfyUI").click(function () {
    $.get("/stop_comfyui", function (data) {
      alert(data);
    }).fail(function () {
      alert("Failed to stop ComfyUI.");
    });
  });

  // Event handler to start ComfyUI
  $("#startComfyUI").click(function () {
    $.get("/start_comfyui", function (data) {
      alert(data);
    }).fail(function () {
      alert("Failed to start ComfyUI.");
    });
  });
});
