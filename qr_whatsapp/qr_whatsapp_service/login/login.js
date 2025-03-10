const db = require("../db_connect/connect");
const jwt = require("jsonwebtoken");
const md5 = require("md5")
const main = require('../logger')
require("dotenv").config();

// login - start
async function login(req) {
    var logger_all = main.logger_all
    var logger = main.logger

    // get all the req data
    let txt_username = req.body.username;
    let txt_password = md5(req.body.password);
    let request_id = req.body.request_id;

    var header_json = req.headers;
    let ip_address = header_json['x-forwarded-for'];
    var bearer_token;

    var log_data = "[API REQUEST] " + req.originalUrl + " - " + JSON.stringify(req.body) + " - " + JSON.stringify(req.headers) + " - " + ip_address
    logger.info(log_data);
    logger_all.info(log_data);

    try { //check the user name

        //JWT Token Accessing value...
        const user = {
            username: req.body.txt_username,
            user_password: req.body.txt_password,
        }
        const accessToken_1 = jwt.sign(user, process.env.ACCESS_TOKEN_SECRET, {
            expiresIn: process.env.ONEWEEK
        });
        bearer_token = "Bearer " + accessToken_1;
        const login_query = `CALL LoginProcedure('${txt_username}', '${txt_password}', '${request_id}','${bearer_token}','${ip_address}','${req.originalUrl}')`;
        logger_all.info("[Select query request] : " + login_query);
        const sql_stat = await db.query(login_query);
        const [results] = sql_stat; // Destructure the single result set
        logger_all.info("results" + JSON.stringify(results))

        // Check if the result set contains any rows
        if (results && results.length > 0) {
            const successMessage = results[0].response_msg;
            const bearer_token = accessToken_1;
            const user_id = results[0].user_id;
            const user_master_id = results[0].user_master_id;
            const parent_id = results[0].parent_id;
            const user_name = results[0].user_name;
            const usr_mgt_status = results[0].usr_mgt_status;

            return {
                response_code: 1,
                response_status: 200,
                num_of_rows: 1,
                response_msg: successMessage,
                bearer_token: bearer_token,
                user_id: user_id,
                user_master_id: user_master_id,
                parent_id: parent_id,
                user_name: user_name,
                usr_mgt_status: usr_mgt_status
            };
        } else {
            logger_all.info(": [Login] Failed - Error occurred.");

            return {
                response_code: 0,
                response_status: 201,
                response_msg: "Error occurred.",
            };
        }
    } catch (err) {
        // Handle other errors
        logger_all.info(": [Login] Failed - " + err.message);
        return {
            response_code: 0,
            response_status: 201,
            response_msg: err.message,
        };
    }
}
// login - end

// using for module exporting
module.exports = {
    login
};
