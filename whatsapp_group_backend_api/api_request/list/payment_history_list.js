const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function Payment_History(req) {
  var logger_all = main.logger_all
  var logger = main.logger

  try {

    var get_payment = `CALL PaymentHistoryList('${req.body.user_id}')`;
    logger_all.info("[Select query request] : " + get_payment);
    var get_payment_result = await db.query(get_payment);
    logger_all.info("[Select query response] : " + JSON.stringify(get_payment_result))

    if (get_payment_result[0].length == 0) {
      return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
    }
    else {
      return {
        response_code: 1, response_status: 200, response_msg: 'Success', payment_history_list: get_payment_result[0]
      };
    }
  }

  catch (err) {
    // Failed - call_index_signin Sign in function
    logger_all.info("[Payment History report] Failed - " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}
module.exports = {
  Payment_History
};

