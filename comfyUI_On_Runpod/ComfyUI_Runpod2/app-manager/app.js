const express = require("express");
const { exec } = require("child_process");
const path = require("path");
const app = express();
const PORT = 8000;

// Serve static files from the 'public' directory
app.use(express.static("public"));

// Serve config.json
app.get("/config.json", (req, res) => {
  res.sendFile(path.join(__dirname, "config.json"));
});

// Endpoint to stop ComfyUI
app.get("/stop_comfyui", (req, res) => {
  exec("scripts/stop_comfyui.sh", (error, stdout, stderr) => {
    if (error) {
      console.error(`Error stopping ComfyUI: ${error}`);
      res.status(500).send("Failed to stop ComfyUI.");
      return;
    }
    res.send("Stopped ComfyUI successfully!");
  });
});

// Endpoint to start ComfyUI
app.get("/start_comfyui", (req, res) => {
  exec("scripts/start_comfyui.sh", (error, stdout, stderr) => {
    if (error) {
      console.error(`Error starting ComfyUI: ${error}`);
      res.status(500).send("Failed to start ComfyUI.");
      return;
    }
    res.send("Started ComfyUI successfully!");
  });
});

// Start the server
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Application Manager is running on http://0.0.0.0:${PORT}`);
});
