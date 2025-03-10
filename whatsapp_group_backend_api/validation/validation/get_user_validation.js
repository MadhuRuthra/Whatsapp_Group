const Joi = require("@hapi/joi");

const getUser = Joi.object().keys({
  user_id: Joi.string().optional().label("User ID"),

}).options({abortEarly : false});

module.exports = getUser


