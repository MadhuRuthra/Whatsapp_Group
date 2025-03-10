const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function campaign_report(req) {
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

    logger_all.info("[Select query request] : " + `SELECT usr.user_name,wht.mobile_no,con.campaign_name,grp.group_name,COUNT(con.campaign_name) total_contacts,COUNT(case con.contact_mobile_status when 'Y' then 1 else null end) total_success,COUNT(case con.contact_mobile_status when 'N' then 1 else null end) total_failure,DATE_FORMAT(con.contact_mobile_entry_date,'%d-%m-%Y %H:%i:%s') contact_mobile_entry_date FROM contact_mobile con
    LEFT JOIN group_contacts grp ON grp.group_contact_id = con.group_contact_id
    LEFT JOIN whatsapp_config wht ON wht.whatspp_config_id = grp.whatspp_config_id
    LEFT JOIN user_management usr ON usr.user_id = wht.user_id
    WHERE grp.group_contact_status = 'Y' AND (con.user_id = '${user_id}' or usr.parent_id = '${user_id}') GROUP BY con.campaign_name`);
    var select_campaign = await db.query(`SELECT usr.user_name,wht.mobile_no,con.campaign_name,grp.group_name,COUNT(con.campaign_name) total_contacts,COUNT(case con.contact_mobile_status when 'Y' then 1 else null end) total_success,COUNT(case con.contact_mobile_status when 'N' then 1 else null end) total_failure,DATE_FORMAT(con.contact_mobile_entry_date,'%d-%m-%Y %H:%i:%s') contact_mobile_entry_date FROM contact_mobile con
    LEFT JOIN group_contacts grp ON grp.group_contact_id = con.group_contact_id
    LEFT JOIN whatsapp_config wht ON wht.whatspp_config_id = grp.whatspp_config_id
    LEFT JOIN user_management usr ON usr.user_id = wht.user_id
    WHERE grp.group_contact_status = 'Y' AND (con.user_id = '${user_id}' or usr.parent_id = '${user_id}') GROUP BY con.campaign_name`);
    logger_all.info("[Select query response] : " + JSON.stringify(select_campaign))

    if(select_campaign.length == 0){
      return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
    }
    else{
      return { response_code: 1, response_status: 200, response_msg: 'Success',report:select_campaign };
    }
   
  }

  catch (err) {
    // Failed - call_index_signin Sign in function
    logger_all.info("[campaign report] Failed - " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}
module.exports = {
    campaign_report
};
