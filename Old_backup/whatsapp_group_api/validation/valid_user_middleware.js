const db = require("../db_connect/connect");
const jwt = require("jsonwebtoken")
const main = require('../logger');

const VerifyUser = async (req, res, next) => {
    var logger_all = main.logger_all
    var logger = main.logger

    try {

        var header_json = req.headers;
        let ip_address = header_json['x-forwarded-for'];
        var request_id = req.body.request_id;

        logger.info("[API REQUEST] " + req.originalUrl + " - " + JSON.stringify(req.body) + " - " + JSON.stringify(req.headers) + " - " + ip_address)
        logger_all.info("[API REQUEST] " + req.originalUrl + " - " + JSON.stringify(req.body) + " - " + JSON.stringify(req.headers) + " - " + ip_address)

        var user_id;
        const bearerHeader = req.headers['authorization'];

        if (bearerHeader) {

            var user_bearer_token = bearerHeader.split('Bearer ')[1];

            var check_bearer = `SELECT * FROM user_management WHERE bearer_token = '${bearerHeader}' AND usr_mgt_status = 'Y'`;
            var invalid_msg = 'Invalid Token';
            if (req.body.user_id) {
                check_bearer = check_bearer + ' AND user_id = ' + req.body.user_id;
                invalid_msg = 'Invalid token or User ID'
            }

            logger_all.info("[select query request] : " + check_bearer);
            const check_bearer_response = await db.query(check_bearer);
            logger_all.info("[select query response] : " + JSON.stringify(check_bearer_response));

            if (check_bearer_response.length == 0) {

                var response_json = { request_id:request_id,response_code: 0, response_status: 403, response_msg: invalid_msg }
                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                logger.info("[API RESPONSE] " + JSON.stringify(response_json))

                return res
                    .status(403)
                    .send(response_json);
            }
            else {
                user_id = check_bearer_response[0].user_id;

                try {

                    jwt.verify(user_bearer_token, process.env.ACCESS_TOKEN_SECRET);
                    next();

                    // const check_login = `select * from user_log where user_log_status = 'I' and user_id = '${user_id}'`
                    // logger_all.info("[Valid User Middleware query request] : " + check_login);
                    // var check_login_result = await db.query(check_login);
                    // logger_all.info("[Valid User Middleware query Response] : " + JSON.stringify(check_login_result));

                    // if (check_login_result.length == 0) {

                    //     const update_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Invalid token' WHERE request_id = '${request_id}' AND response_status = 'N'`
                    //     logger_all.info("[update query request] : " + update_log);
                    //     const update_api_log = await db.query(update_log);
                    //     logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

                    //     var response_json_2 = { request_id:request_id,response_code: 0, response_status: 403, response_msg: 'Invalid Token' }
                    //     logger_all.info("[API RESPONSE] " + JSON.stringify(response_json_2))
                    //     logger.info("[API RESPONSE] " + JSON.stringify(response_json_2))

                    //     return res
                    //         .status(403)
                    //         .send(response_json_2);
                    // }
                    // else {
                    //     next();
                    // }
                } catch (e) {

                    logger_all.info("[Validate user error] : " + e);

                    const update_logout = `UPDATE user_log SET user_log_status = 'O',logout_time = CURRENT_TIMESTAMP WHERE  user_id = '${user_id}'`
                    logger_all.info("[update query request] : " +update_logout );
                    var update_logout_result = await db.query(update_logout);
                    logger_all.info("[update query Response] : " + JSON.stringify(update_logout_result));

                    var response_json_3 = { request_id:request_id,response_code: 0, response_status: 403, response_msg: 'Token expired' }
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json_3))
                    logger.info("[API RESPONSE] " + JSON.stringify(response_json_3))
                    
                    return res
                        .status(403)
                        .send(response_json_3);
                }

            }
        }
        else {

            var response_json_4 = { request_id:request_id,response_code: 0, response_status: 403, response_msg: 'Token is required' }
            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json_4))
            logger.info("[API RESPONSE] " + JSON.stringify(response_json_4))

            return res
                .status(403)
                .send(response_json_4);
        }
    }

    catch (e) {
        logger_all.info("[Validate user error] : " + e);

        var response_json_5 = { request_id:request_id,response_code: 0, response_status: 201, response_msg: 'Error occurred' }
        logger_all.info("[API RESPONSE] " + JSON.stringify(response_json_5))
        logger.info("[API RESPONSE] " + JSON.stringify(response_json_5))
        res.json(response_json_5);
    }
}
module.exports = VerifyUser;
