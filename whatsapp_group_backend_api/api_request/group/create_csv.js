require("dotenv").config();
const main = require('../../logger')
const fs = require('fs');
const env = process.env
const csv = require("csv-stringify");
const media_storage = env.MEDIA_STORAGE;

async function create_csv(req) {
  var logger_all = main.logger_all

  try {
 
    var day = new Date();
    var today_date = day.getFullYear() + '' + (day.getMonth() + 1) + '' + day.getDate();
    var today_time = day.getHours() + "" + day.getMinutes() + "" + day.getSeconds();
    var current_date = today_date + '_' + today_time;

    let sender_number = req.body.mobile_number;

    var data = [
      ['Name', 'Given Name', 'Group Membership', 'Phone 1 - Type', 'Phone 1 - Value']
    ];

    for (var i = 0; i < sender_number.length; i++) {
      data.push([`yjtec${day.getDate()}_${sender_number[i]}`, `yjtec${day.getDate()}_${sender_number[i]}`, '* myContacts', '', `${sender_number[i]}`])
    }

    // (C) CREATE CSV FILE
    csv.stringify(data, async (err, output) => {
      fs.writeFileSync(`${media_storage}/uploads/whatsapp_docs/contacts_${current_date}.csv`, output);

      return { request_id: req.body.request_id, response_code: 1, response_status: 200, response_msg: 'Success ', file_location: `uploads/whatsapp_docs/contacts_${current_date}.csv` };
    });
  }
  catch (err) {
    logger_all.info("[create_csv Error] : " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}
module.exports = {
  create_csv
};
