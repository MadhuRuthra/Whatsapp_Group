const db = require("../../db_connect/connect");
const md5 = require("md5")
const main = require('../../logger')
require("dotenv").config();

async function forgotPassword(req) {
  var logger_all = main.logger_all
  var logger = main.logger
  try {
    var header_json = req.headers;
    let ip_address = header_json['x-forwarded-for'];

    var log_data = "[API REQUEST] " + req.originalUrl + " - " + JSON.stringify(req.body) + " - " + JSON.stringify(req.headers) + " - " + ip_address
    logger.info(log_data)
    logger_all.info(log_data)

    let request_id = req.body.request_id;
    let user_mobile = req.body.user_mobile;
    let user_password = md5(req.body.user_password);

    const insert_log = `INSERT INTO api_log VALUES(NULL,0,'${req.originalUrl}','${ip_address}','${request_id}','N','-','0000-00-00 00:00:00','Y',CURRENT_TIMESTAMP)`;
    logger_all.info("[insert query request] : " + insert_log);
    const insert_log_result = await db.query(insert_log);
    logger_all.info("[insert query response] : " + JSON.stringify(insert_log_result))

    const check_req_id = `SELECT * FROM api_log WHERE request_id = '${request_id}' AND response_status != 'N' AND log_status='Y'`
    logger_all.info("[select query request] : " + check_req_id);
    const check_req_id_result = await db.query(check_req_id);
    logger_all.info("[select query response] : " + JSON.stringify(check_req_id_result));

    if (check_req_id_result.length != 0) {
      return {response_code: 0, response_status: 201, response_msg: 'Request already processed' };
    }

    const check_mobile = `SELECT * FROM user_management where user_mobile = '${user_mobile}' AND usr_mgt_status = 'Y'`
    logger_all.info(" select query request : " + check_mobile);
    const check_mobile_result = await db.query(check_mobile);
    logger_all.info(" select query response : " + check_mobile_result);

    if(check_mobile_result.length == 0){
      return {
        response_code: 0,
        response_status: 201,
        response_msg: "User not found."
      };
    }

    const update_password = `UPDATE user_management SET login_password = '${user_password}' where user_mobile = '${user_mobile}' AND usr_mgt_status = 'Y'`
    logger_all.info(" update query request : " + update_password);
    const update_password_result = await db.query(update_password);
    logger_all.info(" update query response : " + update_password_result);

    return {
      response_code: 1,
      response_status: 200,
      response_msg: "Success."
    };
  } catch (err) {
    // any error occurres send error response to client
    logger_all.info("[forgot password error] : " + err);
    return {
      response_code: 0,
      response_status: 201,
      response_msg: "Error occurred"
    };
  }
}

module.exports = {
  forgotPassword,
};
