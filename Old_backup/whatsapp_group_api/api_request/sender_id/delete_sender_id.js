const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function delete_sender_id(req) {
    var logger_all = main.logger_all
    var logger = main.logger

    let user_id;
    var sender_id = req.body.sender_id;
    var header_json = req.headers;
    let ip_address = header_json['x-forwarded-for'];

    const header_token = req.headers['authorization'];

    try {

        logger_all.info("[insert query request] : " + `INSERT INTO api_log VALUES(NULL,'${req.originalUrl}','${ip_address}','${req.body.request_id}','N','-','0000-00-00 00:00:00','Y',CURRENT_TIMESTAMP)`);
        const insert_api_log = await db.query(`INSERT INTO api_log VALUES(NULL,'${req.originalUrl}','${ip_address}','${req.body.request_id}','N','-','0000-00-00 00:00:00','Y',CURRENT_TIMESTAMP)`);
        logger_all.info("[insert query response] : " + JSON.stringify(insert_api_log))
    
        logger_all.info("[select query request] : " + `SELECT * FROM api_log WHERE request_id = '${req.body.request_id}' AND response_status != 'N' AND log_status='Y'`);
        const check_req_id = await db.query(`SELECT * FROM api_log WHERE request_id = '${req.body.request_id}' AND response_status != 'N' AND log_status='Y'`);
        logger_all.info("[select query response] : " + JSON.stringify(check_req_id));
    
        if (check_req_id.length != 0) {
    
          logger_all.info("[Valid User Middleware failed response] : Request already processed");
          logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Request already processed' }))
    
          return { response_code: 0, response_status: 201, response_msg: 'Request already processed' };
    
        }

        var get_user = `SELECT * FROM user_management where bearer_token = '${header_token}' AND usr_mgt_status = 'Y' `;

        logger_all.info("[select query request] : " + get_user);
        const get_user_id = await db.query(get_user);
        logger_all.info("[select query response] : " + JSON.stringify(get_user_id));

        user_id = get_user_id[0].user_id;

        logger_all.info("[Select query request] : " + `SELECT wht.whatspp_config_id, wht.user_id,usr.user_name, wht.mobile_no, wht.whatspp_config_status, DATE_FORMAT(wht.whatspp_config_entdate,'%d-%m-%Y') whatspp_config_entdate,DATE_FORMAT(wht.whatspp_config_apprdate,'%d-%m-%Y') whatspp_config_apprdate FROM whatsapp_config wht left join user_management usr on usr.user_id = wht.user_id where (wht.user_id = '${user_id}' or usr.parent_id = '${user_id}') AND wht.whatspp_config_id = '${sender_id}' AND wht.whatspp_config_status != 'D'`);
        var select_sender_id = await db.query(`SELECT wht.whatspp_config_id, wht.user_id,usr.user_name, wht.mobile_no, wht.whatspp_config_status, DATE_FORMAT(wht.whatspp_config_entdate,'%d-%m-%Y') whatspp_config_entdate,DATE_FORMAT(wht.whatspp_config_apprdate,'%d-%m-%Y') whatspp_config_apprdate FROM whatsapp_config wht left join user_management usr on usr.user_id = wht.user_id where (wht.user_id = '${user_id}' or usr.parent_id = '${user_id}') AND wht.whatspp_config_id = '${sender_id}' AND wht.whatspp_config_status != 'D'`);
        logger_all.info("[Select query response] : " + JSON.stringify(select_sender_id))

        if (select_sender_id.length == 0) {
            return { response_code: 0, response_status: 201, response_msg: 'Sender ID not found.' };
        }
        else {

            logger_all.info("[update query request] : " + `UPDATE whatsapp_config SET whatspp_config_status = 'D' WHERE whatspp_config_id = '${sender_id}' AND whatspp_config_status != 'D'`);
            var update_sender_id = await db.query(`UPDATE whatsapp_config SET whatspp_config_status = 'D' WHERE whatspp_config_id = '${sender_id}' AND whatspp_config_status != 'D'`);
            logger_all.info("[update query response] : " + JSON.stringify(update_sender_id))

            return { response_code: 1, response_status: 200, response_msg: 'Success'};
        }

    }

    catch (err) {
        // Failed - call_index_signin Sign in function
        logger_all.info(": [delete sender id ] Failed - " + err);
        return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
    }
}
module.exports = {
    delete_sender_id
};
