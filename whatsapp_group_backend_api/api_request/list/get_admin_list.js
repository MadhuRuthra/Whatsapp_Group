const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function Get_Admin_Contact(req) {
    var logger_all = main.logger_all
    var logger = main.logger

    try {

        var group_master_id = req.body.group_master_id;
        var contact_list = `SELECT * FROM group_contacts where group_master_id = "${group_master_id}" and group_contacts_status = "Y" and admin_status = 'Y' order by group_contacts_id desc`;
        logger_all.info("[Select query request] : " + contact_list);
        var contact_list = await db.query(contact_list);
        logger_all.info("[Select query response] : " + JSON.stringify(contact_list))

        if (contact_list.length == 0) {
            return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
        }
        else {
            return { response_code: 1, response_status: 200, response_msg: 'Success', contact_list: contact_list };
        }

    }

    catch (err) {
        // Failed - call_index_signin Sign in function
        logger_all.info("[Get_Admin_Contact report] Failed - " + err);
        return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
    }
}
module.exports = {
    Get_Admin_Contact
};
