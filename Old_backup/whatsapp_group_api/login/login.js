const db = require("../db_connect/connect");
const jwt = require("jsonwebtoken");
const md5 = require("md5")
const main = require('../logger')
require("dotenv").config();

async function login(req) {
  var logger_all = main.logger_all
  var logger = main.logger

  var day = new Date();
  var today_date = day.getFullYear() + '-' + (day.getMonth() + 1) + '-' + day.getDate();

  //File generate
  // get all the req data
  let txt_username = req.body.username;
  let txt_password = md5(req.body.password);
  let request_id = req.body.request_id;

  var header_json = req.headers;
  let ip_address = header_json['x-forwarded-for'];

  var log_data = "[API REQUEST] " + req.originalUrl + " - " + JSON.stringify(req.body) + " - " + JSON.stringify(req.headers) + " - " + ip_address
  logger.info(log_data)
  logger_all.info(log_data)

  try { //check the user name

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

    var check_user = `SELECT * FROM user_management where user_email = '${txt_username}' or user_mobile = '${txt_username}' and usr_mgt_status in ('N', 'W') ORDER BY user_id ASC`
    logger_all.info("[select query request] : " + check_user);
    const check_user_result = await db.query(check_user);
    if (check_user_result.length > 0) {
      return { response_code: 0, response_status: 201, response_msg: "Inactive or Not Approved User. Kindly contact your admin!" };
    }
    else { //otherwise

      const check_valid_user = `SELECT * FROM user_management where user_email = '${txt_username}' or user_mobile = '${txt_username}' and usr_mgt_status = 'Y' ORDER BY user_id ASC`;
      logger_all.info("[select query request] : " + check_valid_user)
      const check_valid_user_result = await db.query(check_valid_user);

      if (check_valid_user_result.length <= 0) { // invalid user checking
        return {response_code: 0, response_status: 201, response_msg: "Invalid User. Kindly try again with the valid User!" };
      }
      else {
        // otherwise checking user name and password
        const check_valid_pass = `SELECT * FROM user_management where user_email = '${txt_username}' or user_mobile = '${txt_username}' and login_password = '${txt_password}' and usr_mgt_status = 'Y' ORDER BY user_id ASC`
        logger_all.info("[select query request] : " + check_valid_pass);
        const check_valid_pass_result = await db.query(check_valid_pass);

        if (check_valid_pass_result.length <= 0) {
          return { response_code: 0, response_status: 201, response_msg: "Invalid Password. Kindly try again with the valid details!" };
        }
        else {
          user_id = check_valid_pass_result[0].user_id;
          //JWT Token Accessing value...
          const user =
          {
            username: txt_username,
            user_password: txt_password,
          }
          const user_access_token = jwt.sign(user, process.env.ACCESS_TOKEN_SECRET, {
            expiresIn: process.env.ONEWEEK
          });

          var bearer_token = "Bearer " + user_access_token;
          //update token

          const update_token = `UPDATE user_management  SET bearer_token = '${bearer_token}' WHERE user_id = '${user_id}'`
          logger_all.info("[Update query request] : " + update_token);
          var update_token_result = await db.query(update_token);
          logger_all.info("[Update query Response] : " + JSON.stringify(update_token_result));

          // Login Success - call_index_signin Sign in function
          const check_user_log = `SELECT user_id,user_log_status,login_date FROM user_log where user_id ='${user_id}' and user_log_status = 'I' and date(login_date) ='${today_date}'`
          logger_all.info("[select query request] : " + check_user_log);
          const check_user_log_result = await db.query(check_user_log);

          if (check_user_log_result.length == 0) { // insert user log

            var insert_user_log = `INSERT INTO user_log VALUES(NULL, '${user_id}', '${ip_address}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL, 'I', CURRENT_TIMESTAMP)`
            logger_all.info("[insert query request] : " + insert_user_log);
            const insert_user_log_result = await db.query(insert_user_log);

            return {response_code: 1, response_status: 200, response_msg: "Success", bearer_token: user_access_token, user_id: user_id, user_master_id: check_valid_pass_result[0].user_master_id, parent_id: check_valid_pass_result[0].parent_id, user_name: check_valid_pass_result[0].user_name };

          }
          else { //update userlog table

            const update_exist_logout = `UPDATE user_log SET user_log_status = 'O',logout_time = CURRENT_TIMESTAMP WHERE user_id = '${user_id}' AND user_log_status = 'I' AND login_date = '${today_date}'`
            logger_all.info("[update query request] : " + update_exist_logout);
            const update_exist_logout_result = await db.query(update_exist_logout);

            // insert userlog table
            const insert_new_user_log = `INSERT INTO user_log VALUES(NULL, '${user_id}', '${ip_address}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL, 'I', CURRENT_TIMESTAMP)`
            logger_all.info("[insert query request] : " + insert_new_user_log);
            const insert_new_user_log_result = await db.query(insert_new_user_log);

            return { response_code: 1, response_status: 200, response_msg: "Success", bearer_token: user_access_token, user_id: user_id, user_master_id: check_valid_pass_result[0].user_master_id, parent_id: check_valid_pass_result[0].parent_id, user_name: check_valid_pass_result[0].user_name };

          }

        }
      }
    }
  } catch (err) {
    logger_all.info("[Login Error] : "+err)
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}

module.exports = {
  login,
};
