const db = require("../../db_connect/connect");
const main = require('../../logger')
require("dotenv").config();

async function getUser(req) {
    var logger_all = main.logger_all
    try {

        var user_id = req.body.user_id;
        var plan_master_id, get_plan, get_plan_result;
        var available_whatsapp_count = 0;
        var available_group_count = 0;
        var available_message_limit = 0;
        var total_group_count = 0;
        var total_whatsapp_count = 0;
        var total_message_limit = 0;
        var available_message_limit = 0;
        var available_group_count = 0;
        var plan_title = "-";
        var plan_range = "-";

        const get_user_detail = `Select usr.user_id,usr.user_name,usr.user_email,usr.user_mobile,mas.user_title from user_management usr 
    LEFT JOIN user_master mas ON mas.user_master_id = usr.user_master_id
    WHERE usr.user_id ='${user_id}' and usr.usr_mgt_status = 'Y'`;
        logger_all.info("[Select query request] : " + get_user_detail);
        const get_user_detail_result = await db.query(get_user_detail);
        logger_all.info("[Select query response] : " + JSON.stringify(get_user_detail_result))

        if (user_id != 1) {

            get_plan = `SELECT * FROM plans_update where plan_status = 'Y' and user_id = '${user_id}' and plan_expiry_date > CURRENT_TIMESTAMP`;
            logger_all.info("[Select query request] : " + get_plan);
            logger_all.info("[Select query request] : " + get_plan);
            get_plan_result = await db.query(get_plan);

        } else {

            get_plan = `SELECT * FROM plans_update where plan_status = 'Y' and user_id = '${user_id}'`;
            logger_all.info("[Select query request] : " + get_plan);
            logger_all.info("[Select query request] : " + get_plan);
            get_plan_result = await db.query(get_plan);
        }


        logger_all.info("[Select query response] : " + JSON.stringify(get_plan_result))

        if (get_plan_result.length > 0) {
            plan_master_id = get_plan_result[0].plan_master_id;
            total_whatsapp_count = get_plan_result[0].total_whatsapp_count;
            total_group_count = get_plan_result[0].total_group_count;
            total_message_limit = get_plan_result[0].total_message_limit;
            available_whatsapp_count = get_plan_result[0].available_whatsapp_count;
            available_group_count = get_plan_result[0].available_group_count;
            available_message_limit = get_plan_result[0].available_message_limit;
        } else {
            return {
                response_code: 0,
                response_status: 201,
                response_msg: "Plan validity is expired.!",
            };
        }

        const get_planmaster = `SELECT * FROM plan_master where plan_status = 'Y' and plan_master_id = ${plan_master_id}`;
        logger_all.info("[Select query request] : " + get_planmaster);
        const get_planmaster_result = await db.query(get_planmaster);
        logger_all.info("[Select query response] : " + JSON.stringify(get_planmaster_result))
        annual_monthly = get_planmaster_result[0].annual_monthly;
        plan_title = get_planmaster_result[0].plan_title;

        var user_details_json = [{
            user_id: get_user_detail_result[0].user_id,
            user_name: get_user_detail_result[0].user_name,
            user_type: get_user_detail_result[0].user_title,
            user_email: get_user_detail_result[0].user_email,
            user_mobile: get_user_detail_result[0].user_mobile,
            plan_title: plan_title,
            plan_range: plan_range,
            message_limit: available_message_limit,
            plan_whatsapp_no_count: total_whatsapp_count,
            plan_group_no_count: total_group_count,
            available_whatsapp_no_count: available_whatsapp_count,
            available_group_no_count: available_group_count
        }]
        return {
            response_code: 1,
            response_status: 200,
            response_msg: "Success.",
            user_details: user_details_json
        };

    } catch (err) {
        // any error occurres send error response to client
        logger_all.info("[Get user error] : " + err);
        return {
            response_code: 0,
            response_status: 201,
            response_msg: "Error occurred"
        };
    }
}

module.exports = {
    getUser,
};