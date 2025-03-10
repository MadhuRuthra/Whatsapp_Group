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

        // get_whatsapp_list to execute the query
        var whatsapp_list = `SELECT cm.compose_message_id, cm.user_id, usr.user_name, cm.campaign_name, cm.message_type,gm.total_count,gm.group_name,sm.mobile_no,cmm.cmm_status,cmm.cmm_entry_date FROM whatsapp_group_newapi_${user_id}.compose_message_${user_id} cm left join whatsapp_group_newapi_${user_id}.compose_msg_media_${user_id} cmm on cm.compose_message_id = cmm.compose_message_id left join whatsapp_group_newapi.user_management usr on cm.user_id = usr.user_id left join whatsapp_group_newapi.group_master gm on gm.group_master_id = cm.group_master_id left join whatsapp_group_newapi.senderid_master sm on gm.sender_master_id = sm.sender_master_id where cm.user_id = '${user_id}' GROUP by cm.campaign_name order by cm.compose_message_id desc`;
        logger_all.info("[select query request] : " + whatsapp_list);

        var whatsapp_list_result = await db.query(whatsapp_list);
        logger_all.info("[Select query response] : " + JSON.stringify(whatsapp_list_result))

        if (whatsapp_list_result.length == 0) {
            return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
        }
        else {
            return { response_code: 1, response_status: 200, response_msg: 'Success', num_of_rows: whatsapp_list_result.length, report: whatsapp_list_result };
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
