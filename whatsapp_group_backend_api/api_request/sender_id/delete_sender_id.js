const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function delete_sender_id(req) {
    var logger_all = main.logger_all

    try {

        const select_sender_id = `CALL DeleteSenderId('${req.body.user_id}', '${req.body.sender_id}')`;
        logger_all.info("[Select query request] : " + select_sender_id);
        var select_sender_id_result = await db.query(select_sender_id);
        logger_all.info("[Select query response] : " + JSON.stringify(select_sender_id_result))

        if (select_sender_id_result[0][0]) {
            return select_sender_id_result[0][0];
        }
    }

    catch (err) {
        // Failed - call_index_signin Sign in function
        logger_all.info(" [delete sender id error] - " + err);
        return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
    }
}
module.exports = {
    delete_sender_id
};