const Joi = require("@hapi/joi");

const SignupSchema = Joi.object().keys({
    request_id: Joi.string().required().label("Request ID"),   
    user_type: Joi.string().required().label("User Type"),
    user_name: Joi.string().required().label("User Name"),
    user_email: Joi.string().required().label("User Email"),
    user_mobile: Joi.string().required().label("User Mobile"),
    user_password: Joi.string().required().label("User Password"),
}).options({ abortEarly: false });

module.exports = SignupSchema
