const express = require("express");
const router = express.Router();
const getUser = require("./get_user_details");
const updateUser = require("./update_user");
const Dashboard = require("./dashboard");
const UserDetails = require("./get_user_profiles");

const validator = require('../../validation/middleware')
const valid_user = require("../../validation/valid_user_middleware");
const valid_user_req_id = require("../../validation/valid_user_middleware_with_request");

const getUserValidation = require("../../validation/get_user_validation");
const updateUserValidation = require("../../validation/update_user_validation");
const ViewuserListValidation = require("../../validation/viewuserlistvalidation");

const main = require('../../logger')
const db = require("../../db_connect/connect");

router.get(
  "/dashboard",
  validator.body(getUserValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all

      var result = await Dashboard.Dashboard(req);

      logger.info("[API RESPONSE] " + JSON.stringify(result))
      logger_all.info("[API RESPONSE] " + JSON.stringify(result))

      res.json(result);
    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

router.get(
  "/user_details",
  validator.body(getUserValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all

      var result = await getUser.getUser(req);

      logger.info("[API RESPONSE] " + JSON.stringify(result))
      logger_all.info("[API RESPONSE] " + JSON.stringify(result))

      res.json(result);
    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

router.put(
  "/update_details",
  validator.body(updateUserValidation),
  valid_user_req_id,
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all

      var result = await updateUser.updateUser(req);
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

router.get(
  "/view_user_list",
  validator.body(ViewuserListValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all

      var result = await UserDetails.User_list_Details(req);

      logger.info("[API RESPONSE] " + JSON.stringify(result))

      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);
module.exports = router;