const Joi = require("@hapi/joi");

const SignupSchema = Joi.object().keys({
    request_id: Joi.string().required().label("Request ID"),
    user_type: Joi.string().required().label("User Type"),
    user_name: Joi.string().required().label("User Name"),
    user_email: Joi.string().required().label("User Email"),
    user_mobile: Joi.string().required().label("User Mobile"),
    user_password: Joi.string().required().label("User Password"),
    plan_master_id: Joi.string().required().label("Plan Master Id"),
    total_whatsapp_count: Joi.string().required().label("Total Whatsapp Count"),
    total_group_count: Joi.string().required().label("Total Group Count"),
    total_message_limit: Joi.string().required().label("Total Message Limit"),
    expiry_date: Joi.string().required().label("Expiry Date"),
    plan_amount: Joi.string().required().label("Plan Amount"),
}).options({ abortEarly: false });

module.exports = SignupSchema
