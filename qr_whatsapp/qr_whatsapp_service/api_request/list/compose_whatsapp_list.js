// Import the required packages and libraries
const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger');
// WhatsappList function - start
async function WhatsappList(req) {
    var logger_all = main.logger_all
    var logger = main.logger
    try {

        let user_id = req.body.user_id;
        let user_master_id = req.body.user_master_id;
        var report = []
        var get_user;

        if (user_master_id == 1) {
            get_user = `SELECT * from user_management WHERE usr_mgt_status = 'Y'`;
            logger_all.info("[select query request] : " + get_user);
        }
        else {
            get_user = `SELECT * from user_management WHERE (user_id = ${user_id} or parent_id = ${user_id}) AND usr_mgt_status = 'Y'`;
            logger_all.info("[select query request] : " + get_user);
        }

        var get_user_result = await db.query(get_user);
        logger_all.info("[Select query response] : " + JSON.stringify(get_user_result))

        var whatsapp_list = "";
        for (var i = 0; i < get_user_result.length; i++) {

             whatsapp_list += `SELECT cm.message,cmm.media_type,cmm.media_url,cm.compose_message_id, cm.user_id, usr.user_name, cm.campaign_name, cm.message_type,gm.total_count,gm.group_name,sm.mobile_no,cmm.cmm_status,cmm.cmm_entry_date FROM compose_message_${get_user_result[0].user_id} cm left join compose_msg_media_${get_user_result[0].user_id} cmm on cm.compose_message_id = cmm.compose_message_id left join user_management usr on cm.user_id = usr.user_id left join group_master gm on gm.group_master_id = cm.group_master_id left join senderid_master sm on gm.sender_master_id = sm.sender_master_id where cm.user_id = '${get_user_result[0].user_id}' UNION `;
            logger_all.info("[select query request] : " + whatsapp_list);
            // GROUP by cm.campaign_name order by cm.compose_message_id desc 
        }

        var report = await db.query(`${whatsapp_list.slice(0, -7)} GROUP by campaign_name order by cmm_entry_date desc`);
        logger_all.info("[Select query response] : " + JSON.stringify(report))

        if (report.length == 0) {
            return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
        }
        else {
            return { response_code: 1, response_status: 200, response_msg: 'Success', num_of_rows: report.length, report: report };
        }

    }

    catch (err) {
        // Failed - call_index_signin Sign in function
        logger_all.info("[message_template report] Failed - " + err);
        return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
    }
}
module.exports = {
    WhatsappList
};