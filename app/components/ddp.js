/**
 * Copyright (c) 2015-present, S10, Inc.
 *
 * @providesModule ddp
 * @flow
 */
let React = require('react-native');
let { AsyncStorage } = React;
let DDPClient = require("ddp-client");
let _ = require('underscore');

let ddpClient = new DDPClient({
  // All properties optional, defaults shown
  autoReconnect : true,
  autoReconnectTimer : 500,
  maintainCollections : true,
  ddpVersion : '1',  // ['1', 'pre2', 'pre1'] available
  // Use a full url instead of a set of `host`, `port` and `ssl`
  url: 'wss://s10-dev.herokuapp.com/websocket'
  // socketConstructor: WebSocket // Another constructor to create new WebSockets
});

ddp = {};

ddp.collections = ddpClient.collections;

// Initialize a connection with the server
ddp.initialize = function () {
  return new Promise(function(resolve, reject) {
    ddpClient.connect(function(error, wasReconnect) {
      // If autoReconnect is true, this back will be invoked each time
      // a server connection is re-established
      if (error) {
        console.log('DDP connection error!');
        return reject(error);
      }

      if (wasReconnect) {
        console.log('Reestablishment of a connection.');
      }

      console.log('connected!');
      resolve(true);
    });
  });
};

// Method to close the ddp connection
ddp.close = function() {
  return ddpClient.close();
};

// Promised based subscription
ddp.subscribe = function(pubName, params) {
  params = params || undefined;
  if (params && !_.isArray(params)) {
    console.warn('Params must be passed as an array to ddp.subscribe');
  }
  return new Promise(function(resolve, reject) {
    ddpClient.subscribe(pubName, params, function () {
      resolve(true);
    });
  });
};

// Promised based method call
ddp.call = function(methodName, params) {
  params = params || undefined;
  if (params && !_.isArray(params)) {
    console.warn('Params must be passed as an array to ddp.call');
  }

  return new Promise(function(resolve, reject) {
    ddpClient.call(methodName, params,
      function (err, result) {   // callback which returns the method call results
        // console.log('called function, result: ' + result);
        if (err) {
          reject(err);
        } else {
          resolve(result);
        }
      },
      function () {              // callback which fires when server has finished
        // console.log('updated');  // sending any updated documents as a result of
        // console.log(ddpclient.collections.posts);  // calling this method
      }
    );
  });
};

ddp.loginWithToken = function(token) {
  console.log("will try to login with token " + token);
  return new Promise(function(resolve, reject) {
    ddpClient.call("login", [{ resume: token }], function (err, res) {
      if (res) {
        console.log('Logged in with resume token.');
        let obj = {
          loggedIn: true,
          userId: res.id
        };
        resolve(obj);
      } else {
        console.trace(err);
        console.log('Failed login');
        let obj = {
          loggedIn: false,
        };
        resolve(obj);
      }
    });
  });
};

module.exports = ddp;