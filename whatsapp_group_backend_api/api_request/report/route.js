const express = require("express");
const router = express.Router();
const DetailedReport = require("./detailed_report");
const CampaignReport = require("./summary_report");

require("dotenv").config();
const validator = require('../../validation/middleware')
const valid_user = require("../../validation/valid_user_middleware");

const DetailedReportValidation = require("../../validation/report_validation");

const main = require('../../logger');

router.get(
  "/detailed_report",
  validator.body(DetailedReportValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger

      var result = await DetailedReport.detailed_report(req);
       
      logger.info("[API RESPONSE] " + JSON.stringify(result))
     
      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

router.get(
  "/summary_report",
  validator.body(DetailedReportValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger

      var result = await CampaignReport.summary_report(req);
       
      logger.info("[API RESPONSE] " + JSON.stringify(result))
     
      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

module.exports = router;
