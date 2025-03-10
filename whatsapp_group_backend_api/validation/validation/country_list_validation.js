const Joi = require("@hapi/joi");

const CountryListSchema = Joi.object().keys({
    user_id: Joi.string().optional().label("User Id"),
}).options({ abortEarly: false });

module.exports = CountryListSchema

