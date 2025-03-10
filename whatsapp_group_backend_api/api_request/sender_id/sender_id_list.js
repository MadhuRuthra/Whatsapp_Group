const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function sender_id_list(req) {
  var logger_all = main.logger_all
  try {

    var get_senders = `CALL SenderIdList('${req.body.user_id}')`;
    logger_all.info("[Select query request] : " + get_senders);
    var get_senders_result = await db.query(get_senders);
    logger_all.info("[Select query response] : " + JSON.stringify(get_senders_result))

    if (get_senders_result[0].length == 0) {
      return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
    }
    else {
      return { response_code: 1, response_status: 200, response_msg: 'Success', sender_id: get_senders_result[0] };
    }

  }

  catch (err) {
    // Failed - call_index_signin Sign in function
    logger_all.info(" [ sender id list error ] - " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}
module.exports = {
  sender_id_list
};