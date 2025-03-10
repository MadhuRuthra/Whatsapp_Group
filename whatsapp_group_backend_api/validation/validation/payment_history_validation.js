const Joi = require("@hapi/joi");

const PaymentHistory = Joi.object().keys({
    slt_user_id: Joi.string().required().label("Select User Id"),
    plan_amount: Joi.string().required().label("Plan Amount"),
    plan_master_id: Joi.string().required().label("Plan Master Id"),
    plan_comments: Joi.array().required().label("plan commments"),
  request_id: Joi.string().required().label("Request ID"),
}).options({abortEarly : false});

module.exports = PaymentHistory
