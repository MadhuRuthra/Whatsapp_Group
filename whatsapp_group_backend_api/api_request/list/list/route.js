const express = require("express");
const router = express.Router();
const List = require("./country_list");
require("dotenv").config();
const validator = require('../../validation/middleware')
const valid_user = require("../../validation/valid_user_middleware");
const commonValidation = require("../../validation/common_validation");
const CountryListValidation = require("../../validation/country_list_validation");
const GroupList = require("./group_list");
const Userplanlist = require("./user_plans_list");
const Payment_History = require("./payment_history_list");
const GroupListValidation = require("../../validation/group_list_validation");
const SenderGroups = require("./group_in_sender");
const main = require('../../logger');

router.get(
  "/country_list",
  validator.body(CountryListValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all

      var result = await List.country_list(req);
       
      logger.info("[API RESPONSE] " + JSON.stringify(result))
     
      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

router.get(
  "/group_list",
  validator.body(CountryListValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger

      var result = await GroupList.group_list(req);
       
      logger.info("[API RESPONSE] " + JSON.stringify(result))
     
      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

router.get(
  "/sender_id_groups",
  validator.body(GroupListValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger

      var result = await SenderGroups.group_list_sender(req);
       
      logger.info("[API RESPONSE] " + JSON.stringify(result))
     
      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

router.get(
  "/user_plans_list",
  validator.body(commonValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger

      var result = await Userplanlist.User_Plan_List(req);
       
      logger.info("[API RESPONSE] " + JSON.stringify(result))
     
      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

router.get(
  "/payment_history_list",
  validator.body(commonValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger

      var result = await Payment_History.Payment_History(req);
       
      logger.info("[API RESPONSE] " + JSON.stringify(result))
     
      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);
module.exports = router;

