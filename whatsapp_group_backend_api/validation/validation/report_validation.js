const Joi = require("@hapi/joi");

const ReportSchema = Joi.object().keys({
    user_id: Joi.string().optional().label("User Id"),
    start_date: Joi.string().optional().label("Start Date"),
    end_date: Joi.string().optional().label("End Date"),
    campaign_name: Joi.string().optional().label("Campaign name"),
    user_name: Joi.string().optional().label("User name"),

}).options({ abortEarly: false });

module.exports = ReportSchema

