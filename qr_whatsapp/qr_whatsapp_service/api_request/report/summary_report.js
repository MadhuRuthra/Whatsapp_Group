const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function summary_report(req) {
    var logger_all = main.logger_all
    var day = new Date();
    var today_date = day.getFullYear() + '-' + (day.getMonth() + 1) + '-' + day.getDate();

    let user_id = req.body.user_id;
    let start_date = req.body.start_date ? req.body.start_date : today_date;
    let end_date = req.body.end_date ? req.body.end_date : today_date;
    let campaign_name = req.body.campaign_name;
    let user_name = req.body.user_name;

    try {

        const select_campaign_query = `SELECT usr.user_name,wht.mobile_no,grp.group_name,con.campaign_name,DATE_FORMAT(con.group_contacts_entry_date,'%d-%m-%Y %H:%i:%s') group_contacts_entry_date,COUNT(case con.group_contacts_status when 'Y' then 1 else null end) total_success,COUNT(case con.group_contacts_status when 'F' then 1 else null end) total_failure,COUNT(case con.group_contacts_status when 'A' then null else 1 end) total_count
        FROM group_contacts con
        LEFT JOIN group_master grp ON grp.group_master_id = con.group_master_id
        LEFT JOIN senderid_master wht ON wht.sender_master_id = grp.sender_master_id
        LEFT JOIN user_management usr ON usr.user_id = wht.user_id
        WHERE (con.user_id = '${user_id}' or usr.parent_id = '${user_id}') AND (date(con.group_contacts_entry_date) BETWEEN '${start_date}' and '${end_date}') `

        let select_campaign_quer2 = campaign_name? `${select_campaign_query}AND con.campaign_name = '${campaign_name}' ` :`${select_campaign_query}`

        let select_campaign = user_name? `${select_campaign_quer2}AND usr.user_name = '${user_name}' GROUP BY campaign_name` :`${select_campaign_quer2}GROUP BY campaign_name`

        logger_all.info("[Select query request] : " + select_campaign);
        var select_campaign_result = await db.query(select_campaign);
        logger_all.info("[Select query response] : " + JSON.stringify(select_campaign_result))

        if (select_campaign_result.length == 0) {
            return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
        }
        else {
            return { response_code: 1, response_status: 200, response_msg: 'Success', report: select_campaign_result };
        }

    }

    catch (err) {
        // Failed - call_index_signin Sign in function
        logger_all.info("[detailed report] Failed - " + err);
        return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
    }
}
module.exports = {
    summary_report
};
