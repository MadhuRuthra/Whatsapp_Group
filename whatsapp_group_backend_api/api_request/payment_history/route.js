const express = require("express");
const router = express.Router();
const PaymentHistory = require("./payment_history_logs");

const validator = require('../../validation/middleware')
const valid_user = require("../../validation/valid_user_middleware");
const valid_user_req_id = require("../../validation/valid_user_middleware_with_request");

const commonValidation = require("../../validation/common_validation");
const PaymentHistoryValidation = require("../../validation/payment_history_validation");
const main = require('../../logger')
const db = require("../../db_connect/connect");

router.post(
  "/payment_history",
  // validator.body(PaymentHistoryValidation),
  async function (req, res, next) {
    try {
      var logger = main.logger
      var logger_all = main.logger_all
      var result = await PaymentHistory.Payment_History(req);
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

// router.put(
//     "/update_details",
//     validator.body(updateUserValidation),
//     valid_user_req_id,
//     async function (req, res, next) {
//       try {
//         var logger = main.logger
//         var logger_all = main.logger_all
  
//         var result = await updateUser.updateUser(req);
//         result['request_id'] = req.body.request_id;

//         if (result.response_code == 0) {
//           logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = '${result.response_msg}' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
//           const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = '${result.response_msg}' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
//           logger_all.info("[update query response] : " + JSON.stringify(update_api_log))
//         }
//         else {
//           logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
//           const update_api_log = await db.query(`UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
//           logger_all.info("[update query response] : " + JSON.stringify(update_api_log))
//         }
//         logger.info("[API RESPONSE] " + JSON.stringify(result))
//         logger_all.info("[API RESPONSE] " + JSON.stringify(result))
  
//         res.json(result);
//       } catch (err) {
//         console.error(`Error while getting data`, err.message);
//         next(err);
//       }
//     }
//   );
module.exports = router;

