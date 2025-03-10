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

-- SELECT
--   @user_plans_id,
--   @array_plan_master_id;
IF @user_plans_id IS NOT NULL THEN --  @user_plans_id IF START
-- Check if the plan to be purchased is already active
SELECT
    plan_expiry_date INTO @plan_expiry_date
FROM
    user_plans
WHERE
    user_id = in_slt_user_id
    AND plan_master_id = in_plan_master_id;

-- SELECT
--     @plan_expiry_date;
IF @plan_expiry_date IS NOT NULL THEN -- Subtract 7 days from plan_expiry_date (@plan_expiry_date IF START)
SET
    @seven_days_before = DATE_SUB(@plan_expiry_date, INTERVAL 7 DAY);

IF @seven_days_before >= current_timestamp THEN  -- (@seven_days_before IF START)
SIGNAL SQLSTATE '45000'
SET
    MESSAGE_TEXT = 'Plan is already active. Cannot purchase the same plan again.';

 -- (@seven_days_before IF END)
-- RENEW PLAN ----------------
ELSE  -- (@seven_days_before ELSE START)
Select
    COUNT(*) INTO @get_plan_status
from
    user_plans
WHERE
    plan_master_id = in_plan_master_id
    and user_id = in_slt_user_id;

IF (@get_plan_status > 0) THEN  -- (@get_plan_status IF START)
UPDATE
    user_plans
SET
    payment_status = 'N'
WHERE
    user_plans_id = @user_plans_id;

UPDATE
    payment_history_log
SET
    payment_status = 'N'
WHERE
    user_plans_id = @user_plans_id;

UPDATE
    plans_update
SET
    plan_status = 'N'
WHERE
    user_id = slt_user_id
    and plan_master_id = in_plan_master_id;

INSERT INTO
    plans_update
VALUES
    (
        NULL,
        in_plan_master_id,
        slt_user_id,
        @whatsapp_no_max_count,
        '0',
        '0',
        @group_no_max_count,
        '0',
        '0',
        @message_limit,
        '0',
        '0',
        'N',
        CURRENT_TIMESTAMP,
        NULL
    );

INSERT INTO
    payment_history_log
VALUES
    (
        NULL,
        slt_user_id,
        in_plan_master_id,
        @user_plans_id,
        in_plan_amount,
        'W',
        in_plan_comments,
        'Y',
        CURRENT_TIMESTAMP
    );

-- Get the last inserted ID
SET
    last_inserted_id = LAST_INSERT_ID();

IF (last_inserted_id > 0) THEN   -- (last_inserted_id IF START)
SELECT
    'Success.';
 -- (last_inserted_id IF END )
END IF;  -- (Total last_inserted_id IF END)
  -- (@get_plan_status IF END)
ELSE   -- (@get_plan_status ELSE START)
UPDATE
    api_log
SET
    response_status = 'F',
    response_date = CURRENT_TIMESTAMP,
    response_comments = 'Inactive Plan'
WHERE
    request_id = in_request_id
    AND response_status = 'N';
    SIGNAL SQLSTATE '45000'
SET
    MESSAGE_TEXT = 'Inactive Plan';

  -- (@get_plan_status ELSE END)
END IF; -- (@get_plan_status Total IF END)
 -- (@seven_days_before ELSE END)
END IF; -- (@seven_days_before TOTAL IF END)
 -- @plan_expiry_date IF END
ELSE IF FIND_IN_SET(in_plan_master_id, array_plan_master_id) > 0 THEN   -- @plan_expiry_date ELSE IF START
UPDATE
    api_log
SET
    response_status = 'F',
    response_date = CURRENT_TIMESTAMP,
    response_comments = 'Already plan is active. Cannot Upgrade'
WHERE
    request_id = in_request_id
    AND response_status = 'N';

SIGNAL SQLSTATE '45000'
SET
    MESSAGE_TEXT = 'Already plan is active. Cannot Upgrade.';

  -- @plan_expiry_date ELSE IF END

-- UPGRADE PLANS -----------------------------
ELSE   -- @plan_expiry_date ELSE START
Select
    COUNT(*) INTO @plans_update
from
    plans_update
WHERE
    plan_master_id = in_plan_master_id
    and user_id = slt_user_id
    and plan_status in ('Y')
ORDER BY
    plan_entry_date;

IF (@plans_update > 0) THEN  -- @plans_update IF START
UPDATE
    api_log
SET
    response_status = 'F',
    response_date = CURRENT_TIMESTAMP,
    response_comments = 'Only Upgrade Plan is active.'
WHERE
    request_id = in_request_id
    AND response_status = 'N';

SIGNAL SQLSTATE '45000'
SET
    MESSAGE_TEXT = 'Only Upgrade Plan is active.';

 -- @plans_update IF END
ELSE   -- @plans_update ELSE START
INSERT INTO
    plans_update
VALUES
    (
        NULL,
        plan_master_id,
        slt_user_id,
        in_whatsapp_no_max_count,
        '0',
        '0',
        in_group_no_max_count,
        '0',
        '0',
        in_message_limit,
        '0',
        '0',
        'N',
        CURRENT_TIMESTAMP,
        NULL
    );

INSERT INTO
    payment_history_log
VALUES
    (
        NULL,
        slt_user_id,
        @user_plans_id,
        in_plan_master_id,
        in_plan_amount,
        'W',
        in_plan_comments,
        'Y',
        CURRENT_TIMESTAMP
    );

-- Get the last inserted ID
SET
    last_inserted_ids = LAST_INSERT_ID();

IF (last_inserted_ids > 0) THEN  -- last_inserted_ids IF START
SELECT
    'Success.';
 -- last_inserted_ids IF END
END IF; -- last_inserted_ids TOTAL IF END
 -- @plans_update ELSE END 
END IF; -- @plans_update TOTAL IF END 
 -- @plan_expiry_date ELSE END
END IF;  -- @plan_expiry_date TOTAL IF END
 --  @user_plans_id IF END 
ELSE  -- @user_plans_id ELSE START
-- Purchase the new plan
INSERT INTO
    user_plans (
        user_id,
        plan_master_id,
        plan_amount,
        plan_expiry_date,
        payment_status,
        plan_comments,
        plan_reference_id,
        user_plans_status,
        user_plans_entdate
    )
VALUES
    (
        in_slt_user_id,
        in_plan_master_id,
        in_plan_amount,
        '0000-00-00 00:00:00',
        'W',
        in_plan_comments,
        in_plan_reference_id,
        'W',
        CURRENT_TIMESTAMP
    );

-- Update plans_update table
INSERT INTO
    plans_update (
        plan_master_id,
        user_id,
        whatsapp_no_max_count,
        group_no_max_count,
        message_limit,
        plan_status,
        plan_entry_date
    )
VALUES
    (
        in_plan_master_id,
        in_slt_user_id,
        in_whatsapp_no_max_count,
        in_group_no_max_count,
        in_message_limit,
        'N',
        CURRENT_TIMESTAMP
    );

-- Insert into payment_history_log
INSERT INTO
    payment_history_log (
        user_id,
        user_plans_id,
        plan_master_id,
        plan_amount,
        payment_status,
        plan_comments,
        payment_status,
        payment_entdate
    )
VALUES
    (
        in_slt_user_id,
        LAST_INSERT_ID(),
        in_plan_master_id,
        in_plan_amount,
        'W',
        in_plan_comments,
        'Y',
        CURRENT_TIMESTAMP
    );

-- Get the last inserted ID
SET
    @last_inserted_ids = LAST_INSERT_ID();

IF (@last_inserted_ids > 0) THEN  -- @last_inserted_ids IF START
SELECT
    'Success.';

END IF;  -- @last_inserted_ids IF END
 -- @user_plans_id ELSE END
END IF; -- @user_plans_id TOTAL IF ELSE END
-- 
-- ELSE BEGIN
-- UPDATE
--     api_log
-- SET
--     response_status = 'F',
--     response_date = CURRENT_TIMESTAMP,
--     response_comments = 'Invalid Plan'
-- WHERE
--     request_id = '${req.body.request_id}'
--     AND response_status = 'N' SIGNAL SQLSTATE '45000'
-- SET
--     MESSAGE_TEXT = 'Invalid Plan.';
-- END
-- END IF;
END //

DELIMITER ;