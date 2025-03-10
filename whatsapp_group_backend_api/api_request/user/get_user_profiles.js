const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function User_list_Details(req) {
    var logger_all = main.logger_all

    try {

        var user_id = req.body.user_id;
        var slt_user_id = req.body.slt_user_id;
        if (slt_user_id) {
            user_id = slt_user_id;
        }

        const user_list = `SELECT * FROM user_management where usr_mgt_status = 'Y' and user_id = ${user_id}`
        logger_all.info("[Select query request] : " + user_list);
        var user_list_Result = await db.query(user_list);
        logger_all.info("[Select query response] : " + JSON.stringify(user_list_Result))

        if (user_list_Result.length == 0) {
            return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
        }
        else {
            return { response_code: 1, response_status: 200, response_msg: 'Success', user_list: user_list_Result };
        }

    }

    catch (err) {
        // Failed - User_list_Details Sign in function
        logger_all.info("[country list report] Failed - " + err);
        return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
    }
}
module.exports = {
    User_list_Details
};