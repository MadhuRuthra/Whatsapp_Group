const db = require("../db_connect/connect");
const jwt = require("jsonwebtoken")
const main = require('../logger');

const VerifyUser = async (req, res, next) => {
    var logger_all = main.logger_all
    var logger = main.logger

    try {
        var header_json = req.headers;
        const ip_address = header_json['x-forwarded-for'] ? `'${req.body.ip_address}'` : 'undefined';
        var request_id = req.body.request_id;

        logger.info("[API REQUEST] " + req.originalUrl + " - " + JSON.stringify(req.body) + " - " + JSON.stringify(req.headers) + " - " + ip_address)
        logger_all.info("[API REQUEST] " + req.originalUrl + " - " + JSON.stringify(req.body) + " - " + JSON.stringify(req.headers) + " - " + ip_address)

        var user_id;
        var user_master_id;

        const bearerHeader = req.headers['authorization'];

        let parameters = '';
        if (bearerHeader) {
            parameters += `,'${bearerHeader}'`;
        } else {
            parameters += `,null`;
        }

        if (req.body.user_id) {
            parameters += `,'${req.body.user_id}'`;
        } else {
            parameters += `,null`;
        }
        

        const update_api_log = `CALL update_api_log('${req.originalUrl}','${ip_address}','${req.body.request_id}' ${parameters})`;
        logger_all.info("[Select query request] : " + update_api_log);
        var update_api_log_result = await db.query(update_api_log);
        logger_all.info("[select query response ] : " + JSON.stringify(update_api_log_result))


        user_id = update_api_log_result[0][0].response_user_id;
        
        if (update_api_log_result[0][0].Success) {
            try {
                var user_bearer_token = bearerHeader.split('Bearer ')[1];
                logger_all.info("[select query response ] : " + JSON.stringify(update_api_log_result))
                jwt.verify(user_bearer_token, process.env.ACCESS_TOKEN_SECRET);
                logger_all.info("[select query response ] :" + user_id)

                const get_con_id = `SELECT usr.zone_id from user_zone_details usr WHERE usr.user_id = '${user_id}'`
                logger_all.info("[update query request] : " + get_con_id);
                var get_con_id_result = await db.query(get_con_id);
                logger_all.info("[update query Response] : " + JSON.stringify(get_con_id_result));

                const get_master_id = `SELECT user_master_id from user_management WHERE user_id = '${user_id}'`
                logger_all.info("[update query request] : " + get_master_id);
                var get_mas_id_result = await db.query(get_master_id);
                logger_all.info("[update query Response] : " + JSON.stringify(get_mas_id_result));

                var zone_id = get_con_id_result[0].zone_id ;
                user_master_id = get_mas_id_result[0].user_master_id;

                req['body']['user_id'] = user_id;
                req['body']['user_master_id'] = user_master_id;
                req['body']['zone_id'] = zone_id;

                next();
            } catch (e) {

                logger_all.info("[Validate user error] : " + e);

                const update_logout = `UPDATE user_log SET user_log_status = 'O',logout_time = CURRENT_TIMESTAMP WHERE  user_id = '${user_id}'`
                logger_all.info("[update query request] : " + update_logout);
                var update_logout_result = await db.query(update_logout);
                logger_all.info("[update query Response] : " + JSON.stringify(update_logout_result));

                const update_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Token expired' WHERE request_id = '${request_id}' AND response_status = 'N'`
                logger_all.info("[update query request] : " + update_log);
                const update_api_log = await db.query(update_log);
                logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

                var response_json_3 = {
                    request_id: request_id,
                    response_code: 0,
                    response_status: 403,
                    response_msg: 'Token expired'
                }
                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json_3))
                logger.info("[API RESPONSE] " + JSON.stringify(response_json_3))

                return res
                    .status(403)
                    .send(response_json_3);
            }

        } else if (update_api_log_result[0][0].Status) {
            var response_json = {
                request_id: request_id,
                response_code: 0,
                response_status: 201,
                response_msg: update_api_log_result[0][0].response_msg
            }
            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

            return res
                .status(201)
                .send(response_json);

        } else {
            var response_json = {
                request_id: request_id,
                response_code: 0,
                response_status: 403,
                response_msg: update_api_log_result[0][0].response_msg
            }
            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

            return res
                .status(403)
                .send(response_json);
        }
    } catch (e) {
        logger_all.info("[Validate user error] : " + e);

        const update_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${request_id}' AND response_status = 'N'`
        logger_all.info("[update query request] : " + update_log);
        const update_api_log = await db.query(update_log);
        logger_all.info("[update query response] : " + JSON.stringify(update_api_log))

        var response_json_5 = {
            request_id: request_id,
            response_code: 0,
            response_status: 201,
            response_msg: 'Error occurred'
        }
        logger_all.info("[API RESPONSE] " + JSON.stringify(response_json_5))
        logger.info("[API RESPONSE] " + JSON.stringify(response_json_5))
        res.json(response_json_5);
    }
}
module.exports = VerifyUser;