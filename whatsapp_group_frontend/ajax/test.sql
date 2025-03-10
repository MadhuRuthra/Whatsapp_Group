BEGIN
    DECLARE sender_mobiles VARCHAR(255);
    DECLARE sender_no VARCHAR(255); -- Declare sender_no variable
    
    -- Construct dynamic query to get distinct sender mobile numbers
    SET @query = CONCAT(
        'SELECT GROUP_CONCAT(DISTINCT sts.sender_mobile_no) INTO @sender_mobiles
        FROM mobile_marketing_', in_user_id, '.compose_message_', in_user_id, ' cmp
        LEFT JOIN mobile_marketing_', in_user_id, '.compose_msg_status_', in_user_id, ' sts
        ON sts.compose_message_id = cmp.compose_message_id
        WHERE cmp.campaign_name = "', campaign_name, '" AND cmp.cm_status = "P"'
    );
    
    -- Execute the dynamic query to get sender_mobiles
    PREPARE stmt FROM @query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
      -- Construct dynamic query
    SET @querys = '';
    
    -- Loop through user_id values
    WHILE LENGTH(@sender_mobiles) > 0 DO
        -- Get the first user_id from the list
        SET sender_no = SUBSTRING_INDEX(@sender_mobiles, ',', 1);
        -- Remove the processed user_id from the list
        SET @sender_mobiles = TRIM(BOTH ',' FROM SUBSTRING(@sender_mobiles, LENGTH(sender_no) + 2));


  SET @querys = CONCAT(@querys,
            'SELECT sender_id, send.user_id, usr.user_name, send.mobile_no, send.sender_id_status, 
            DATE_FORMAT(send.sender_id_entry_date, "%d-%m-%Y %H:%i:%s") AS sender_id_entdate, send.is_qr_code 
            FROM sender_id_master send 
            LEFT JOIN user_management usr ON usr.user_id = send.user_id 
            WHERE send.sender_id_status = "P" 
            AND send.is_qr_code = "N" 
            AND send.mobile_no = "', sender_no, '"'
        );

        -- If there are more user IDs, add UNION
        IF LENGTH(@sender_mobiles) > 0 THEN
            SET @querys = CONCAT(@querys, ' UNION ALL ');
        END IF;
    END WHILE;

    -- If the user_id length is zero, add ORDER BY
    IF LENGTH(@sender_mobiles) = 0 THEN
        SET @querys = CONCAT(@querys, ' ORDER BY sender_id DESC');
    END IF;

    -- Print or log the final query for debugging
  -- SELECT @querys AS debug_query;

    -- Execute the final query
    PREPARE final_stmt FROM @querys;
    EXECUTE final_stmt;
    DEALLOCATE PREPARE final_stmt;
END