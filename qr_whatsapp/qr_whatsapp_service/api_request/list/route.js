const express = require("express");
const router = express.Router();
require("dotenv").config();
const GroupList = require("./group_list");
const Payment_History = require("./payment_history_list");
const Message_Template = require("./template_list");
const Manage_users_list = require("./manage_users_list");
const GetGroupConatct = require("./get_group_contact");
const SenderGroups = require("./group_in_sender");
const List = require("./country_list");
const masterlanguage = require("./master_language");
const Groupsenderlist = require("./group_senderid_list")
const create_admin_contacts = require("./create_admin_contacts");
const get_admin_list = require("./get_admin_list")

const Compose_whatsapplist = require("./compose_whatsapp_list");
const GroupListValidation = require("../../validation/group_list_validation");
const CountryListValidation = require("../../validation/country_list_validation");
const compose_group_senderidlist = require("../../validation/compose_group_senderid_validation");
const GroupListSenderValidation = require("../../validation/group_list_sender_validation");
const validator = require('../../validation/middleware')
const valid_user = require("../../validation/valid_user_middleware");
const commonValidation = require("../../validation/common_validation");
const main = require('../../logger');
const ParlValidation = require("../../validation/parl_list_validation");

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
  "/parliament_list",
  validator.body(CountryListValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all

      var result = await List.parliament_list(req);

      logger.info("[API RESPONSE] " + JSON.stringify(result))

      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

router.get(
  "/constituency_list",
  validator.body(ParlValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all

      var result = await List.constituency_list(req);

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


router.post(
  "/group_list_for_sender",
  validator.body(GroupListSenderValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger

      var result = await GroupList.group_list_Sender(req);

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

router.get(
  "/get_conatct_list",
  // validator.body(commonValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger

      var result = await GetGroupConatct.Get_Group_Contact(req);

      logger.info("[API RESPONSE] " + JSON.stringify(result))

      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

// whatsapp_senderid -start
router.get(
  "/master_language",
  validator.body(commonValidation),
  valid_user,
  async function (req, res, next) {
    try {// access the MasterLanguage function
      var logger = main.logger

      var result = await masterlanguage.MasterLanguage(req);

      logger.info("[API RESPONSE] " + JSON.stringify(result))

      res.json(result);
    } catch (err) { // any error occurres send error response to client
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);
// whatsapp_senderid -end

router.get(
  "/message_template",
  validator.body(CountryListValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all

      var result = await Message_Template.message_template(req);

      logger.info("[API RESPONSE] " + JSON.stringify(result))

      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

router.get(
  "/group_senders_list",
  validator.body(compose_group_senderidlist),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all

      var result = await Groupsenderlist.SenderGroup_list(req);

      logger.info("[API RESPONSE] " + JSON.stringify(result))

      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);


router.get(
  "/compose_whatsapp_list",
  validator.body(CountryListValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all

      var result = await Compose_whatsapplist.WhatsappList(req);

      logger.info("[API RESPONSE] " + JSON.stringify(result))

      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

router.get(
  "/manage_users_list",
  validator.body(CountryListValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all

      var result = await Manage_users_list.ManageUsersList(req);

      logger.info("[API RESPONSE] " + JSON.stringify(result))

      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

router.get(
  "/create_admin_list",
  // validator.body(CountryListValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all

      var result = await create_admin_contacts.create_Admin_Contact(req);

      logger.info("[API RESPONSE] " + JSON.stringify(result))

      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

router.get(
  "/get_admin_list",
  // validator.body(CountryListValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all
      var result = await get_admin_list.Get_Admin_Contact(req);
      logger.info("[API RESPONSE] " + JSON.stringify(result))
      res.json(result);
    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);


module.exports = router;