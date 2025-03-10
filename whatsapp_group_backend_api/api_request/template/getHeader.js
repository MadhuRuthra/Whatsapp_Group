/*
API that allows your frontend to communicate with your backend server (Node.js) for processing and retrieving data.
To access a MySQL database with Node.js and can be use it.
This page is used in template function which is used to get a header template
details.

Version : 1.0
Author : Madhubala (YJ0009)
Date : 05-Jul-2023
*/
// Import the required packages and libraries
const fs = require('fs');
var axios = require('axios');
const env = process.env
const api_url = env.API_URL;
const app_id = env.APP_ID;
const media_bearer = env.MEDIA_BEARER;
var util = require('util');
const main = require('../../logger');
// getHeaderFile - start
async function getHeaderFile(file_url) {
    var logger = main.logger
    var logger_all = main.logger_all;

    // get current Date 
    var day = new Date();
    // declare the array
    var header_value = [];
    // declare the variables
    let media_name;
    var config = {
        method: 'get',
        url: file_url,
        headers: {},
        responseType: 'arraybuffer'
    };

    await axios(config)//config with using the response function
        .then(async function (response) {
            // response header requset
            logger_all.info("[get session request] : " + JSON.stringify(response.headers));
            // upload the header media option
            var media_type = response.headers['content-type'].split("/");
            media_name = `upload_${day.getDate()}${day.getHours()}${day.getMinutes()}${day.getSeconds()}_${response.headers['content-length']}.${media_type[1]}`;

            fs.writeFile(`${media_name}`, response.data, function (err) {
                if (err) { // if any error are occured to send
                    logger_all.info("[upload image failed response] : " + err);
                }

            });

            logger_all.info("[upload image success response] : file written in - " + media_name);
            // get_session variable declare
            var get_session = {
                method: 'post',
                url: `${api_url}${app_id}/uploads`,
                params: {
                    file_length: response.headers['content-length'],
                    file_type: response.headers['content-type'],
                    access_token: media_bearer,
                }
            };

            logger_all.info("[get session request] : " + JSON.stringify(get_session))
            // get_session with to send the response 
            await axios(get_session)
                .then(async function (response) {
                    logger_all.info("[get session response] : " + util.inspect(response.data))
                    header_value.push(response.data.id);
                    header_value.push(media_name);
                    if (media_type[0] == 'image') { //image using
                        header_value.push('IMAGE');
                    }
                    else if (media_type[0] == 'video') { //video using
                        header_value.push('VIDEO');
                    }
                    else { // document using
                        header_value.push('DOCUMENT');
                    }
                    //return header_value;
                })
                .catch(async function (error) {// any error occurres send error response to client
                    logger_all.info("[get session failed number] : " + error)
                    if (fs.existsSync(media_name)) {
                        fs.unlinkSync(media_name);
                    }
                    //  return 'null';
                })
        })
        .catch(function (error) {// any error occurres send error response to client
            logger_all.info("[get session failed number] : " + error)
            if (fs.existsSync(media_name)) {
                fs.unlinkSync(media_name);
            }
            //return 'null';

        });//to return the header value
    return header_value;
}
// getHeaderFile - end
// using for module exporting
module.exports = {
    getHeaderFile,
};
