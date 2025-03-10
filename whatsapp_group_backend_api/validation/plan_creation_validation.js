const Joi = require("@hapi/joi");

const plancreation = Joi.object().keys({
    plan_title: Joi.string().required().label("Plan Title"),
    annual_monthly: Joi.string().required().label("Annual monthly"),
    whatsapp_no_min_count: Joi.string().required().label("Whatsapp no min count"),
    whatsapp_no_max_count: Joi.string().required().label("whatsapp no max count"),
    group_no_min_count: Joi.string().required().label("Group no min count"),
    group_no_max_count: Joi.string().required().label("Group no max count"),
    plan_price: Joi.string().required().label("Plan Price"),
    message_limit: Joi.string().required().label("Message Limit"),
    request_id: Joi.string().required().label("Request ID"),

}).options({ abortEarly: false });

module.exports = plancreation