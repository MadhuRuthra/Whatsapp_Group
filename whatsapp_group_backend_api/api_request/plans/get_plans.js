// Import the required packages and libraries
const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger');
// Get_plans - start
async function Get_plans(req) {
    var logger_all = main.logger_all
    var logger = main.logger
    try {
        var plan_master_id = req.body.plan_master_id;
        var condition = '';
        // query parameters
        logger_all.info("[Get_plans - query parameters] : " + JSON.stringify(req.body));
        // to get Get_plans query

        if (plan_master_id) {
            condition = `where plan_master_id = '${plan_master_id}'`;
        }
        var get_plans = `SELECT * FROM plan_master  ${condition} Order by plan_entry_date Desc`;
        logger_all.info("[select query request] : " + get_plans);
        const get_plans_result = await db.query(get_plans);
        logger_all.info("[select query response] : " + JSON.stringify(get_plans_result))
        // if the get_master_language length is '0' to get the no available data.otherwise it will be return the get_master_language details.
        if (get_plans_result.length == 0) {
            return {
                response_code: 1,
                response_status: 204,
                response_msg: 'No data available'
            };
        } else {
            return {
                response_code: 1,
                response_status: 200,
                num_of_rows: get_plans_result.length,
                response_msg: 'Success',
                report: get_plans_result
            };
        }

    } catch (e) { // any error occurres send error response to client
        logger_all.info("[master_language - failed response] : " + e)
        return {
            response_code: 0,
            response_status: 201,
            response_msg: 'Error occured'
        };
    };
}
// Get_plans - end

// using for module exporting
module.exports = {
    Get_plans
}