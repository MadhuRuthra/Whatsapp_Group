const { Client, LocalAuth } = require('whatsapp-web.js');
const fse = require('fs-extra');
const fs = require('fs');
const env = process.env
const chrome_path = env.GOOGLE_CHROME;
const waiting_time = env.WAITING_TIME;
const main = require('../../logger')
const db = require("../../db_connect/connect");
const { log } = require("util");

var logger_all = main.logger_all
var logger = main.logger
var function_call = false;

// Define the function containing the logic you want to run periodically
async function cronfolder() {
    try {

        var senderid_array = [];
        const select_sender_id = `SELECT * FROM senderid_master WHERE senderid_master_status = 'Y'`;

        logger_all.info("[select query request] : " + select_sender_id)
        const select_sender_result = await db.query(select_sender_id);
        logger_all.info("[select query response] : " + JSON.stringify(select_sender_result));
        if (select_sender_result.length > 0) {
            senderid_array.push(select_sender_result[0].mobile_no);

            for (let senderno = 0; senderno < senderid_array.length; senderno++) {

                var client = new Client({
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
                        { clientId: senderid_array[senderno] }
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
                    logger_all.info('Client is ready! : ' + senderid_array[senderno]);
                    const update_processing = `UPDATE senderid_master SET senderid_master_status = 'P' WHERE mobile_no = '${senderid_array[senderno]}' AND senderid_master_status != 'P'`
                    logger_all.info(" [update query request] : " + update_processing)
                    const update_processing_result = await db.query(update_processing);
                    logger_all.info(" [update query response] : " + JSON.stringify(update_processing_result))
                    update_members_admin();
                });

                setTimeout(async function () {
                    if (function_call == false) {
                        logger_all.info(' rescan number - ' + senderid_array[senderno])
                        if (fs.existsSync(`./.wwebjs_auth/session-${senderid_array[senderno]}`)) {
                            fs.rmdirSync(`./.wwebjs_auth/session-${senderid_array[senderno]}`, { recursive: true })
                        }
                        if (fs.existsSync(`./session_copy/session-${senderid_array[senderno]}`)) {
                            try {
                                if (fs.existsSync(`./session_copy/session-${senderid_array[senderno]}`)) {
                                    fse.copySync(`./session_copy/session-${senderid_array[senderno]}`, `./.wwebjs_auth/session-${senderid_array[senderno]}`, { overwrite: true | false })
                                    logger_all.info('Folder copied successfully')
                                }

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
                                        { clientId: senderid_array[senderno] }
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
                                    const update_processing = `UPDATE senderid_master SET senderid_master_status = 'P' WHERE mobile_no = '${senderid_array[senderno]}' AND senderid_master_status != 'P'`
                                    logger_all.info(" [update query request] : " + update_processing)
                                    const update_processing_result = await db.query(update_processing);
                                    logger_all.info(" [update query response] : " + JSON.stringify(update_processing_result))
                                    logger_all.info(" [Client is ready] : " + client.options.authStrategy.clientId);
                                    update_members_admin();
                                });

                                setTimeout(async function () {

                                    if (function_call == false) {
                                        const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'X' WHERE mobile_no = '${senderid_array[senderno]}' AND senderid_master_status != 'D'`
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

                async function update_members_admin() {

                    logger_all.info("update_members_admin Function calling")
                    function_call = true;
                    const group_array = [];
                    const total_count_array = [];
                    const group_master_id_array = [];
                    const campaign_name_array = [];
                    const user_id_array = [];

                    const get_group_name = `SELECT * FROM group_master WHERE group_master_status = 'Y'`;
                    logger_all.info("[update query request] : " + get_group_name);
                    const get_group_name_result = await db.query(get_group_name);
                    logger_all.info("[update query response] : " + JSON.stringify(get_group_name_result));

                    get_group_name_result.forEach((group) => {
                        group_array.push(group.group_name);
                        total_count_array.push(group.total_count);
                        group_master_id_array.push(group.group_master_id);
                        campaign_name_array.push(group.campaign_name);
                        user_id_array.push(group.user_id);
                    });

                    client.getChats().then(async (chats) => {

                        try {

                            for (var group = 0; group < group_array.length; group++) {
                                // Find the newly created group
                                const myGroup = chats.find((chat) => chat.name === group_array[group]);
                                if (!myGroup) {
                                    logger_all.info("[Group Not Found] : " + group_array[group])
                                    // break; // Skip if group not found
                                    continue;
                                }
                                console.log(myGroup.participants);
                                // Iterate over participants of the group   
                                for (const participant of myGroup.participants) {

                                    if (typeof participant !== 'string') {
                                        logger_all.info("Participant is not a string:", participant);
                                        continue; // Skip this participant
                                    }

                                    const get_members = `SELECT * FROM group_contacts where mobile_no = '${participant}'`;
                                    logger_all.info("[update query request] : " + get_members);
                                    const get_members_result = await db.query(get_members);
                                    logger_all.info("[update query response] : " + JSON.stringify(get_members_result));

                                    if (get_members_result.length == 0) {
                                        const group_contacts = `INSERT INTO group_contacts VALUES(NULL,'${user_id_array[group]}','${group_master_id_array[group]}','${campaign_name_array[group]}','${participant}','${participant}','Success','Y',CURRENT_TIMESTAMP,NULL,NULL)`
                                        logger_all.info("[insert query request] : " + group_contacts);
                                        const group_contacts_result = await db.query(group_contacts);
                                        logger_all.info("[insert query response] : " + JSON.stringify(group_contacts_result))

                                    }

                                    // Check if the participant has admin privileges
                                    if (participant.isAdmin) {
                                        const get_admin = `SELECT admin_status FROM group_contacts where mobile_no = '${participant}' and admin_status = 'Y'`;
                                        logger_all.info("[update query request] : " + get_admin);
                                        const get_admin_result = await db.query(get_admin);
                                        logger_all.info("[update query response] : " + JSON.stringify(get_admin_result));

                                        if (get_admin_result.length == 0) {
                                            const update_group = `UPDATE group_contacts SET admin_status = 'Y' WHERE group_master_id = '${group_master_id_array[group]}' AND group_contacts_status = 'Y' and mobile_no = '${participant}'`;
                                            logger_all.info("[update query request] : " + update_group);
                                            const update_group_result = await db.query(update_group);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_group_result))
                                        }
                                    }
                                }

                                console.log(myGroup.participants.length + "myGroup.participants.length");
                                const parti_count = myGroup.participants.length;

                                if ((parti_count - 1) == total_count_array[group]) {
                                    logger_all.info(" Group Name is " + group_array[group] + "Group Participants Count is Equal ");
                                } else {
                                    const update_group = `UPDATE group_master SET total_count = '${parti_count - 1}',group_updated_date = CURRENT_TIMESTAMP WHERE group_name = '${group_array[group]}' AND group_master_status = 'Y'`;
                                    logger_all.info("[update query request] : " + update_group);
                                    const update_group_result = await db.query(update_group);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_group_result))
                                }
                            }
                            const update_active = `UPDATE senderid_master SET senderid_master_status = 'Y' WHERE mobile_no = '${senderid_array[senderno]}' AND senderid_master_status = 'P'`
                            logger_all.info(" [update query request] : " + update_active)
                            const update_active_result = await db.query(update_active);
                            logger_all.info(" [update query response] : " + JSON.stringify(update_active_result))

                        } catch (err) {
                            console.error(`Error while getting data`, err.message);
                            next(err);
                        }
                    })
                }
            } //for loop ending

            logger_all.info("[Cron Task response] : Cron task executed successfully");

        }

    } catch (error) {
        logger_all.info("Error in cron task:", error);
    }
}

// Export the function so that it can be called from outside
module.exports = cronfolder;
