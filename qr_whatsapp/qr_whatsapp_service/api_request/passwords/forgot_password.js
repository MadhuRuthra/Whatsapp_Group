const db = require("../../db_connect/connect");
const md5 = require("md5")
const main = require('../../logger')
require("dotenv").config();

async function forgotPassword(req) {
    var logger_all = main.logger_all
    var logger = main.logger
    try {

        let user_mobile = req.body.user_mobile;
        let user_password = md5(req.body.user_password);

        const check_mobile = `SELECT * FROM user_management where user_mobile = '${user_mobile}' AND usr_mgt_status = 'Y'`
        logger_all.info(" select query request : " + check_mobile);
        const check_mobile_result = await db.query(check_mobile);
        logger_all.info(" select query response : " + check_mobile_result);

        if (check_mobile_result.length == 0) {
            return {
                response_code: 0,
                response_status: 201,
                response_msg: "User not found."
            }
            }else if (check_mobile_result[0].login_password == user_password){
          return {
            response_code: 0,
            response_status: 201,
            response_msg: "The existing password and the forget password are the same, so cannot be changed!"
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
