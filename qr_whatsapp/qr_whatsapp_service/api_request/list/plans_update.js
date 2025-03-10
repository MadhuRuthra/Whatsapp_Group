const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function Getcurrentplan_details(req) {
    var logger_all = main.logger_all
    var logger = main.logger

    try {

        var user_id = req.body.user_id;

        var plans_update = `SELECT * FROM plans_update where user_id = "${user_id}" and plan_status = "Y" and plan_expiry_date > CURRENT_TIMESTAMP`;
        logger_all.info("[Select query request] : " + plans_update);
        var plans_update_result = await db.query(plans_update);
        logger_all.info("[Select query response] : " + JSON.stringify(plans_update_result))

        if (plans_update_result.length == 0) {
            return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
        }
        else {
            return { response_code: 1, response_status: 200, response_msg: 'Success', plans_update: plans_update_result };
        }

    }

    catch (err) {
        // Failed - call_index_signin Sign in function
        logger_all.info("[Get_Group_Contact report] Failed - " + err);
        return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
    }
}
module.exports = {
    Getcurrentplan_details
};
