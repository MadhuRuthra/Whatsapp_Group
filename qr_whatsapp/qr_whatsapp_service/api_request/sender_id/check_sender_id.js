const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function Check_Senderid(req) {
  var logger_all = main.logger_all

  var user_id = req.body.user_id;
  var sender_id = req.body.mobile_no;
  try {

    var senderis_status = `select * from senderid_master WHERE user_id = ${user_id} AND senderid_master_status in('Y','L','P' )  and mobile_no = '${sender_id}'`;


    logger_all.info("[Select query request] : " + senderis_status);
    var get_senders_result = await db.query(senderis_status);
    logger_all.info("[Select query response] : " + JSON.stringify(get_senders_result))

    if(get_senders_result.length != 0){
      return { response_code: 0, response_status: 204, response_msg: 'Mobile number already exists.' };
    }
    else {
      return { response_code: 1, response_status: 200, response_msg: 'Success' };
    }

  }

  catch (err) {
    // Failed - call_index_signin Sign in function
    logger_all.info(" [ sender id list error ] - " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}
module.exports = {
    Check_Senderid
};