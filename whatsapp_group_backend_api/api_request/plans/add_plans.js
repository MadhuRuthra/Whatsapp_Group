const db = require("../../db_connect/connect");
const main = require('../../logger')
require("dotenv").config();

async function Create_plans(req) {
    var logger_all = main.logger_all
    try {

        // get all the req data
        var plan_title = req.body.plan_title;
        var whatsapp_no_max_count_month = req.body.whatsapp_no_max_count_month;
        var group_no_max_count_month = req.body.group_no_max_count_month;
        var whatsapp_no_max_count_annual = req.body.whatsapp_no_max_count_annual;
        var group_no_max_count_annual = req.body.group_no_max_count_annual;
        var annual_price = req.body.annual_price;
        var month_price = req.body.month_price;
        var get_plans;

        if (month_price) {
            get_plans = `INSERT INTO plan_master VALUES(NULL,'${plan_title}','M','0','${whatsapp_no_max_count_month}','0','${group_no_max_count_month}','${month_price}','100','Y',CURRENT_TIMESTAMP)`;
            logger_all.info("[Insert query request] : " + get_plans);
            var get_plans_result = await db.query(get_plans);
            logger_all.info("[Insert query response] : " + JSON.stringify(get_plans_result))
        }
        if (annual_price) {
            get_plans = `INSERT INTO plan_master VALUES(NULL,'${plan_title}','A','0','${whatsapp_no_max_count_annual}','0','${group_no_max_count_annual}','${annual_price}','100','Y',CURRENT_TIMESTAMP)`;
            logger_all.info("[Insert query request] : " + get_plans);
            var get_plans_result = await db.query(get_plans);
            logger_all.info("[Insert query response] : " + JSON.stringify(get_plans_result))
        }

        if (!get_plans_result.affectedRows) {
            return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
        }
        else {
            return {
                response_code: 1, response_status: 200, response_msg: 'Success'
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
    Create_plans,
};