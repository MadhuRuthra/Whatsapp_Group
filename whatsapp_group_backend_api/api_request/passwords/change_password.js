const db = require("../../db_connect/connect");
const md5 = require("md5")
const main = require('../../logger')
require("dotenv").config();

async function changePassword(req) {
  var logger_all = main.logger_all
  try {

    var user_id = req.body.user_id;
    let user_password = md5(req.body.new_password);
    let old_password = md5(req.body.old_password);

    const check_old_pass = `Select * from user_management WHERE user_id ='${user_id}' and login_password ='${old_password}' and usr_mgt_status = 'Y'`
    logger_all.info("[Select query request] : " + check_old_pass);
    const check_old_pass_result = await db.query(check_old_pass);
    logger_all.info("[Select query response] : " + JSON.stringify(check_old_pass_result))

    if(check_old_pass_result.length ==0){
        return {
            response_code: 0,
            response_status: 201,
            response_msg: "Invalid Existing Password. Kindly try again!"
          };
    }
    const update_password = `UPDATE user_management SET login_password = '${user_password}' where user_id = '${user_id}' AND usr_mgt_status = 'Y'`
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
    logger_all.info("[change password error] : " + err);
    return {
      response_code: 0,
      response_status: 201,
      response_msg: "Error occurred"
    };
  }
}

module.exports = {
  changePassword,
};
