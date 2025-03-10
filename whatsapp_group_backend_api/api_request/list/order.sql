DELIMITER //

CREATE PROCEDURE TEST(
    IN in_slt_user_id INT,
    IN in_plan_master_id INT,
    IN in_whatsapp_no_max_count INT,
    IN in_group_no_max_count INT,
    IN in_message_limit INT,
    IN in_plan_amount INT,
    IN in_plan_comments VARCHAR(255),
    IN in_plan_reference_id VARCHAR(255),
    IN in_current_timestamp DATETIME,
    IN in_request_id VARCHAR(30)
)
BEGIN
    DECLARE plan_title VARCHAR(255);
    DECLARE user_plans_id INT;
    DECLARE array_plan_master_id VARCHAR(255);
    DECLARE last_inserted_id INT;

    -- Get plan details from plan_master
    SELECT plan_title
    INTO plan_title
    FROM plan_master
    WHERE plan_master_id = in_plan_master_id AND plan_status = 'Y';

    -- Check if the user already has plans
    SELECT user_plans_id, plan_master_id
    INTO @user_plans_id, array_plan_master_id
    FROM user_plans
    WHERE user_id = in_slt_user_id;

    IF @user_plans_id IS NOT NULL THEN
        -- User has existing plans
        -- Check if the plan to be purchased is already active
        SELECT plan_expiry_date
        INTO @plan_expiry_date
        FROM user_plans
        WHERE user_id = in_slt_user_id AND plan_master_id = in_plan_master_id;

        IF @plan_expiry_date IS NOT NULL THEN
            -- Subtract 7 days from plan_expiry_date
            SET @seven_days_before = DATE_SUB(@plan_expiry_date, INTERVAL 7 DAY);

            IF @seven_days_before >= in_current_timestamp THEN
                -- Plan is still active, return an error or take necessary action
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Plan is already active. Cannot purchase the same plan again.';
            ELSE
                -- RENEW PLAN
              
        Select COUNT(*) INTO @get_plan_status from user_plans WHERE plan_master_id = in_plan_master_id and user_id = in_slt_user_id;

         IF (@get_plan_status > 0) THEN

         UPDATE user_plans SET payment_status = 'N' WHERE user_plans_id = @user_plans_id;
         UPDATE payment_history_log SET payment_status = 'N' WHERE user_plans_id = @user_plans_id ;
         UPDATE plans_update SET plan_status = 'N' WHERE user_id = slt_user_id and plan_master_id = in_plan_master_id;

         INSERT INTO plans_update VALUES(NULL,in_plan_master_id,slt_user_id,in_whatsapp_no_max_count,'0','0',in_group_no_max_count,'0','0',in_message_limit,'0','0','N',CURRENT_TIMESTAMP,NULL);

         INSERT INTO payment_history_log VALUES(NULL,slt_user_id,in_plan_master_id,@user_plans_id,in_plan_amount,'W',in_plan_comments,'Y',CURRENT_TIMESTAMP);
          -- Get the last inserted ID
        SET last_inserted_id = LAST_INSERT_ID();

        IF (last_inserted_id > 0) THEN
        SELECT 'Success.';
      END IF;
      
    ELSE
      UPDATE api_log SET response_status = 'F', response_date = CURRENT_TIMESTAMP, response_comments = 'Inactive Plan' WHERE request_id = in_request_id AND response_status = 'N'
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Inactive Plan';
      --  renew plan else end
    END IF;
           ELSE IF FIND_IN_SET(in_plan_master_id, array_plan_master_id) > 0 THEN

                UPDATE api_log SET response_status = 'F', response_date = CURRENT_TIMESTAMP, response_comments = 'Already plan is active. Cannot Upgrade' WHERE request_id = in_request_id AND response_status = 'N';
              SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Already plan is active. Cannot Upgrade.';
                
        ELSE
          -------------------UPGRADE PLANS -----------------------------
                   Select COUNT(*) INTO @plans_update from plans_update WHERE plan_master_id = in_plan_master_id and user_id = slt_user_id and plan_status in ('Y') ORDER BY plan_entry_date;

          IF (@plans_update > 0) THEN
          UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Only Upgrade Plan is active.' WHERE request_id = in_request_id AND response_status = 'N';
           SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Only Upgrade Plan is active.';
        ELSE
        INSERT INTO plans_update VALUES(NULL,plan_master_id,slt_user_id,in_whatsapp_no_max_count,'0','0',in_group_no_max_count,'0','0',in_message_limit,'0','0','N',CURRENT_TIMESTAMP,NULL);

        INSERT INTO payment_history_log VALUES(NULL,slt_user_id,@user_plans_id,in_plan_master_id,in_plan_amount,'W',in_plan_comments,'Y',CURRENT_TIMESTAMP)

        -- Get the last inserted ID
        SET last_inserted_ids = LAST_INSERT_ID();

           IF (last_inserted_ids > 0) THEN
     -- Set response variables
      SELECT 'Success.';
     END IF

    END IF;
        END IF;
        END IF;
    ELSE
        -- User does not have existing plans
        -- Purchase the new plan
         INSERT INTO user_plans (user_id, plan_master_id, plan_amount, plan_expiry_date, payment_status, plan_comments, plan_reference_id, user_plans_status, user_plans_entdate)
        VALUES (in_slt_user_id, in_plan_master_id, in_plan_amount, '0000-00-00 00:00:00', 'W', in_plan_comments, in_plan_reference_id, 'W', CURRENT_TIMESTAMP);

        -- Update plans_update table
        INSERT INTO plans_update (plan_master_id, user_id, whatsapp_no_max_count, group_no_max_count, message_limit, plan_status, plan_entry_date)
        VALUES (in_plan_master_id, in_slt_user_id, in_whatsapp_no_max_count, in_group_no_max_count, in_message_limit, 'N', CURRENT_TIMESTAMP);

        -- Insert into payment_history_log
        INSERT INTO payment_history_log (user_id, user_plans_id, plan_master_id, plan_amount, payment_status, plan_comments, payment_status, payment_entdate)
        VALUES (in_slt_user_id, LAST_INSERT_ID(), in_plan_master_id, in_plan_amount, 'W', in_plan_comments, 'Y', CURRENT_TIMESTAMP);
    END IF;
END //

DELIMITER ;