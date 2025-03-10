const Joi = require("@hapi/joi");

const ReportSchema = Joi.object().keys({
    user_id: Joi.string().optional().label("User Id"),
}).options({ abortEarly: false });

module.exports = ReportSchema

