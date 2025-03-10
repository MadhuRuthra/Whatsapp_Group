const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function delete_Plan(req) {
    var logger_all = main.logger_all

    try {
        const select_plan_id = `CALL DeletePlan('${req.body.plan_master_id}')`;
        logger_all.info("[Select query request] : " + select_plan_id);
        var select_plan_id_result = await db.query(select_plan_id);
        logger_all.info("[Select query response] : " + JSON.stringify(select_plan_id_result))

        if (select_plan_id_result[0][0]) {
            return select_plan_id_result[0][0];
        }
    }
    catch (err) {
        // Failed - call_index_signin Sign in function
        logger_all.info(" [delete sender id error] - " + err);
        return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
    }
}
module.exports = {
    delete_Plan
};