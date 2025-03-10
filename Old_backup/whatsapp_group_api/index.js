// Import the required packages and libraries
const https = require("http");
const express = require("express");
const dotenv = require('dotenv');
dotenv.config();
// const router = express.Router();
var cors = require("cors");
const { Client, LocalAuth, Buttons, MessageMedia, Location, List } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const qrcode_img = require('qrcode');
const fse = require('fs-extra');
const validator = require('./validation/middleware')
const csv = require("csv-stringify");
const {logger,logger_all} = require('./logger')

// Database Connections
const app = express();
const port = 10015;
const db = require("./db_connect/connect");

const addGroupValidation = require("./validation/add_group_validation");
const qr_code_validation = require("./validation/get_qrcode_validation");
const CreateCsvValidation = require("./validation/create_csv_validation");

const valid_user = require("./validation/valid_user_middleware");
const Login = require("./login/route");
const Signup = require("./signup/route");
const Logout = require("./logout/route");
const SenderID = require("./api_request/sender_id/route");
const ListApi = require("./api_request/list/route");
const Report = require("./api_request/report/route");
const Passwords = require("./api_request/passwords/route");

const env = process.env

const chrome_path = env.GOOGLE_CHROME;
const waiting_time = env.WAITING_TIME;
const media_storage = env.MEDIA_STORAGE;

const bodyParser = require('body-parser');
const fs = require('fs');

// var today = new Date().toLocaleString("en-IN", {timeZone: "Asia/Kolkata"});
app.use(cors());
app.use(express.json());
app.use(
  express.urlencoded({
    extended: true,
  })
);

app.get("/", (req, res) => {
  res.json({ message: "ok" });
});

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// parse application/x-www-form-urlencoded
app.use(bodyParser.urlencoded({ extended: false }));

// parse application/json
app.use(bodyParser.json());

app.use("/login", Login);
app.use("/signup", Signup);
app.use("/password", Passwords);
app.use("/logout", Logout);
app.use("/sender_id", SenderID);
app.use("/list", ListApi);
app.use("/report", Report);

// get QR code api
app.post("/get_qrcode", validator.body(qr_code_validation), valid_user, async (req, res) => {

  try {
    // client id i.e, client mobile number
    var sender_id = req.body.mobile_number;
    var user_id;
    const header_token = req.headers['authorization'];
    var status_user = '';

    logger_all.info(" [get QR code query parameters] : " + req.body);
    logger.info("[API REQUEST] " + req.originalUrl + " - " + JSON.stringify(req.body) + " - " + JSON.stringify(req.headers))

    var header_json = req.headers;
    let ip_address = header_json['x-forwarded-for'];

    logger_all.info("[insert query request] : " + `INSERT INTO api_log VALUES(NULL,'${req.originalUrl}','${ip_address}','${req.body.request_id}','N','-','0000-00-00 00:00:00','Y',CURRENT_TIMESTAMP)`);
    const insert_api_log = await db.query(`INSERT INTO api_log VALUES(NULL,'${req.originalUrl}','${ip_address}','${req.body.request_id}','N','-','0000-00-00 00:00:00','Y',CURRENT_TIMESTAMP)`);
    logger_all.info("[insert query response] : " + JSON.stringify(insert_api_log))

    logger_all.info("[select query request] : " + `SELECT * FROM api_log WHERE request_id = '${req.body.request_id}' AND response_status != 'N' AND log_status='Y'`);
    const check_req_id = await db.query(`SELECT * FROM api_log WHERE request_id = '${req.body.request_id}' AND response_status != 'N' AND log_status='Y'`);
    logger_all.info("[select query response] : " + JSON.stringify(check_req_id));

    if (check_req_id.length != 0) {

      logger_all.info("[Valid User Middleware failed response] : Request already processed");

      logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Request already processed' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Request already processed' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

      logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Request already processed' }))

      return res.json({ request_id: req.body.request_id,response_code: 0, response_status: 201, response_msg: 'Request already processed' });

    }

    var get_user = `SELECT * FROM user_management where bearer_token = '${header_token}' AND usr_mgt_status = 'Y' `;

    logger_all.info("[select query request] : " + get_user);
    const get_user_id = await db.query(get_user);
    logger_all.info("[select query response] : " + JSON.stringify(get_user_id));

    user_id = get_user_id[0].user_id;

    logger_all.info(" [select query request] : " + `SELECT * from whatsapp_config WHERE mobile_no = '${sender_id}' AND whatspp_config_status in ('L', 'Y')`)
    const select_number = await db.query(`SELECT * from whatsapp_config WHERE mobile_no = '${sender_id}' AND whatspp_config_status in ('L', 'Y')`);
    logger_all.info(" [select query response] : " + JSON.stringify(select_number))

    if (select_number.length == 0) {

      if (fs.existsSync(`./.wwebjs_auth/session-${sender_id}`)) {
        fs.rmdirSync(`./.wwebjs_auth/session-${sender_id}`, { recursive: true })
      }

      // initialize client with mobile number
      const client = new Client({
        restartOnAuthFail: true,
        takeoverOnConflict: true,
        takeoverTimeoutMs: 0,
        puppeteer: {
          handleSIGINT: false,
          args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-accelerated-2d-canvas',
            '--no-first-run',
            '--no-zygote',
            '--disable-gpu'
          ],
          executablePath: chrome_path,
        },
        authStrategy: new LocalAuth(
          { clientId: sender_id }
        )

      });

      client.initialize();

      // get the QR code by socket
      client.on('qr', async (qr) => {
        // Generate and scan this code with your phone
        logger_all.info(" [get QR code success response] : " + qr);
        qrcode.generate(qr, { small: true });

        const qrOption = {
          margin: 7,
          width: 175
        };
        const qrString = qr;
        const bufferImage = await qrcode_img.toDataURL(qrString, qrOption);

        logger_all.info(" [select query request] : " + `SELECT * from whatsapp_config WHERE mobile_no = '${sender_id}' ORDER BY whatspp_config_id DESC`)
        const select_number = await db.query(`SELECT * from whatsapp_config WHERE mobile_no = '${sender_id}' ORDER BY whatspp_config_id DESC`);
        logger_all.info(" [select query response] : " + JSON.stringify(select_number))

        if (select_number.length == 0) {
          status_user = 'Y'
          logger_all.info(" [insert query request] : " + `INSERT INTO whatsapp_config VALUES(NULL,${user_id},${sender_id},'N',CURRENT_TIMESTAMP,'0000-00-00 00:00:00')`)
          const insert_to_config = await db.query(`INSERT INTO whatsapp_config VALUES(NULL,${user_id},${sender_id},'N',CURRENT_TIMESTAMP,'0000-00-00 00:00:00')`);
          logger_all.info(" [insert query response] : " + JSON.stringify(insert_to_config))

        }
        else {
          if (select_number[0].whatspp_config_status == 'X' || select_number[0].whatspp_config_status == 'Y') {
            status_user = 'Y'
          }
          else {
            status_user = 'Y'
          }

          if (select_number[0].whatspp_config_status == 'D') {
            logger_all.info(" [insert query request] : " + `INSERT INTO whatsapp_config VALUES(NULL,${user_id},${sender_id},'N',CURRENT_TIMESTAMP,'0000-00-00 00:00:00')`)
            const deleted_user = await db.query(`INSERT INTO whatsapp_config VALUES(NULL,${user_id},${sender_id},'N',CURRENT_TIMESTAMP,'0000-00-00 00:00:00')`);
            logger_all.info(" [insert query response] : " + JSON.stringify(deleted_user))

          }
        }

        setTimeout(async function () {
          await client.destroy();
          logger_all.info("client destroyed")

        }, 50000);

        logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        const update_api_log = await db.query(`UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

        logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 1, response_status: 200, response_msg: 'success', "qr_code": bufferImage }))

        return res.json({ request_id: req.body.request_id, response_code: 1, response_status: 200, response_msg: 'success', "qr_code": bufferImage })
      });

      client.on('ready', async () => {
        logger_all.info(" Client is ready - " + sender_id)
        var qr_number = client.info.wid.user;
        if (`${qr_number}` == `${sender_id}`) {

          logger_all.info(" [update query request] : " + `UPDATE whatsapp_config SET whatspp_config_status = '${status_user}' WHERE mobile_no = '${sender_id}' AND whatspp_config_status != 'D'`)
          const update_user = await db.query(`UPDATE whatsapp_config SET whatspp_config_status = '${status_user}' WHERE mobile_no = '${sender_id}' AND whatspp_config_status != 'D'`);
          logger_all.info(" [update query response] : " + JSON.stringify(update_user))

          if (fs.existsSync(`./.session_copy/session-${sender_id}`)) {
            fs.rmdirSync(`./.session_copy/session-${sender_id}`, { recursive: true })
          }
          if (fs.existsSync(`./.wwebjs_auth/session-${sender_id}`)) {
            // fs.rmdirSync(`./.wwebjs_auth/session-${sender_numbers[c]}`, { recursive: true })
            // fs.c
            try {
              fse.copySync(`./.wwebjs_auth/session-${sender_id}`, `./session_copy/session-${sender_id}`, { overwrite: true | false })
            } catch (err) {
              console.error(err)
            }
          }

        }
        else {
          logger_all.info(" [update query request] : " + `UPDATE whatsapp_config SET whatspp_config_status = 'M' WHERE mobile_no = '${sender_id}' AND whatspp_config_status != 'D'`)
          const update_user = await db.query(`UPDATE whatsapp_config SET whatspp_config_status = 'M' WHERE mobile_no = '${sender_id}' AND whatspp_config_status != 'D'`);
          logger_all.info(" [update query response] : " + JSON.stringify(update_user))
        }

        await client.destroy();

        if (status_user == '') {

          logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'User already exists' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
          const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'User already exists' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
          logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

          logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'User already exists' }))
          return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'User already exists' })
        }
      });

      client.on('disconnected', async (reason) => {
        logger_all.info(" [update query request] : " + `UPDATE whatsapp_config SET whatspp_config_status = 'U' WHERE mobile_no = '${sender_id}' AND whatspp_config_status != 'D'`)
        const disconn_user = await db.query(`UPDATE whatsapp_config SET whatspp_config_status = 'U' WHERE mobile_no = '${sender_id}' AND whatspp_config_status != 'D'`);
        logger_all.info(" [update query response] : " + JSON.stringify(disconn_user))

        // Destroy and reinitialize the client when disconnected
        await client.destroy();
      });
    }
    else {
      logger_all.info(" [Number already available] : " + sender_id)

      logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Mobile number already exists' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Mobile number already exists' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

      logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Mobile number already exists.' }))
      return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Mobile number already exists.' })
    }

  }
  catch (e) {
    logger_all.info(" [get QR code failed response] : " + e)
  }

});

app.post('/create_csv', validator.body(CreateCsvValidation),
  valid_user, async function (req, res) {

    try {

      var day = new Date();
      var today_date = day.getFullYear() + '' + (day.getMonth() + 1) + '' + day.getDate();
      var today_time = day.getHours() + "" + day.getMinutes() + "" + day.getSeconds();
      var current_date = today_date + '_' + today_time;

      let sender_number = req.body.mobile_number;

      logger_all.info(" [create csv query parameters] : " + sender_number)
      logger.info("[API REQUEST] " + req.originalUrl + " - " + JSON.stringify(req.body) + " - " + JSON.stringify(req.headers))

      var header_json = req.headers;
      let ip_address = header_json['x-forwarded-for'];

      logger_all.info("[insert query request] : " + `INSERT INTO api_log VALUES(NULL,'${req.originalUrl}','${ip_address}','${req.body.request_id}','N','-','0000-00-00 00:00:00','Y',CURRENT_TIMESTAMP)`);
      const insert_api_log = await db.query(`INSERT INTO api_log VALUES(NULL,'${req.originalUrl}','${ip_address}','${req.body.request_id}','N','-','0000-00-00 00:00:00','Y',CURRENT_TIMESTAMP)`);
      logger_all.info("[insert query response] : " + JSON.stringify(insert_api_log))

      logger_all.info("[select query request] : " + `SELECT * FROM api_log WHERE request_id = '${req.body.request_id}' AND response_status != 'N' AND log_status='Y'`);
      const check_req_id = await db.query(`SELECT * FROM api_log WHERE request_id = '${req.body.request_id}' AND response_status != 'N' AND log_status='Y'`);
      logger_all.info("[select query response] : " + JSON.stringify(check_req_id));

      if (check_req_id.length != 0) {

        logger_all.info("[Valid User Middleware failed response] : Request already processed");

        logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Request already processed' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Request already processed' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

        logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Request already processed' }))

        return res.json({request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Request already processed' });

      }

      var data = [
        ['Name', 'Given Name', 'Group Membership', 'Phone 1 - Type', 'Phone 1 - Value']
      ];

      for (var i = 0; i < sender_number.length; i++) {
        data.push([`yjtec${day.getDate()}_${sender_number[i]}`, `yjtec${day.getDate()}_${sender_number[i]}`, '* myContacts', '', `${sender_number[i]}`])
      }

      // (C) CREATE CSV FILE
      csv.stringify(data, async (err, output) => {
        fs.writeFileSync(`${media_storage}/uploads/whatsapp_docs/contacts_${current_date}.csv`, output);

        logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        const update_api_log = await db.query(`UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

        logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 1, response_status: 200, response_msg: 'Success ', file_location: `uploads/whatsapp_docs/contacts_${current_date}.csv` }))

        res.json({ request_id: req.body.request_id, response_code: 1, response_status: 200, response_msg: 'Success ', file_location: `uploads/whatsapp_docs/contacts_${current_date}.csv` });
      });

    }
    catch (e) {
      logger_all.info("[create csv failed response] : " + e.message)

      logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

      logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error Occurred ' }))

      res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error Occurred ' });
    }
  });

app.post("/create_group", validator.body(addGroupValidation),
  valid_user, async (req, res) => {

    try {
      logger_all.info(" [create group] - " + req.body);
      logger.info("[API REQUEST] " + req.originalUrl + " - " + JSON.stringify(req.body) + " - " + JSON.stringify(req.headers))

      var myGroupName = req.body.group_name;
      var participants = req.body.participants_name;
      var participants_number = req.body.participants_number;
      var sender_id = req.body.sender_id;
      var campaign_name = req.body.campaign_name;

      var function_call = false;
      var contact_id = [];
      var user_id;
      var whatspp_config_id;

      var header_json = req.headers;
      let ip_address = header_json['x-forwarded-for'];

      logger_all.info("[insert query request] : " + `INSERT INTO api_log VALUES(NULL,'${req.originalUrl}','${ip_address}','${req.body.request_id}','N','-','0000-00-00 00:00:00','Y',CURRENT_TIMESTAMP)`);
      const insert_api_log = await db.query(`INSERT INTO api_log VALUES(NULL,'${req.originalUrl}','${ip_address}','${req.body.request_id}','N','-','0000-00-00 00:00:00','Y',CURRENT_TIMESTAMP)`);
      logger_all.info("[insert query response] : " + JSON.stringify(insert_api_log))

      logger_all.info("[select query request] : " + `SELECT * FROM api_log WHERE request_id = '${req.body.request_id}' AND response_status != 'N' AND log_status='Y'`);
      const check_req_id = await db.query(`SELECT * FROM api_log WHERE request_id = '${req.body.request_id}' AND response_status != 'N' AND log_status='Y'`);
      logger_all.info("[select query response] : " + JSON.stringify(check_req_id));

      if (check_req_id.length != 0) {

        logger_all.info("[Valid User Middleware failed response] : Request already processed");

        logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Request already processed' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Request already processed' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

        logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Request already processed' }))

        return res.json({ request_id: req.body.request_id,response_code: 0, response_status: 201, response_msg: 'Request already processed' });

      }
      logger_all.info(" [select query request] : " + `SELECT * FROM whatsapp_config WHERE mobile_no = '${sender_id}' AND whatspp_config_status = 'Y'`)
      const select_sender_id = await db.query(`SELECT * FROM whatsapp_config WHERE mobile_no = '${sender_id}' AND whatspp_config_status = 'Y'`);
      logger_all.info(" [select query response] : " + JSON.stringify(select_sender_id))

      if (select_sender_id.length == 0) {

        logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

        logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID not found.' }))
        return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID not found.' })
      }
      else {

        user_id = select_sender_id[0].user_id;
        whatspp_config_id = select_sender_id[0].whatspp_config_id;

        logger_all.info("[select query request] : " + `SELECT * FROM group_contacts WHERE whatspp_config_id = '${whatspp_config_id}' AND group_name = '${myGroupName}' AND group_contact_status = 'Y'`)
        const select_grp = await db.query(`SELECT * FROM group_contacts WHERE whatspp_config_id = '${whatspp_config_id}' AND group_name = '${myGroupName}' AND group_contact_status = 'Y'`);
        logger_all.info("[select query response] : " + JSON.stringify(select_grp))

        if (select_grp.length != 0) {
          logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group already exists' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
          const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group already exists' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
          logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

          logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group already exists' }))
          return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group already exists' })

        }

        Date.prototype.julianDate = function () {
          var j = parseInt((this.getTime() - new Date('Dec 30,' + (this.getFullYear() - 1) + ' 23:00:00').getTime()) / 86400000).toString(),
            i = 3 - j.length;
          while (i-- > 0) j = 0 + j;
          return j
        };

        logger_all.info("[select query request] : " + `SELECT * FROM contact_mobile ORDER BY campaign_name DESC`)
        const select_campaign_id = await db.query(`SELECT * FROM contact_mobile ORDER BY campaign_name DESC`);
        logger_all.info("[select query response] : " + JSON.stringify(select_campaign_id))

        if (select_campaign_id.length == 0) {
          campaign_name = `ca_${myGroupName}_${new Date().julianDate()}_1`;
        }
        else {

          var temp_var = select_campaign_id[0].campaign_name.split("_");
          var unique_id = temp_var[temp_var.length - 1];
          campaign_name = `ca_${myGroupName}_${new Date().julianDate()}_${unique_id + 1}`;
        }
        var client = new Client({
          restartOnAuthFail: true,
          puppeteer: {
            headless: true,
            args: [
              '--no-sandbox',
              '--disable-setuid-sandbox',
              '--disable-dev-shm-usage',
              '--disable-accelerated-2d-canvas',
              '--no-first-run',
              '--no-zygote',
              '--disable-gpu'
            ],
            executablePath: chrome_path,
          },
          authStrategy: new LocalAuth(
            { clientId: sender_id }
          )
        }
        );

        client.initialize();

        client.on('ready', async (data) => {
          logger_all.info('Client is ready! - ' + sender_id);
          create_grp();
        });

        setTimeout(async function () {
          if (function_call == false) {

            logger_all.info(' rescan number - ' + sender_id)
            if (fs.existsSync(`./.wwebjs_auth/session-${sender_id}`)) {
              fs.rmdirSync(`./.wwebjs_auth/session-${sender_id}`, { recursive: true })

            }
            if (fs.existsSync(`./session_copy/session-${sender_id}`)) {
              try {
           //if (fs.existsSync(`./session_copy/session-${sender_id}`)) { 
	       fse.copySync(`./session_copy/session-${sender_id}`, `./.wwebjs_auth/session-${sender_id}`, { overwrite: true | false })
                logger_all.info('Folder copied successfully')
       	   //}

                client = new Client({
                  restartOnAuthFail: true,
                  takeoverOnConflict: true,
                  takeoverTimeoutMs: 0,
                  puppeteer: {
                    handleSIGINT: false,
                    args: [
                      '--no-sandbox',
                      '--disable-setuid-sandbox',
                      '--disable-dev-shm-usage',
                      '--disable-accelerated-2d-canvas',
                      '--no-first-run',
                      '--no-zygote',
                      '--disable-gpu'
                    ],
                    executablePath: chrome_path,
                  },
                  authStrategy: new LocalAuth(
                    { clientId: sender_id }
                  )
                }
                );

                client.initialize();

                client.on('authenticated', async (data) => {
                  logger_all.info(" [Client is Log in] : " + JSON.stringify(data));

                });

                client.on('ready', async (data) => {
                  logger_all.info(" [Client is ready] : " + client.options.authStrategy.clientId);
                  create_grp()
                });

                setTimeout(async function () {
                  if (function_call == false) {

                    logger_all.info(" [update query request] : " + `UPDATE whatsapp_config SET whatspp_config_status = 'X' WHERE mobile_no = '${sender_id}' AND whatspp_config_status != 'D'`)
                    const update_inactive = await db.query(`UPDATE whatsapp_config SET whatspp_config_status = 'X' WHERE mobile_no = '${sender_id}' AND whatspp_config_status != 'D'`);
                    //logger_all.info(" [update query response] : " + JSON.stringify(update_inactive))

        logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID unlinked' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID unlinked' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

                    logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID unlinked.',}))
                    return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID unlinked.' })
                  }
                }, waiting_time);
              } catch (err) {
                logger_all.info(err)

                logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
                const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
                logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

                logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.', "success": contact_id.length, "failure": participants.length - contact_id.length }))
                return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.', "success": contact_id.length, "failure": participants.length - contact_id.length })
              }
            }
         //}
	else{
		
      logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

      logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }))
      return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' })
	}
	}
        }, waiting_time);

        async function create_grp() {
          function_call = true;

          try {

            for (var i = 0; i < participants.length; i++) {
              await client.getContacts().then((contacts) => {
                logger_all.info(" - " + participants[i])
                const contactToAdd = contacts.find(
                  (contact) => contact.name === `${participants[i]}`
                );

                if (contactToAdd) {
                  logger_all.info("Contact Found!!!");
                  contact_id.push(contactToAdd.id._serialized);

                } else {
                  logger_all.info('Not found!!!');
                }
              });
            }

            if (contact_id.length == 0) {

              client.destroy();
              logger_all.info(" Destroy client - " + sender_id)

              logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'No contacts found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
              const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'No contacts found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
              logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

              logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'No contacts found.' }))
              return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'No contacts found.' })
            }

            var create_grp = await client.createGroup(myGroupName, contact_id)
            logger_all.info(create_grp);

            client.destroy();
            logger_all.info(" Destroy client - " + sender_id)

            logger_all.info("[insert query request] : " + `INSERT INTO group_contacts VALUES(NULL,'${user_id}','${whatspp_config_id}','${myGroupName}','${participants.length}','${contact_id.length}','${participants.length - contact_id.length}','Y',CURRENT_TIMESTAMP)`);
            const insert_grp = await db.query(`INSERT INTO group_contacts VALUES(NULL,'${user_id}','${whatspp_config_id}','${myGroupName}','${participants.length}','${contact_id.length}','${participants.length - contact_id.length}','Y',CURRENT_TIMESTAMP)`);
            logger_all.info("[insert query response] : " + JSON.stringify(insert_grp))

            for (var k = 0; k < participants.length; k++) {
              var contact_status = 'F';
              if (contact_id.includes(`${participants[k]}`)) {
                contact_status = 'Y'
              }

              logger_all.info("[insert query request] : " + `INSERT INTO contact_mobile VALUES(NULL,'${user_id}','${insert_grp.insertId}','${campaign_name}','${participants_number[k]}','${participants[k]}','${contact_status}',CURRENT_TIMESTAMP)`);
              const update_number_status = await db.query(`INSERT INTO contact_mobile VALUES(NULL,'${user_id}','${insert_grp.insertId}','${campaign_name}','${participants_number[k]}','${participants[k]}','${contact_status}',CURRENT_TIMESTAMP)`);
              logger_all.info("[insert query response] : " + JSON.stringify(update_number_status))

            }

            logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
            const update_api_log = await db.query(`UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
            logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

            logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 1, response_status: 200, response_msg: 'Success.', "success": contact_id.length, "failure": participants.length - contact_id.length }))
            return res.json({ request_id: req.body.request_id, response_code: 1, response_status: 200, response_msg: 'Success.', "success": contact_id.length, "failure": participants.length - contact_id.length })
          }
          catch (e) {
            logger_all.info(e);
            client.destroy();
            logger_all.info(" Destroy client - " + sender_id)

            logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
            const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
            logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

            logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }))
            return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' })
          }
        }
      }
    }
    catch (e) {
      logger_all.info(e);

      logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

      logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }))
      return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' })
    }

  });

app.post("/add_group", validator.body(addGroupValidation),
  valid_user, async (req, res) => {

    try {
      logger_all.info(" [add participants to the group] - " + req.body);
      logger.info("[API REQUEST] " + req.originalUrl + " - " + JSON.stringify(req.body) + " - " + JSON.stringify(req.headers))

      var myGroupName = req.body.group_name;
      var participants = req.body.participants_name;
      var participants_number = req.body.participants_number;
      var sender_id = req.body.sender_id;
      var function_call = false;
      var contact_id = [];
      var user_id;
      var whatspp_config_id;
      var grp_id;
      var campaign_name;

      var header_json = req.headers;
      let ip_address = header_json['x-forwarded-for'];

      logger_all.info("[insert query request] : " + `INSERT INTO api_log VALUES(NULL,'${req.originalUrl}','${ip_address}','${req.body.request_id}','N','-','0000-00-00 00:00:00','Y',CURRENT_TIMESTAMP)`);
      const insert_api_log = await db.query(`INSERT INTO api_log VALUES(NULL,'${req.originalUrl}','${ip_address}','${req.body.request_id}','N','-','0000-00-00 00:00:00','Y',CURRENT_TIMESTAMP)`);
      logger_all.info("[insert query response] : " + JSON.stringify(insert_api_log))

      logger_all.info("[select query request] : " + `SELECT * FROM api_log WHERE request_id = '${req.body.request_id}' AND response_status != 'N' AND log_status='Y'`);
      const check_req_id = await db.query(`SELECT * FROM api_log WHERE request_id = '${req.body.request_id}' AND response_status != 'N' AND log_status='Y'`);
      logger_all.info("[select query response] : " + JSON.stringify(check_req_id));

      if (check_req_id.length != 0) {

        logger_all.info("[Valid User Middleware failed response] : Request already processed");

        logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Request already processed' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Request already processed' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

        logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Request already processed' }))

        return res.json({ request_id: req.body.request_id,response_code: 0, response_status: 201, response_msg: 'Request already processed' });

      }
      logger_all.info(" [select query request] : " + `SELECT * FROM whatsapp_config WHERE mobile_no = '${sender_id}' AND whatspp_config_status = 'Y'`)
      const select_sender_id = await db.query(`SELECT * FROM whatsapp_config WHERE mobile_no = '${sender_id}' AND whatspp_config_status = 'Y'`);
      logger_all.info(" [select query response] : " + JSON.stringify(select_sender_id))

      if (select_sender_id.length == 0) {

        logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

        logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID not found.' }))
        return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID not found.' })
      }
      else {

        user_id = select_sender_id[0].user_id;
        whatspp_config_id = select_sender_id[0].whatspp_config_id;

        logger_all.info("[select query request] : " + `SELECT * FROM group_contacts WHERE whatspp_config_id = '${whatspp_config_id}' AND group_name = '${myGroupName}' AND group_contact_status = 'Y'`)
        const select_grp = await db.query(`SELECT * FROM group_contacts WHERE whatspp_config_id = '${whatspp_config_id}' AND group_name = '${myGroupName}' AND group_contact_status = 'Y'`);
        logger_all.info("[select query response] : " + JSON.stringify(select_grp))

        if (select_grp.length == 0) {
          logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
          const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
          logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

          logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group not found' }))
          return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group not found.' })

        }

        Date.prototype.julianDate = function () {
          var j = parseInt((this.getTime() - new Date('Dec 30,' + (this.getFullYear() - 1) + ' 23:00:00').getTime()) / 86400000).toString(),
            i = 3 - j.length;
          while (i-- > 0) j = 0 + j;
          return j
        };

        logger_all.info("[select query request] : " + `SELECT * FROM contact_mobile ORDER BY campaign_name DESC`)
        const select_campaign_id = await db.query(`SELECT * FROM contact_mobile ORDER BY campaign_name DESC`);
        logger_all.info("[select query response] : " + JSON.stringify(select_campaign_id))

        if (select_campaign_id.length == 0) {
          campaign_name = `ca_${myGroupName}_${new Date().julianDate()}_1`;
        }
        else {
          var temp_var = select_campaign_id[0].campaign_name.split("_");
          var unique_id = temp_var[temp_var.length - 1];
          campaign_name = `ca_${myGroupName}_${new Date().julianDate()}_${unique_id + 1}`;
        }

        grp_id = select_grp[0].group_contact_id;

        var client = new Client({
          restartOnAuthFail: true,
          puppeteer: {
            headless: true,
            args: [
              '--no-sandbox',
              '--disable-setuid-sandbox',
              '--disable-dev-shm-usage',
              '--disable-accelerated-2d-canvas',
              '--no-first-run',
              '--no-zygote',
              '--disable-gpu'
            ],
            executablePath: chrome_path,
          },
          authStrategy: new LocalAuth(
            { clientId: sender_id }
          )
        }
        );

        client.initialize();

        client.on('ready', async (data) => {
          logger_all.info('Client is ready! - ' + sender_id);
          add_participant();
        });

        setTimeout(async function () {
          if (function_call == false) {
            // await client.destroy();

            // logger_all.info('destroy number - ' + sender_id)

            logger_all.info(' rescan number - ' + sender_id)
            if (fs.existsSync(`./.wwebjs_auth/session-${sender_id}`)) {
              fs.rmdirSync(`./.wwebjs_auth/session-${sender_id}`, { recursive: true })

            }
            if (fs.existsSync(`./session_copy/session-${sender_id}`)) {
              try {
	//if (fs.existsSync(`./session_copy/session-${sender_id}`)) {
                fse.copySync(`./session_copy/session-${sender_id}`, `./.wwebjs_auth/session-${sender_id}`, { overwrite: true | false })
                logger_all.info('Folder copied successfully')
	//}

                client = new Client({
                  restartOnAuthFail: true,
                  takeoverOnConflict: true,
                  takeoverTimeoutMs: 0,
                  puppeteer: {
                    handleSIGINT: false,
                    args: [
                      '--no-sandbox',
                      '--disable-setuid-sandbox',
                      '--disable-dev-shm-usage',
                      '--disable-accelerated-2d-canvas',
                      '--no-first-run',
                      '--no-zygote',
                      '--disable-gpu'
                    ],
                    executablePath: chrome_path,
                  },
                  authStrategy: new LocalAuth(
                    { clientId: sender_id }
                  )
                }
                );

                client.initialize();

                client.on('authenticated', async (data) => {
                  logger_all.info(" [Client is Log in] : " + JSON.stringify(data));

                });

                client.on('ready', async (data) => {
                  logger_all.info(" [Client is ready] : " + client.options.authStrategy.clientId);
                  add_participant()
                });

                setTimeout(async function () {
                  if (function_call == false) {

                    logger_all.info(" [update query request] : " + `UPDATE whatsapp_config SET whatspp_config_status = 'X' WHERE mobile_no = '${sender_id}' AND whatspp_config_status != 'D'`)
                    const update_inactive = await db.query(`UPDATE whatsapp_config SET whatspp_config_status = 'X' WHERE mobile_no = '${sender_id}' AND whatspp_config_status != 'D'`);
                   // logger_all.info(" [update query response] : " + JSON.stringify(update_inactive))

        logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID unlinked' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID unlinked' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
        logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

                    logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID unlinked.',}))
                    return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID unlinked.' })
                  }
                }, waiting_time);
              } catch (err) {
                logger_all.info(err)

                logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
                const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
                logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

                logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.', "success": contact_id.length, "failure": participants.length - contact_id.length }))
                return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.', "success": contact_id.length, "failure": participants.length - contact_id.length })
              }
            }
         // }
	else{
      logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

      logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }))
      return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' })
	}
	}
        }, waiting_time);

        async function add_participant() {
          function_call = true;
          console.log(client);

          client.getChats().then(async (chats) => {
            try {

              const myGroup = chats.find((chat) => chat.name === myGroupName);

              for (var i = 0; i < participants.length; i++) {
                await client.getContacts().then((contacts) => {
                 // logger_all.info(JSON.stringify(contacts))

                  logger_all.info(" - " + participants[i])
                  const contactToAdd = contacts.find(
                    (contact) => contact.name === `${participants[i]}`
                  );

                  if (contactToAdd) {
                    logger_all.info("Contact Found!!!");
                    contact_id.push(contactToAdd.id._serialized);

                  } else {
                    logger_all.info('Not found!!!');
                  }
                });
              }

              if (contact_id.length == 0) {

                client.destroy();
                logger_all.info(" Destroy client - " + sender_id)

                logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'No contacts found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
                const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'No contacts found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
                logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

                logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'No contacts found.' }))
                return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'No contacts found.' })
              }

              var group_add = await myGroup.addParticipants(contact_id);
              logger_all.info(group_add);

              client.destroy();
              logger_all.info(" Destroy client - " + sender_id)

              logger_all.info("[update query request] : " + `UPDATE group_contacts SET total_count = total_count+${participants.length},success_count= success_count+${contact_id.length}, failure_count= failure_count+${participants.length - contact_id.length} WHERE group_contact_id = '${grp_id}' AND group_contact_status = 'Y'`);
              const insert_grp = await db.query(`UPDATE group_contacts SET total_count = total_count+${participants.length},success_count= success_count+${contact_id.length}, failure_count= failure_count+${participants.length - contact_id.length} WHERE group_contact_id = '${grp_id}' AND group_contact_status = 'Y'`);
              logger_all.info("[update query response] : " + JSON.stringify(insert_grp))

              for (var k = 0; k < participants.length; k++) {
                var contact_status = 'F';
                if (contact_id.includes(`${participants[k]}`)) {
                  contact_status = 'Y'
                }

                logger_all.info("[insert query request] : " + `INSERT INTO contact_mobile VALUES(NULL,'${user_id}','${grp_id}','${campaign_name}','${participants_number[k]}','${participants[k]}','${contact_status}',CURRENT_TIMESTAMP)`);
                const update_number_status = await db.query(`INSERT INTO contact_mobile VALUES(NULL,'${user_id}','${grp_id}','${campaign_name}','${participants_number[k]}','${participants[k]}','${contact_status}',CURRENT_TIMESTAMP)`);
                logger_all.info("[insert query response] : " + JSON.stringify(update_number_status))

              }
              logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
              const update_api_log = await db.query(`UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
              logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

              logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 1, response_status: 200, response_msg: 'Success.', "success": contact_id.length, "failure": participants.length - contact_id.length }))
              return res.json({ request_id: req.body.request_id, response_code: 1, response_status: 200, response_msg: 'Success.', "success": contact_id.length, "failure": participants.length - contact_id.length })
            }
            catch (e) {
              logger_all.info(e);

              client.destroy();
              logger_all.info(" Destroy client - " + sender_id)

              logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
              const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
              logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

              logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }))

              return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' })
            }
          })
        }
      }
    }
    catch (e) {
      logger_all.info(e);

      logger_all.info("[update query request] : " + `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      const update_api_log = await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

      logger.info("[API RESPONSE] " + JSON.stringify({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }))
      return res.json({ request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' })
    }
  });

//  const options = {
//    key: fs.readFileSync("/etc/letsencrypt/live/yjtec.in/privkey.pem"),
//    cert: fs.readFileSync("/etc/letsencrypt/live/yjtec.in/cert.pem")
//  };

 https.createServer( app)
   .listen(port, function (req, res) {
     logger.info("Server started at port " + port);
   });

