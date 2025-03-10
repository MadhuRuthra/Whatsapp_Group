const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function group_list_sender(req) {
  var logger_all = main.logger_all
  
  try {

    var user_id = req.body.user_id;
    var sender_id = req.body.sender_id;

    const group_list = `SELECT grp.group_master_id,usr.user_name,con.mobile_no,grp.group_name,grp.total_count,grp.success_count,grp.failure_count,grp.group_master_status,DATE_FORMAT(grp.group_master_entdate,'%d-%m-%Y %H:%i:%s') group_master_entdate FROM group_master grp
    LEFT JOIN senderid_master con ON con.sender_master_id = grp.sender_master_id
    LEFT JOIN user_management usr ON usr.user_id = con.user_id
    where (con.user_id = '${user_id}' or usr.parent_id = '${user_id}') AND con.mobile_no = '${sender_id}'
    ORDER BY grp.group_master_id DESC`
    logger_all.info("[Select query request] : " + group_list);
    var group_list_Result = await db.query(group_list);
    logger_all.info("[Select query response] : " + JSON.stringify(group_list_Result))

    if(group_list_Result.length == 0){
      return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
    }
    else{
      return { response_code: 1, response_status: 200, response_msg: 'Success',group_list:group_list_Result };
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