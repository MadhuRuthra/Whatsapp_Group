const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function group_list_sender(req) {
  var logger_all = main.logger_all
  var logger = main.logger

  let user_id;
  const header_token = req.headers['authorization'];
  
  try {

    var get_user = `SELECT * FROM user_management where bearer_token = '${header_token}' AND usr_mgt_status = 'Y' `;

    logger_all.info("[select query request] : " + get_user);
    const get_user_id = await db.query(get_user);
    logger_all.info("[select query response] : " + JSON.stringify(get_user_id));

    user_id = get_user_id[0].user_id;
    var sender_id = req.body.sender_id;

    logger_all.info("[Select query request] : " + `SELECT grp.group_contact_id,usr.user_name,con.mobile_no,grp.group_name,grp.total_count,grp.success_count,grp.failure_count,grp.group_contact_status,DATE_FORMAT(grp.group_contact_entdate,'%d-%m-%Y %H:%i:%s') group_contact_entdate FROM group_contacts grp
    LEFT JOIN whatsapp_config con ON con.whatspp_config_id = grp.whatspp_config_id
    LEFT JOIN user_management usr ON usr.user_id = con.user_id
    where (con.user_id = '${user_id}' or usr.parent_id = '${user_id}') AND con.mobile_no = '${sender_id}'
    ORDER BY grp.group_contact_id DESC`);
    var group_list = await db.query(`SELECT grp.group_contact_id,usr.user_name,con.mobile_no,grp.group_name,grp.total_count,grp.success_count,grp.failure_count,grp.group_contact_status,DATE_FORMAT(grp.group_contact_entdate,'%d-%m-%Y %H:%i:%s') group_contact_entdate FROM group_contacts grp
    LEFT JOIN whatsapp_config con ON con.whatspp_config_id = grp.whatspp_config_id
    LEFT JOIN user_management usr ON usr.user_id = con.user_id
    where (con.user_id = '${user_id}' or usr.parent_id = '${user_id}') AND con.mobile_no = '${sender_id}'
    ORDER BY grp.group_contact_id DESC`);
    logger_all.info("[Select query response] : " + JSON.stringify(group_list))

    if(group_list.length == 0){
      return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
    }
    else{
      return { response_code: 1, response_status: 200, response_msg: 'Success',group_list:group_list };
    }
   
  }

  catch (err) {
    // Failed - call_index_signin Sign in function
    logger_all.info("[country list report] Failed - " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}
module.exports = {
    group_list_sender
};
