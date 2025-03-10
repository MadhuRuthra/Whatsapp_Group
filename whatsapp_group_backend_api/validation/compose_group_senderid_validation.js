const Joi = require("@hapi/joi");

const Common = Joi.object().keys({
    user_id: Joi.string().required().label("User Id"),
    group_master_id: Joi.string().required().label("Group Master Id"),
}).options({ abortEarly: false });

module.exports = Common
