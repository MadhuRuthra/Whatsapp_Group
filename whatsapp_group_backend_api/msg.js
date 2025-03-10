
app.post("/send_msg", validator.body(send_msg_validation), valid_user, async (req, res) => {

    var day = new Date();
    var today_date = day.getFullYear() + '-' + (day.getMonth() + 1) + '-' + day.getDate();
    var today_time = day.getHours() + ":" + day.getMinutes() + ":" + day.getSeconds();
    var current_date = today_date + ' ' + today_time;
  
    var sender_numbers = req.body.sender_numbers;
    var mobiles = req.body.mobile_numbers;
    var message = req.body.messages;
    var db_name = req.body.db_name;
    var table_names = req.body.table_names;
    var mobile_numbers_insertid = req.body.mobile_numbers_insertid;
    var compose_whatsapp_id = req.body.compose_whatsapp_id;
  
    logger_all.info(" [send_msg query parameters] : " + JSON.stringify(req.body));
  
    var senders = {};
    var all_senders = {};
    var msg_count;
    var time_delay;
    var loop_delay;
    var function_call = false;
  
    res.json({ response_code: 0, response_status: 200, response_msg: 'Initiated' });
    try {
  
      logger_all.info(" [select query request] : " + `SELECT * from message_settings WHERE message_settings_status = 'Y'`);
      const select_details = await db.query(`SELECT * from message_settings WHERE message_settings_status = 'Y'`);
      logger_all.info(" [select query response] : " + JSON.stringify(select_details))
  
      if (select_details.length != 0) {
        msg_count = select_details[0].message_count;
        //   time_delay = select_details[0].message_delay_seconds;
        loop_delay = select_details[0].message_loop_min;
  
        logger_all.info(" [sender number count] : " + sender_numbers.length);
  
        for (var i = 0; i < sender_numbers.length; i++) {
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
              { clientId: sender_numbers[i] }
            )
          }
  
          );
  
          all_senders[`${sender_numbers[i]}`] = client;
          client.initialize();
  
          client.on('authenticated', async (data) => {
            logger_all.info(" [Client is Log in] : " + JSON.stringify(data));
  
          });
          if (!client.pupPage) {
            // client has not been initialized
          }
  
          client.on('ready', async (data) => {
            logger_all.info(" [Client is ready] : " + client.options.authStrategy.clientId);
            client.pupPage.addScriptTag({ path: require.resolve("@wppconnect/wa-js") });
            await client.pupPage.waitForFunction(() => window.WPP?.isReady);
  
            senders[`${client.options.authStrategy.clientId}`] = client;
  
            if (Object.keys(senders).length == sender_numbers.length) {
              send_msg(sender_numbers);
            }
  
          });
  
        }
  
        setTimeout(function () {
          if (function_call == false) {
            send_msg(sender_numbers);
          }
        }, sender_numbers.length * 120000);
  
        async function send_msg(sender_mobiles) {
          logger_all.info(" Funtion called. ");
          function_call = true;
          var succ_array = [];
          var error_array = [];
  
          var json_length = Object.keys(senders).length;
  
          if (sender_mobiles.length != 0) {
  
            if (json_length == sender_mobiles.length) {
              logger_all.info(" [Sender mobile length] : " + sender_mobiles.length);
  
              //   res.json({ response_code: 0, response_status: 200, response_msg: 'Initiated' });
              for (var s = 0; s < sender_mobiles.length; s++) {
                logger_all.info(" [update query request] : " + `UPDATE whatsapp_config SET whatspp_config_status = 'P' WHERE concat(country_code, mobile_no) = '${sender_mobiles[s]}' AND whatspp_config_status != 'D'`)
                const update_number_unavailable = await db.query(`UPDATE whatsapp_config SET whatspp_config_status = 'P' WHERE concat(country_code, mobile_no) = '${sender_mobiles[s]}' AND whatspp_config_status != 'D'`);
                logger_all.info(" [update query response] : " + JSON.stringify(update_number_unavailable))
              }
  
              for (var t = 0; t < sender_mobiles.length; t++) {
                try {
  
                  senders[`${sender_mobiles[t]}`].on("message_ack", async (data) => {
  
                    logger_all.info(" [Message ack] : " + JSON.stringify(data));
                    if (data._data.ack == 2) {
                      logger_all.info(" [update query request] : " + `UPDATE ${table_names[1]} SET delivery_status = 'Y' WHERE response_id = '${data._data.id._serialized}'`)
                      const update_delivery_status = await dynamic_db.query(`UPDATE ${table_names[1]} SET delivery_status = 'Y' WHERE response_id = '${data._data.id._serialized}'`, null, `${db_name}`);
                      logger_all.info(" [update query response] : " + JSON.stringify(update_delivery_status))
  
                    }
                    if (data._data.ack == 3) {
                      logger_all.info(" [update query request] : " + `UPDATE ${table_names[1]} SET read_status = 'Y' WHERE response_id = '${data._data.id._serialized}'`)
                      const update_read_status = await dynamic_db.query(`UPDATE ${table_names[1]} SET read_status = 'Y' WHERE response_id = '${data._data.id._serialized}'`, null, `${db_name}`);
                      logger_all.info(" [update query response] : " + JSON.stringify(update_read_status))
  
                    }
  
                  });
                  senders[`${sender_mobiles[t]}`].on("message", async (data) => {
                    logger_all.info(" [Message listen] : " + JSON.stringify(data));
  
                  });
  
                  /* senders[`${sender_mobiles[t]}`].on("disconnected", async (data) => {
                             logger_all.info( " [Client is disconnected] : " + JSON.stringify(data));
           
                             logger_all.info( " [update query request] : " + `UPDATE whatsapp_config SET whatspp_config_status = 'B' WHERE concat(country_code, mobile_no) = '${sender_mobiles[t]}' AND whatspp_config_status != 'D'`)
                             const update_inactive = await db.query(`UPDATE whatsapp_config SET whatspp_config_status = 'B' WHERE concat(country_code, mobile_no) = '${sender_mobiles[t]}' AND whatspp_config_status != 'D'`);
                             logger_all.info( " [update query response] : " + JSON.stringify(update_inactive))
                   
                           }); */
  
                }
                catch (e) {
                  logger_all.info(" [Message listen] : " + e);
                }
              }
              for (var m = 0; m < mobiles.length; m) {
                if (m != 0) {
                  var loop_delay_new = 1000 * (Math.floor(Math.random() * 25) + 35);
                  logger_all.info(current_date + " [loop delay] - " + loop_delay_new);
                  await sleep(loop_delay_new);
                }
  
                if (sender_mobiles.length == 0) {
                  logger_all.info(" No sender available");
                  logger_all.info(" [update query request] : " + `UPDATE ${table_names[1]} SET response_date = CURRENT_TIMESTAMP,response_status = 'F',response_message = 'NO SENDER AVAILABLE' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`)
                  const update_failed_block = await dynamic_db.query(`UPDATE ${table_names[1]} SET response_date = CURRENT_TIMESTAMP,response_status = 'F',response_message = 'NO SENDER AVAILABLE' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`, null, `${db_name}`);
                  logger_all.info(" [update query response] : " + JSON.stringify(update_failed_block))
  
                  error_array.push({ "sender": "-", "receiver": mobiles[m], "status": "No sender available" })
                  m++;
  
                  // break;
                }
  
                for (var s = 0; s < sender_mobiles.length; s++) {
  
                  logger_all.info(" [select query request] : " + `SELECT * from whatsapp_config WHERE concat(country_code, mobile_no) = '${sender_mobiles[s]}' AND whatspp_config_status = 'B'`)
                  const check_blocked = await db.query(`SELECT * from whatsapp_config WHERE concat(country_code, mobile_no) = '${sender_mobiles[s]}' AND whatspp_config_status = 'B'`);
                  logger_all.info(" [select query response] : " + JSON.stringify(check_blocked))
  
                  if (check_blocked.length != 0) {
                    logger_all.info(" Number Blocked : " + sender_mobiles[s])
                    const index = sender_mobiles.indexOf(sender_mobiles[s]);
                    if (index > -1) { // only splice array when item is found
                      sender_mobiles.splice(index, 1); // 2nd parameter means remove one item only
                    }
                    break;
                  }
                  else {
                    try {
                      const isAuthenticated = await senders[`${sender_mobiles[s]}`].pupPage.evaluate(() => WPP.conn.isAuthenticated());
                      if (isAuthenticated) {
                        // for (var i = 0; i < msg_count; i++) {
                        if (m != mobiles.length) {
                          // time_delay = Math.floor(Math.random() * 60) + 60;
  
                          const number_details = await senders[`${sender_mobiles[s]}`].getNumberId(`${mobiles[m]}`); // get mobile number details
  
                          if (number_details) {
                            for (var k = 0; k < message.length; k++) {
                              await sleep(5000);
                              logger_all.info(" [Message send] : " + JSON.stringify(message[k]) + " - " + mobiles[m]);
  
                              if (message[k].msg_type == "text") {
                                //   var text_msg = message[k].text_msg
                                // const text_msg = querystring.decode(message[k].text_msg)
                                // const text_msg = Buffer.from(message[k].text_msg, 'base64').toString('ascii');
                                let bufferObj = Buffer.from(message[k].text_msg, "base64");
                                let text_msg = bufferObj.toString("utf8");
                                text_msg = text_msg.replace(/&amp;/g, "&")
  
                                //let text_msg = messages[m]
                                var status_msg;
                                var status_comment;
  
                                try {
                                  const sendMessageData = await senders[`${sender_mobiles[s]}`].sendMessage(number_details._serialized, text_msg);
                                  logger_all.info(" [Message response] : " + JSON.stringify(message[k]) + " - " + mobiles[m] + " - " + JSON.stringify(sendMessageData));
  
                                  status_msg = 'S';
                                  status_comment = 'SUCCESS';
                                  succ_array.push({ "sender": sender_mobiles[s], "receiver": mobiles[m], "status": "success", "message_id": sendMessageData._data.id._serialized })
  
                                  logger_all.info(" [update query request] : " + `UPDATE ${table_names[1]} SET response_id = '${sendMessageData._data.id._serialized}',comments='${sender_mobiles[s]}',response_date = CURRENT_TIMESTAMP,response_status = '${status_msg}',response_message = '${status_comment}' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`)
                                  const update_text_id = await dynamic_db.query(`UPDATE ${table_names[1]} SET response_id = '${sendMessageData._data.id._serialized}',comments='${sender_mobiles[s]}',response_date = CURRENT_TIMESTAMP,response_status = '${status_msg}',response_message = '${status_comment}' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`, null, `${db_name}`);
                                  logger_all.info(" [update query response] : " + JSON.stringify(update_text_id))
  
                                  logger_all.info(" [update query request] : " + `UPDATE whatsapp_config SET sent_count = sent_count+1 WHERE concat(country_code, mobile_no) = '${sender_mobiles[s]}'`)
                                  const update_count = await db.query(`UPDATE whatsapp_config SET sent_count = sent_count+1 WHERE concat(country_code, mobile_no) = '${sender_mobiles[s]}'`);
                                  logger_all.info(" [update query response] : " + JSON.stringify(update_count))
  
                                }
                                catch (e) {
                                  status_msg = 'F';
                                  status_comment = 'FAILED';
                                  error_array.push({ "sender": sender_mobiles[s], "receiver": mobiles[m], "status": "Failed" })
  
                                  logger_all.info(" [Message send] : " + JSON.stringify(message[k]) + " - " + mobiles[m] + " - " + e);
  
                                  logger_all.info(" [update query request] : " + `UPDATE ${table_names[1]} SET comments='${sender_mobiles[s]}',response_date = CURRENT_TIMESTAMP,response_status = '${status_msg}',response_message = '${status_comment}' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`)
                                  const update_text_id = await dynamic_db.query(`UPDATE ${table_names[1]} SET comments='${sender_mobiles[s]}',response_date = CURRENT_TIMESTAMP,response_status = '${status_msg}',response_message = '${status_comment}' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`, null, `${db_name}`);
                                  logger_all.info(" [update query response] : " + JSON.stringify(update_text_id))
  
                                }
                                // logger_all.info( " [update query request] : " + `UPDATE ${table_names[1]} SET response_id = '${sendMessageData._data.id._serialized}',comments='${sender_mobiles[s]}',response_date = CURRENT_TIMESTAMP,response_status = '${status_msg}',response_message = '${status_comment}' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`)
                                // const update_text_id = await dynamic_db.query(`UPDATE ${table_names[1]} SET response_id = '${sendMessageData._data.id._serialized}',comments='${sender_mobiles[s]}',response_date = CURRENT_TIMESTAMP,response_status = '${status_msg}',response_message = '${status_comment}' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`,null, `${db_name}`);
                                // logger_all.info( " [update query response] : " + JSON.stringify(update_text_id))
  
                                // succ_array.push({ "sender": sender_mobiles[s], "receiver": mobiles[m], "status": "success", "message_id": sendMessageData._data.id._serialized })
  
                              }
                              if (message[k].msg_type == "list") {
                                var title = message[k].title
                                var body = message[k].body
                                var btn_text = message[k].btn_text
                                var list_title = message[k].list_title
                                var list_items = message[k].list_items
  
                                const list_msg = await new List(
                                  body,
                                  btn_text,
                                  [
                                    {
                                      title: list_title,
                                      rows: list_items,
                                    },
                                  ],
                                  title
                                );
                                try {
                                  const send_list = await senders[`${sender_mobiles[s]}`].sendMessage(number_details._serialized, list_msg);
                                  logger_all.info(" [Message response] : " + JSON.stringify(message[k]) + " - " + mobiles[m] + " - " + JSON.stringify(send_list));
  
                                  logger_all.info(" [update query request] : " + `UPDATE whatsapp_config SET sent_count = sent_count+1 WHERE concat(country_code, mobile_no) = '${sender_mobiles[s]}'`)
                                  const update_count = await db.query(`UPDATE whatsapp_config SET sent_count = sent_count+1 WHERE concat(country_code, mobile_no) = '${sender_mobiles[s]}'`);
                                  logger_all.info(" [update query response] : " + JSON.stringify(update_count))
  
                                }
                                catch (e) {
                                  logger_all.info(" [Message send] : " + JSON.stringify(message[k]) + " - " + mobiles[m] + " - " + e);
  
                                }
                                /*    logger_all.info( " [update query request] : " + `UPDATE ${table_names[1]} SET response_id = '${send_list._data.id._serialized}',comments='${sender_mobiles[s]}',response_date = CURRENT_TIMESTAMP,response_status = 'S',response_message = 'Success' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`)
                                    const update_list_id = await dynamic_db.query(`UPDATE ${table_names[1]} SET response_id = '${send_list._data.id._serialized}',comments='${sender_mobiles[s]}',response_date = CURRENT_TIMESTAMP,response_status = 'S',response_message = 'Success' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`,null, `${db_name}`);
                                    logger_all.info( " [update query response] : " + JSON.stringify(update_list_id)) */
  
                                // succ_array.push({ "sender": sender_mobiles[s], "receiver": mobiles[m], "status": "success", "message_id": send_list._data.id._serialized })
  
                              }
                              if (message[k].msg_type == "media") {
                                var media = message[k].media_file;
                                var filename = message[k].file_name;
                                var media_caption = message[k].media_caption;
  
                                const b64data = fs.readFileSync(media, { encoding: 'base64' });
                                const mimetype = mime.getType(media);
                                var send_media = await new MessageMedia(mimetype, b64data, filename);
  
                                //  var send_media = new MessageMedia(media_type, media, filename);
  
                                if (!media_caption) {
  
                                  try {
                                    const media_without_caption = await senders[`${sender_mobiles[s]}`].sendMessage(number_details._serialized, send_media);
                                    logger_all.info(" [Message response] : " + JSON.stringify(message[k]) + " - " + mobiles[m] + " - " + JSON.stringify(media_without_caption));
  
                                    logger_all.info(" [update query request] : " + `UPDATE whatsapp_config SET sent_count = sent_count+1 WHERE concat(country_code, mobile_no) = '${sender_mobiles[s]}'`)
                                    const update_count = await db.query(`UPDATE whatsapp_config SET sent_count = sent_count+1 WHERE concat(country_code, mobile_no) = '${sender_mobiles[s]}'`);
                                    logger_all.info(" [update query response] : " + JSON.stringify(update_count))
  
                                  }
                                  catch (e) {
                                    logger_all.info(" [Message send] : " + JSON.stringify(message[k]) + " - " + mobiles[m] + " - " + e);
  
                                  }
  
                                  /*   logger_all.info( " [update query request] : " + `UPDATE ${table_names[1]} SET response_id = '${media_without_caption._data.id._serialized}',comments='${sender_mobiles[s]}',response_date = CURRENT_TIMESTAMP,response_status = 'S',response_message = 'Success' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`)
                                     const update_media_cap_id = await dynamic_db.query(`UPDATE ${table_names[1]} SET response_id = '${media_without_caption._data.id._serialized}',comments='${sender_mobiles[s]}',response_date = CURRENT_TIMESTAMP,response_status = 'S',response_message = 'Success' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`,null, `${db_name}`);
                                     logger_all.info( " [update query response] : " + JSON.stringify(update_media_cap_id)) */
  
                                  // succ_array.push({ "sender": sender_mobiles[s], "receiver": mobiles[m], "status": "success", "message_id": media_without_caption._data.id._serialized })
  
                                }
                                else {
  
                                  try {
                                    media_caption = media_caption.replace(/&amp;/g, "&")
  
                                    const media_with_caption = await senders[`${sender_mobiles[s]}`].sendMessage(number_details._serialized, send_media, { caption: media_caption });
                                    logger_all.info(" [Message response] : " + JSON.stringify(message[k]) + " - " + mobiles[m] + " - " + JSON.stringify(media_with_caption));
  
                                    logger_all.info(" [update query request] : " + `UPDATE whatsapp_config SET sent_count = sent_count+1 WHERE concat(country_code, mobile_no) = '${sender_mobiles[s]}'`)
                                    const update_count = await db.query(`UPDATE whatsapp_config SET sent_count = sent_count+1 WHERE concat(country_code, mobile_no) = '${sender_mobiles[s]}'`);
                                    logger_all.info(" [update query response] : " + JSON.stringify(update_count))
  
                                  }
                                  catch (e) {
                                    logger_all.info(" [Message send] : " + JSON.stringify(message[k]) + " - " + mobiles[m] + " - " + e);
  
                                  }
                                  /* logger_all.info( " [update query request] : " + `UPDATE ${table_names[1]} SET response_id = '${media_with_caption._data.id._serialized}' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`)
                                  const update_media_id = await dynamic_db.query(`UPDATE ${table_names[1]} SET response_id = '${media_with_caption._data.id._serialized}',comments='${sender_mobiles[s]}',response_date = CURRENT_TIMESTAMP,response_status = 'S',response_message = 'Success' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`,null, `${db_name}`);
                                  logger_all.info( " [update query response] : " + JSON.stringify(update_media_id)) */
  
                                  // succ_array.push({ "sender": sender_mobiles[s], "receiver": mobiles[m], "status": "success", "message_id": media_with_caption._data.id._serialized })
  
                                }
                              }
                              if (message[k].msg_type == "button") {
  
                                var url_btn = message[k].url_btn;
                                var url_text = message[k].url_text;
                                var btn_content = message[k].btn_content;
  
                                var call_btn = message[k].call_btn;
                                var call_text = message[k].call_text;
  
                                var reply_btn1 = message[k].reply_btn1;
                                // var reply_btn_id1 = req.body.reply_btn_id1;
  
                                var reply_btn2 = message[k].reply_btn2;
                                // var reply_btn_id2 = req.body.reply_btn_id2;
  
                                var reply_btn3 = message[k].reply_btn3;
                                // var reply_btn_id3 = req.body.reply_btn_id3;
                                let optionsButtonMessage = {
                                  useTemplateButtons: true,
                                  buttons: [],
  
                                };
  
                                if (url_btn) {
                                  optionsButtonMessage.buttons.push({
                                    url: url_btn,
                                    text: url_text
                                  })
                                }
                                if (call_btn) {
                                  optionsButtonMessage.buttons.push({
                                    phoneNumber: call_btn,
                                    text: call_text
                                  })
                                }
                                if (reply_btn1) {
                                  optionsButtonMessage.buttons.push({
                                    id: reply_btn1,
                                    text: reply_btn1
                                  })
                                }
                                if (reply_btn2) {
                                  optionsButtonMessage.buttons.push({
                                    id: reply_btn2,
                                    text: reply_btn2
                                  })
                                }
                                if (reply_btn3) {
                                  optionsButtonMessage.buttons.push({
                                    id: reply_btn3,
                                    text: reply_btn3
                                  })
                                }
  
                                try {
                                  const sendButton = await senders[`${sender_mobiles[s]}`].pupPage.evaluate(
                                    (to, btn_content, options) =>
                                      WPP.chat.sendTextMessage(to, btn_content, options),
                                    number_details._serialized,
                                    btn_content,
                                    optionsButtonMessage
  
                                  );
                                  logger_all.info(" [Message response] : " + JSON.stringify(message[k]) + " - " + mobiles[m] + " - " + JSON.stringify(sendButton));
  
                                  logger_all.info(" [update query request] : " + `UPDATE whatsapp_config SET sent_count = sent_count+1 WHERE concat(country_code, mobile_no) = '${sender_mobiles[s]}'`)
                                  const update_count = await db.query(`UPDATE whatsapp_config SET sent_count = sent_count+1 WHERE concat(country_code, mobile_no) = '${sender_mobiles[s]}'`);
                                  logger_all.info(" [update query response] : " + JSON.stringify(update_count))
  
                                }
                                catch (e) {
                                  logger_all.info(" [Message send] : " + JSON.stringify(message[k]) + " - " + mobiles[m] + " - " + e);
  
                                }
  
                                /* logger_all.info( " [update query request] : " + `UPDATE ${table_names[1]} SET response_id = '${sendButton._data.id._serialized}',comments='${sender_mobiles[s]}',response_date = CURRENT_TIMESTAMP,response_status = 'S',response_message = 'Success' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`)
                                 const update_btn_id = await dynamic_db.query(`UPDATE ${table_names[1]} SET response_id = '${sendButton._data.id._serialized}',comments='${sender_mobiles[s]}',response_date = CURRENT_TIMESTAMP,response_status = 'S',response_message = 'Success' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`,null, `${db_name}`);
                                 logger_all.info( " [update query response] : " + JSON.stringify(update_btn_id)) */
  
                                //succ_array.push({ "sender": sender_mobiles[s], "receiver": mobiles[m], "status": "success", "message_id": sendButton.id })
                              }
                            }
                            m++
                            // if(m == mobiles.length-1){
                            //     res.json({ "succ_count": succ_array.length, "error_count": error_array.length,"success":succ_array,"failure":error_array})
                            // }
                            // res.json({ "message": "Message sent successfully." })
                            // send message
                          }
                          else {
                            logger_all.info(" [Message send] : Mobile number not registered - " + mobiles[m]);
  
                            logger_all.info(" [update query request] : " + `UPDATE ${table_names[1]} SET response_status = 'I',response_message = 'NUMBER NOT REGISTERED',response_date=CURRENT_TIMESTAMP,comments='${sender_mobiles[s]}' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`)
                            const update_failure = await dynamic_db.query(`UPDATE ${table_names[1]} SET comments='${sender_mobiles[s]}',response_date=CURRENT_TIMESTAMP,response_status = 'I',response_message = 'NUMBER NOT REGISTERED' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`, null, `${db_name}`);
                            logger_all.info(" [update query response] : " + JSON.stringify(update_failure))
                            // error_array.push({ "sender": sender_mobiles[s], "receiver": mobiles[m], "status": "Mobile number is not registered" })
                            m++
  
                            // if(m == mobiles.length-1){
                            //     res.json({ "succ_count": succ_array.length, "error_count": error_array.length,"success":succ_array,"failure":error_array})
                            // }
                          }
                          if (m != mobiles.length) {
  
                            // logger_all.info( " [Time delay] : " + 1000 * time_delay);
  
                            // await sleep(1000 * time_delay)
                          }
                        }
                        else {
                          break;
                        }
                      }
                    }
                    catch (e) {
                      logger_all.info(" [Client is disconnected] : " + sender_mobiles[s]);
  
                      logger_all.info(" [update query request] : " + `UPDATE whatsapp_config SET whatspp_config_status = 'B' WHERE concat(country_code, mobile_no) = '${sender_mobiles[s]}' AND whatspp_config_status != 'D'`)
                      const update_inactive = await db.query(`UPDATE whatsapp_config SET whatspp_config_status = 'B' WHERE concat(country_code, mobile_no) = '${sender_mobiles[s]}' AND whatspp_config_status != 'D'`);
                      logger_all.info(" [update query response] : " + JSON.stringify(update_inactive))
  
                    }
  
                  }
                  /* logger_all.info( " [Time delay] : " + 1000 * time_delay);
   
                   await sleep(1000 * time_delay) */
                }
                if (m == mobiles.length) {
                  for (var t = 0; t < sender_mobiles.length; t++) {
                    try {
                      await sleep(5000);
                      await senders[`${sender_mobiles[t]}`].destroy();
  
                      logger_all.info(" [update query request] : " + `UPDATE whatsapp_config SET whatspp_config_status = 'Y' WHERE concat(country_code, mobile_no) = '${sender_mobiles[t]}' AND whatspp_config_status != 'D' AND whatspp_config_status != 'B'`)
                      const update_number = await db.query(`UPDATE whatsapp_config SET whatspp_config_status = 'Y' WHERE concat(country_code, mobile_no) = '${sender_mobiles[t]}' AND whatspp_config_status != 'D' AND whatspp_config_status != 'B'`);
                      logger_all.info(" [update query response] : " + JSON.stringify(update_number))
  
  
                      logger_all.info(" [Destroy client] : " + sender_mobiles[t]);
                    }
                    catch (e) {
                      logger_all.info(" [Destroy client] : " + e);
                    }
                  }
  
                  var com_status = 'S';
                  if (error_array.length == 0) {
                    com_status = 'S';
                  }
                  else {
                    com_status = 'F';
                  }
  
                  logger_all.info(" [update query request] : " + `UPDATE ${table_names[0]} SET whatsapp_status = '${com_status}' WHERE compose_whatsapp_id = ${compose_whatsapp_id}`)
                  const update_complete = await dynamic_db.query(`UPDATE ${table_names[0]} SET whatsapp_status = '${com_status}' WHERE compose_whatsapp_id = ${compose_whatsapp_id}`, null, `${db_name}`);
                  logger_all.info(" [update query response] : " + JSON.stringify(update_complete))
  
  
                  // return res.json({ "succ_count": succ_array.length, "error_count": error_array.length, "success": succ_array, "failure": error_array })
                }
                // else {
                // logger_all.info( " [Loop delay] : " + 60000 * loop_delay);
                //  await sleep(60000 * loop_delay)
                // }
              }
  
            }
            else {
              var mob_num = []
              function_call = false
  
              for (var prop in senders) {
                mob_num.push(prop)
              }
              for (var c = 0; c < sender_numbers.length; c++) {
                if (!senders[`${sender_numbers[c]}`]) {
  
                  await all_senders[`${sender_numbers[c]}`].destroy();
                  delete all_senders[`${sender_numbers[c]}`];
  
                  logger_all.info(' destroy number - ' + sender_numbers[c])
  
                  logger_all.info(' rescan number - ' + sender_numbers[c])
                  if (fs.existsSync(`./.wwebjs_auth/session-${sender_numbers[c]}`)) {
                    fs.rmdirSync(`./.wwebjs_auth/session-${sender_numbers[c]}`, { recursive: true })
  
                  }
                  if (fs.existsSync(`./session_copy/session-${sender_numbers[c]}`)) {
                    // fs.rmdirSync(`./.wwebjs_auth/session-${sender_numbers[c]}`, { recursive: true })
                    // fs.c
                    try {
                      fse.copySync(`./session_copy/session-${sender_numbers[c]}`, `./.wwebjs_auth/session-${sender_numbers[c]}`, { overwrite: true | false })
                      logger_all.info(' Folder copied successfully')
  
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
                          { clientId: sender_numbers[c] }
                        )
                      }
                      );
  
                      all_senders[`${sender_numbers[c]}`] = client;
  
                      client.initialize();
  
                      client.on('authenticated', async (data) => {
                        logger_all.info(" [Client is Log in] : " + JSON.stringify(data));
  
                      });
  
                      if (!client.pupPage) {
                        // client has not been initialized
                      }
  
                      client.on('ready', async (data) => {
                        logger_all.info(" [Client is ready] : " + client.options.authStrategy.clientId);
                        client.pupPage.addScriptTag({ path: require.resolve("@wppconnect/wa-js") });
                        await client.pupPage.waitForFunction(() => window.WPP?.isReady);
  
                        senders[`${client.options.authStrategy.clientId}`] = client;
                        mob_num.push(client.options.authStrategy.clientId);
  
                        if (mob_num.length == sender_numbers.length) {
                          function_call = true
                          send_msg(mob_num);
                        }
                      });
  
                    } catch (err) {
                      console.error(err)
                    }
                  }
  
                  //  logger_all.info( " [update query request] : " + `UPDATE whatsapp_config SET whatspp_config_status = 'X' WHERE concat(country_code, mobile_no) = '${sender_numbers[c]}' AND whatspp_config_status != 'D'`)
                  //  const update_inactive = await db.query(`UPDATE whatsapp_config SET whatspp_config_status = 'X' WHERE concat(country_code, mobile_no) = '${sender_numbers[c]}' AND whatspp_config_status != 'D'`);
                  //  logger_all.info( " [update query response] : " + JSON.stringify(update_inactive))
  
                }
              }
  
              setTimeout(async function () {
                var mob_num_rescan = []
                for (var prop in senders) {
                  mob_num_rescan.push(prop)
                }
                for (var c = 0; c < sender_numbers.length; c++) {
                  if (!senders[`${sender_numbers[c]}`]) {
                    await all_senders[`${sender_numbers[c]}`].destroy();
  
                    logger_all.info(" [update query request] : " + `UPDATE whatsapp_config SET whatspp_config_status = 'X' WHERE concat(country_code, mobile_no) = '${sender_numbers[c]}' AND whatspp_config_status != 'D'`)
                    const update_inactive = await db.query(`UPDATE whatsapp_config SET whatspp_config_status = 'X' WHERE concat(country_code, mobile_no) = '${sender_numbers[c]}' AND whatspp_config_status != 'D'`);
                    logger_all.info(" [update query response] : " + JSON.stringify(update_inactive))
  
                  }
                }
  
                if (function_call == false) {
                  send_msg(mob_num_rescan);
                }
              }, (sender_numbers.length - mob_num.length) * 120000);
  
            }
          }
          else {
            for (var t = 0; t < sender_numbers.length; t++) {
  
              try {
                await all_senders[`${sender_numbers[t]}`].destroy();
  
                logger_all.info(" [Destroy client] : " + sender_numbers[t]);
              }
              catch (e) {
                logger_all.info(" [Destroy client] : " + e);
  
              }
            }
  
            for (var m = 0; m < mobile_numbers_insertid.length; m++) {
              try {
  
                logger_all.info(" [update query request] : " + `UPDATE ${table_names[1]} SET response_date = CURRENT_TIMESTAMP,response_status = 'F',response_message = 'NO SENDER AVAILABLE' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`, null, `${db_name}`)
                const update_failure = await dynamic_db.query(`UPDATE ${table_names[1]} SET response_date = CURRENT_TIMESTAMP,response_status = 'F',response_message = 'NO SENDER AVAILABLE' WHERE comwtap_status_id = ${mobile_numbers_insertid[m]}`, null, `${db_name}`);
                logger_all.info(" [update query response] : " + JSON.stringify(update_failure))
  
              }
              catch (e) {
                logger_all.info(" [Status Change error] : " + e);
  
              }
            }
  
            logger_all.info(" [No senders available] ");
            //   return res.json({ response_code: 1, response_status: 201, response_msg: 'No senders available.' });
          }
        }
      }
      else {
        logger_all.info(" [Error occured] ");
        // return res.json({ response_code: 1, response_status: 201, response_msg: 'Error occurred ' });
      }
    }
    catch (e) {
      for (var prop in senders) {
        try {
          await senders[`${prop}`].destroy();
          logger_all.info(" [Destroy client] : " + sender_numbers[t]);
  
        }
        catch (e) {
          logger_all.info(" [Destroy client] : " + e);
        }
      }
      logger_all.info(" [Error occured] : " + e);
    }
  });