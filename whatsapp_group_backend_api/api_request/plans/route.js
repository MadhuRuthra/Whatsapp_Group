const express = require("express");
const router = express.Router();
const getAllPlans = require("./get_all_plans");
const User_plans = require("./user_plans_purchase");
const update_user_purchase = require("./update_user_purchase");

const rppayment_user_id = require("./rppayment_user_id");
const AddPlans = require("./add_plans");
const PricingPlans = require("./get_plans");
const DeletePlan = require("./delete_plan");
const UpdatePlans = require("./update_plans");

const validator = require('../../validation/middleware')
const valid_user = require("../../validation/valid_user_middleware");
const valid_user_req_id = require("../../validation/valid_user_middleware_with_request");

const commonValidation = require("../../validation/common_validation");
const Userplanspurchase = require("../../validation/user_plans_purchase_validation");
const update_payment_validation = require("../../validation/update_payment_validation");
const main = require('../../logger')
const db = require("../../db_connect/connect");

router.get(
  "/plan_details",
  validator.body(commonValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all

      var result = await getAllPlans.getAllPlans(req);

      logger.info("[API RESPONSE] " + JSON.stringify(result))
      logger_all.info("[API RESPONSE] " + JSON.stringify(result))

      res.json(result);
    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

router.post(
  "/user_plans_purchase",
  valid_user_req_id,
  // validator.body(Userplanspurchase),
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all
      var result = await User_plans.user_plans(req);
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


// Rppayment_User_id -start
router.post(
  "/rppayment_user_id",
  // validator.body(rppayment_user_idvalidation),
  valid_user,
  async function (req, res, next) {
    try { // access the Rppayment_User_id function
      var logger = main.logger
      var result = await rppayment_user_id.Rppayment_user__id(req);
      logger.info("[API RESPONSE] " + JSON.stringify(result))
      res.json(result);
    } catch (err) { // any error occurres send error response to client
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);
// Rppayment_User_id - end


// update_user_purchase -start
router.put(
  "/update_payment_status",
  validator.body(update_payment_validation),
  valid_user,
  async function (req, res, next) {
    try { // access the update_user_purchase function
      var logger = main.logger
      var result = await update_user_purchase.UpdateCreditRaisestatus(req);
      logger.info("[API RESPONSE] " + JSON.stringify(result))
      res.json(result);

    } catch (err) { // any error occurres send error response to client
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);
// update_user_purchase - end

// create_plans -start
router.post(
  "/create_plans",
  // validator.body(),
  valid_user,
  async function (req, res, next) {
    try { // access the create_plans function
      var logger = main.logger
      var result = await AddPlans.Create_plans(req);
      logger.info("[API RESPONSE] " + JSON.stringify(result))
      res.json(result);

    } catch (err) { // any error occurres send error response to client
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);
// create_plans - end



// update_plans -start
router.put(
  "/update_plans",
  // validator.body(),
  valid_user,
  async function (req, res, next) {
    try { // access the update_plans function
      var logger = main.logger
      var result = await UpdatePlans.Update_plans(req);
      logger.info("[API RESPONSE] " + JSON.stringify(result))
      res.json(result);

    } catch (err) { // any error occurres send error response to client
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);
// update_plans - end

// create_plans -start
router.get(
  "/get_plans",
  // validator.body(),
  valid_user,
  async function (req, res, next) {
    try { // access the create_plans function
      var logger = main.logger
      var result = await PricingPlans.Get_plans(req);
      logger.info("[API RESPONSE] " + JSON.stringify(result))
      res.json(result);

    } catch (err) { // any error occurres send error response to client
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);
// create_plans - end

router.delete(
  "/delete_plan",
  valid_user_req_id,
  // validator.body(Userplanspurchase),
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all
      var result = await DeletePlan.delete_Plan(req);
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

