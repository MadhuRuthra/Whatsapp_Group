const express = require("express");
const router = express.Router();
const Logout = require("./logout");
require("dotenv").config();
const validator = require('../validation/middleware')
const valid_user = require("../validation/valid_user_middleware_with_request");
const db = require("../db_connect/connect");

const LogoutValidation = require("../validation/logout_validation");
const main = require('../logger');

router.post(
  "/",
  validator.body(LogoutValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all

      var result = await Logout.logout(req);
      result['request_id'] = req.body.request_id;

      var update_api_log = "";
      if (result.response_code == 0) {
        update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = '${result.response_msg}' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
      }
      else {
        update_api_log = `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
      }

      logger_all.info("[update query request] : " + update_api_log);
      const update_api_log_result = await db.query(update_api_log);
      logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

      logger.info("[API RESPONSE] " + JSON.stringify(result))
      logger_all.info("[API RESPONSE] " + JSON.stringify(result))

      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

module.exports = router;
