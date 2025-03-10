
var winston = require('winston');
const config = require('./config/default.json');
const config_all = require('./config/all_log.json');
const DailyRotateFile = require('winston-daily-rotate-file');

const logFormat = winston.format.combine(
  // winston.format.colorize(),
  winston.format.timestamp({
    format: "DD-MM-YYYY HH:mm:ss",
  }),
  winston.format.printf(
    info => `${info.timestamp} ${info.level}: ${info.message}`,
  ),);

const transport = new DailyRotateFile({
  filename: config.logConfig.logFolder + config.logConfig.logFile,
  datePattern: "YYYY-MM-DD",
  maxSize: '20m',
});

const transport_all = new DailyRotateFile({
  filename: config_all.logConfig.logFolder + config_all.logConfig.logFile,
  datePattern: "YYYY-MM-DD",
  maxSize: '20m',
});

const logger = winston.createLogger({
  format: logFormat,
  transports: [
    transport,
    new winston.transports.Console({
      level: "info",
    })
  ]
});

const logger_all = winston.createLogger({
  format: logFormat,
  transports: [
    transport_all,
    new winston.transports.Console({
      level: "info",
    }),
  ]
});

module.exports = {logger,logger_all};
