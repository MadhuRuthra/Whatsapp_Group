DELIMITER // CREATE DEFINER = `root` @`localhost` PROCEDURE `TEST`(
    IN `in_slt_user_id` INT,
    IN `in_plan_master_id` INT,
    IN `in_plan_amount` INT,
    IN `in_plan_comments` VARCHAR(300),
    IN `in_plan_reference_id` VARCHAR(100),
    IN `in_request_id` VARCHAR(30)
) 
BEGIN DECLARE last_inserted_id INT;
       DECLARE last_inserted_ids INT;
      DECLARE array_plan_master_id VARCHAR(255);

-- Get plan details from plan_master
SELECT
    plan_title,
    whatsapp_no_max_count,
    group_no_max_count,
    message_limit,
    annual_monthly INTO @plan_title,
    @whatsapp_no_max_count,
    @group_no_max_count,
    @message_limit,
    @annual_monthly
FROM
    plan_master
WHERE
    plan_master_id = in_plan_master_id
    AND plan_status = 'Y';

-- SELECT
--     @plan_title,
--     @whatsapp_no_max_count,
--     @group_no_max_count,
--     @message_limit,
--     @annual_monthly;
-- Check if the user already has plans
SELECT
    user_plans_id,
    plan_master_id INTO @user_plans_id,
    @array_plan_master_id
FROM
    user_plans
WHERE
    user_id = in_slt_user_id;
IF @user_plans_id IS NOT NULL THEN --  @user_plans_id IF START
-- Check if the plan to be purchased is already active
SELECT
    plan_expiry_date INTO @plan_expiry_date
FROM
    user_plans
WHERE
    user_id = in_slt_user_id
    AND plan_master_id = in_plan_master_id;
