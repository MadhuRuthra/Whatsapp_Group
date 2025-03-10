const db = require("../../db_connect/connect");
const main = require('../../logger')
require("dotenv").config();

async function Update_plans(req) {
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
        var plan_master_id = req.body.plan_master_id;

        if (month_price) {
            get_plans = `Update plan_master SET plan_title = '${plan_title}',whatsapp_no_max_count = '${whatsapp_no_max_count_month}',group_no_max_count = '${group_no_max_count_month}', plan_price = '${month_price}' where plan_master_id = '${plan_master_id}'`;

            logger_all.info("[Insert query request] : " + get_plans);
            var get_plans_result = await db.query(get_plans);
            logger_all.info("[Insert query response] : " + JSON.stringify(get_plans_result))
        } else {
            get_plans = `Update plan_master SET plan_title = '${plan_title}',whatsapp_no_max_count = '${whatsapp_no_max_count_annual}',group_no_max_count = '${group_no_max_count_annual}', plan_price = '${annual_price}' where plan_master_id = '${plan_master_id}'`;

            logger_all.info("[Insert query request] : " + get_plans);
            var get_plans_result = await db.query(get_plans);
            logger_all.info("[Insert query response] : " + JSON.stringify(get_plans_result))
        }

        logger_all.info("[Update query request] : " + get_plans);
        var get_plans_result = await db.query(get_plans);
        logger_all.info("[Update query response] : " + JSON.stringify(get_plans_result))

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
        logger_all.info("[Update Query error] : " + err);
        return {
            response_code: 0,
            response_status: 201,
            response_msg: "Error occurred"
        };
    }
}

module.exports = {
    Update_plans,
};