const Joi = require("@hapi/joi");

const updateUser = Joi.object().keys({
  user_id: Joi.string().optional().label("User ID"),
  slt_user_id: Joi.string().optional().label("Slt User Id"),

}).options({abortEarly : false});

module.exports = updateUser