const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function sender_id_list(req) {
  var logger_all = main.logger_all

  let user_id;

  const header_token = req.headers['authorization'];

  try {

    var get_user = `SELECT * FROM user_management where bearer_token = '${header_token}' AND usr_mgt_status = 'Y' `;

    logger_all.info("[select query request] : " + get_user);
    const get_user_id = await db.query(get_user);
    logger_all.info("[select query response] : " + JSON.stringify(get_user_id));

    user_id = get_user_id[0].user_id;

    logger_all.info("[Select query request] : " + `SELECT wht.whatspp_config_id, wht.user_id,usr.user_name, wht.mobile_no, wht.whatspp_config_status, DATE_FORMAT(wht.whatspp_config_entdate,'%d-%m-%Y %H:%i:%s') whatspp_config_entdate,DATE_FORMAT(wht.whatspp_config_apprdate,'%d-%m-%Y %H:%i:%s') whatspp_config_apprdate FROM whatsapp_config wht left join user_management usr on usr.user_id = wht.user_id where (wht.user_id = '${user_id}' or usr.parent_id = '${user_id}') ORDER BY whatspp_config_id DESC`);
    var select_sender_id = await db.query(`SELECT wht.whatspp_config_id, wht.user_id,usr.user_name, wht.mobile_no, wht.whatspp_config_status, DATE_FORMAT(wht.whatspp_config_entdate,'%d-%m-%Y %H:%i:%s') whatspp_config_entdate,DATE_FORMAT(wht.whatspp_config_apprdate,'%d-%m-%Y %H:%i:%s') whatspp_config_apprdate FROM whatsapp_config wht left join user_management usr on usr.user_id = wht.user_id where (wht.user_id = '${user_id}' or usr.parent_id = '${user_id}') ORDER BY whatspp_config_id DESC`);
    logger_all.info("[Select query response] : " + JSON.stringify(select_sender_id))

    if(select_sender_id.length == 0){
      return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
    }
    else{
      return { response_code: 1, response_status: 200, response_msg: 'Success',sender_id:select_sender_id };
    }
   
  }

  catch (err) {
    // Failed - call_index_signin Sign in function
    logger_all.info(": [sender id list ] Failed - " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}
module.exports = {
    sender_id_list
};
