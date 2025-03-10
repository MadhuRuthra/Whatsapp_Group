const db = require("../../db_connect/connect");
const md5 = require("md5")
const main = require('../../logger')
require("dotenv").config();
const moment = require("moment")

async function Dashboard(req) {
    var logger_all = main.logger_all
    try {

        var user_id = req.body.user_id;
        var user_master_id = req.body.user_master_id;
        console.log(user_master_id);
        
        // var dashboard_data = []
        var get_group_detail;
        if (user_master_id == 1) {
            get_group_detail = `SELECT 
            usr.user_id,
            usr.user_name,
            COUNT(grp.group_name) AS total_groups,
            COUNT(CASE grp.group_master_status WHEN 'Y' THEN 1 ELSE NULL END) AS total_active_group,
            COUNT(CASE grp.group_master_status WHEN 'N' THEN 1 ELSE NULL END) AS total_inactive_group,
            SUM(CASE grp.group_master_status WHEN 'Y' THEN grp.total_count ELSE 0 END) AS total_member,
            SUM(CASE grp.group_master_status WHEN 'Y' THEN grp.members_count ELSE 0 END) AS total_active_member,
            SUM(CASE grp.group_master_status WHEN 'Y' THEN grp.admin_count ELSE 0 END) AS total_admin
        FROM 
            user_management usr 
        LEFT JOIN 
            group_master grp ON grp.user_id = usr.user_id 
        GROUP BY 
            user_name 
        ORDER BY 
            user_id ASC;`
        }
        else {
            get_group_detail = `SELECT 
            usr.user_id,
            usr.user_name,
            COUNT(grp.group_name) AS total_groups,
            COUNT(CASE grp.group_master_status WHEN 'Y' THEN 1 ELSE NULL END) AS total_active_group,
            COUNT(CASE grp.group_master_status WHEN 'N' THEN 1 ELSE NULL END) AS total_inactive_group,
            SUM(CASE grp.group_master_status WHEN 'Y' THEN grp.total_count ELSE 0 END) AS total_member,
            SUM(CASE grp.group_master_status WHEN 'Y' THEN grp.members_count ELSE 0 END) AS total_active_member,
            SUM(CASE grp.group_master_status WHEN 'Y' THEN grp.admin_count ELSE 0 END) AS total_admin
        FROM 
            user_management usr 
        LEFT JOIN 
            group_master grp ON grp.user_id = usr.user_id 
            WHERE (usr.user_id = '${user_id}' or usr.parent_id = '${user_id}')
        GROUP BY 
            user_name 
        ORDER BY 
            user_id ASC;`
        }

        logger_all.info("[Select query request] : " + get_group_detail);
        const get_group_detail_result = await db.query(get_group_detail);
        logger_all.info("[Select query response] : " + JSON.stringify(get_group_detail_result))

        if (get_group_detail_result.length == 0) {
            return {
                response_code: 0,
                response_status: 204,
                response_msg: "No data available"
            };
        }
        // dashboard_data.push(get_group_detail_result)

        var get_contact_detail

        if (user_master_id == 1) {
            get_contact_detail = `SELECT 
            grp.group_master_id,
            usr.user_name,
            grp.group_name,
            SUM(CASE grp.group_master_status WHEN 'Y' THEN grp.total_count ELSE 0 END) AS total_member,
            SUM(CASE grp.group_master_status WHEN 'Y' THEN grp.members_count ELSE 0 END) AS total_active_member,
            SUM(CASE grp.group_master_status WHEN 'Y' THEN grp.admin_count ELSE 0 END) AS total_admin
        FROM 
        group_master grp 
        LEFT JOIN 
            user_management usr ON grp.user_id = usr.user_id
        GROUP BY 
            group_master_id 
        ORDER BY 
            group_master_id DESC;`
        }
        else {
            get_contact_detail = `SELECT 
            grp.group_master_id,
            usr.user_name,
            grp.group_name,
            SUM(CASE grp.group_master_status WHEN 'Y' THEN grp.total_count ELSE 0 END) AS total_member,
            SUM(CASE grp.group_master_status WHEN 'Y' THEN grp.members_count ELSE 0 END) AS total_active_member,
            SUM(CASE grp.group_master_status WHEN 'Y' THEN grp.admin_count ELSE 0 END) AS total_admin
        FROM 
        group_master grp 
        LEFT JOIN 
            user_management usr ON grp.user_id = usr.user_id
            WHERE (grp.user_id = '${user_id}' or usr.parent_id = '${user_id}')
        GROUP BY 
            group_master_id 
        ORDER BY 
            group_master_id DESC;`
        }

        logger_all.info("[Select query request] : " + get_contact_detail);
        const get_contact_detail_result = await db.query(get_contact_detail);
        logger_all.info("[Select query response] : " + JSON.stringify(get_contact_detail_result))

        // if (get_contact_detail_result.length == 0) {
        //     return {
        //         response_code: 0,
        //         response_status: 204,
        //         response_msg: "No data available"
        //     };
        // }
        // dashboard_data.push(get_contact_detail_result)
        // for (var i = 0; i < get_group_detail_result.length; i++) {
        //     dashboard_data.push(
        //         {
        //             user_name: get_group_detail_result[i].user_name,
        //             total_groups: get_group_detail_result[i].total_groups,
        //             total_active_group: get_group_detail_result[i].total_active_group,
        //             total_inactive_group: get_group_detail_result[i].total_inactive_group,
        //             total_contacts: get_contact_detail_result[i].total_contacts,
        //             total_succ_contact: get_contact_detail_result[i].total_succ_contact,
        //             total_fail_contact: get_contact_detail_result[i].total_fail_contact
        //         }
        //     )
        // }

        return {
            response_code: 1,
            response_status: 200,
            response_msg: "Success.",
            total: get_group_detail_result,
            group_wise:get_contact_detail_result
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
