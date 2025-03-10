const Joi = require("@hapi/joi");

const GetQrCode = Joi.object().keys({
  mobile_number: Joi.string().required().label("Mobile number"),
  user_id: Joi.string().optional().label("User ID"),
  request_id: Joi.string().required().label("Request ID"),
  profile_name: Joi.string().required().label("Profile name"),
  profile_image: Joi.string().required().label("Profile image"),

}).options({abortEarly : false});

module.exports = GetQrCode


