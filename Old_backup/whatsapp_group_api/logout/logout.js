const db = require("../db_connect/connect");
require("dotenv").config();
const main = require('../logger')

async function logout(req) {
  var logger_all = main.logger_all

  var day = new Date();
  var today_date = day.getFullYear() + '-' + (day.getMonth() + 1) + '-' + day.getDate();

  let user_id;
  var header_json = req.headers;
  let ip_address = header_json['x-forwarded-for'];
  var request_id = req.body.request_id;

  const header_token = req.headers['authorization'];

  logger_all.info("[Logout query parameters] : " + JSON.stringify(req.body));
  try {

    var get_user = `SELECT * FROM user_management where bearer_token = '${header_token}' AND usr_mgt_status = 'Y' `;

    logger_all.info("[select query request] : " + get_user);
    const get_user_result = await db.query(get_user);
    logger_all.info("[select query response] : " + JSON.stringify(get_user_result));

    user_id = get_user_result[0].user_id;

    // const insert_log = `INSERT INTO api_log VALUES(NULL,'${user_id}','${req.originalUrl}','${ip_address}','${request_id}','N','-','0000-00-00 00:00:00','Y',CURRENT_TIMESTAMP)`
    // logger_all.info("[insert query request] : " + insert_log);
    // const insert_log_result = await db.query(insert_log);
    // logger_all.info("[insert query response] : " + JSON.stringify(insert_log_result))

    // const check_req_id = `SELECT * FROM api_log WHERE request_id = '${request_id}' AND response_status != 'N' AND log_status='Y'`
    // logger_all.info("[select query request] : " + check_req_id);
    // const check_req_id_result = await db.query(check_req_id);
    // logger_all.info("[select query response] : " + JSON.stringify(check_req_id_result));

    // if (check_req_id_result.length != 0) {
    //   return { response_code: 0, response_status: 201, response_msg: 'Request already processed' };
    // }

    const check_user_log = `Select * from user_log WHERE user_id ='${user_id}' and login_date ='${today_date}' and user_log_status = 'I'`
    logger_all.info("[Select query request] : " + check_user_log);
    const check_user_log_result = await db.query(check_user_log);
    logger_all.info("[Select query response] : " + JSON.stringify(check_user_log_result))

    const update_token = `UPDATE user_management SET bearer_token = "-" WHERE user_id ='${user_id}' and usr_mgt_status = 'Y'`
    logger_all.info("[Update query request] : " + update_token);
    const update_token_result = await db.query(update_token);
    logger_all.info("[Update query response] : " + JSON.stringify(update_token_result))

    if (check_user_log_result.length > 0) {
      const update_logout = `UPDATE user_log SET logout_time = CURRENT_TIMESTAMP,user_log_status ='O' WHERE user_id ='${user_id}' and login_date ='${today_date}' and user_log_status = 'I'`
      logger_all.info("[Update query request] : " + update_logout);
      const update_logout_result = await db.query(update_logout);
      logger_all.info("[Update query response] : " + JSON.stringify(update_logout_result))

      return { response_code: 1, response_status: 200, response_msg: "Success" };
    }
    else {
      return { response_code: 1, response_status: 200, response_msg: "Success" };
    }
  }

  catch (err) {
    // Failed - call_index_signin Sign in function
    logger_all.info("[Logout Error] : " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}
module.exports = {
  logout
};
