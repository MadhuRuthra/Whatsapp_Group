const db = require("../db_connect/connect");
const md5 = require("md5")
const main = require('../logger')
require("dotenv").config();
const dynamic_db = require("../db_connect/dynamic_connect");

async function Signup(req) {
  var logger_all = main.logger_all
  var logger = main.logger
  try {
    var header_json = req.headers;
    let ip_address = header_json['x-forwarded-for'];

    var log_data = "[API REQUEST] " + req.originalUrl + " - " + JSON.stringify(req.body) + " - " + JSON.stringify(req.headers) + " - " + ip_address
    logger.info(log_data)
    logger_all.info(log_data)

    let request_id = req.body.request_id;
    let user_type = req.body.user_type;
    let user_name = req.body.user_name;
    let user_email = req.body.user_email;
    let user_mobile = req.body.user_mobile;
    let user_password = md5(req.body.user_password);
    let parent_id = 1;

    const insert_log = `INSERT INTO api_log VALUES(NULL,0,'${req.originalUrl}','${ip_address}','${request_id}','N','-','0000-00-00 00:00:00','Y',CURRENT_TIMESTAMP)`;
    logger_all.info("[insert query request] : " + insert_log);
    const insert_log_result = await db.query(insert_log);
    logger_all.info("[insert query response] : " + JSON.stringify(insert_log_result))

    const check_req_id = `SELECT * FROM api_log WHERE request_id = '${request_id}' AND response_status != 'N' AND log_status='Y'`
    logger_all.info("[select query request] : " + check_req_id);
    const check_req_id_result = await db.query(check_req_id);
    logger_all.info("[select query response] : " + JSON.stringify(check_req_id_result));

    if (check_req_id_result.length != 0) {
      return {response_code: 0, response_status: 201, response_msg: 'Request already processed' };
    }

    // To check the login_id and user_email already exists are not.if already exists to send the error message
    const check_email_exists = `SELECT * FROM user_management where user_email = '${user_email}' AND usr_mgt_status = 'Y'`
    logger_all.info(" select query request : " + check_email_exists);
    const check_email_exists_result = await db.query(check_email_exists);

    const check_mobile_exists = `SELECT * FROM user_management where user_mobile = '${user_mobile}' AND usr_mgt_status = 'Y'`
    logger_all.info(" select query request : " + check_mobile_exists);
    const check_mobile_exists_result = await db.query(check_mobile_exists);

    if (check_email_exists_result.length == 0 && check_mobile_exists_result.length == 0) {

      // To generate the random characters in the apikey
      const apikey_characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
      let apikey_length = 32;
      let apikey_result = ' ';
      const apikey_charactersLength = apikey_characters.length;
      // loop the length To create the random number in the apikey
      for (let i = 0; i < apikey_length; i++) {
        apikey_result += apikey_characters.charAt(Math.floor(Math.random() * apikey_charactersLength));
      }

      apikey_string = apikey_result.substring(0, 15);
      apikey = apikey_string.toUpperCase();
      // To insert the user_management table from the request values
      const insert_new_user = `INSERT INTO user_management VALUES (NULL, '${user_type}', '${parent_id}', '${user_name}', '${apikey}', '${user_password}', '${user_email}', '${user_mobile}', 'Y', CURRENT_TIMESTAMP,'-')`
      logger_all.info(" [signup - insert query request] : " + insert_new_user)
      const insert_new_user_result = await db.query(insert_new_user);
      logger_all.info(" [signup - insert query response] : " + JSON.stringify(insert_new_user_result))
      var user_id = insert_new_user_result.insertId;

      // To create the new DB for the sign the new user --
      const create_db = `CREATE DATABASE IF NOT EXISTS whatsapp_group_${user_id} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci`
      logger_all.info(" [create DB request] : " + create_db)
      let create_db_result = await db.query(create_db);
      logger_all.info(" [create DB response] : " + JSON.stringify(create_db_result))

      var db_name = `whatsapp_group_${user_id}`;
      // The process is continued.To create the new table in the new database
      const create_table_compose_msg = `CREATE TABLE IF NOT EXISTS compose_message_${user_id} (
        compose_message_id int NOT NULL,
        user_id int NOT NULL,
        sender_master_id int NOT NULL,
        group_master_id int NOT NULL,
        message_type varchar(10) NOT NULL,
        campaign_name varchar(30) NOT NULL,
        cm_status char(1) NOT NULL,
        cm_entry_date timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT`
      logger_all.info(` [create table compose_message_${user_id} request] : ` + JSON.stringify(create_table_compose_msg))
      let create_table_compose_msg_result = await dynamic_db.query(create_table_compose_msg, null, `${db_name}`);
      logger_all.info(` [create table compose_message_${user_id} response] : ` + JSON.stringify(create_table_compose_msg_result))

      // The process is continued.To create the new table in the new database
      const create_table_compose_msg_media = `CREATE TABLE IF NOT EXISTS compose_msg_media_${user_id} (
        compose_msg_media_id int NOT NULL,
        compose_message_id int NOT NULL,
        text_title varchar(50) DEFAULT NULL,
        text_reply varchar(50) DEFAULT NULL,
        text_number varchar(15) DEFAULT NULL,
        text_url varchar(100) DEFAULT NULL,
        text_address varchar(100) DEFAULT NULL,
        media_url varchar(100) DEFAULT NULL,
        media_type varchar(10) DEFAULT NULL,
        cmm_status char(1) NOT NULL,
        cmm_entry_date timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT`
      logger_all.info(` [create table compose_msg_media_${user_id} request] : ` + JSON.stringify(create_table_compose_msg_media))
      let create_table_compose_msg_media_result = await dynamic_db.query(create_table_compose_msg_media, null, `${db_name}`);
      logger_all.info(` [create table compose_msg_media_${user_id} response] : ` + JSON.stringify(create_table_compose_msg_media_result))

      // The process is continued.To create the new table in the new database
      const alter_compose_msg = `ALTER TABLE compose_message_${user_id}
      ADD PRIMARY KEY (compose_message_id),
      ADD KEY user_id (user_id),
      ADD KEY user_id_2 (user_id),
      ADD KEY sender_master_id (sender_master_id),
      ADD KEY group_master_id (group_master_id)`
      logger_all.info(` [alter table compose_message_${user_id} request] : ` + JSON.stringify(alter_compose_msg))
      let alter_compose_msg_result = await dynamic_db.query(alter_compose_msg, null, `${db_name}`);
      logger_all.info(` [create table compose_message_${user_id} response] : ` + JSON.stringify(alter_compose_msg_result))

      const alter_compose_msg_media = `ALTER TABLE compose_msg_media_${user_id}
      ADD PRIMARY KEY (compose_msg_media_id),
      ADD KEY compose_whatsapp_id (compose_message_id),
      ADD KEY compose_message_id (compose_message_id)`
      logger_all.info(` [alter table compose_msg_media_${user_id} request] : ` + JSON.stringify(alter_compose_msg_media))
      let alter_compose_msg_media_result = await dynamic_db.query(alter_compose_msg_media, null, `${db_name}`);
      logger_all.info(` [create table compose_msg_media_${user_id} response] : ` + JSON.stringify(alter_compose_msg_media_result))

      const alter_inc_compose_msg = `ALTER TABLE compose_message_${user_id}
      MODIFY compose_message_id int NOT NULL AUTO_INCREMENT`
      logger_all.info(` [alter table compose_message_${user_id} request] : ` + JSON.stringify(alter_inc_compose_msg))
      let alter_inc_compose_msg_result = await dynamic_db.query(alter_inc_compose_msg, null, `${db_name}`);
      logger_all.info(` [create table compose_message_${user_id} response] : ` + JSON.stringify(alter_inc_compose_msg_result))

      const alter_inc_compose_msg_media = `ALTER TABLE compose_msg_media_${user_id}
      MODIFY compose_msg_media_id int NOT NULL AUTO_INCREMENT`
      logger_all.info(` [alter table compose_msg_media_${user_id} request] : ` + JSON.stringify(alter_inc_compose_msg_media))
      let alter_inc_compose_msg_media_result = await dynamic_db.query(alter_inc_compose_msg_media, null, `${db_name}`);
      logger_all.info(` [create table compose_msg_media_${user_id} response] : ` + JSON.stringify(alter_inc_compose_msg_media_result))

      return {
        response_code: 1,
        response_status: 200,
        response_msg: 'Success'
      };

    }
    else {
      // Failed [Inactive or Not Approved User] - call_index_signin Sign in function
      return {
        response_code: 0,
        response_status: 201,
        response_msg: "Mobile number / Email already used. Kindly try with some others!!"
      };
    }

  } catch (err) {
    // any error occurres send error response to client
    logger_all.info("[signup error] : " + err);
    return {
      response_code: 0,
      response_status: 201,
      response_msg: "Error occurred"
    };
  }
}

module.exports = {
  Signup,
};
