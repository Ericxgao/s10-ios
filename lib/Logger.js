let React = require('react-native');
let TSLogger = React.NativeModules.TSLogger;

class Logger {

  constructor(callerInstance) {
    this.callerInstance = callerInstance;
  }

  warning(message) {
    console.warn(message);
    TSLogger.log(message, 'warning', this.callerInstance.constructor.name, '', 0);
  }

  verbose(message) {
    console.log(message);
    TSLogger.log(message, 'verbose', this.callerInstance.constructor.name, '', 0);
  }

  debug(message) {
    console.log(message);
    TSLogger.log(message, 'debug', this.callerInstance.constructor.name, '', 0);
  }

  error(message) {
    console.error(message);
    TSLogger.log(message, 'error', this.callerInstance.constructor.name, '', 0);
  }

  info(message) {
    console.info(message);
    TSLogger.log(message, 'info', this.callerInstance.constructor.name, '', 0);
  }
}

module.exports = Logger;