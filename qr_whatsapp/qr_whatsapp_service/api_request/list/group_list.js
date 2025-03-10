const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger');
const { use } = require("./route");

async function group_list(req) {
  var logger_all = main.logger_all

  let user_id = req.body.user_id;
  let user_master_id = req.body.user_master_id;

  try {
    var group_list
    if(user_master_id == '1'){
      group_list = `SELECT COALESCE(zon.zone_name, '-') AS zone_name, COALESCE(par.parl_name, '-') AS parl_name,
      COALESCE(cons.consti_name, '-') AS consti_name,
      COALESCE(man.mandal_name, '-') AS mandal_name,grp.group_master_id,usr.user_name,usr.user_id,con.mobile_no,grp.group_name,grp.total_count,grp.success_count,grp.failure_count,grp.group_master_status,DATE_FORMAT(grp.group_master_entdate,'%d-%m-%Y %H:%i:%s') group_master_entdate,DATE_FORMAT(grp.group_updated_date,'%d-%m-%Y %H:%i:%s') group_updated_date,grp.group_link,grp.group_qrcode,grp.members_count,grp.admin_count,grp.latest_group FROM group_master grp
      LEFT JOIN senderid_master con ON con.sender_master_id = grp.sender_master_id
      LEFT JOIN user_management usr ON usr.user_id = con.user_id 
      LEFT JOIN master_mandal man ON man.mandal_id = grp.mandal_id
      LEFT JOIN master_constituency cons ON cons.consti_id = grp.consti_id
      LEFT JOIN master_parliament par ON par.parl_id = cons.parl_id
      LEFT JOIN master_zone zon ON zon.zone_id = par.zone_id
      ORDER BY grp.group_master_id DESC`
    }
    else{
      group_list = `SELECT COALESCE(zon.zone_name, '-') AS zone_name, COALESCE(par.parl_name, '-') AS parl_name,
      COALESCE(cons.consti_name, '-') AS consti_name,
      COALESCE(man.mandal_name, '-') AS mandal_name,grp.group_master_id,usr.user_name,usr.user_id,con.mobile_no,grp.group_name,grp.total_count,grp.success_count,grp.failure_count,grp.group_master_status,DATE_FORMAT(grp.group_master_entdate,'%d-%m-%Y %H:%i:%s') group_master_entdate,DATE_FORMAT(grp.group_updated_date,'%d-%m-%Y %H:%i:%s') group_updated_date,grp.group_link,grp.group_qrcode,grp.members_count,grp.admin_count,grp.latest_group FROM group_master grp
      LEFT JOIN senderid_master con ON con.sender_master_id = grp.sender_master_id
      LEFT JOIN user_management usr ON usr.user_id = con.user_id 
      LEFT JOIN master_mandal man ON man.mandal_id = grp.mandal_id
      LEFT JOIN master_constituency cons ON cons.consti_id = grp.consti_id
      LEFT JOIN master_parliament par ON par.parl_id = cons.parl_id
      LEFT JOIN master_zone zon ON zon.zone_id = par.zone_id
      where (con.user_id = '${user_id}' or usr.parent_id = '${user_id}')
      ORDER BY grp.group_master_id DESC`
    }

    logger_all.info("[Select query request] : " + group_list);
    var group_list_result = await db.query(group_list);
    // logger_all.info("[Select query response] : " + JSON.stringify(group_list_result))

    const contact_list = `SELECT grp.group_master_id,grp.group_name,grp.group_link,grp.group_qrcode,congrp.mobile_no as receiver_no,congrp.admin_status FROM group_master grp
    LEFT JOIN group_contacts congrp ON congrp.group_master_id = grp.group_master_id where congrp.admin_status = 'Y' AND congrp.group_contacts_status = 'Y'
    ORDER BY grp.group_master_id DESC`;
    logger_all.info("[Select query request] : " + contact_list);
    var contact_list_result = await db.query(contact_list);
    // logger_all.info("[Select query response] : " + JSON.stringify(contact_list_result))

    if (group_list_result.length == 0) {
      return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
    }
    else {
      return { response_code: 1, response_status: 200, response_msg: 'Success', group_list: group_list_result,admin_numbers : contact_list_result };
    }

  }

  catch (err) {
    // Failed - call_index_signin Sign in function
    logger_all.info("[country list report] Failed - " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}

async function group_list_Sender(req) {
  var logger_all = main.logger_all

  let user_id = req.body.user_id;
  let sender_id = req.body.sender_id;

  try {

    const group_list = `SELECT grp.group_master_id,con.mobile_no,grp.group_name FROM group_master grp
    LEFT JOIN senderid_master con ON con.sender_master_id = grp.sender_master_id
    LEFT JOIN user_management usr ON usr.user_id = con.user_id
    where (con.user_id = '${user_id}' or usr.parent_id = '${user_id}') AND con.mobile_no in (${sender_id}) and grp.group_master_status = 'Y' ORDER BY grp.group_master_id DESC;`
    logger_all.info("[Select query request] : " + group_list);
    var group_list_result = await db.query(group_list);
  
    if (group_list_result.length == 0) {
      return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
    }
    else {
      return { response_code: 1, response_status: 200, response_msg: 'Success', groups: group_list_result};
    }

  }

  catch (err) {
    // Failed - call_index_signin Sign in function
    logger_all.info("[country list report] Failed - " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}

module.exports = {
  group_list,
  group_list_Sender
};