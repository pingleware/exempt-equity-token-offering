"use strict";

const {app, BrowserWindow, ipcMain} = require("electron");
const path = require("path");

const Web3Utils = require('web3-utils');

let mainWindow;

function createWindow () {
    mainWindow = new BrowserWindow({
      width: 800,
      height: 700,
      icon: "../assets/stockcertificate.png",
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true,
        enableRemoteModule: false,
        preload: path.join(__dirname, "preload.js")
      }
    });
  
    mainWindow.loadFile("views/index.html");
    mainWindow.on("closed", function () {
      mainWindow = null;
    });
    //mainWindow.setMenu(null);
    mainWindow.setResizable(false);
}

app.on("ready", createWindow);
app.on("window-all-closed", function () {
  if (process.platform !== "darwin") app.quit();
});
app.on("activate", function () {
  if (mainWindow === null) createWindow();
});
ipcMain.on("error", function(evt, data){
  mainWindow.webContents.send("error", data);
});
