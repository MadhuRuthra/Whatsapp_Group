const db = require("../../db_connect/connect");
const md5 = require("md5")
const main = require('../../logger')
require("dotenv").config();
const moment = require("moment")

async function getUser(req) {
    var logger_all = main.logger_all
    try {

        var user_id = req.body.user_id;

        var one_month_before_day = moment(new Date()).subtract(30, 'days').format("YYYY-MM-DD HH:mm:ss");
        var whatsapp_no_max_count = 0;
        var group_no_max_count = 0;
        var whatsapp_no_avail_count = 0;
        var message_limit = 0;
        var group_no_avail_count = 0;
        var plan_title = "-";
        var plan_range = "-";

        const get_user_detail = `Select usr.user_id,usr.user_name,usr.user_email,usr.user_mobile,mas.user_title from user_management usr 
    LEFT JOIN user_master mas ON mas.user_master_id = usr.user_master_id
    WHERE usr.user_id ='${user_id}' and usr.usr_mgt_status = 'Y';`
        logger_all.info("[Select query request] : " + get_user_detail);
        const get_user_detail_result = await db.query(get_user_detail);
        logger_all.info("[Select query response] : " + JSON.stringify(get_user_detail_result))

        const get_user_credits = `Select plnmas.whatsapp_no_max_count,plnmas.message_limit, plnmas.group_no_max_count, plnmas.plan_title,CASE
    WHEN annual_monthly = 'A' THEN 'Annually'
    WHEN annual_monthly = 'M' THEN 'Monthly'
    ELSE 'Monthly' END AS annual_monthly from user_management usr 
    LEFT JOIN user_plans plan ON plan.user_id = usr.user_id
    LEFT JOIN plan_master plnmas ON plnmas.plan_master_id = plan.plan_master_id
    WHERE usr.user_id ='${user_id}' and usr.usr_mgt_status = 'Y' AND plan.user_plans_entdate BETWEEN '${one_month_before_day}' AND CURRENT_TIMESTAMP ORDER BY plan.user_plans_entdate;`
        logger_all.info("[Select query request] : " + get_user_credits);
        const get_user_credits_result = await db.query(get_user_credits);
        logger_all.info("[Select query response] : " + JSON.stringify(get_user_credits_result))

        if (get_user_credits_result.length != 0) {
            whatsapp_no_max_count = get_user_credits_result[0].whatsapp_no_max_count;
            group_no_max_count = get_user_credits_result[0].group_no_max_count;
            plan_range = get_user_credits_result[0].annual_monthly
            plan_title = get_user_credits_result[0].plan_title
            message_limit = get_user_credits_result[0].message_limit
        }

        const get_group_available_credits = `SELECT COUNT(*) cntgroups FROM group_master WHERE user_id = ${user_id} AND is_created_by_api = 'Y' AND group_master_status = 'Y'`
        logger_all.info("[Select query request] : " + get_group_available_credits);
        const get_group_available_credits_result = await db.query(get_group_available_credits);
        logger_all.info("[Select query response] : " + JSON.stringify(get_group_available_credits_result))

        if (get_group_available_credits_result.length != 0) {
            group_no_avail_count = group_no_max_count - get_group_available_credits_result[0].cntgroups
        }

        const get_wat_available_credits = `SELECT COUNT(*) cntsenders FROM senderid_master WHERE user_id = ${user_id} AND senderid_master_status = 'Y';`
        logger_all.info("[Select query request] : " + get_wat_available_credits);
        const get_wat_available_credits_result = await db.query(get_wat_available_credits);
        logger_all.info("[Select query response] : " + JSON.stringify(get_wat_available_credits_result))

        if (get_wat_available_credits_result.length != 0) {
            whatsapp_no_avail_count =  whatsapp_no_max_count - get_wat_available_credits_result[0].cntsenders
        }

        var user_details_json = [{
            user_id: get_user_detail_result[0].user_id,
            user_name: get_user_detail_result[0].user_name,
            user_type: get_user_detail_result[0].user_title,
            user_email: get_user_detail_result[0].user_email,
            user_mobile: get_user_detail_result[0].user_mobile,
            plan_title:plan_title,
            plan_range:plan_range,
            message_limit : message_limit,
            plan_whatsapp_no_count: whatsapp_no_max_count,
            plan_group_no_count: group_no_max_count,
            available_whatsapp_no_count: whatsapp_no_avail_count,
            available_group_no_count: group_no_avail_count
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
