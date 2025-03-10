const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function summary_report(req) {
    var logger_all = main.logger_all
    var day = new Date();
    var today_date = day.getFullYear() + '-' + (day.getMonth() + 1) + '-' + day.getDate();

    let start_date = req.body.start_date ? req.body.start_date : today_date;
    let end_date = req.body.end_date ? req.body.end_date : today_date;
    var get_summary;
    try {

        get_summary = `SELECT * FROM summary_report where (date(summary_report_entdate) BETWEEN '${start_date}' and '${end_date}')`;

        logger_all.info("[Select query request] : " + get_summary);
        var get_summary_result = await db.query(get_summary);
        logger_all.info("[Select query response] : " + JSON.stringify(get_summary_result))

        if (get_summary_result.length == 0) {
            return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
        }
        else {
            return { response_code: 1, response_status: 200, response_msg: 'Success', report: get_summary_result };
        }

    }

    catch (err) {
        // Failed - summary_report function
        logger_all.info("[detailed report] Failed - " + err);
        return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
    }
}
module.exports = {
    summary_report
};
