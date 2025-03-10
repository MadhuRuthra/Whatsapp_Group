const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function ManageUsersList(req) {
    var logger_all = main.logger_all
    var logger = main.logger

    try {

        var get_users = `SELECT usr.user_name,usr.user_email,usr.user_mobile,usr.usr_mgt_status,usr.usr_mgt_entry_date,plans.plan_title,plans.annual_monthly,plans.plan_price FROM user_management usr LEFT JOIN plans_update plan ON plan.user_id = usr.user_id LEFT JOIN plan_master plans ON plans.plan_master_id = plan.plan_master_id ORDER BY usr.user_id DESC`;

        logger_all.info("[Select query request] : " + get_users);
        var get_users_results = await db.query(get_users);
        logger_all.info("[Select query response] : " + JSON.stringify(get_users_results))

        if (get_users_results.length == 0) {
            return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
        }
        else {
            return { response_code: 1, response_status: 200, response_msg: 'Success', num_of_rows: get_users_results.length, report: get_users_results };
        }

    }

    catch (err) {
        // Failed - call_index_signin Sign in function
        logger_all.info("[ManageUsersList report] Failed - " + err);
        return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
    }
}
module.exports = {
    ManageUsersList
};
