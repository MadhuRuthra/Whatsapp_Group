DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertPaymentPlans`(IN `p_plan_master_id` INT, IN `p_slt_user_id` INT, IN `p_whatsapp_no_max_count` INT, IN `p_group_no_max_count` INT, IN `p_message_limit` INT, IN `p_plan_amount` DECIMAL(10,2), IN `p_plan_comments` VARCHAR(255))
BEGIN
  DECLARE last_inserted_id INT;

  -- Insert into plans_update table
  INSERT INTO plans_update
    VALUES (
      NULL,
      p_plan_master_id,
      p_slt_user_id,
      p_whatsapp_no_max_count,
      0,
      0,
      p_group_no_max_count,
      0,
      0,
      p_message_limit,
      0,
      0,
      'N',
      CURRENT_TIMESTAMP,
      NULL
    );

  -- Insert into payment_history_log table
  INSERT INTO payment_history_log
    VALUES (
      NULL,
      p_slt_user_id,
      in_user_plans_id,
      p_plan_master_id,
      p_plan_amount,
      'W',
      p_plan_comments,
      'Y',
      CURRENT_TIMESTAMP
    );
    
    SET
    last_inserted_id = LAST_INSERT_ID();

IF (last_inserted_id > 0) THEN   -- (last_inserted_id IF START)
SELECT
    'Success.';
 -- (last_inserted_id IF END )
END IF;  
END$$
DELIMITER ;