/*const db = require("../../db_connect/connect");
const main = require('../../logger')
require("dotenv").config();

async function getAllPlans(req) {
    var logger_all = main.logger_all
    try {
        // get all the req data
        var user_id = req.body.user_id;
        const get_all_plans = `SELECT plan_master_id,plan_title,CASE
        WHEN annual_monthly = 'A' THEN 'Annually'
        WHEN annual_monthly = 'M' THEN 'Monthly'
        ELSE 'Monthly' END AS annual_monthly,whatsapp_no_max_count,group_no_max_count,message_limit,plan_price,plan_status,DATE_FORMAT(plan_entry_date,'%d-%m-%Y %H:%i:%s') plan_entry_date  FROM plan_master where plan_status = 'Y';`
        logger_all.info(" select query request : " + get_all_plans);
        const get_all_plans_result = await db.query(get_all_plans);
        logger_all.info(" select query response : " + get_all_plans_result);

        // query parameters
        logger_all.info("[check_plans_result query parameters] : " + JSON.stringify(req.body));
        // get_available_message to execute this query
        var check_plans = `SELECT DISTINCT plan_master_id,plan_expiry_date,user_id from plans_update where user_id = '${user_id}' and plan_status = "Y" order by plans_update_id desc`;
        logger_all.info("[select query request] : " + check_plans);
        const check_plans_result = await db.query(check_plans);
        logger_all.info("[select query response] : " + JSON.stringify(check_plans_result));

        return {
            response_code: 1,
            response_status: 200,
            response_msg: "Success.",
            plan_details: get_all_plans_result,
            plan_status: check_plans_result
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
    getAllPlans,
};*/
const db = require("../../db_connect/connect");
const main = require('../../logger')
require("dotenv").config();

async function getAllPlans(req) {
    var logger_all = main.logger_all
    try {

        var get_plans = `CALL GetPlanDetails('${req.body.user_id}')`;
        logger_all.info("[Select query request] : " + get_plans);
        var get_plans_result = await db.query(get_plans);
        logger_all.info("[Select query response] : " + JSON.stringify(get_plans_result))

        if (get_plans_result[0].length == 0) {
            return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
        }
        else {
            return {
                response_code: 1, response_status: 200, response_msg: 'Success', plan_details: get_plans_result[0],
                plan_status: get_plans_result[1]
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
    getAllPlans,
};
