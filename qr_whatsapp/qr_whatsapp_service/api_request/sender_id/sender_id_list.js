const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger');
const { use } = require("./route");

async function sender_id_list(req) {
  var logger_all = main.logger_all
  try {
    var user_id = req.body.user_id;
    var user_master_id = req.body.user_master_id;
    var get_senders;
    if(user_master_id == 1){
      get_senders = `SELECT sndr.sender_master_id,sndr.user_id,usr.user_name,sndr.profile_name,sndr.profile_image, sndr.mobile_no, CASE
      WHEN sndr.senderid_master_status = 'Y' THEN 'Active'
      WHEN sndr.senderid_master_status = 'X' THEN 'Unlinked'
      WHEN sndr.senderid_master_status = 'L' THEN 'Linked'
      WHEN sndr.senderid_master_status = 'B' THEN 'Blocked'
      WHEN sndr.senderid_master_status = 'D' THEN 'Deleted'
      ELSE 'Inactive' END AS senderid_status, sndr.senderid_master_status,DATE_FORMAT(sndr.senderid_master_entdate,'%d-%m-%Y %H:%i:%s') senderid_master_entdate
       FROM senderid_master sndr left join user_management usr on usr.user_id = sndr.user_id ORDER BY sender_master_id DESC`;
    }
    else{
      get_senders = `SELECT sndr.sender_master_id,sndr.user_id,usr.user_name,sndr.profile_name,sndr.profile_image, sndr.mobile_no, CASE
      WHEN sndr.senderid_master_status = 'Y' THEN 'Active'
      WHEN sndr.senderid_master_status = 'X' THEN 'Unlinked'
      WHEN sndr.senderid_master_status = 'L' THEN 'Linked'
      WHEN sndr.senderid_master_status = 'B' THEN 'Blocked'
      WHEN sndr.senderid_master_status = 'D' THEN 'Deleted'
      ELSE 'Inactive' END AS senderid_status, sndr.senderid_master_status,DATE_FORMAT(sndr.senderid_master_entdate,'%d-%m-%Y %H:%i:%s') senderid_master_entdate
       FROM senderid_master sndr left join user_management usr on usr.user_id = sndr.user_id where (sndr.user_id = ${user_id} or usr.parent_id = ${user_id}) ORDER BY sender_master_id DESC`;
    }
    
    logger_all.info("[Select query request] : " + get_senders);
    var get_senders_result = await db.query(get_senders);
    logger_all.info("[Select query response] : " + JSON.stringify(get_senders_result))

    if (get_senders_result.length == 0) {
      return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
    }
    else {
      return { response_code: 1, response_status: 200, response_msg: 'Success', sender_id: get_senders_result };
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