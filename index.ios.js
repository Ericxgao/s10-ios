/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 */
'use strict';
let React = require('react-native');
let {
  AppRegistry,
  NativeAppEventEmitter,
} = React;

let TSDDPClient = require('./lib/ddpclient');
let BridgeManager = require('./modules/BridgeManager');
let TSLogger = React.NativeModules.TSLogger; // not wrapping because dont have callerInstance.
let LayoutContainer = require('./components/LayoutContainer');

// polyfill the process functionality needed
global.process = require("./lib/process.polyfill");

TSLogger.log('JS App Launched', 'debug', '', 'index.io.js', '', 0);
console.log('bundle url', BridgeManager.bundleUrlScheme());

let ddp = new TSDDPClient(BridgeManager.serverUrl());

NativeAppEventEmitter.addListener('RegisteredPushToken', (tokenInfo) => {
  if (!tokenInfo) {
    TSLogger.log('Register push token called with no token', 'warning', 'index.io.js', '', 0);
    return;
  }

  tokenInfo.appId = BridgeManager.appId();
  tokenInfo.version = BridgeManager.version();
  tokenInfo.build = BridgeManager.build();
  tokenInfo.deviceId = BridgeManager.deviceId();
  tokenInfo.deviceName = BridgeManager.deviceName();

  ddp.call({ methodName: 'device/update/push', params: tokenInfo })
  .then(() => {
    TSLogger.log('Registered push token', 'debug', 'index.io.js', '', 0);
  })
  .catch(err => {
    TSLogger.log(JSON.stringify(err), 'error', 'index.io.js', '', 0);
  })
});

class Main extends React.Component {
  render() {
    return <LayoutContainer ddp={ddp} />;
  }
}

AppRegistry.registerComponent('Taylr', () => Main);
