const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger');
const { use } = require("./route");

async function get_group(req) {
  var logger_all = main.logger_all

  let user_id = req.body.user_id;
  let group_id = req.body.group_id;

  try {
    var result = [];

    var get_group = `SELECT case when mem.mobile_no != con.mobile_no then mem.mobile_no end as member FROM group_master grp LEFT JOIN group_contacts mem ON mem.group_master_id = grp.group_master_id LEFT JOIN senderid_master con ON con.sender_master_id = grp.sender_master_id where grp.group_master_id = '${group_id}' AND grp.group_master_status = 'Y' AND mem.group_contacts_status = 'Y';`

    logger_all.info("[Select query request] : " + get_group);
    var get_group_result = await db.query(get_group);
    // logger_all.info("[Select query response] : " + JSON.stringify(get_group_result))
    result.push(get_group_result);

    var get_without_admins = `SELECT case when mem.mobile_no != con.mobile_no then mem.mobile_no end as member FROM group_master grp LEFT JOIN group_contacts mem ON mem.group_master_id = grp.group_master_id LEFT JOIN senderid_master con ON con.sender_master_id = grp.sender_master_id where grp.group_master_id = '${group_id}' AND grp.group_master_status = 'Y' AND mem.group_contacts_status = 'Y' AND (mem.admin_status != 'Y' || mem.admin_status is NULL);`

    logger_all.info("[Select query request] : " + get_without_admins);
    var get_without_admins_result = await db.query(get_without_admins);
    // logger_all.info("[Select query response] : " + JSON.stringify(get_group_result))
    result.push(get_without_admins_result);

    var get_group_admin = `SELECT case when mem.mobile_no != con.mobile_no then mem.mobile_no end as admin FROM group_master grp LEFT JOIN group_contacts mem ON mem.group_master_id = grp.group_master_id LEFT JOIN senderid_master con ON con.sender_master_id = grp.sender_master_id where grp.group_master_id = '${group_id}' AND grp.group_master_status = 'Y' AND mem.group_contacts_status = 'Y' AND mem.admin_status = 'Y';`

    logger_all.info("[Select query request] : " + get_group_admin);
    var get_group_admin_result = await db.query(get_group_admin);
    // logger_all.info("[Select query response] : " + JSON.stringify(get_group_result))
    result.push(get_group_admin_result);

    const admin_setting = `SELECT con.mobile_no,rig.rights_value FROM group_master grp
    LEFT JOIN senderid_master con ON con.sender_master_id = grp.sender_master_id
    LEFT JOIN group_rights rig ON rig.group_master_id = grp.group_master_id
     where rig.right_status = 'Y' AND rig.setting_id = '1' AND grp.group_master_id = '1'`;
    logger_all.info("[Select query request] : " + admin_setting);
    var admin_setting_result = await db.query(admin_setting);
    logger_all.info("[Select query response] : " + JSON.stringify(admin_setting_result))
    result.push(admin_setting_result);

    if (get_group_result.length == 0) {
      return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
    }
    else {
      return { response_code: 1, response_status: 200, response_msg: 'Success', group_data: result };
    }

  }

  catch (err) {
    // Failed - call_index_signin Sign in function
    logger_all.info("[country list report] Failed - " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}

async function get_group_latest(req) {
    var logger_all = main.logger_all
  
    let user_id = req.body.user_id;
  
    try {
  
      var get_group = `SELECT group_name,members_count from group_master WHERE user_id = '${user_id}' AND latest_group='L'`
  
      logger_all.info("[Select query request] : " + get_group);
      var get_group_result = await db.query(get_group);
      logger_all.info("[Select query response] : " + JSON.stringify(get_group_result))
  
      if (get_group_result.length == 0) {
        return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
      }
      else {
        if(get_group_result[0].members_count > 1){
            var group_name= get_group_result[0].group_name.split(" - ")
            if(group_name.length == 1 ){
                group_name = `${get_group_result[0].group_name} - 1`;
            }
            else{
                var count = parseInt(group_name[1])+1;
                group_name = `${group_name[0]} - ${count}`
            }
            
            return { response_code: 1, response_status: 200, response_msg: 'Success', group_name };
        }
        else{
            return { response_code: 0, response_status: 201, response_msg: 'Latest group already exists.' };
        }
      }
  
    }
  
    catch (err) {
      // Failed - call_index_signin Sign in function
      logger_all.info("[country list report] Failed - " + err);
      return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
    }
  }

module.exports = {
  get_group,
  get_group_latest
};