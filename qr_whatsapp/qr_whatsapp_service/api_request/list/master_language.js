// Import the required packages and libraries
const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger');
// MasterLanguage - start
async function MasterLanguage(req) {
    var logger_all = main.logger_all
    var logger = main.logger
    try {

        // query parameters
        logger_all.info("[master_language - query parameters] : " + JSON.stringify(req.body));
        // to get get_master_language query
        var get_language = `SELECT language_id, language_name, language_code, language_id FROM master_language where language_status = 'Y' Order by language_name Asc`;

        logger_all.info("[select query request] : " + get_language);
        const get_master_language = await db.query(get_language);
        logger_all.info("[select query response] : " + JSON.stringify(get_master_language))
        // if the get_master_language length is '0' to get the no available data.otherwise it will be return the get_master_language details.
        if (get_master_language.length == 0) {
            return {
                response_code: 1,
                response_status: 204,
                response_msg: 'No data available'
            };
        } else {
            return {
                response_code: 1,
                response_status: 200,
                num_of_rows: get_master_language.length,
                response_msg: 'Success',
                report: get_master_language
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
// MasterLanguage - end

// using for module exporting
module.exports = {
    MasterLanguage
}

















                               