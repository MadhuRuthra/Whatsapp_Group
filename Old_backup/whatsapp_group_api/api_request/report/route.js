const express = require("express");
const router = express.Router();
const Report = require("./report");
require("dotenv").config();
const validator = require('../../validation/middleware')
const valid_user = require("../../validation/valid_user_middleware");

const ReportValidation = require("../../validation/report_validation");

const main = require('../../logger');

router.get(
  "/campaign_report",
  validator.body(ReportValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger

      var result = await Report.campaign_report(req);
       
      logger.info("[API RESPONSE] " + JSON.stringify(result))
     
      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

module.exports = router;
