const db = require("../../db_connect/connect");
const main = require('../../logger')
require("dotenv").config();

async function updateUser(req) {
    var logger_all = main.logger_all
    try {

        var user_id = req.body.user_id;
        var user_name = req.body.user_name;
        var user_email = req.body.user_email;
        var user_mobile = req.body.user_mobile;

        var update_user = ''
        var error_msg = ''
        if (!user_name && !user_email && !user_mobile) {
            return {
                response_code: 0,
                response_status: 201,
                response_msg: "Kindly send atleast one field to update"
            }
        }

        if (user_name) {
            update_user += `,user_name='${user_name}'`
        }
        if (user_email) {

            const check_email_exists = `SELECT * FROM user_management where user_email = '${user_email}' AND usr_mgt_status = 'Y'`
            logger_all.info(" select query request : " + check_email_exists);
            const check_email_exists_result = await db.query(check_email_exists);
            logger_all.info(" select query response : " + check_email_exists_result);

            if (check_email_exists_result.length == 0) {
                update_user += `,user_email='${user_email}'`
            }
            else {
                if (check_email_exists_result[0].user_id.toString() != user_id.toString()) {
                    error_msg = "and User email"
                }
                else {
                    update_user += `,user_email='${user_email}'`
                }
            }
        }
        if (user_mobile) {

            const check_mobile_exists = `SELECT * FROM user_management where user_mobile = '${user_mobile}' AND usr_mgt_status = 'Y'`
            logger_all.info(" select query request : " + check_mobile_exists);
            const check_mobile_exists_result = await db.query(check_mobile_exists);
            logger_all.info(" select query response : " + check_mobile_exists_result);

            if (check_mobile_exists_result.length == 0) {
                update_user += `,user_mobile='${user_mobile}'`
            }
            else {
                if (check_mobile_exists_result[0].user_id.toString() != user_id.toString()) {
                    error_msg = "and User mobile"
                }
                else {
                    update_user += `,user_mobile='${user_mobile}'`
                }
            }
        }

        if (!error_msg) {
            const update_details = `UPDATE user_management SET ${update_user.substring(1)} WHERE user_id ='${user_id}' and usr_mgt_status = 'Y'`
            logger_all.info("[Update query request] : " + update_details);
            const update_details_result = await db.query(update_details);
            logger_all.info("[Update query response] : " + JSON.stringify(update_details_result))
            return {
                response_code: 1,
                response_status: 200,
                response_msg: "Success."
            };
        }
        else {
            return {
                response_code: 0,
                response_status: 201,
                response_msg: `${error_msg.substring(4)} already exists.`
            };
        }

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
    updateUser,
};