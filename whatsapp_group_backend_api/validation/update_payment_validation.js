const Joi = require("@hapi/joi");

const UpdatePaymentHistory = Joi.object().keys({
 user_id: Joi.string().optional().label("User Id"),
    user_plans_id: Joi.string().required().label("User Plan Id"),
    payment_status: Joi.string().required().label("Payment Status"),
    user_plan_status: Joi.string().required().label("User Plan Status"),
    plan_comments: Joi.string().required().label("plan commments"),
    plan_master_id :Joi.string().required().label("plan Master Id"),
  request_id: Joi.string().required().label("Request ID"),
}).options({abortEarly : false});

module.exports = UpdatePaymentHistory
