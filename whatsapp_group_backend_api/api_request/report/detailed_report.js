const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function detailed_report(req) {
  var logger_all = main.logger_all

  let user_id = req.body.user_id;

  var day = new Date();
  var today_date = day.getFullYear() + '-' + (day.getMonth() + 1) + '-' + day.getDate();

  let start_date = req.body.start_date ? req.body.start_date : today_date;
  let end_date = req.body.end_date ? req.body.end_date : today_date;

  try {

    const select_campaign_query = `SELECT usr.user_name,wht.mobile_no,grp.group_name,con.campaign_name,con.mobile_no as receiver_no, con.mobile_id, CASE WHEN con.group_contacts_status = 'Y' THEN 'Success'ELSE 'Failure' END AS grp_con_status,con.group_contacts_status,con.comments ,DATE_FORMAT(con.group_contacts_entry_date,'%d-%m-%Y %H:%i:%s') group_contacts_entry_date FROM group_contacts con LEFT JOIN group_master grp ON grp.group_master_id = con.group_master_id LEFT JOIN senderid_master wht ON wht.sender_master_id = grp.sender_master_id LEFT JOIN user_management usr ON usr.user_id = wht.user_id WHERE (con.user_id = '${user_id}' or usr.parent_id = '${user_id}') AND (date(con.group_contacts_entry_date) BETWEEN '${start_date}' and '${end_date}') ORDER BY con.group_contacts_entry_date DESC`
    
    logger_all.info("[Select query request] : " + select_campaign_query);
    var select_campaign_query_result = await db.query(select_campaign_query);
    logger_all.info("[Select query response] : " + JSON.stringify(select_campaign_query_result))

    if (select_campaign_query_result.length == 0) {
      return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
    }
    else {
      return { response_code: 1, response_status: 200, response_msg: 'Success', report: select_campaign_query_result };
    }

  }

  catch (err) {
    // Failed - call_index_signin Sign in function
    logger_all.info("[detailed report] Failed - " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}
module.exports = {
  detailed_report
};
