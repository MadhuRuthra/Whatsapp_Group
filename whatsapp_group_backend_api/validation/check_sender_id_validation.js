const Joi = require("@hapi/joi");

const SenderIDSchema = Joi.object().keys({
    user_id: Joi.string().optional().label("User Id"),
    mobile_no: Joi.string().required().label("Mobile No"),
}).options({ abortEarly: false });

module.exports = SenderIDSchema
