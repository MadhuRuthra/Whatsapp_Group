const Joi = require("@hapi/joi");

const mandal = Joi.object().keys({
    parl_id: Joi.string().required().label("Parliament ID")

}).options({abortEarly : false});

module.exports = mandal


