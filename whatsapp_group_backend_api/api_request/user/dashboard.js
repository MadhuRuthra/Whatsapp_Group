const db = require("../../db_connect/connect");
const md5 = require("md5")
const main = require('../../logger')
require("dotenv").config();
const moment = require("moment")

async function Dashboard(req) {
    var logger_all = main.logger_all
    try {

        var user_id = req.body.user_id;
        var dashboard_data = []
       
        const get_group_detail = `SELECT usr.user_name,COUNT(grp.group_name) as total_groups,COUNT(case grp.group_master_status when 'Y' then 1 else null end) total_active_group,COUNT(case grp.group_master_status when 'N' then 1 else null end) total_inactive_group FROM 
        user_management usr 
        LEFT JOIN group_master grp ON grp.user_id = usr.user_id
        WHERE (grp.user_id = '${user_id}' or usr.parent_id = '${user_id}') GROUP BY user_name`
        logger_all.info("[Select query request] : " + get_group_detail);
        const get_group_detail_result = await db.query(get_group_detail);
        logger_all.info("[Select query response] : " + JSON.stringify(get_group_detail_result))

        if(get_group_detail_result.length == 0){
            return {
                response_code: 0,
                response_status: 204,
                response_msg: "No data available"
            };  
        }

        const get_contact_detail = `SELECT usr.user_name,COUNT(con.group_contacts_id) as total_contacts,COUNT(case con.group_contacts_status when 'Y' then 1 else null end) total_succ_contact,COUNT(case con.group_contacts_status when 'F' then 1 else null end) total_fail_contact FROM 
        user_management usr 
        LEFT JOIN group_contacts con ON usr.user_id = con.user_id
        WHERE (con.user_id = '${user_id}' or usr.parent_id = '${user_id}') GROUP BY user_name`
        logger_all.info("[Select query request] : " + get_contact_detail);
        const get_contact_detail_result = await db.query(get_contact_detail);
        logger_all.info("[Select query response] : " + JSON.stringify(get_contact_detail_result))

        if(get_contact_detail_result.length == 0){
            return {
                response_code: 0,
                response_status: 204,
                response_msg: "No data available"
            };  
        }

        for(var i=0; i<get_group_detail_result.length; i++){
            dashboard_data.push(
                {
                    user_name: get_group_detail_result[i].user_name,
                    total_groups: get_group_detail_result[i].total_groups,
                    total_active_group: get_group_detail_result[i].total_active_group,
                    total_inactive_group: get_group_detail_result[i].total_inactive_group,
                    total_contacts: get_contact_detail_result[i].total_contacts,
                    total_succ_contact: get_contact_detail_result[i].total_succ_contact,
                    total_fail_contact: get_contact_detail_result[i].total_fail_contact
                }
            )
        }

        return {
            response_code: 1,
            response_status: 200,
            response_msg: "Success.",
            dashboard_data: dashboard_data
        };
    } catch (err) {
        // any error occurres send error response to client
        logger_all.info("[dashboard error] : " + err);
        return {
            response_code: 0,
            response_status: 201,
            response_msg: "Error occurred"
        };
    }
}

module.exports = {
    Dashboard,
};
