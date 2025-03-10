const { Client, LocalAuth } = require('whatsapp-web.js');
const fse = require('fs-extra');
const fs = require('fs');
const env = process.env
const chrome_path = env.GOOGLE_CHROME;
const waiting_time = env.WAITING_TIME;
const main = require('../../logger')
const db = require("../../db_connect/connect");
const { log } = require("util");
const util = require("util")
const whatsapp_link = env.WHATSAPP_LINK;
const media_storage = env.MEDIA_STORAGE;
const qr = require('qrcode');
const moment = require("moment")
const { pool } = require("../../db_connect/postgre_connect");

// Create a PostgreSQL client instance
const client = new Client({
    user: 'your_username',
    host: 'localhost',
    database: 'your_database_name',
    password: 'your_password',
    port: 5432, // default PostgreSQL port
});

var logger_all = main.logger_all
var logger = main.logger
// var function_call = false;

// Define the function containing the logic you want to run periodically
async function cronfolder() {
    try {
        // var sender_numbers = {};
        var senderid_array = [];
        var flag_array = {};

        const select_sender_id = `SELECT * FROM senderid_master WHERE senderid_master_status = 'Y' order by sender_master_id asc`;
        logger_all.info("[select query request] : " + select_sender_id)
        const select_sender_result = await db.query(select_sender_id);
        logger_all.info("[select query response] : " + JSON.stringify(select_sender_result));

        for (let i = 0; i < select_sender_result.length; i++) {
            senderid_array.push(select_sender_result[i].mobile_no);
            flag_array[select_sender_result[i].mobile_no] = false;
        }
        Date.prototype.julianDate = function () {
            var j = parseInt((this.getTime() - new Date('Dec 30,' + (this.getFullYear() - 1) + ' 23:00:00').getTime()) / 86400000).toString(),
                i = 3 - j.length;
            while (i-- > 0) j = 0 + j;
            return j
        };

        console.log(senderid_array);
        for (let senderno = 0; senderno < senderid_array.length; senderno++) {
            const sender_id_cron = senderid_array[senderno];

            const select_sender_id = `SELECT * FROM senderid_master WHERE mobile_no = '${sender_id_cron}' AND senderid_master_status = 'Y'`;
            logger_all.info("[select query request] : " + select_sender_id)
            const select_sender_result = await db.query(select_sender_id);
            logger_all.info("[select query response] : " + JSON.stringify(select_sender_result));

            if (select_sender_result.length != 0) {

                const update_processing = `UPDATE senderid_master SET senderid_master_status = 'P' WHERE mobile_no = '${sender_id_cron}' AND senderid_master_status != 'P'`
                logger_all.info(" [update query request] : " + update_processing)
                const update_processing_result = await db.query(update_processing);
                logger_all.info(" [update query response] : " + JSON.stringify(update_processing_result))

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
                        { clientId: sender_id_cron }
                    )
                }
                );
                // Event: Client is disconnected
                client.on('disconnect', (reason) => {
                    if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                        console.log(`Client logout with reason: ${reason}`);
                        // Perform logout logic here
                    } else {
                        console.log(`Client disconnected with reason: ${reason}`);
                        // Perform other cleanup or disconnection logic here
                    }
                });

                client.initialize();

                client.on('ready', async (data) => {
                    logger_all.info('Client is ready! : ' + client.options.authStrategy.clientId);

                    update_members_admin(client);
                });

                setTimeout(async function () {

                    console.log(flag_array[sender_id_cron])
                    if (flag_array[sender_id_cron] == false) {
                        // try{
                        //     await client.destroy();
                        //     logger_all.info("client destroyed")
                        // }
                        // catch(e){

                        // }

                        logger_all.info(' rescan number - ' + sender_id_cron)
                        if (fs.existsSync(`./.wwebjs_auth/session-${sender_id_cron}`)) {
                            fs.rmdirSync(`./.wwebjs_auth/session-${sender_id_cron}`, { recursive: true })
                        }
                        if (fs.existsSync(`./session_copy/session-${sender_id_cron}`)) {
                            try {
                                if (fs.existsSync(`./session_copy/session-${sender_id_cron}`)) {
                                    fse.copySync(`./session_copy/session-${sender_id_cron}`, `./.wwebjs_auth/session-${sender_id_cron}`, { overwrite: true | false })
                                    logger_all.info('Folder copied successfully')
                                }

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
                                        { clientId: sender_id_cron }
                                    )
                                }
                                );
                                // Event: Client is disconnected
                                client.on('disconnect', (reason) => {
                                    if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                                        console.log(`Client logout with reason: ${reason}`);
                                        // Perform logout logic here
                                    } else {
                                        console.log(`Client disconnected with reason: ${reason}`);
                                        // Perform other cleanup or disconnection logic here
                                    }
                                });

                                client.initialize();

                                client.on('authenticated', async (data) => {
                                    logger_all.info(" [Client is Log in] : " + JSON.stringify(data));

                                });

                                client.on('ready', async (data) => {
                                    logger_all.info(" [Client is ready] : " + client.options.authStrategy.clientId);
                                    update_members_admin(client);
                                });

                                setTimeout(async function () {

                                    if (flag_array[sender_id_cron] == false) {
                                        try {
                                            await client.destroy();
                                            logger_all.info("client destroyed")
                                        }
                                        catch (e) {

                                        }
                                        logger_all.info("client destroyed")

                                        const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'X' WHERE mobile_no = '${sender_id_cron}' AND senderid_master_status != 'D'`
                                        logger_all.info(" [update query request] : " + update_inactive)
                                        const update_inactive_result = await db.query(update_inactive);
                                        logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))
                                        logger.info("[API RESPONSE] : Sender ID unlinked.")
                                        logger_all.info("[API RESPONSE] : Sender ID unlinked. ")

                                    }
                                }, waiting_time);
                            } catch (err) {
                                logger_all.info(err)
                                logger.info("[API RESPONSE] : Error occurred." + err)
                                logger_all.info("[API RESPONSE] : Error occurred. " + err)
                            }
                        }
                        else {
                            logger.info("[API RESPONSE] : Error occurred.")
                            logger_all.info("[API RESPONSE] : Error occurred. ")
                        }
                    }
                }, waiting_time);

                async function update_members_admin(client_data) {

                    logger_all.info("update_members_admin Function calling")
                    logger_all.info(util.inspect(client_data))

                    flag_array[client_data.options.authStrategy.clientId.toString()] = true;
                    // const group_array = [];
                    // const total_count_array = [];
                    // const group_master_id_array = [];
                    // const campaign_name_array = [];
                    // const user_id_array = [];
                    // const grp_id_array = [];

                    const select_sender = `SELECT * FROM senderid_master snd LEFT JOIN user_management usr ON usr.user_id  = snd.user_id WHERE snd.mobile_no = '${client_data.options.authStrategy.clientId}' AND snd.senderid_master_status = 'P'`;
                    logger_all.info("[update query request] : " + select_sender);
                    const select_sender_result = await db.query(select_sender);
                    logger_all.info("[update query response] : " + JSON.stringify(select_sender_result));

                    var sender_master_id = select_sender_result[0].sender_master_id
                    var user_id = select_sender_result[0].user_id
                    var sender_id = select_sender_result[0].mobile_no

                    var user_master_id = select_sender_result[0].user_master_id
                    var constituency = 0;

                    // if (user_master_id == 3) {
                    //     const get_consti = `SELECT * FROM user_consti_details WHERE user_id = '${user_id}' AND usr_consti_status = 'Y'`
                    //     logger_all.info("[select query request] : " + get_consti)
                    //     const get_consti_result = await db.query(get_consti);
                    //     logger_all.info("[select query response] : " + JSON.stringify(get_consti_result))

                    //     constituency = get_consti_result[0].consti_id;
                    // }

                    client_data.getChats().then(async (chats) => {

                        try {

                            const update_all_grp = `UPDATE group_master SET group_master_status = 'T'
                            WHERE sender_master_id = '${sender_master_id}' and group_master_status = 'Y'`
                            logger_all.info(" [get query request] : " + update_all_grp)
                            const update_all_grp_result = await db.query(update_all_grp);

                            for (var i = 0; i < chats.length; i++) {
                                logger_all.info(chats[i])
                                if (chats[i].isGroup) {
                                    logger_all.info(JSON.stringify(chats[i]))
                                    logger_all.info(chats[i].name)
                                    var wtsp_grp_id = chats[i].id._serialized;

                                    const get_frp = `SELECT * from group_master 
                                    WHERE sender_master_id = '${sender_master_id}' AND wtsp_group_id = '${wtsp_grp_id}' and group_master_status = 'T'`
                                    logger_all.info(" [get query request] : " + get_frp)
                                    const get_frp_result = await db.query(get_frp);
                                    var latest_status = 'N'
                                    var qr_path;
                                    var another_number;
                                    var admin_count = 0;

                                    if (get_frp_result.length == 0) {
                                        logger_all.info(chats[i].participants.length)

                                        const date = new Date(chats[i].timestamp * 1000); // Convert seconds to milliseconds

                                        // Convert to Kolkata time (IST)
                                        // Format the date to IST (Indian Standard Time)
                                        const options = {
                                            timeZone: 'Asia/Kolkata',
                                            year: 'numeric',
                                            month: '2-digit',
                                            day: '2-digit',
                                            hour: '2-digit',
                                            minute: '2-digit',
                                            second: '2-digit'
                                        };

                                        const dateString = date.toLocaleString('en-IN', options);

                                        const date1 = moment(dateString, 'DD/MM/YYYY, hh:mm:ss a').utcOffset('+05:30');

                                        const formattedDateTime = date1.format('YYYY-MM-DD HH:mm:ss');
                                        logger_all.info(formattedDateTime)

                                        var myGroup = await client_data.getChatById(wtsp_grp_id)
                                        console.log(myGroup);
                                        try {
                                            if (myGroup) {
                                                var grp_code = await myGroup.getInviteCode();
                                                logger_all.info(grp_code)
                                                var group_link = `${whatsapp_link + grp_code}`;
                                                // Generate QR code
                                                var randomNumber = Math.floor(Math.random() * 900) + 100;
                                                var now = new Date();

                                                // if (user_master_id == 3) {

                                                //     const get_qr_link = `SELECT qr_url,mobile_number FROM user_zone_details WHERE user_id = '${user_id}' AND usr_zone_status = 'Y'`
                                                //     logger_all.info("[select query request] : " + get_qr_link)
                                                //     const get_qr_link_result = await db.query(get_qr_link);
                                                //     logger_all.info("[select query response] : " + JSON.stringify(get_qr_link_result))
                                                //     // latest_status = 'L'

                                                //     another_number = get_qr_link_result[0].mobile_number
                                                //     qr_path = get_qr_link_result[0].qr_url;
                                                // }
                                                // else {

                                                    qr_path = `/uploads/group_qr/${new Date().julianDate()}${now.getHours()}${now.getMinutes()}${now.getSeconds()}_${randomNumber}.png`

                                                    // Generate QR code
                                                    qr.toFile(media_storage + `${qr_path}`, group_link, (err) => {
                                                        if (err) throw err;

                                                    });
                                                    logger_all.info("QR code generated successfully");
                                                    qr_path = `${media_storage}${qr_path}`
                                                // }
                                                // if (user_master_id == 3) {
                                                //     const update_old_grp = `UPDATE group_master SET latest_group = 'N' WHERE user_id = '${user_id}' AND latest_group = 'L'`
                                                //     logger_all.info("[update query request] : " + update_old_grp);
                                                //     const update_old_grp_result = await db.query(update_old_grp);
                                                //     logger_all.info("[update query response] : " + JSON.stringify(update_old_grp_result))
                                                // }

                                                const insert_grp = `INSERT INTO group_master VALUES(NULL,'${user_id}','${sender_master_id}','${wtsp_grp_id}',${constituency == 0 ? null : constituency},NULL,'${chats[i].name}','${chats[i].participants.length}','${chats[i].participants.length}','0','Y','Y','${formattedDateTime}',CURRENT_TIMESTAMP,'${group_link}','${qr_path}',1,'${chats[i].participants.length}','${latest_status}')`
                                                logger_all.info("[insert query request] : " + insert_grp);
                                                const insert_grp_result = await db.query(insert_grp);
                                                logger_all.info("[insert query response] : " + JSON.stringify(insert_grp_result))

                                                var insert_rights = `INSERT INTO group_rights VALUES(NULL,'${insert_grp_result.insertId}','1','N','Y',CURRENT_TIMESTAMP)`

                                                logger_all.info("[insert query request] : " + insert_rights);
                                                const insert_rights_result = await db.query(insert_rights);
                                                logger_all.info("[insert query response] : " + JSON.stringify(insert_rights_result))

                                                for (var k = 0; k < chats[i].participants.length; k++) {

                                                    logger_all.info(JSON.stringify(chats[i].participants[k]));
                                                    var participant = chats[i].participants[k].id.user;

                                                    const get_members = `SELECT * FROM group_contacts where mobile_no = '${participant}' AND group_master_id = '${insert_grp_result.insertId}' AND group_contacts_status = 'Y'`;
                                                    logger_all.info("[update query request] : " + get_members);
                                                    const get_members_result = await db.query(get_members);
                                                    logger_all.info("[update query response] : " + JSON.stringify(get_members_result));

                                                    if (get_members_result.length == 0) {
                                                        const group_contacts = `INSERT INTO group_contacts VALUES(NULL,'${user_id}','${insert_grp_result.insertId}','cron_campaign','${participant}','${participant}','Success','Y',CURRENT_TIMESTAMP,NULL,NULL)`
                                                        logger_all.info("[insert query request] : " + group_contacts);
                                                        const group_contacts_result = await db.query(group_contacts);
                                                        logger_all.info("[insert query response] : " + JSON.stringify(group_contacts_result))

                                                    }

                                                    // Check if the participant has admin privileges
                                                    if (chats[i].participants[k].isAdmin) {
                                                        // const get_admin = `SELECT admin_status FROM group_contacts where mobile_no = '${participant}' and admin_status = 'Y'`;
                                                        // logger_all.info("[update query request] : " + get_admin);
                                                        // const get_admin_result = await db.query(get_admin);
                                                        // logger_all.info("[update query response] : " + JSON.stringify(get_admin_result));
                                                        admin_count = admin_count + 1;
                                                        if (get_members_result.length != 0) {
                                                            if (get_members_result[0].admin_status != 'Y' && participant != sender_id) {
                                                                const update_group = `UPDATE group_contacts SET admin_status = 'Y' WHERE group_master_id = '${insert_grp_result.insertId}' AND group_contacts_status = 'Y' and mobile_no = '${participant}'`;
                                                                logger_all.info("[update query request] : " + update_group);
                                                                const update_group_result = await db.query(update_group);
                                                                logger_all.info("[update query response] : " + JSON.stringify(update_group_result))

                                                            }
                                                        }
                                                        else {
                                                            if (participant != sender_id) {
                                                                const update_group = `UPDATE group_contacts SET admin_status = 'Y' WHERE group_master_id = '${insert_grp_result.insertId}' AND group_contacts_status = 'Y' and mobile_no = '${participant}'`;
                                                                logger_all.info("[update query request] : " + update_group);
                                                                const update_group_result = await db.query(update_group);
                                                                logger_all.info("[update query response] : " + JSON.stringify(update_group_result))
                                                            }
                                                        }
                                                    }
                                                }
                                                const update_admin = `UPDATE group_master SET admin_count = ${admin_count} WHERE group_master_id = '${insert_grp_result.insertId}' AND group_master_status = 'Y'`;
                                                logger_all.info("[update query request] : " + update_admin);
                                                const uupdate_admin_result = await db.query(update_admin);
                                                logger_all.info("[update query response] : " + JSON.stringify(uupdate_admin_result))

                                                //     if(chats[i].participants.length > 1000){
                                                // // %%%%%%
                                                //     }
                                            }
                                            else {
                                                logger_all.info("grp not found")
                                            }

                                        }
                                        catch (e) {
                                            logger_all.info(e)
                                        }
                                    }
                                    else {

                                        var group_wtsp_name = chats[i].name
                                        const update_one_grp = `UPDATE group_master SET group_master_status = 'Y'
                                    WHERE sender_master_id = '${sender_master_id}' AND wtsp_group_id = '${wtsp_grp_id}' and group_master_status = 'T'`
                                        logger_all.info(" [get query request] : " + update_one_grp)
                                        const update_one_grp_result = await db.query(update_one_grp);

                                        const update_grp = `UPDATE group_master SET members_count = '${chats[i].participants.length}' , success_count = '${chats[i].participants.length}' WHERE sender_master_id = '${sender_master_id}' AND group_master_id = '${get_frp_result[0].group_master_id}'`
                                        logger_all.info("[insert query request] : " + update_grp);
                                        const update_grp_result = await db.query(update_grp);
                                        logger_all.info("[insert query response] : " + JSON.stringify(update_grp_result))

                                        const update_all_contact = `UPDATE group_contacts SET group_contacts_status = 'T'
                                        WHERE group_master_id = '${get_frp_result[0].group_master_id}' AND group_contacts_status='Y'`
                                        logger_all.info(" [get query request] : " + update_all_contact)
                                        const update_all_contact_result = await db.query(update_all_contact);

                                        for (var k = 0; k < chats[i].participants.length; k++) {

                                            logger_all.info(JSON.stringify(chats[i].participants[k]));
                                            var participant = chats[i].participants[k].id.user;

                                            const update_one_contact = `UPDATE group_contacts SET group_contacts_status = 'Y'
                                            WHERE group_master_id = '${get_frp_result[0].group_master_id}' and mobile_no = '${participant}' AND group_contacts_status='T'`
                                            logger_all.info(" [get query request] : " + update_one_contact)
                                            const update_one_contact_result = await db.query(update_one_contact);

                                            const get_members = `SELECT * FROM group_contacts where mobile_no = '${participant}' AND group_master_id = '${get_frp_result[0].group_master_id}' AND group_contacts_status = 'Y'`;
                                            logger_all.info("[update query request] : " + get_members);
                                            const get_members_result = await db.query(get_members);
                                            logger_all.info("[update query response] : " + JSON.stringify(get_members_result));

                                            if (get_members_result.length == 0) {
                                                const group_contacts = `INSERT INTO group_contacts VALUES(NULL,'${user_id}','${get_frp_result[0].group_master_id}','cron_campaign','${participant}','${participant}','Success','Y',CURRENT_TIMESTAMP,NULL,NULL)`
                                                logger_all.info("[insert query request] : " + group_contacts);
                                                const group_contacts_result = await db.query(group_contacts);
                                                logger_all.info("[insert query response] : " + JSON.stringify(group_contacts_result))

                                            }

                                            // Check if the participant has admin privileges
                                            if (chats[i].participants[k].isAdmin) {
                                                // const get_admin = `SELECT admin_status FROM group_contacts where mobile_no = '${participant}' and admin_status = 'Y'`;
                                                // logger_all.info("[update query request] : " + get_admin);
                                                // const get_admin_result = await db.query(get_admin);
                                                // logger_all.info("[update query response] : " + JSON.stringify(get_admin_result));
                                                admin_count = admin_count + 1;
                                                if (get_members_result.length != 0) {

                                                    if (get_members_result[0].admin_status != 'Y' && participant != sender_id) {
                                                        const update_group = `UPDATE group_contacts SET admin_status = 'Y' WHERE group_master_id = '${get_frp_result[0].group_master_id}' AND group_contacts_status = 'Y' and mobile_no = '${participant}'`;
                                                        logger_all.info("[update query request] : " + update_group);
                                                        const update_group_result = await db.query(update_group);
                                                        logger_all.info("[update query response] : " + JSON.stringify(update_group_result))
                                                    }
                                                }
                                                else {
                                                    if (participant != sender_id) {
                                                        const update_group = `UPDATE group_contacts SET admin_status = 'Y' WHERE group_master_id = '${get_frp_result[0].group_master_id}' AND group_contacts_status = 'Y' and mobile_no = '${participant}'`;
                                                        logger_all.info("[update query request] : " + update_group);
                                                        const update_group_result = await db.query(update_group);
                                                        logger_all.info("[update query response] : " + JSON.stringify(update_group_result))
                                                    }
                                                }
                                            }
                                        }

                                        const update_one_contact = `UPDATE group_contacts SET group_contacts_status = 'L'
                                        WHERE group_master_id = '${get_frp_result[0].group_master_id}' AND group_contacts_status='T'`
                                        logger_all.info(" [get query request] : " + update_one_contact)
                                        const update_one_contact_result = await db.query(update_one_contact);

                                        const update_admin = `UPDATE group_master SET admin_count = ${admin_count},group_name = '${group_wtsp_name}'  WHERE group_master_id = '${get_frp_result[0].group_master_id}' AND group_master_status = 'Y'`;
                                        logger_all.info("[update query request] : " + update_admin);
                                        const uupdate_admin_result = await db.query(update_admin);
                                        logger_all.info("[update query response] : " + JSON.stringify(uupdate_admin_result))

                                    }
                                }
                            }

                            const update_one_grp = `UPDATE group_master SET group_master_status = 'D'
                            WHERE sender_master_id = '${sender_master_id}' and group_master_status = 'T'`
                            logger_all.info(" [get query request] : " + update_one_grp)
                            const update_one_grp_result = await db.query(update_one_grp);

                            var get_group = `SELECT * from group_master WHERE user_id = '${user_id}' AND latest_group='L' and group_master_status = 'Y'`

                            logger_all.info("[Select query request] : " + get_group);
                            var get_group_result = await db.query(get_group);
                            logger_all.info("[Select query response] : " + JSON.stringify(get_group_result))

                            for (var i = 0; i < get_group_result.length; i++) {

                                var another_admin;
                                var numberDetails;
                                var old_grp;

                                if (get_group_result.length != 0) {

                                    constituency = get_group_result[i].consti_id;
                                    old_grp = get_group_result[i].group_name;

                                    var get_an_num = `SELECT mobile_number from user_zone_details WHERE user_id = '${user_id}' AND usr_zone_status='Y'`

                                    logger_all.info("[Select query request] : " + get_an_num);
                                    var get_an_num_result = await db.query(get_an_num);
                                    logger_all.info("[Select query response] : " + JSON.stringify(get_an_num_result))

                                    another_number = get_an_num_result[0].mobile_number

                                    if (get_group_result[i].members_count > 5) {
                                        var group_nm = get_group_result[i].group_name
                                        console.log(group_nm, "&&&&&&&")
                                        var group_name = group_nm.split(" - ")
                                        if (group_name.length == 1) {
                                            group_name = `${group_nm} - 1`;
                                        }
                                        else {
                                            var count = parseInt(group_name[1]) + 1;
                                            group_name = `${group_name[0]} - ${count}`
                                        }

                                        var numbersArray = another_number.split(',');

                                        // Filter out the excluded number
                                        var filteredNumbers = numbersArray.filter(function (num) {
                                            return num !== sender_id;
                                        });

                                        // Join the filtered numbers back into a string
                                        another_admin = filteredNumbers.join(',');
                                        if (another_admin != "" && another_admin.trim() != "-") {
                                            numberDetails = await client_data.getNumberId(another_admin);
                                        }
                                        else {
                                            numberDetails = await client_data.getNumberId("916380885546");
                                            another_admin = "916380885546";

                                        }
                                        logger_all.info("[Phone Number Details] : " + JSON.stringify(numberDetails));
                                        var create_grp = await client_data.createGroup(group_name, [numberDetails._serialized]);
                                        logger_all.info("create group if 1000 exceeds: " + JSON.stringify(create_grp));

                                        var myGroup_after_1000 = await client_data.getChatById(create_grp.gid._serialized)
                                        if (myGroup_after_1000) {
                                            var latest_status_grp = 'L'
                                            var qr_path_grp;
                                            var group_code = await myGroup_after_1000.getInviteCode();
                                            var group_link = `${whatsapp_link + group_code}`;

                                            logger_all.info(group_code, group_link);
                                            var randomNumber = Math.floor(Math.random() * 900) + 100;
                                            var now = new Date();

                                            // if (user_master_id == 3) {

                                            //     const get_qr_link = `SELECT qr_url,mobile_number FROM user_zone_details WHERE user_id = '${user_id}' AND usr_zone_status = 'Y'`
                                            //     logger_all.info("[select query request] : " + get_qr_link)
                                            //     const get_qr_link_result = await db.query(get_qr_link);
                                            //     logger_all.info("[select query response] : " + JSON.stringify(get_qr_link_result))

                                            // latest_status_grp = 'L'

                                            //     qr_path_grp = get_qr_link_result[0].qr_url;
                                            // }
                                            // else {

                                            qr_path_grp = `/uploads/group_qr/${new Date().julianDate()}${now.getHours()}${now.getMinutes()}${now.getSeconds()}_${randomNumber}.png`

                                            // Generate QR code
                                            qr.toFile(media_storage + `${qr_path_grp}`, group_link, (err) => {
                                                if (err) throw err;

                                            });
                                            logger_all.info("QR code generated successfully");
                                            qr_path_grp = `${media_storage}${qr_path_grp}`
                                            // }

                                            if (user_master_id == 3) {
                                                const update_old_grp = `UPDATE group_master SET latest_group = 'N' WHERE user_id = '${user_id}' AND latest_group = 'L' AND group_master_id = '${get_group_result[i].group_master_id}'`
                                                logger_all.info("[update query request] : " + update_old_grp);
                                                const update_old_grp_result = await db.query(update_old_grp);
                                                logger_all.info("[update query response] : " + JSON.stringify(update_old_grp_result))

                                                // const update_lates = `UPDATE public.qr_list SET whatsapp_url = '${group_link}', latest_group = '${group_name}' WHERE "group" = '${old_grp}'`
                                                // logger_all.info("[update query request] : " + update_lates);
                                                // const update_lates_result = await db.query(update_lates);
                                                // logger_all.info("[update query response] : " + JSON.stringify(update_lates_result))

                                                let client_db;
                                                try {
                                                    client_db = await pool.connect();
                                                    const result = await client_db.query(`UPDATE public.qr_list SET whatsapp_url = '${group_link}', latest_group = '${group_name}' WHERE "group" = '${old_grp}'`);
                                                    //console.log(result.rows[0])
                                                    //           if (result.rows.length === 0) {
                                                    logger_all.info("[postgresql grp updated] : " + result);
                                                    //             // return null; // AC not found
                                                    //           } else {
                                                    //             return result.rows[0];
                                                    //           }
                                                } catch (err) {
                                                    logger_all.info("[postgresql grp updated error] : " + err);
                                                } finally {
                                                    if (client_db) {
                                                        client_db.release();
                                                        logger_all.info("[postgresql grp updated] : client released");
                                                    }
                                                }
                                            }

                                            var insert_grp = `INSERT INTO group_master VALUES(NULL,'${user_id}','${sender_master_id}','${create_grp.gid._serialized}',${constituency == 0 ? null : constituency},NULL,'${group_name}','2','2','0','Y','Y',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'${group_link}','${qr_path_grp}',2,'2','${latest_status_grp}')`

                                            logger_all.info("[insert query request] : " + insert_grp);
                                            const insert_grp_result = await db.query(insert_grp);
                                            logger_all.info("[insert query response] : " + JSON.stringify(insert_grp_result))

                                            var insert_rights = `INSERT INTO group_rights VALUES(NULL,'${insert_grp_result.insertId}','1','N','Y',CURRENT_TIMESTAMP)`

                                            logger_all.info("[insert query request] : " + insert_rights);
                                            const insert_rights_result = await db.query(insert_rights);
                                            logger_all.info("[insert query response] : " + JSON.stringify(insert_rights_result))

                                            const insert_admin = `INSERT INTO group_contacts VALUES(NULL,'${user_id}','${insert_grp_result.insertId}','cron_campaign','${sender_id}','${sender_id}','Success','Y',CURRENT_TIMESTAMP,NULL,NULL)`
                                            logger_all.info("[insert query request] : " + insert_admin);
                                            const insert_admin_result = await db.query(insert_admin);
                                            logger_all.info("[insert query response] : " + JSON.stringify(insert_admin_result))
                                            var update_number_status;

                                            if (user_master_id == 3) {

                                                var admin_add = await myGroup_after_1000.promoteParticipants([numberDetails._serialized]);
                                                logger_all.info("promote admin : " + JSON.stringify(admin_add));

                                                update_number_status = `INSERT INTO group_contacts VALUES(NULL,'${user_id}','${insert_grp_result.insertId}','cron_Campaign','${another_admin}','${another_admin}','Success','Y',CURRENT_TIMESTAMP,NULL,'Y')`
                                            }
                                            else {

                                                update_number_status = `INSERT INTO group_contacts VALUES(NULL,'${user_id}','${insert_grp_result.insertId}','cron_Campaign','${another_admin}','${another_admin}','Success','Y',CURRENT_TIMESTAMP,NULL,NULL)`
                                            }
                                            logger_all.info("[insert query request] : " + update_number_status);
                                            const update_number_status_result = await db.query(update_number_status);
                                            logger_all.info("[insert query response] : " + JSON.stringify(update_number_status_result))

                                        }

                                    }
                                }

                            }
                            const update_active = `UPDATE senderid_master SET senderid_master_status = 'Y' WHERE mobile_no = '${sender_id_cron}' AND senderid_master_status = 'P'`
                            logger_all.info(" [update query request] : " + update_active)
                            const update_active_result = await db.query(update_active);
                            logger_all.info(" [update query response] : " + JSON.stringify(update_active_result))

                            await client_data.destroy();
                            logger_all.info("client_data destroyed")

                        } catch (err) {
                            const update_active = `UPDATE senderid_master SET senderid_master_status = 'Y' WHERE mobile_no = '${sender_id_cron}' AND senderid_master_status = 'P'`
                            logger_all.info(" [update query request] : " + update_active)
                            const update_active_result = await db.query(update_active);
                            logger_all.info(" [update query response] : " + JSON.stringify(update_active_result))

                            await client_data.destroy();
                            logger_all.info("client_data destroyed")

                            console.error(`Error while getting data`, err.message);
                            // next(err);
                        }
                    })
                }
            }
        } //for loop ending

        logger_all.info("[Cron Task response] : Cron task executed successfully");

    } catch (error) {
        logger_all.info("Error in cron task:", error);
    }
}

// Export the function so that it can be called from outside
module.exports = cronfolder;
