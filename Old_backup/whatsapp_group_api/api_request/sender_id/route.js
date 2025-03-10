const express = require("express");
const router = express.Router();
const List = require("./sender_id_list");
const Delete = require("./delete_sender_id");
require("dotenv").config();
const validator = require('../../validation/middleware')
const valid_user = require("../../validation/valid_user_middleware");
const db = require("../../db_connect/connect");

const ListValidation = require("../../validation/sender_id_validation");
const DeleteValidation = require("../../validation/delete_sender_id_validation");

const main = require('../../logger');

router.post(
  "/sender_id_list",
  validator.body(ListValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger

      var result = await List.sender_id_list(req);
       
      logger.info("[API RESPONSE] " + JSON.stringify(result))
     
      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

router.delete(
  "/delete_sender_id",
  validator.body(DeleteValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger

      var result = await Delete.delete_sender_id(req);
      result['request_id'] = req.body.request_id;

      logger.info("[API RESPONSE] " + JSON.stringify(result))

      if (result.response_code == 0) {
        logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = '${result.response_msg}' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = '${result.response_msg}' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        logger_all.info("[update query response] : " + JSON.stringify(update_api_log))
      }
      else {
        logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        const update_api_log = await db.query(`UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        logger_all.info("[update query response] : " + JSON.stringify(update_api_log))
      }
      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);

module.exports = router;
