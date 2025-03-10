const Joi = require("@hapi/joi");

const createCsvValidation = Joi.object().keys({
  user_id: Joi.string().optional().label("User Id"),
  // api_key: Joi.string().required().label("Api key"),
  mobile_number: Joi.array().required().label("Mobile Number"),
  request_id: Joi.string().required().label("Request ID"),

}).options({abortEarly : false});

module.exports = createCsvValidation
