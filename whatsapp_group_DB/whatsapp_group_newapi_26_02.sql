-- phpMyAdmin SQL Dump
-- version 4.4.15.10
-- https://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Feb 27, 2024 at 04:38 AM
-- Server version: 8.0.27
-- PHP Version: 7.4.27

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `whatsapp_group_newapi`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteSenderId`(IN `in_user_id` INT, IN `in_sender_id` INT)
    NO SQL
BEGIN
    DECLARE sender_count INT;

    -- Check if the sender ID exists for the specified user
    SELECT COUNT(*) INTO sender_count
    FROM senderid_master sndr
    LEFT JOIN user_management usr ON usr.user_id = sndr.user_id
    WHERE (sndr.user_id = in_user_id OR usr.parent_id = in_user_id)
        AND sndr.sender_master_id = in_sender_id
        AND sndr.senderid_master_status != 'D';

    IF sender_count = 0 THEN
        -- Sender ID not found
        SELECT 0 AS response_code, 201 AS response_status, 'Sender ID not found.' AS response_msg;
    ELSE
        -- Mark the sender ID as deleted
        UPDATE senderid_master
        SET senderid_master_status = 'D'
        WHERE sender_master_id = in_sender_id
            AND senderid_master_status != 'D';

        SELECT 1 AS response_code, 200 AS response_status, 'Success' AS response_msg;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetPlanDetails`(IN `in_user_id` INT)
BEGIN
    -- Declare variables
    DECLARE user_id INT;
    
    -- Set user_id variable
    SET user_id = in_user_id;

    -- Get all plans
    SELECT
        plan_master_id,
        plan_title,
        CASE
            WHEN annual_monthly = 'A' THEN 'Annually'
            WHEN annual_monthly = 'M' THEN 'Monthly'
            ELSE 'Monthly'
        END AS annual_monthly,
        whatsapp_no_max_count,
        group_no_max_count,
        message_limit,
        plan_price,
        plan_status,
        DATE_FORMAT(plan_entry_date, '%d-%m-%Y %H:%i:%s') AS plan_entry_date
    FROM plan_master
    WHERE plan_status = 'Y';

    -- Get available plans for the given user
    SELECT DISTINCT plan_master_id, plan_expiry_date, user_id
    FROM plans_update
    WHERE user_id = in_user_id AND plan_status = 'Y'
    ORDER BY plans_update_id DESC;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertPaymentPlans`(IN `p_plan_master_id` INT, IN `p_slt_user_id` INT, IN `p_whatsapp_no_max_count` INT, IN `p_group_no_max_count` INT, IN `p_message_limit` INT, IN `p_plan_amount` DECIMAL(10,2), IN `p_plan_comments` VARCHAR(255), IN `in_user_plans_id` INT)
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `LoginProcedure`(IN `p_txt_username` VARCHAR(255), IN `p_txt_password` VARCHAR(255), IN `p_request_id` VARCHAR(255), IN `p_bearer_token` VARCHAR(255), IN `p_ip_address` VARCHAR(255), IN `p_request_url` VARCHAR(255))
BEGIN
    DECLARE today_date DATE;
    DECLARE crnt_date TIMESTAMP;
    DECLARE selected_user_id INT;
    DECLARE selected_user_id_2 INT;
    DECLARE selected_user_id_3 INT;
    DECLARE selected_user_id_4 INT;
    DECLARE selected_user_id_5 INT;
    DECLARE user_log_status VARCHAR(255);
    DECLARE login_date DATE;
    DECLARE check_req_id INT;
    DECLARE check_login INT;
     DECLARE usr_master_id INT;
      DECLARE usr_name VARCHAR(25);
      DECLARE usr_status VARCHAR(25);
       DECLARE usr_parent_id INT;
    

    SET today_date = CURDATE();
     SET crnt_date = CURRENT_TIMESTAMP();
     
    -- Insert into api_log
     INSERT INTO api_log
    VALUES (NULL, 0, p_request_url, p_ip_address, p_request_id, 'N', '-', '0000-00-00 00:00:00', 'Y', crnt_date);
   -- Check if request_id already processed
    SELECT COUNT(*) INTO check_req_id FROM api_log WHERE request_id = p_request_id AND response_status != 'N' AND api_log_status = 'Y';
    
    IF (check_req_id > 0) THEN
        -- Request already processed
         SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Request already processed';
  ELSE
        -- Check user status
        SELECT COUNT(*) INTO selected_user_id FROM user_management WHERE (user_email = p_txt_username or user_mobile = p_txt_username) AND usr_mgt_status IN ('N', 'W') ORDER BY user_id ASC LIMIT 1;

        IF (selected_user_id > 0) THEN
            -- Failed [Inactive or Not Approved User]
  SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inactive or Not Approved User. Kindly contact your admin!';

 ELSE
            -- Check if user is valid
            
            SELECT COUNT(*) INTO selected_user_id_2 FROM user_management WHERE (user_email = p_txt_username or user_mobile = p_txt_username) and usr_mgt_status = 'Y' ORDER BY user_id ASC LIMIT 1;
     IF (selected_user_id_2 <= 0) THEN
                -- Failed [Invalid User]
   SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid User. Kindly try again with the valid User!';
  
   ELSE
                -- Check username and password
                SELECT COUNT(*) INTO selected_user_id_3 FROM user_management WHERE (user_email = p_txt_username or user_mobile = p_txt_username) AND login_password = p_txt_password AND usr_mgt_status = 'Y' ORDER BY user_id ASC LIMIT 1;

                IF (selected_user_id_3<=0) THEN
                    -- Failed [Invalid Password]
               SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Password. Kindly try again with the valid details!';
 ELSE
 
 SELECT user_id INTO selected_user_id_4 FROM user_management WHERE (user_email = p_txt_username or user_mobile = p_txt_username) AND login_password = p_txt_password AND usr_mgt_status = 'Y' ORDER BY user_id ASC LIMIT 1;
 
                -- Update user token
                UPDATE user_management SET bearer_token = p_bearer_token WHERE user_id = selected_user_id_4;

                -- Check user login status
                SELECT user_id  INTO selected_user_id_5 FROM user_log WHERE user_id = selected_user_id_4 AND user_log_status = 'I' AND login_date = today_date LIMIT 1;

                IF (selected_user_id_5 = 0) THEN
                    -- Insert user log
                    INSERT INTO user_log VALUES (NULL, selected_user_id_4, p_ip_address, crnt_date, crnt_date, NULL, 'I', crnt_date);
  
   SELECT user_master_id,parent_id,user_name,usr_mgt_status INTO usr_master_id,usr_parent_id,usr_name,usr_status FROM user_management WHERE (user_email = p_txt_username or user_mobile = p_txt_username) AND login_password = p_txt_password AND usr_mgt_status = 'Y'  ORDER BY user_id ASC LIMIT 1;
   
                    SELECT 'Success' AS response_msg , p_bearer_token AS bearer_token, selected_user_id_4 AS user_id,usr_master_id AS user_master_id,usr_parent_id AS parent_id,usr_name AS user_name,usr_status AS usr_mgt_status;
       ELSE
                    -- Update user log
                    UPDATE user_log SET user_log_status = 'O', logout_time = crnt_date WHERE user_id = selected_user_id_4 AND user_log_status = 'I' AND login_date = today_date;

                    -- Insert user log
                    INSERT INTO user_log VALUES (NULL, selected_user_id_4, p_ip_address, crnt_date, crnt_date, NULL, 'I', crnt_date);
                    SELECT user_master_id,parent_id,user_name,usr_mgt_status INTO usr_master_id,usr_parent_id,usr_name,usr_status FROM user_management WHERE (user_email = p_txt_username or user_mobile = p_txt_username) AND login_password = p_txt_password AND usr_mgt_status = 'Y' ORDER BY user_id ASC LIMIT 1;
                    
                    SELECT 'Success' AS response_msg , p_bearer_token AS bearer_token, selected_user_id_4 AS user_id,usr_master_id AS user_master_id,usr_parent_id AS parent_id,usr_name AS user_name,usr_status AS usr_mgt_status;           

END IF;                  
END IF;
END IF;
END IF;
END IF;   
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `LogoutProcedure`(IN `in_user_id` INT)
    NO SQL
BEGIN
    DECLARE today_date VARCHAR(10);
    DECLARE user_log_length INT;

    -- Get today's date
    SET today_date = DATE_FORMAT(CURRENT_DATE, '%Y-%m-%d');

    -- Check user log
    SELECT COUNT(*) INTO user_log_length
    FROM user_log
    WHERE user_id = in_user_id
      AND login_date = today_date
      AND user_log_status = 'I';

    -- Update token
    UPDATE user_management
    SET bearer_token = '-'
    WHERE user_id = in_user_id
      AND usr_mgt_status = 'Y';

    IF user_log_length > 0 THEN
        -- Update logout
        UPDATE user_log
        SET logout_time = CURRENT_TIMESTAMP,
            user_log_status = 'O'
        WHERE user_id = in_user_id
          AND login_date = today_date
          AND user_log_status = 'I';

        -- Return success
        SELECT 1 AS response_code, 200 AS response_status, 'Success' AS response_msg;
    ELSE
        -- Return success
        SELECT 1 AS response_code, 200 AS response_status, 'Success' AS response_msg;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `PaymentHistoryList`(IN `in_user_id` INT)
BEGIN
    -- Declare variables
    DECLARE getuserid INT;
    DECLARE condition_add VARCHAR(255);

    -- Get the count
    SELECT COUNT(*) INTO getuserid FROM user_management WHERE parent_id = in_user_id;

    -- Set condition based on the count
    IF (getuserid > 0) THEN
        SET condition_add = CONCAT('AND usr.parent_id = ', in_user_id);
    ELSE
        SET condition_add = CONCAT('AND usr.user_id = ', in_user_id);
    END IF;

    -- Dynamic SQL query
    SET @sql_query = CONCAT('
        Select Distinct usr.user_name,usr.user_email, plnmas.plan_title,phl.user_id,phl.plan_master_id,phl.plan_amount,phl.plan_comments,phl.payment_status,phl.payment_history_log_date,phl.payment_history_logstatus,phl.payment_history_logid
    from payment_history_log phl 
         LEFT JOIN user_management usr ON phl.user_id = usr.user_id
         LEFT JOIN plan_master plnmas ON plnmas.plan_master_id = phl.plan_master_id
         WHERE usr.usr_mgt_status = "Y" ', condition_add, '
        ORDER by phl.payment_history_logid Desc');

    -- Prepare and execute the dynamic SQL query
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `PricingPlanList`(IN `in_user_id` INT)
BEGIN
    -- Declare variables
    DECLARE getuserid INT;
    DECLARE condition_add VARCHAR(255);

    -- Get the count
    SELECT COUNT(*) INTO getuserid FROM user_management WHERE parent_id = in_user_id;

    -- Set condition based on the count
    IF (getuserid > 0) THEN
        SET condition_add = CONCAT('AND usr.parent_id = ', in_user_id);
    ELSE
        SET condition_add = CONCAT('AND usr.user_id = ', in_user_id);
    END IF;

    -- Dynamic SQL query
    SET @sql_query = CONCAT('
        SELECT DISTINCT usr.user_id, max(user_plans_id) mx_user_plans_id, plnmas.whatsapp_no_max_count, plnmas.message_limit, usr.user_name, plan.user_id, plan.plan_master_id,
        plnmas.group_no_max_count, plnmas.plan_title, plan.plan_amount, plan.plan_expiry_date, plan.payment_status, plan.plan_comments, plan.plan_reference_id,
        plan.user_plans_status, plan.user_plans_entdate,
        CASE
            WHEN annual_monthly = ''A'' THEN ''Annually''
            WHEN annual_monthly = ''M'' THEN ''Monthly''
            ELSE ''Monthly''
        END AS annual_monthly
        FROM user_management usr
        LEFT JOIN user_plans plan ON plan.user_id = usr.user_id
        LEFT JOIN plan_master plnmas ON plnmas.plan_master_id = plan.plan_master_id
        WHERE usr.usr_mgt_status = ''Y'' AND plan.user_plans_status = ''A'' ', condition_add, '
        GROUP BY usr.user_id
        ORDER BY plan.user_plans_entdate DESC');

    -- Prepare and execute the dynamic SQL query
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Purchase_plans`(IN `p_slt_user_id` INT, IN `p_plan_master_id` INT, IN `p_whatsapp_no_max_count` INT, IN `p_group_no_max_count` INT, IN `p_message_limit` INT, IN `p_plan_amount` DECIMAL(10,2), IN `p_plan_comments` VARCHAR(255), IN `p_plan_reference_id` VARCHAR(255))
BEGIN
  DECLARE v_user_plans_id INT;
  DECLARE last_inserted_id INT;

  -- Insert into user_plans table
  INSERT INTO user_plans
    VALUES (
      NULL,
      p_slt_user_id,
      p_plan_master_id,
      p_plan_amount,
      '0000-00-00 00:00:00',
      'W',
      p_plan_comments,
      p_plan_reference_id,
      'W',
      CURRENT_TIMESTAMP
    );

  -- Get the last inserted user_plans_id
  SELECT LAST_INSERT_ID() INTO v_user_plans_id;

  -- Insert into plans_update table
  INSERT INTO plans_update
    VALUES (
      NULL,
      p_plan_master_id,
      p_slt_user_id,
      p_whatsapp_no_max_count,
      p_whatsapp_no_max_count,
      0,
      p_group_no_max_count,
      p_group_no_max_count,
      0,
      p_message_limit,
      p_message_limit,
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
      v_user_plans_id,
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `SenderIdList`(IN `in_user_id` INT)
    NO SQL
SELECT sndr.sender_master_id,sndr.user_id,usr.user_name,sndr.profile_name,sndr.profile_image, sndr.mobile_no, CASE
    WHEN sndr.senderid_master_status = 'Y' THEN 'Active'
    WHEN sndr.senderid_master_status = 'X' THEN 'Unlinked'
    WHEN sndr.senderid_master_status = 'L' THEN 'Linked'
    WHEN sndr.senderid_master_status = 'B' THEN 'Blocked'
    WHEN sndr.senderid_master_status = 'D' THEN 'Deleted'
    ELSE 'Inactive' END AS senderid_status, sndr.senderid_master_status,DATE_FORMAT(sndr.senderid_master_entdate,'%d-%m-%Y %H:%i:%s') senderid_master_entdate
     FROM senderid_master sndr left join user_management usr on usr.user_id = sndr.user_id where (sndr.user_id = in_user_id or usr.parent_id = in_user_id) ORDER BY sender_master_id DESC$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SignUpProcedure`(IN `in_user_type` VARCHAR(255), IN `in_user_email` VARCHAR(255), IN `in_user_password` VARCHAR(255), IN `in_user_mobile` VARCHAR(255), IN `in_parent_id` VARCHAR(255), IN `in_user_name` VARCHAR(255))
BEGIN
    DECLARE apikey VARCHAR(15);
    DECLARE lastid INT;
    DECLARE db_name VARCHAR(255);
    DECLARE create_db_query VARCHAR(255);

    -- Check if login_id or user_email already exists
    IF (
        SELECT COUNT(*)
        FROM user_management
        WHERE (user_email = in_user_email OR user_mobile = in_user_mobile) AND usr_mgt_status = 'Y'
    ) > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Mobile number / Email already used. Kindly try with some others!!';
    ELSE
        -- Continue with the signup process
        -- Generate the apikey
        SET apikey = '';
        SET @characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        SET @length = 15;

        WHILE LENGTH(apikey) < @length DO
            SET apikey = CONCAT(apikey, SUBSTRING(@characters, FLOOR(1 + RAND() * LENGTH(@characters)), 1));
        END WHILE;

        INSERT INTO user_management
        VALUES (
            NULL, in_user_type, in_parent_id, in_user_name, apikey, in_user_password, in_user_email, in_user_mobile, 'Y', CURRENT_TIMESTAMP, '-'
        );

        -- Get the last inserted user id
        SET lastid = LAST_INSERT_ID();

        -- Create new database for the user
        SET db_name = CONCAT('whatsapp_group_newapi_', lastid);
        SET @create_db_query = CONCAT('CREATE DATABASE IF NOT EXISTS ', db_name, ' DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci');
        PREPARE stmt FROM @create_db_query;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        -- Create tables in the new database
        SET @create_table_query1 = CONCAT(
            'CREATE TABLE IF NOT EXISTS ', db_name, '.compose_message_', lastid,
            ' (compose_message_id INT NOT NULL AUTO_INCREMENT, user_id INT NOT NULL,',
            ' sender_master_id int NOT NULL, group_master_id int NOT NULL,',
            ' message_type varchar(10) NOT NULL, campaign_name varchar(30) NOT NULL,',
            ' cm_status char(1) NOT NULL, cm_entry_date timestamp NOT NULL DEFAULT "0000-00-00 00:00:00",',
            ' INDEX (compose_message_id), INDEX (user_id),',
            ' PRIMARY KEY (compose_message_id),',
            ' KEY sender_master_id (sender_master_id), KEY group_master_id (group_master_id))',
            ' ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT'
        );
        PREPARE stmt FROM @create_table_query1;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET @create_table_query2 = CONCAT(
            'CREATE TABLE IF NOT EXISTS ', db_name, '.compose_msg_media_', lastid,
            ' (compose_msg_media_id int NOT NULL AUTO_INCREMENT,',
            ' compose_message_id int NOT NULL,',
            ' text_title varchar(2000) DEFAULT NULL,',
            ' text_reply varchar(50) DEFAULT NULL,',
            ' text_number varchar(15) DEFAULT NULL,',
            ' text_url varchar(100) DEFAULT NULL,',
            ' text_address varchar(100) DEFAULT NULL,',
            ' media_url varchar(100) DEFAULT NULL,',
            ' media_type varchar(10) DEFAULT NULL,',
            ' cmm_status char(1) NOT NULL,',
            ' cmm_entry_date timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,',
            ' PRIMARY KEY (compose_msg_media_id),',
            ' KEY compose_message_id (compose_message_id))',
            ' ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT'
        );
        PREPARE stmt FROM @create_table_query2;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        -- Return success response
        SELECT 1 AS response_code, 200 AS response_status, 1 AS num_of_rows, 'Success' AS response_msg;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateUserPurchase`(IN `in_user_id` INT, IN `in_user_plans_id` INT, IN `in_payment_status` VARCHAR(1), IN `in_plan_comments` VARCHAR(300), IN `in_user_plan_status` VARCHAR(1), IN `in_plan_master_id` INT)
BEGIN
    -- Declare variables
    DECLARE plan_ex_date DATETIME;
    DECLARE currentDate DATETIME;

    -- Get plan details from plan_master
    SELECT annual_monthly,plan_price INTO @annual_monthly,@plan_amount
    FROM plan_master
    WHERE plan_master_id = in_plan_master_id AND plan_status = 'Y';

    -- Calculate plan expiry date
    SET currentDate = NOW();
    IF (@annual_monthly = 'M') THEN
        SET currentDate = DATE_ADD(currentDate, INTERVAL 1 MONTH);
    ELSE
        SET currentDate = DATE_ADD(currentDate, INTERVAL 12 MONTH);
    END IF;

    SET plan_ex_date = currentDate;

    -- Update user_plans table
    UPDATE user_plans
    SET
        payment_status = in_payment_status,
        plan_comments = in_plan_comments,
        user_plans_status = in_user_plan_status,
        plan_expiry_date = plan_ex_date,
        plan_amount = @plan_amount,
        plan_reference_id = '-',
        plan_master_id = in_plan_master_id
    WHERE user_plans_id = in_user_plans_id;

    -- Update payment_history_log table
    UPDATE payment_history_log
    SET
        payment_status = in_payment_status,
        plan_comments = in_plan_comments
    WHERE user_plans_id = in_user_plans_id;
    
       -- before status is inactive
 UPDATE payment_history_log 
SET payment_status = 'N' 
WHERE NOT (plan_master_id = in_plan_master_id);

    -- Update plans_update table
    UPDATE plans_update
    SET
        plan_status = 'Y',
        plan_expiry_date = plan_ex_date
    WHERE user_id = in_user_id AND plan_master_id = in_plan_master_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_api_log`(IN `in_originalUrl` VARCHAR(255), IN `ip_address` VARCHAR(255), IN `in_request_id` VARCHAR(255), IN `bearerHeader` VARCHAR(255), IN `in_user_id` INT)
    NO SQL
BEGIN
    DECLARE Error_message VARCHAR(255);

    BEGIN
        DECLARE error_msg TEXT;
        GET DIAGNOSTICS CONDITION 1 error_msg = MESSAGE_TEXT;

        -- Check for fatal errors and decide whether to rollback
        IF POSITION('fatal' IN error_msg) > 0 THEN
            ROLLBACK;
        END IF;

        -- SELECT CONCAT('error: ', error_msg) AS response_msg;
    END;

    START TRANSACTION; 

    -- Insert statement when count is 0
    INSERT INTO api_log (
        api_log_id, user_id, api_url, ip_address, request_id, response_status, response_comments, api_log_status, api_log_entry_date
    ) VALUES (
        NULL, 00, in_originalUrl, ip_address, in_request_id, 'N', '-', 'Y', CURRENT_TIMESTAMP
    );

    SET @new_api = CONCAT(
        'SELECT COUNT(*) INTO @new_log FROM api_log WHERE request_id = "', in_request_id,
        '" AND response_status != "N" AND api_log_status="Y"'
    );

    PREPARE stmt FROM @new_api;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    IF @new_log != 0 THEN
        UPDATE api_log SET
            response_status = 'F',
            response_date = CURRENT_TIMESTAMP,
            response_comments = 'Request already processed'
        WHERE request_id = in_request_id AND response_status = 'N';

        -- Failed [Request already processed]
        SELECT 'Request already processed' AS response_msg, 'Status' AS Status;
    END IF;

    IF LENGTH(bearerHeader) > 0 THEN
        -- Construct dynamic query
        SET @check_bearer = CONCAT(
            'SELECT COALESCE(user_id) INTO @result_user_id FROM user_management WHERE bearer_token = "',
            bearerHeader, '" AND usr_mgt_status = "Y"'
        );

        SET Error_message = 'Invalid token';

        IF LENGTH(in_user_id) > 0 THEN
            SET @check_bearer = CONCAT(@check_bearer, ' AND user_id = ', in_user_id);
            SET Error_message = 'Invalid token or User ID';
        END IF;

        -- SELECT @check_bearer;

        PREPARE stmt FROM @check_bearer;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        IF @result_user_id IS NULL THEN
            -- Failed [Invalid token or User ID]
            UPDATE api_log SET
                response_status = 'F',
                response_date = CURRENT_TIMESTAMP,
                response_comments = Error_message
            WHERE request_id = in_request_id AND response_status = 'N';

            -- Failed [Invalid token or User ID]
            SELECT Error_message AS response_msg, 'Failed' AS Failed;
        ELSE
            UPDATE api_log SET user_id = @result_user_id WHERE request_id = in_request_id AND response_status = 'N';
            SELECT @result_user_id AS response_user_id, 'success' AS Success;
        END IF;
    ELSE
        UPDATE api_log SET
            response_status = 'F',
            response_date = CURRENT_TIMESTAMP,
            response_comments = 'Token is required'
        WHERE request_id = in_request_id AND response_status = 'N';

        -- Failed [Token is required]
        SELECT 'Token is required' AS response_msg, 'failed' AS Failed;
    END IF;

    COMMIT;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `api_log`
--

CREATE TABLE IF NOT EXISTS `api_log` (
  `api_log_id` int NOT NULL,
  `user_id` int NOT NULL,
  `api_url` varchar(50) NOT NULL,
  `ip_address` varchar(50) NOT NULL,
  `request_id` varchar(30) NOT NULL,
  `response_status` char(1) DEFAULT NULL,
  `response_comments` varchar(100) DEFAULT NULL,
  `response_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `api_log_status` char(1) NOT NULL,
  `api_log_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB AUTO_INCREMENT=487 DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `api_log`
--

INSERT INTO `api_log` (`api_log_id`, `user_id`, `api_url`, `ip_address`, `request_id`, `response_status`, `response_comments`, `response_date`, `api_log_status`, `api_log_entry_date`) VALUES
(1, 0, '/login', 'undefined', '79953648_56866176', 'S', 'Success', '2024-01-05 05:06:50', 'Y', '2024-01-05 05:06:50'),
(4, 0, '/logout', 'undefined', '1_20244104312_7682', 'F', 'Error occurred', '2024-01-05 05:13:12', 'Y', '2024-01-05 05:13:12'),
(5, 0, '/login', 'undefined', '56415304_59253239', 'S', 'Success', '2024-01-05 05:13:33', 'Y', '2024-01-05 05:13:33'),
(6, 0, '/password/change_password', 'undefined', '1_20244104656_5299', 'F', 'Error occurred', '2024-01-05 05:16:56', 'Y', '2024-01-05 05:16:56'),
(7, 0, '/password/change_password', 'undefined', '1_20244105605_7327', 'F', 'Error occurred', '2024-01-05 05:26:05', 'Y', '2024-01-05 05:26:05'),
(8, 1, '/password/change_password', 'undefined', '1_20244105751_5909', 'S', 'Success', '2024-01-05 05:27:52', 'Y', '2024-01-05 05:27:52'),
(9, 0, '/login', 'undefined', '98135357_93915107', 'F', 'Invalid Password. Kindly try again with the valid details!', '2024-01-05 05:29:00', 'Y', '2024-01-05 05:29:00'),
(10, 0, '/login', 'undefined', '90614744_61239920', 'F', 'Invalid Password. Kindly try again with the valid details!', '2024-01-05 05:29:06', 'Y', '2024-01-05 05:29:06'),
(11, 0, '/login', 'undefined', '59458817_12056742', 'S', 'Success', '2024-01-05 05:29:13', 'Y', '2024-01-05 05:29:12'),
(12, 1, '/password/change_password', 'undefined', '1_20244110009_2463', 'S', 'Success', '2024-01-05 05:30:09', 'Y', '2024-01-05 05:30:09'),
(13, 0, '/login', 'undefined', '85636682_20137936', 'S', 'Success', '2024-01-05 05:30:19', 'Y', '2024-01-05 05:30:19'),
(14, 1, '/logout', 'undefined', '1_20244111632_9251', 'S', 'Success', '2024-01-05 05:46:32', 'Y', '2024-01-05 05:46:32'),
(15, 0, '/login', 'undefined', '15187852_59685803', 'F', 'Invalid Password. Kindly try again with the valid details!', '2024-01-05 05:57:54', 'Y', '2024-01-05 05:57:54'),
(16, 0, '/login', 'undefined', '28537069_70536273', 'S', 'Success', '2024-01-05 05:58:00', 'Y', '2024-01-05 05:57:59'),
(17, 1, '/logout', 'undefined', '1_20244112825_3384', 'S', 'Success', '2024-01-05 05:58:25', 'Y', '2024-01-05 05:58:25'),
(18, 0, '/login', 'undefined', '11192417_15866787', 'S', 'Success', '2024-01-05 06:04:32', 'Y', '2024-01-05 06:04:32'),
(19, 1, '/logout', 'undefined', '1_20244113438_5370', 'S', 'Success', '2024-01-05 06:04:39', 'Y', '2024-01-05 06:04:38'),
(20, 0, '/login', 'undefined', '87644192_92502592', 'S', 'Success', '2024-01-05 06:05:10', 'Y', '2024-01-05 06:05:10'),
(21, 1, '/logout', 'undefined', 'djnjd', 'S', 'Success', '2024-01-05 06:07:18', 'Y', '2024-01-05 06:07:17'),
(22, 0, '/logout', 'undefined', '1_20244113924_9814', 'F', 'Invalid token', '2024-01-05 06:09:24', 'Y', '2024-01-05 06:09:24'),
(23, 0, '/login', 'undefined', '87518329_89156009', 'S', 'Success', '2024-01-05 06:09:36', 'Y', '2024-01-05 06:09:36'),
(24, 1, '/logout', 'undefined', 'djjbnjd', 'S', 'Success', '2024-01-05 06:10:15', 'Y', '2024-01-05 06:10:15'),
(25, 1, '/logout', 'undefined', '1_20244114053_2008', 'S', 'Success', '2024-01-05 06:10:53', 'Y', '2024-01-05 06:10:53'),
(26, 0, '/password/forgot_password', 'undefined', '36195852_64725039', 'F', 'Token is required', '2024-01-05 06:32:10', 'Y', '2024-01-05 06:32:10'),
(27, 0, '/login', 'undefined', '19661996_43598059', 'F', 'Invalid Password. Kindly try again with the valid details!', '2024-01-05 09:31:44', 'Y', '2024-01-05 09:31:44'),
(28, 0, '/login', 'undefined', '76978807_91936022', 'F', 'Invalid User. Kindly try again with the valid User!', '2024-01-05 09:32:15', 'Y', '2024-01-05 09:32:14'),
(29, 0, '/login', 'undefined', '17253266_28865945', 'F', 'Invalid Password. Kindly try again with the valid details!', '2024-01-05 10:53:47', 'Y', '2024-01-05 10:53:47'),
(30, 0, '/login', 'undefined', '56564470_33305349', 'F', 'Invalid Password. Kindly try again with the valid details!', '2024-01-05 10:54:52', 'Y', '2024-01-05 10:54:51'),
(31, 0, '/login', 'undefined', '91509930_14764253', 'S', 'Success', '2024-01-05 10:54:58', 'Y', '2024-01-05 10:54:58'),
(32, 1, '/sender_id/delete_sender_id', 'undefined', '1_20244162554_5658', 'S', 'Success', '2024-01-05 10:55:54', 'Y', '2024-01-05 10:55:54'),
(33, 1, '/sender_id/delete_sender_id', 'undefined', '1_20244162554_5316', 'F', 'Sender ID not found.', '2024-01-05 10:55:54', 'Y', '2024-01-05 10:55:54'),
(34, 1, '/sender_id/delete_sender_id', 'undefined', '1_20244162555_3067', 'S', 'Success', '2024-01-05 10:55:55', 'Y', '2024-01-05 10:55:55'),
(35, 1, '/sender_id/delete_sender_id', 'undefined', '1_20244162555_1120', 'F', 'Sender ID not found.', '2024-01-05 10:55:55', 'Y', '2024-01-05 10:55:55'),
(36, 1, '/logout', 'undefined', '1_20244162739_2136', 'S', 'Success', '2024-01-05 10:57:39', 'Y', '2024-01-05 10:57:39'),
(37, 0, '/login', 'undefined', '47368595_48073722', 'S', 'Success', '2024-01-05 10:58:38', 'Y', '2024-01-05 10:58:37'),
(38, 1, '/group/add_members', 'undefined', '1_20244162943_3390', 'F', 'Sender ID unlinked', '2024-01-05 11:01:45', 'Y', '2024-01-05 10:59:43'),
(39, 1, '/logout', 'undefined', '1_20244163317_7626', 'S', 'Success', '2024-01-05 11:03:17', 'Y', '2024-01-05 11:03:17'),
(40, 0, '/login', 'undefined', '37094079_32111849', 'S', 'Success', '2024-01-05 11:03:33', 'Y', '2024-01-05 11:03:33'),
(41, 1, '/logout', 'undefined', '1_20244163338_1290', 'S', 'Success', '2024-01-05 11:03:38', 'Y', '2024-01-05 11:03:38'),
(42, 0, '/login', 'undefined', '73996394_43963897', 'S', 'Success', '2024-01-05 11:09:11', 'Y', '2024-01-05 11:09:11'),
(43, 1, '/logout', 'undefined', '1_20244163916_4288', 'S', 'Success', '2024-01-05 11:09:16', 'Y', '2024-01-05 11:09:16'),
(44, 0, '/login', 'undefined', '40064922_52884021', 'F', 'Invalid Password. Kindly try again with the valid details!', '2024-01-05 11:10:55', 'Y', '2024-01-05 11:10:55'),
(45, 0, '/login', 'undefined', '34988914_60365323', 'S', 'Success', '2024-01-05 11:27:51', 'Y', '2024-01-05 11:27:50'),
(46, 1, '/logout', 'undefined', '1_20244165755_1248', 'S', 'Success', '2024-01-05 11:27:55', 'Y', '2024-01-05 11:27:55'),
(47, 0, '/login', 'undefined', '92305354_91571497', 'F', 'Invalid Password. Kindly try again with the valid details!', '2024-01-05 11:28:09', 'Y', '2024-01-05 11:28:09'),
(48, 0, '/login', 'undefined', '30952594_86524572', 'S', 'Success', '2024-01-05 11:28:15', 'Y', '2024-01-05 11:28:15'),
(49, 1, '/logout', 'undefined', '1_20244165821_7403', 'S', 'Success', '2024-01-05 11:28:22', 'Y', '2024-01-05 11:28:21'),
(50, 0, '/login', 'undefined', '12161448_58265719', 'S', 'Success', '2024-01-05 12:11:48', 'Y', '2024-01-05 12:11:48'),
(51, 1, '/sender_id/delete_sender_id', 'undefined', '1_20244185847_4965', 'S', 'Success', '2024-01-05 13:28:47', 'Y', '2024-01-05 13:28:47'),
(52, 1, '/sender_id/add_sender_id', 'undefined', '1_20245073019_7549', 'S', 'Success', '2024-01-06 02:00:29', 'Y', '2024-01-06 02:00:19'),
(53, 1, '/sender_id/add_sender_id', 'undefined', '1_20245073219_9520', 'F', 'Mobile number already exists', '2024-01-06 02:02:19', 'Y', '2024-01-06 02:02:19'),
(54, 1, '/logout', 'undefined', '1_20245074448_9848', 'S', 'Success', '2024-01-06 02:14:49', 'Y', '2024-01-06 02:14:48'),
(55, 0, '/login', 'undefined', '68030081_95726772', 'S', 'Success', '2024-01-06 02:15:05', 'Y', '2024-01-06 02:15:05'),
(56, 2, '/sender_id/add_sender_id', 'undefined', '2_20245075409_8556', 'F', 'Mobile number already exists', '2024-01-06 02:24:10', 'Y', '2024-01-06 02:24:10'),
(57, 2, '/sender_id/add_sender_id', 'undefined', '2_20245075507_9398', 'S', 'Success', '2024-01-06 02:25:18', 'Y', '2024-01-06 02:25:07'),
(58, 2, '/sender_id/add_sender_id', 'undefined', '2_20245075707_1022', 'S', 'Success', '2024-01-06 02:27:18', 'Y', '2024-01-06 02:27:07'),
(59, 0, '/plan/user_plans_purchase', 'undefined', '2_20245120401_3366', 'F', 'Error occurred', '2024-01-06 06:34:01', 'Y', '2024-01-06 06:34:01'),
(60, 0, '/plan/user_plans_purchase', 'undefined', '2_20245120600_7875', 'F', 'Error occurred', '2024-01-06 06:36:00', 'Y', '2024-01-06 06:36:00'),
(61, 0, '/plan/user_plans_purchase', 'undefined', '2_20245121328_9408', 'S', 'Success', '2024-01-06 06:43:28', 'Y', '2024-01-06 06:43:28'),
(62, 2, '/sender_id/add_sender_id', 'undefined', '2_20245152805_4205', 'F', 'Mobile number already exists', '2024-01-06 09:58:05', 'Y', '2024-01-06 09:58:05'),
(63, 2, '/sender_id/add_sender_id', 'undefined', '2_20245153444_3888', 'S', 'Success', '2024-01-06 10:04:59', 'Y', '2024-01-06 10:04:44'),
(64, 2, '/sender_id/add_sender_id', 'undefined', '2_20245153644_4866', 'F', 'QRcode already scanned', '2024-01-06 10:06:45', 'Y', '2024-01-06 10:06:44'),
(65, 2, '/sender_id/add_sender_id', 'undefined', '2_20245164853_3529', 'S', 'Success', '2024-01-06 11:19:05', 'Y', '2024-01-06 11:18:53'),
(66, 2, '/sender_id/add_sender_id', 'undefined', '2_20245165053_2965', 'S', 'Success', '2024-01-06 11:21:04', 'Y', '2024-01-06 11:20:53'),
(67, 2, '/sender_id/add_sender_id', 'undefined', '2_20245170000_8481', 'S', 'Success', '2024-01-06 11:30:11', 'Y', '2024-01-06 11:30:00'),
(68, 2, '/sender_id/add_sender_id', 'undefined', '2_20245172827_6704', 'S', 'Success', '2024-01-06 11:58:38', 'Y', '2024-01-06 11:58:27'),
(69, 2, '/sender_id/add_sender_id', 'undefined', '2_20245172918_4962', 'S', 'Success', '2024-01-06 11:59:28', 'Y', '2024-01-06 11:59:19'),
(70, 2, '/sender_id/add_sender_id', 'undefined', '2_20245173008_3606', 'S', 'Success', '2024-01-06 12:00:19', 'Y', '2024-01-06 12:00:08'),
(71, 2, '/sender_id/add_sender_id', 'undefined', '2_20245173208_4098', 'S', 'Success', '2024-01-06 12:02:20', 'Y', '2024-01-06 12:02:08'),
(72, 2, '/sender_id/add_sender_id', 'undefined', '2_20245173311_2201', 'S', 'Success', '2024-01-06 12:03:21', 'Y', '2024-01-06 12:03:11'),
(73, 2, '/sender_id/add_sender_id', 'undefined', '2_20245182657_7978', 'S', 'Success', '2024-01-06 12:57:08', 'Y', '2024-01-06 12:56:57'),
(74, 2, '/sender_id/add_sender_id', 'undefined', '2_20245183257_7976', 'S', 'Success', '2024-01-06 13:03:07', 'Y', '2024-01-06 13:02:57'),
(75, 2, '/sender_id/add_sender_id', 'undefined', '2_20245183311_1073', 'S', 'Success', '2024-01-06 13:03:21', 'Y', '2024-01-06 13:03:11'),
(76, 2, '/sender_id/add_sender_id', 'undefined', '2_20245183321_9833', 'S', 'Success', '2024-01-06 13:03:34', 'Y', '2024-01-06 13:03:21'),
(77, 2, '/sender_id/add_sender_id', 'undefined', '2_20245183334_5389', 'S', 'Success', '2024-01-06 13:03:46', 'Y', '2024-01-06 13:03:34'),
(78, 2, '/sender_id/add_sender_id', 'undefined', '2_20245183346_9109', 'S', 'Success', '2024-01-06 13:04:00', 'Y', '2024-01-06 13:03:46'),
(79, 2, '/sender_id/add_sender_id', 'undefined', '2_20245183831_7721', 'S', 'Success', '2024-01-06 13:08:41', 'Y', '2024-01-06 13:08:31'),
(80, 2, '/logout', 'undefined', '2_20245184245_7505', 'S', 'Success', '2024-01-06 13:12:46', 'Y', '2024-01-06 13:12:45'),
(81, 0, '/login', 'undefined', '72489989_61943395', 'F', 'Invalid User. Kindly try again with the valid User!', '2024-01-07 13:20:31', 'Y', '2024-01-07 13:20:31'),
(82, 0, '/login', 'undefined', '74925141_17439355', 'S', 'Success', '2024-01-07 13:21:50', 'Y', '2024-01-07 13:21:50'),
(83, 0, '/logout', 'undefined', '_20247072004_2490', 'F', 'Token is required', '2024-01-08 01:50:04', 'Y', '2024-01-08 01:50:04'),
(84, 0, '/login', 'undefined', '60248235_15302471', 'S', 'Success', '2024-01-08 02:15:54', 'Y', '2024-01-08 02:15:54'),
(85, 0, '/plan/user_plans_purchase', 'undefined', '1_20247074733_8663', 'S', 'Success', '2024-01-08 02:17:33', 'Y', '2024-01-08 02:17:33'),
(86, 0, '/logout', 'undefined', '1_20247101939_5181', 'F', 'Invalid token', '2024-01-08 04:49:39', 'Y', '2024-01-08 04:49:39'),
(87, 0, '/login', 'undefined', '67649304_15667993', 'S', 'Success', '2024-01-09 04:37:14', 'Y', '2024-01-09 04:37:14'),
(88, 0, '/logout', 'undefined', '_20248115847_2288', 'F', 'Token is required', '2024-01-09 06:28:47', 'Y', '2024-01-09 06:28:47'),
(89, 0, '/login', 'undefined', '42419592_93255199', 'S', 'Success', '2024-01-09 09:31:47', 'Y', '2024-01-09 09:31:47'),
(90, 0, '/plan/user_plans_purchase', 'undefined', '_20248164052_4862', 'F', 'Error occurred', '2024-01-09 11:10:52', 'Y', '2024-01-09 11:10:52'),
(91, 0, '/login', 'undefined', '55674079_30604836', 'S', 'Success', '2024-01-10 14:15:48', 'Y', '2024-01-10 14:15:48'),
(92, 0, '/login', 'undefined', '24930610_53699647', 'S', 'Success', '2024-01-11 13:01:01', 'Y', '2024-01-11 13:01:01'),
(93, 0, '/login', 'undefined', '23124412_61636834', 'S', 'Success', '2024-01-11 13:12:24', 'Y', '2024-01-11 13:12:23'),
(94, 1, '/logout', 'undefined', '1_202410184419_5353', 'S', 'Success', '2024-01-11 13:14:19', 'Y', '2024-01-11 13:14:19'),
(95, 0, '/login', 'undefined', '86477901_84899855', 'S', 'Success', '2024-01-11 13:15:44', 'Y', '2024-01-11 13:15:44'),
(96, 1, '/logout', 'undefined', '1_202410184759_7931', 'S', 'Success', '2024-01-11 13:17:59', 'Y', '2024-01-11 13:17:59'),
(97, 0, '/login', 'undefined', '40232753_95077986', 'S', 'Success', '2024-01-11 13:18:24', 'Y', '2024-01-11 13:18:24'),
(98, 1, '/plan/user_plans_purchase', 'undefined', '1_202410185043_3462', 'S', 'Success', '2024-01-11 13:20:44', 'Y', '2024-01-11 13:20:43'),
(99, 1, '/plan/user_plans_purchase', 'undefined', '1_202410185333_1425', 'S', 'Success', '2024-01-11 13:23:33', 'Y', '2024-01-11 13:23:33'),
(100, 1, '/plan/user_plans_purchase', 'undefined', '1_202410185550_5194', 'S', 'Success', '2024-01-11 13:25:50', 'Y', '2024-01-11 13:25:50'),
(101, 1, '/plan/user_plans_purchase', 'undefined', '1_202410185731_9387', 'S', 'Success', '2024-01-11 13:27:31', 'Y', '2024-01-11 13:27:31'),
(102, 1, '/plan/user_plans_purchase', 'undefined', '1_202410190124_4904', 'S', 'Success', '2024-01-11 13:31:24', 'Y', '2024-01-11 13:31:24'),
(103, 1, '/group/create_group', 'undefined', '1_202410191019_5112', 'F', 'No available credit to create group.', '2024-01-11 13:40:19', 'Y', '2024-01-11 13:40:19'),
(104, 1, '/logout', 'undefined', '1_202410192110_5817', 'S', 'Success', '2024-01-11 13:51:11', 'Y', '2024-01-11 13:51:10'),
(105, 0, '/login', 'undefined', '29996506_51158459', 'S', 'Success', '2024-01-11 13:51:28', 'Y', '2024-01-11 13:51:28'),
(106, 2, '/group/create_group', 'undefined', '2_202410192210_9737', 'F', 'No available credit to create group.', '2024-01-11 13:52:10', 'Y', '2024-01-11 13:52:10'),
(107, 0, '/login', 'undefined', '84568899_54982297', 'S', 'Success', '2024-01-12 04:51:22', 'Y', '2024-01-12 04:51:22'),
(108, 1, '/group/create_group', 'undefined', '1_202411102312_9211', 'F', 'Validity period is expired.', '2024-01-12 04:53:13', 'Y', '2024-01-12 04:53:12'),
(109, 1, '/group/create_group', 'undefined', '1_202411102808_8451', 'S', 'Success', '2024-01-12 05:02:23', 'Y', '2024-01-12 04:58:08'),
(110, 1, '/logout', 'undefined', '1_202411104946_4669', 'S', 'Success', '2024-01-12 05:19:46', 'Y', '2024-01-12 05:19:46'),
(111, 0, '/login', 'undefined', '38674169_57048423', 'F', 'Invalid Password. Kindly try again with the valid details!', '2024-01-12 05:20:03', 'Y', '2024-01-12 05:20:03'),
(112, 0, '/login', 'undefined', '39069119_39583939', 'S', 'Success', '2024-01-12 05:20:08', 'Y', '2024-01-12 05:20:07'),
(113, 2, '/group/add_members', 'undefined', '2_202411110506_4881', 'S', 'Success', '2024-01-12 05:35:30', 'Y', '2024-01-12 05:35:06'),
(114, 2, '/logout', 'undefined', '2_202411111252_8193', 'S', 'Success', '2024-01-12 05:42:53', 'Y', '2024-01-12 05:42:52'),
(115, 0, '/login', 'undefined', '69507176_23489778', 'S', 'Success', '2024-01-12 05:48:11', 'Y', '2024-01-12 05:48:11'),
(116, 1, '/group/create_group', 'undefined', '1_202411111900_6664', 'S', 'Success', '2024-01-12 05:49:22', 'Y', '2024-01-12 05:49:00'),
(117, 1, '/logout', 'undefined', '1_202411113014_5474', 'S', 'Success', '2024-01-12 06:00:15', 'Y', '2024-01-12 06:00:14'),
(118, 0, '/login', 'undefined', '70295499_73066087', 'S', 'Success', '2024-01-12 06:00:21', 'Y', '2024-01-12 06:00:21'),
(119, 2, '/group/create_group', 'undefined', '2_202411113043_2786', 'F', 'Validity period is expired.', '2024-01-12 06:00:43', 'Y', '2024-01-12 06:00:43'),
(120, 2, '/group/create_group', 'undefined', '2_202411113109_6133', 'F', 'Validity period is expired.', '2024-01-12 06:01:09', 'Y', '2024-01-12 06:01:09'),
(121, 2, '/group/create_group', 'undefined', '2_202411113130_2656', 'F', 'Validity period is expired.', '2024-01-12 06:01:30', 'Y', '2024-01-12 06:01:30'),
(122, 0, '/login', 'undefined', '66842867_71776930', 'S', 'Success', '2024-01-12 06:11:25', 'Y', '2024-01-12 06:11:25'),
(123, 2, '/group/create_group', 'undefined', '2_202411114142_6501', 'F', 'No available credit to create group.', '2024-01-12 06:11:43', 'Y', '2024-01-12 06:11:43'),
(124, 2, '/logout', 'undefined', '2_202411150943_6746', 'S', 'Success', '2024-01-12 09:39:43', 'Y', '2024-01-12 09:39:43'),
(125, 0, '/login', 'undefined', '89300998_63061979', 'S', 'Success', '2024-01-12 09:40:06', 'Y', '2024-01-12 09:40:06'),
(126, 2, '/group/remove_members', 'undefined', '2_224110_481', 'F', 'Validity period is expired.', '2024-01-12 09:40:56', 'Y', '2024-01-12 09:40:56'),
(127, 2, '/logout', 'undefined', '2_202411151119_7664', 'S', 'Success', '2024-01-12 09:41:20', 'Y', '2024-01-12 09:41:19'),
(128, 0, '/login', 'undefined', '40407343_64202716', 'S', 'Success', '2024-01-12 09:41:34', 'Y', '2024-01-12 09:41:33'),
(129, 0, '/group/remove_members', 'undefined', '2_224110_481', 'F', 'Request already processed', '2024-01-12 09:42:34', 'Y', '2024-01-12 09:42:34'),
(130, 1, '/group/remove_members', 'undefined', '2_228978910_481', 'F', 'Error occurred', '2024-01-12 09:43:07', 'Y', '2024-01-12 09:42:41'),
(131, 1, '/group/remove_members', 'undefined', '2_228978990_481', 'F', 'Cannot remove more than 1000 numbers to a group.', '2024-01-12 09:54:40', 'Y', '2024-01-12 09:54:19'),
(132, 1, '/group/remove_members', 'undefined', '2_22897d990_481', 'F', 'Error occurred', '2024-01-12 10:01:55', 'Y', '2024-01-12 10:01:32'),
(133, 0, '/group/remove_members', 'undefined', '2_22897d990_481', 'F', 'Request already processed', '2024-01-12 10:30:48', 'Y', '2024-01-12 10:30:48'),
(134, 1, '/group/remove_members', 'undefined', '2_22897d0_481', 'F', 'Error occurred', '2024-01-12 10:31:15', 'Y', '2024-01-12 10:30:53'),
(135, 1, '/group/remove_members', 'undefined', '2_22897d087686_481', 'F', 'Error occurred', '2024-01-12 10:38:34', 'Y', '2024-01-12 10:38:11'),
(136, 1, '/group/remove_members', 'undefined', '2_22897d0876_481', 'F', 'Error occurred', '2024-01-12 10:39:58', 'Y', '2024-01-12 10:39:36'),
(137, 1, '/group/remove_members', 'undefined', '2_22897d0324_481', 'F', 'Error occurred', '2024-01-12 10:54:35', 'Y', '2024-01-12 10:54:13'),
(138, 1, '/group/remove_members', 'undefined', '2_228924_481', 'F', 'Error occurred', '2024-01-12 10:59:44', 'Y', '2024-01-12 10:59:22'),
(139, 1, '/group/remove_members', 'undefined', '2_223487588924_481', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-12 11:06:35'),
(140, 1, '/group/remove_members', 'undefined', '2_2234874_481', 'F', 'Sender ID unlinked', '2024-01-12 11:11:15', 'Y', '2024-01-12 11:09:03'),
(141, 1, '/sender_id/add_sender_id', 'undefined', '1_202411164230_6517', 'S', 'Success', '2024-01-12 11:12:40', 'Y', '2024-01-12 11:12:30'),
(142, 1, '/group/remove_members', 'undefined', '2_22374e8789_481', 'F', 'Sender ID unlinked', '2024-01-12 11:18:44', 'Y', '2024-01-12 11:16:44'),
(143, 1, '/logout', 'undefined', '1_202411164758_2263', 'S', 'Success', '2024-01-12 11:18:00', 'Y', '2024-01-12 11:17:58'),
(144, 0, '/login', 'undefined', '31573851_11866644', 'S', 'Success', '2024-01-12 11:18:19', 'Y', '2024-01-12 11:18:19'),
(145, 2, '/sender_id/add_sender_id', 'undefined', '2_202411164953_8177', 'S', 'Success', '2024-01-12 11:20:04', 'Y', '2024-01-12 11:19:53'),
(146, 2, '/sender_id/add_sender_id', 'undefined', '2_202411165153_6678', 'S', 'Success', '2024-01-12 11:22:04', 'Y', '2024-01-12 11:21:53'),
(147, 2, '/logout', 'undefined', '2_202411165343_1591', 'S', 'Success', '2024-01-12 11:23:44', 'Y', '2024-01-12 11:23:43'),
(148, 0, '/login', 'undefined', '50436130_70483524', 'S', 'Success', '2024-01-12 11:23:59', 'Y', '2024-01-12 11:23:59'),
(149, 0, '/login', 'undefined', '96204875_24159502', 'S', 'Success', '2024-01-12 12:30:26', 'Y', '2024-01-12 12:30:26'),
(150, 1, '/sender_id/add_sender_id', 'undefined', '1_202411180549_8506', 'S', 'Success', '2024-01-12 12:36:01', 'Y', '2024-01-12 12:35:50'),
(151, 0, '/group/remove_members', 'undefined', '2_22374esdfsd8789_481', 'F', 'Invalid token', '2024-01-12 12:44:26', 'Y', '2024-01-12 12:44:26'),
(152, 0, '/group/remove_members', 'undefined', '2_22374esdfsd8789_481', 'F', 'Request already processed', '2024-01-12 12:58:02', 'Y', '2024-01-12 12:58:02'),
(153, 1, '/group/remove_members', 'undefined', '2_22374sd8789_481', 'F', 'Group is not exists', '2024-01-12 12:58:16', 'Y', '2024-01-12 12:58:16'),
(154, 1, '/group/remove_members', 'undefined', '2_22378789_481', 'F', 'Sender ID unlinked', '2024-01-12 13:03:47', 'Y', '2024-01-12 12:59:09'),
(155, 1, '/group/remove_members', 'undefined', '2_22378789_481', 'F', 'Sender ID unlinked', '2024-01-12 13:03:47', 'Y', '2024-01-12 13:01:47'),
(156, 1, '/sender_id/add_sender_id', 'undefined', '1_202411183405_7690', 'S', 'Success', '2024-01-12 13:04:17', 'Y', '2024-01-12 13:04:05'),
(157, 0, '/group/remove_members', 'undefined', '2_22378789_481', 'F', 'Request already processed', '2024-01-12 13:06:05', 'Y', '2024-01-12 13:06:05'),
(158, 1, '/group/remove_members', 'undefined', '2_22789_481', 'F', 'Sender ID unlinked', '2024-01-12 13:08:11', 'Y', '2024-01-12 13:06:11'),
(159, 0, '/group/remove_members', 'undefined', '2_22789_481', 'F', 'Request already processed', '2024-01-12 13:11:43', 'Y', '2024-01-12 13:11:43'),
(160, 1, '/sender_id/add_sender_id', 'undefined', '1_202411184215_7371', 'S', 'Success', '2024-01-12 13:12:27', 'Y', '2024-01-12 13:12:15'),
(161, 1, '/group/remove_members', 'undefined', '2_228365783489_481', 'F', 'Sender ID unlinked', '2024-01-12 13:15:27', 'Y', '2024-01-12 13:13:27'),
(162, 1, '/sender_id/add_sender_id', 'undefined', '1_202411184812_7358', 'S', 'Success', '2024-01-12 13:18:23', 'Y', '2024-01-12 13:18:12'),
(163, 0, '/group/remove_members', 'undefined', '2_228365783489_481', 'F', 'Request already processed', '2024-01-12 13:19:35', 'Y', '2024-01-12 13:19:35'),
(164, 1, '/group/remove_members', 'undefined', '2_2283683489_481', 'F', 'Group is not exists', '2024-01-12 14:09:34', 'Y', '2024-01-12 13:19:44'),
(165, 1, '/sender_id/add_sender_id', 'undefined', '1_202411190148_2721', 'F', 'QRcode already scanned', '2024-01-12 13:31:48', 'Y', '2024-01-12 13:31:48'),
(166, 1, '/group/remove_members', 'undefined', '2_2283683489_481', 'F', 'Group is not exists', '2024-01-12 14:09:34', 'Y', '2024-01-12 13:32:10'),
(167, 1, '/sender_id/add_sender_id', 'undefined', '1_202411190340_6973', 'S', 'Success', '2024-01-12 13:33:52', 'Y', '2024-01-12 13:33:40'),
(168, 1, '/group/remove_members', 'undefined', '2_2283683489_481', 'F', 'Group is not exists', '2024-01-12 14:09:34', 'Y', '2024-01-12 13:36:38'),
(169, 1, '/sender_id/add_sender_id', 'undefined', '1_202411190740_2002', 'F', 'QRcode already scanned', '2024-01-12 13:37:41', 'Y', '2024-01-12 13:37:40'),
(170, 1, '/sender_id/add_sender_id', 'undefined', '1_202411191539_1278', 'S', 'Success', '2024-01-12 13:45:51', 'Y', '2024-01-12 13:45:39'),
(171, 1, '/sender_id/add_sender_id', 'undefined', '1_202411191739_6519', 'F', 'QRcode already scanned', '2024-01-12 13:47:39', 'Y', '2024-01-12 13:47:39'),
(172, 1, '/group/remove_members', 'undefined', '2_2283683489_481', 'F', 'Group is not exists', '2024-01-12 14:09:34', 'Y', '2024-01-12 14:09:34'),
(173, 0, '/group/remove_members', 'undefined', '2_2283683489_481', 'F', 'Request already processed', '2024-01-12 14:09:35', 'Y', '2024-01-12 14:09:35'),
(174, 1, '/group/remove_members', 'undefined', '2_2683489_481', 'F', 'Group is not exists', '2024-01-12 14:10:33', 'Y', '2024-01-12 14:10:33'),
(175, 1, '/group/remove_members', 'undefined', '2_26834481', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-12 14:15:49'),
(176, 1, '/group/remove_members', 'undefined', '2_26834481', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-12 14:32:09'),
(177, 1, '/group/remove_members', 'undefined', '2_26834481', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-12 14:36:40'),
(178, 1, '/group/remove_members', 'undefined', '2_2687858534481', 'F', 'Group is not exists', '2024-01-13 04:54:21', 'Y', '2024-01-13 02:05:25'),
(179, 1, '/sender_id/add_sender_id', 'undefined', '1_202412073852_7597', 'S', 'Success', '2024-01-13 02:09:06', 'Y', '2024-01-13 02:08:52'),
(180, 1, '/group/remove_members', 'undefined', '2_2687858534481', 'F', 'Group is not exists', '2024-01-13 04:54:21', 'Y', '2024-01-13 02:11:03'),
(181, 1, '/group/remove_members', 'undefined', '2_2687858534481', 'F', 'Group is not exists', '2024-01-13 04:54:21', 'Y', '2024-01-13 02:16:50'),
(182, 1, '/sender_id/add_sender_id', 'undefined', '1_202412075055_5867', 'S', 'Success', '2024-01-13 02:21:06', 'Y', '2024-01-13 02:20:55'),
(183, 1, '/group/add_members', 'undefined', '1_202412075421_7182', 'F', 'Sender ID unlinked', '2024-01-13 02:26:34', 'Y', '2024-01-13 02:24:21'),
(184, 1, '/sender_id/add_sender_id', 'undefined', '1_202412085137_3466', 'S', 'Success', '2024-01-13 03:21:50', 'Y', '2024-01-13 03:21:37'),
(185, 1, '/group/add_members', 'undefined', '1_202412085316_7134', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-13 03:23:16'),
(186, 1, '/group/remove_members', 'undefined', '2_2687858534481', 'F', 'Group is not exists', '2024-01-13 04:54:21', 'Y', '2024-01-13 04:54:21'),
(187, 0, '/group/remove_members', 'undefined', '2_2687858534481', 'F', 'Request already processed', '2024-01-13 04:54:48', 'Y', '2024-01-13 04:54:48'),
(188, 1, '/group/remove_members', 'undefined', '2_262742388534481', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-13 04:54:58'),
(189, 1, '/group/remove_members', 'undefined', '2_262742388534481', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-13 04:57:56'),
(190, 1, '/sender_id/add_sender_id', 'undefined', '1_202412103927_1665', 'S', 'Success', '2024-01-13 05:09:43', 'Y', '2024-01-13 05:09:27'),
(191, 1, '/sender_id/add_sender_id', 'undefined', '1_202412104127_3643', 'F', 'QRcode already scanned', '2024-01-13 05:11:27', 'Y', '2024-01-13 05:11:27'),
(192, 1, '/group/add_members', 'undefined', '1_202412104311_5609', 'S', 'Success', '2024-01-13 05:16:10', 'Y', '2024-01-13 05:13:11'),
(193, 1, '/group/add_members', 'undefined', '1_202412104701_7489', 'S', 'Success', '2024-01-13 05:17:30', 'Y', '2024-01-13 05:17:01'),
(194, 1, '/group/add_members', 'undefined', '1_202412112305_4002', 'F', 'Sender ID unlinked', '2024-01-13 05:55:30', 'Y', '2024-01-13 05:53:05'),
(195, 0, '/sender_id/add_sender_id', 'undefined', '1_202164430_1160', 'F', 'Token is required', '2024-01-13 06:00:17', 'Y', '2024-01-13 06:00:17'),
(196, 1, '/sender_id/add_sender_id', 'undefined', '1_2021630_1160', 'S', 'Success', '2024-01-13 06:01:07', 'Y', '2024-01-13 06:00:55'),
(197, 1, '/group/remove_members', 'undefined', '2_26274234481', 'F', 'Error occurred', '2024-01-13 06:06:33', 'Y', '2024-01-13 06:03:45'),
(198, 1, '/group/remove_members', 'undefined', '2_26274481', 'F', 'Sender ID unlinked', '2024-01-13 06:20:06', 'Y', '2024-01-13 06:18:05'),
(199, 1, '/sender_id/add_sender_id', 'undefined', '1_2021630_18888160', 'S', 'Success', '2024-01-13 06:25:38', 'Y', '2024-01-13 06:25:24'),
(200, 0, '/group/remove_members', 'undefined', '2_26274481', 'F', 'Request already processed', '2024-01-13 06:27:25', 'Y', '2024-01-13 06:27:25'),
(201, 1, '/group/remove_members', 'undefined', '2_2627723794294481', 'S', 'Success', '2024-01-13 06:30:23', 'Y', '2024-01-13 06:27:34'),
(202, 1, '/group/add_members', 'undefined', '1_202416130428_8817', 'F', 'Sender ID unlinked', '2024-01-17 07:37:11', 'Y', '2024-01-17 07:34:28'),
(203, 1, '/sender_id/add_sender_id', 'undefined', '1_202416130818_2095', 'S', 'Success', '2024-01-17 07:38:34', 'Y', '2024-01-17 07:38:18'),
(204, 1, '/sender_id/add_sender_id', 'undefined', '1_202416131018_5160', 'F', 'QRcode already scanned', '2024-01-17 07:40:18', 'Y', '2024-01-17 07:40:18'),
(205, 1, '/group/remove_members', 'undefined', '1_202416131213_5191', 'F', 'Sender ID not found', '2024-01-17 07:42:14', 'Y', '2024-01-17 07:42:13'),
(206, 1, '/group/remove_members', 'undefined', '1_202416131843_7334', 'F', 'Sender ID unlinked', '2024-01-17 07:51:13', 'Y', '2024-01-17 07:48:43'),
(207, 1, '/sender_id/add_sender_id', 'undefined', '1_202416132253_5826', 'S', 'Success', '2024-01-17 07:53:07', 'Y', '2024-01-17 07:52:53'),
(208, 1, '/sender_id/add_sender_id', 'undefined', '1_202416132454_9947', 'F', 'QRcode already scanned', '2024-01-17 07:54:54', 'Y', '2024-01-17 07:54:54'),
(209, 1, '/group/remove_members', 'undefined', '1_202416132522_4586', 'F', 'Sender ID unlinked', '2024-01-17 07:58:00', 'Y', '2024-01-17 07:55:22'),
(210, 1, '/sender_id/add_sender_id', 'undefined', '1_202416132849_8758', 'S', 'Success', '2024-01-17 07:59:04', 'Y', '2024-01-17 07:58:49'),
(211, 1, '/group/add_members', 'undefined', '1_202416133145_9844', 'F', 'No contacts found', '2024-01-17 08:02:45', 'Y', '2024-01-17 08:01:45'),
(212, 1, '/group/add_members', 'undefined', '1_202416133417_3694', 'F', 'Error occurred', '2024-01-17 08:07:57', 'Y', '2024-01-17 08:04:17'),
(213, 1, '/group/add_members', 'undefined', '1_202416142242_8900', 'F', 'No contacts found', '2024-01-17 08:53:12', 'Y', '2024-01-17 08:52:42'),
(214, 1, '/group/add_members', 'undefined', '1_202416142704_5401', 'F', 'No contacts found', '2024-01-17 08:59:01', 'Y', '2024-01-17 08:57:04'),
(215, 1, '/sender_id/add_sender_id', 'undefined', '1_202416143020_7464', 'S', 'Success', '2024-01-17 09:00:35', 'Y', '2024-01-17 09:00:20'),
(216, 1, '/group/add_members', 'undefined', '1_202416143156_8350', 'F', 'No contacts found', '2024-01-17 09:03:15', 'Y', '2024-01-17 09:01:56'),
(217, 1, '/group/add_members', 'undefined', '1_202416143814_6066', 'F', 'No contacts found', '2024-01-17 09:10:14', 'Y', '2024-01-17 09:08:14'),
(218, 1, '/group/add_members', 'undefined', '1_202416144216_6804', 'F', 'No contacts found', '2024-01-17 09:12:41', 'Y', '2024-01-17 09:12:16'),
(219, 1, '/group/add_members', 'undefined', '1_202416144544_5971', 'S', 'Success', '2024-01-17 09:16:10', 'Y', '2024-01-17 09:15:44'),
(220, 1, '/group/add_members', 'undefined', '1_202416144719_4738', 'F', 'No contacts found', '2024-01-17 09:17:45', 'Y', '2024-01-17 09:17:19'),
(221, 1, '/group/remove_members', 'undefined', '1_202416144840_6465', 'F', 'Error occurred', '2024-01-17 09:19:07', 'Y', '2024-01-17 09:18:40'),
(222, 1, '/group/remove_members', 'undefined', '1_202416145725_2329', 'S', 'Success', '2024-01-17 09:27:51', 'Y', '2024-01-17 09:27:25'),
(223, 1, '/group/add_members', 'undefined', '1_202416145927_5202', 'F', 'No contacts found', '2024-01-17 09:29:52', 'Y', '2024-01-17 09:29:27'),
(224, 1, '/group/add_members', 'undefined', '1_202416150104_4961', 'F', 'No contacts found', '2024-01-17 09:31:28', 'Y', '2024-01-17 09:31:04'),
(225, 1, '/group/add_members', 'undefined', '1_202416151432_5911', 'S', 'Success', '2024-01-17 09:45:00', 'Y', '2024-01-17 09:44:32'),
(226, 1, '/group/add_members', 'undefined', '1_202416151613_8728', 'S', 'Success', '2024-01-17 09:46:40', 'Y', '2024-01-17 09:46:13'),
(227, 1, '/group/remove_members', 'undefined', '1_202416151703_5941', 'S', 'Success', '2024-01-17 09:47:29', 'Y', '2024-01-17 09:47:03'),
(228, 0, '/login', 'undefined', '86843880_10651921', 'S', 'Success', '2024-01-23 04:57:28', 'Y', '2024-01-23 04:57:27'),
(229, 1, '/template/create_template', 'undefined', '_2024023105818_973', 'S', 'Success', '2024-01-23 05:28:19', 'Y', '2024-01-23 05:28:18'),
(235, 0, '/login', 'undefined', '88370078_80472842', 'S', 'Success', '2024-01-23 07:17:50', 'Y', '2024-01-23 07:17:50'),
(236, 1, '/template/create_template', 'undefined', '_2024023124808_391', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-23 07:18:08'),
(237, 1, '/template/create_template', 'undefined', '_2024023124955_322', 'S', 'Success', '2024-01-23 07:19:55', 'Y', '2024-01-23 07:19:55'),
(238, 0, '/login', 'undefined', '98647628_57176093', 'S', 'Success', '2024-01-23 07:40:56', 'Y', '2024-01-23 07:40:55'),
(239, 1, '/template/create_template', 'undefined', '_2024023131108_141', 'S', 'Success', '2024-01-23 07:41:09', 'Y', '2024-01-23 07:41:08'),
(240, 1, '/template/create_template', 'undefined', '_2024023131502_202', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-23 07:45:02'),
(241, 1, '/template/create_template', 'undefined', '_2024023131606_656', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-23 07:46:06'),
(242, 1, '/template/create_template', 'undefined', '_2024023131824_324', 'S', 'Success', '2024-01-23 07:48:24', 'Y', '2024-01-23 07:48:24'),
(243, 1, '/template/create_template', 'undefined', '_2024023131856_964', 'S', 'Success', '2024-01-23 07:48:56', 'Y', '2024-01-23 07:48:56'),
(244, 1, '/sender_id/add_sender_id', 'undefined', '1_202422132036_4528', 'S', 'Success', '2024-01-23 07:51:07', 'Y', '2024-01-23 07:50:36'),
(245, 1, '/sender_id/add_sender_id', 'undefined', '1_202422132236_6120', 'F', 'QRcode already scanned', '2024-01-23 07:52:36', 'Y', '2024-01-23 07:52:36'),
(246, 1, '/group/create_group', 'undefined', '1_202422133013_5822', 'S', 'Success', '2024-01-23 08:02:57', 'Y', '2024-01-23 08:00:13'),
(247, 1, '/group/add_members', 'undefined', '1_202422133415_2088', 'F', 'No contacts found', '2024-01-23 08:04:37', 'Y', '2024-01-23 08:04:15'),
(248, 1, '/group/add_members', 'undefined', '1_202422133504_3905', 'S', 'Success', '2024-01-23 08:05:26', 'Y', '2024-01-23 08:05:04'),
(249, 0, '/login', 'undefined', '99380953_18926138', 'S', 'Success', '2024-01-23 09:40:35', 'Y', '2024-01-23 09:40:35'),
(250, 0, '/group/send_message', 'undefined', '1_2021630_18888160', 'F', 'Request already processed', '2024-01-23 12:49:19', 'Y', '2024-01-23 12:49:19'),
(251, 1, '/group/send_message', 'undefined', '1_2021630_188160', 'F', 'Group not found', '2024-01-23 12:50:04', 'Y', '2024-01-23 12:49:34'),
(252, 1, '/group/send_message', 'undefined', '1_2021630_1837459160', 'Y', 'Success', '2024-01-23 12:53:13', 'Y', '2024-01-23 12:52:51'),
(253, 1, '/group/send_message', 'undefined', '1_2021630_2386459160', 'F', 'Error occurred', '2024-01-23 13:24:25', 'Y', '2024-01-23 13:24:03'),
(254, 1, '/group/send_message', 'undefined', '1_20216323874160', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-23 13:29:56'),
(255, 1, '/group/send_message', 'undefined', '1_2021638458937474160', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-23 13:31:31'),
(256, 1, '/group/send_message', 'undefined', '1_202132752337474160', 'F', 'Error occurred', '2024-01-23 13:35:40', 'Y', '2024-01-23 13:35:19'),
(257, 0, '/login', 'undefined', '70025411_30017824', 'S', 'Success', '2024-01-24 09:04:43', 'Y', '2024-01-24 09:04:43'),
(258, 1, '/sender_id/add_sender_id', 'undefined', '1_202423143601_3135', 'S', 'Success', '2024-01-24 09:06:11', 'Y', '2024-01-24 09:06:01'),
(259, 1, '/sender_id/add_sender_id', 'undefined', '1_202423170254_9838', 'S', 'Success', '2024-01-24 11:33:06', 'Y', '2024-01-24 11:32:54'),
(260, 1, '/sender_id/add_sender_id', 'undefined', '1_202423170655_9871', 'S', 'Success', '2024-01-24 11:37:06', 'Y', '2024-01-24 11:36:55'),
(261, 0, '/group/send_message', 'undefined', '1_202132757852n74160', 'F', 'Invalid token or User ID', '2024-01-24 12:44:29', 'Y', '2024-01-24 12:44:29'),
(262, 1, '/sender_id/add_sender_id', 'undefined', '1_202423181751_5733', 'S', 'Success', '2024-01-24 12:48:02', 'Y', '2024-01-24 12:47:51'),
(263, 1, '/sender_id/add_sender_id', 'undefined', '1_202423184504_4028', 'S', 'Success', '2024-01-24 13:15:16', 'Y', '2024-01-24 13:15:04'),
(264, 1, '/sender_id/add_sender_id', 'undefined', '1_202423184704_8988', 'F', 'QRcode already scanned', '2024-01-24 13:17:04', 'Y', '2024-01-24 13:17:04'),
(265, 0, '/login', 'undefined', '18226893_66069004', 'S', 'Success', '2024-01-25 05:34:45', 'Y', '2024-01-25 05:34:45'),
(266, 1, '/sender_id/add_sender_id', 'undefined', '1_202424110524_7869', 'S', 'Success', '2024-01-25 05:35:36', 'Y', '2024-01-25 05:35:24'),
(267, 1, '/sender_id/add_sender_id', 'undefined', '1_202424110724_6772', 'F', 'QRcode already scanned', '2024-01-25 05:37:24', 'Y', '2024-01-25 05:37:24'),
(268, 1, '/sender_id/add_sender_id', 'undefined', '1_202424111058_2979', 'S', 'Success', '2024-01-25 05:41:11', 'Y', '2024-01-25 05:40:58'),
(269, 1, '/sender_id/add_sender_id', 'undefined', '1_202424111258_2734', 'S', 'Success', '2024-01-25 05:43:12', 'Y', '2024-01-25 05:42:58'),
(270, 1, '/sender_id/add_sender_id', 'undefined', '1_202424111458_9205', 'S', 'Success', '2024-01-25 05:45:12', 'Y', '2024-01-25 05:44:58'),
(271, 1, '/sender_id/add_sender_id', 'undefined', '1_202424111512_2271', 'S', 'Success', '2024-01-25 05:45:26', 'Y', '2024-01-25 05:45:12'),
(272, 1, '/sender_id/add_sender_id', 'undefined', '1_202424111658_4997', 'S', 'Success', '2024-01-25 05:47:12', 'Y', '2024-01-25 05:46:58'),
(273, 1, '/sender_id/add_sender_id', 'undefined', '1_202424111712_6740', 'S', 'Success', '2024-01-25 05:47:26', 'Y', '2024-01-25 05:47:12'),
(274, 1, '/sender_id/add_sender_id', 'undefined', '1_202424111727_9299', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 05:47:27'),
(275, 0, '/login', 'undefined', '94571203_67488908', 'S', 'Success', '2024-01-25 05:59:54', 'Y', '2024-01-25 05:59:54'),
(276, 1, '/sender_id/add_sender_id', 'undefined', '1_202424113712_4201', 'S', 'Success', '2024-01-25 06:07:24', 'Y', '2024-01-25 06:07:12'),
(277, 1, '/group/add_members', 'undefined', '1_202424113939_3487', 'F', 'Sender ID unlinked', '2024-01-25 06:11:47', 'Y', '2024-01-25 06:09:39'),
(278, 1, '/sender_id/add_sender_id', 'undefined', '1_202424114316_1349', 'S', 'Success', '2024-01-25 06:13:33', 'Y', '2024-01-25 06:13:16'),
(279, 1, '/sender_id/add_sender_id', 'undefined', '1_202424114517_5576', 'F', 'QRcode already scanned', '2024-01-25 06:15:17', 'Y', '2024-01-25 06:15:17'),
(280, 1, '/group/add_members', 'undefined', '1_202424115006_7828', 'S', 'Success', '2024-01-25 06:22:51', 'Y', '2024-01-25 06:20:06'),
(281, 1, '/sender_id/add_sender_id', 'undefined', '1_202424122553_5343', 'S', 'Success', '2024-01-25 06:56:05', 'Y', '2024-01-25 06:55:53'),
(282, 1, '/sender_id/add_sender_id', 'undefined', '1_202424122753_3181', 'F', 'QRcode already scanned', '2024-01-25 06:57:54', 'Y', '2024-01-25 06:57:53'),
(283, 1, '/sender_id/add_sender_id', 'undefined', '1_202424123709_6519', 'S', 'Success', '2024-01-25 07:07:19', 'Y', '2024-01-25 07:07:09'),
(284, 1, '/sender_id/add_sender_id', 'undefined', '1_202424151929_4250', 'S', 'Success', '2024-01-25 09:49:40', 'Y', '2024-01-25 09:49:29'),
(285, 1, '/sender_id/add_sender_id', 'undefined', '1_202424160203_5126', 'S', 'Success', '2024-01-25 10:32:14', 'Y', '2024-01-25 10:32:03'),
(286, 0, '/login', 'undefined', '86072384_63606410', 'S', 'Success', '2024-01-25 13:07:10', 'Y', '2024-01-25 13:07:10'),
(287, 1, '/sender_id/add_sender_id', 'undefined', '1_202424183739_4089', 'F', 'QRcode already scanned', '2024-01-25 13:07:39', 'Y', '2024-01-25 13:07:39'),
(288, 1, '/sender_id/add_sender_id', 'undefined', '1_202424183823_2586', 'S', 'Success', '2024-01-25 13:08:38', 'Y', '2024-01-25 13:08:23'),
(289, 0, '/login', 'undefined', '56893540_32286189', 'S', 'Success', '2024-01-25 14:50:36', 'Y', '2024-01-25 14:50:36'),
(290, 1, '/sender_id/add_sender_id', 'undefined', '1_202424202139_6147', 'S', 'Success', '2024-01-25 14:51:50', 'Y', '2024-01-25 14:51:39'),
(291, 1, '/sender_id/add_sender_id', 'undefined', '1_202424202345_5969', 'F', 'QRcode already scanned', '2024-01-25 14:53:45', 'Y', '2024-01-25 14:53:45'),
(292, 1, '/logout', 'undefined', '1_202426104647_4776', 'S', 'Success', '2024-01-27 05:16:47', 'Y', '2024-01-27 05:16:47'),
(293, 0, '/login', 'undefined', '98655642_75269810', 'S', 'Success', '2024-01-27 05:17:47', 'Y', '2024-01-27 05:17:47'),
(294, 0, '/login', 'undefined', '18482233_18548696', 'S', 'Success', '2024-01-30 06:43:12', 'Y', '2024-01-30 06:43:12'),
(295, 1, '/logout', 'undefined', '1_202429122123_4399', 'S', 'Success', '2024-01-30 06:51:23', 'Y', '2024-01-30 06:51:23'),
(296, 0, '/login', 'undefined', '10317656_35635219', 'F', 'Invalid Password. Kindly try again with the valid details!', '2024-01-30 06:51:34', 'Y', '2024-01-30 06:51:34'),
(297, 0, '/login', 'undefined', '90020278_59881698', 'S', 'Success', '2024-01-30 06:51:41', 'Y', '2024-01-30 06:51:40'),
(298, 1, '/sender_id/add_sender_id', 'undefined', '1_202429123350_4095', 'S', 'Success', '2024-01-30 07:04:01', 'Y', '2024-01-30 07:03:50'),
(299, 0, '/login', 'undefined', '90506749_81881736', 'F', 'Invalid Password. Kindly try again with the valid details!', '2024-01-30 11:18:23', 'Y', '2024-01-30 11:18:23'),
(300, 0, '/login', 'undefined', '30602384_58956602', 'S', 'Success', '2024-01-30 11:18:29', 'Y', '2024-01-30 11:18:29'),
(301, 1, '/sender_id/add_sender_id', 'undefined', '1_202429170352_3474', 'S', 'Success', '2024-01-30 11:34:02', 'Y', '2024-01-30 11:33:52'),
(302, 1, '/sender_id/add_sender_id', 'undefined', '1_202429170552_8156', 'F', 'QRcode already scanned', '2024-01-30 11:35:52', 'Y', '2024-01-30 11:35:52'),
(303, 1, '/group/send_message', 'undefined', '_2024030181037_209', 'F', 'Error occurred', '2024-01-30 12:41:32', 'Y', '2024-01-30 12:40:37'),
(304, 1, '/group/send_message', 'undefined', '_2024030181652_141', 'F', 'Error occurred', '2024-01-30 12:48:55', 'Y', '2024-01-30 12:46:53'),
(305, 1, '/group/send_message', 'undefined', '_2024030182240_876', 'F', 'Error occurred', '2024-01-30 12:53:11', 'Y', '2024-01-30 12:52:40'),
(306, 1, '/group/send_message', 'undefined', '_2024030182331_223', 'F', 'Error occurred', '2024-01-30 12:53:57', 'Y', '2024-01-30 12:53:31'),
(307, 1, '/group/send_message', 'undefined', '_2024030182512_116', 'F', 'Error occurred', '2024-01-30 12:55:39', 'Y', '2024-01-30 12:55:12'),
(308, 1, '/group/send_message', 'undefined', '_2024030182712_586', 'F', 'Error occurred', '2024-01-30 12:57:38', 'Y', '2024-01-30 12:57:12'),
(309, 1, '/group/send_message', 'undefined', '_2024030182845_113', 'Y', 'Success', '2024-01-30 12:59:12', 'Y', '2024-01-30 12:58:46'),
(310, 1, '/group/send_message', 'undefined', '_2024030183445_595', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-30 13:04:45'),
(311, 1, '/group/send_message', 'undefined', '_2024030183524_834', 'Y', 'Success', '2024-01-30 13:05:51', 'Y', '2024-01-30 13:05:24'),
(312, 1, '/group/send_message', 'undefined', '_2024030183643_854', 'Y', 'Success', '2024-01-30 13:07:10', 'Y', '2024-01-30 13:06:43'),
(313, 1, '/group/send_message', 'undefined', '_2024030185447_809', 'F', 'Error occurred', '2024-01-30 13:25:14', 'Y', '2024-01-30 13:24:47'),
(314, 1, '/group/send_message', 'undefined', '_2024030185618_213', 'Y', 'Success', '2024-01-30 13:26:45', 'Y', '2024-01-30 13:26:18'),
(315, 1, '/group/send_message', 'undefined', '_2024030192905_217', 'Y', 'Success', '2024-01-30 13:59:32', 'Y', '2024-01-30 13:59:05'),
(316, 1, '/group/send_message', 'undefined', '_2024030193210_927', 'Y', 'Success', '2024-01-30 14:02:37', 'Y', '2024-01-30 14:02:10'),
(317, 1, '/group/send_message', 'undefined', '_2024030194147_296', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-30 14:11:47'),
(318, 1, '/group/send_message', 'undefined', '_2024031110904_575', 'Y', 'Success', '2024-01-31 05:39:37', 'Y', '2024-01-31 05:39:04'),
(319, 1, '/group/send_message', 'undefined', '_2024031111647_920', 'Y', 'Success', '2024-01-31 05:47:13', 'Y', '2024-01-31 05:46:47'),
(320, 1, '/group/schedule_send_message', 'undefined', '_2024031112145_474', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-31 05:51:45'),
(321, 1, '/group/schedule_send_message', 'undefined', '_2024031115620_646', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-31 06:26:20'),
(322, 1, '/group/schedule_send_message', 'undefined', '_2024031122720_673', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-31 06:57:20'),
(323, 1, '/group/schedule_send_message', 'undefined', '_2024031124108_602', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-31 07:11:08'),
(324, 1, '/group/schedule_send_message', 'undefined', '_2024031131106_723', 'F', 'Sender ID unlinked', '2024-01-31 07:52:31', 'Y', '2024-01-31 07:41:06'),
(325, 1, '/group/schedule_send_message', 'undefined', '_2024031131537_169', 'Y', 'Success', '2024-01-31 07:48:26', 'Y', '2024-01-31 07:45:37'),
(326, 1, '/sender_id/add_sender_id', 'undefined', '1_202430132353_5506', 'S', 'Success', '2024-01-31 07:54:05', 'Y', '2024-01-31 07:53:53'),
(327, 1, '/sender_id/add_sender_id', 'undefined', '1_202430132553_6644', 'F', 'QRcode already scanned', '2024-01-31 07:55:53', 'Y', '2024-01-31 07:55:53'),
(328, 1, '/group/schedule_send_message', 'undefined', '_2024031132630_112', 'F', 'Sender ID unlinked', '2024-01-31 08:02:02', 'Y', '2024-01-31 07:56:30'),
(329, 1, '/group/schedule_send_message', 'undefined', '_2024031132644_555', 'Y', 'Success', '2024-01-31 08:00:42', 'Y', '2024-01-31 07:56:44'),
(330, 1, '/sender_id/add_sender_id', 'undefined', '1_202430143454_4499', 'S', 'Success', '2024-01-31 09:05:06', 'Y', '2024-01-31 09:04:54'),
(331, 1, '/sender_id/add_sender_id', 'undefined', '1_202430143655_9751', 'F', 'QRcode already scanned', '2024-01-31 09:06:55', 'Y', '2024-01-31 09:06:55'),
(332, 1, '/group/schedule_send_message', 'undefined', '_2024031144228_790', 'F', 'Sender ID unlinked', '2024-01-31 09:17:52', 'Y', '2024-01-31 09:12:28'),
(333, 1, '/group/schedule_send_message', 'undefined', '_2024031144253_973', 'F', 'Sender ID unlinked', '2024-01-31 09:17:12', 'Y', '2024-01-31 09:12:53'),
(334, 1, '/group/schedule_send_message', 'undefined', '_2024031144325_659', 'Y', 'Success', '2024-01-31 09:16:57', 'Y', '2024-01-31 09:13:25'),
(335, 1, '/sender_id/add_sender_id', 'undefined', '1_202430144955_8051', 'S', 'Success', '2024-01-31 09:20:11', 'Y', '2024-01-31 09:19:55'),
(336, 1, '/sender_id/add_sender_id', 'undefined', '1_202430145155_8178', 'F', 'QRcode already scanned', '2024-01-31 09:21:55', 'Y', '2024-01-31 09:21:55'),
(337, 1, '/group/send_message', 'undefined', '_2024031145221_139', 'Y', 'Success', '2024-01-31 09:23:40', 'Y', '2024-01-31 09:22:21'),
(338, 1, '/group/schedule_send_message', 'undefined', '_2024031145420_242', 'F', 'Sender ID unlinked', '2024-01-31 09:28:35', 'Y', '2024-01-31 09:24:20'),
(339, 1, '/sender_id/add_sender_id', 'undefined', '1_202430150346_3727', 'S', 'Success', '2024-01-31 09:33:57', 'Y', '2024-01-31 09:33:46'),
(340, 1, '/sender_id/add_sender_id', 'undefined', '1_202430150547_9233', 'F', 'QRcode already scanned', '2024-01-31 09:35:47', 'Y', '2024-01-31 09:35:47'),
(341, 1, '/group/schedule_send_message', 'undefined', '_2024031150619_940', 'Y', 'Success', '2024-01-31 09:38:40', 'Y', '2024-01-31 09:36:19'),
(342, 1, '/template/create_template', 'undefined', '_2024031151256_958', 'S', 'Success', '2024-01-31 09:42:56', 'Y', '2024-01-31 09:42:56'),
(343, 1, '/group/schedule_send_message', 'undefined', '_2024031151530_218', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-31 09:45:30'),
(344, 1, '/group/schedule_send_message', 'undefined', '_2024031151605_810', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-31 09:46:05'),
(345, 1, '/group/schedule_send_message', 'undefined', '_2024031151732_854', 'F', 'Sender ID unlinked', '2024-01-31 09:57:02', 'Y', '2024-01-31 09:47:32'),
(346, 1, '/group/schedule_send_message', 'undefined', '_2024031151907_332', 'Y', 'Success', '2024-01-31 09:53:00', 'Y', '2024-01-31 09:49:07'),
(347, 1, '/sender_id/add_sender_id', 'undefined', '1_202430153024_1040', 'S', 'Success', '2024-01-31 10:00:36', 'Y', '2024-01-31 10:00:24'),
(348, 1, '/sender_id/add_sender_id', 'undefined', '1_202430153225_5757', 'F', 'QRcode already scanned', '2024-01-31 10:02:25', 'Y', '2024-01-31 10:02:25'),
(349, 1, '/group/schedule_send_message', 'undefined', '_2024031154432_913', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-31 10:14:32'),
(350, 1, '/group/schedule_send_message', 'undefined', '_2024031155124_722', 'Y', 'Success', '2024-01-31 10:24:01', 'Y', '2024-01-31 10:21:24'),
(351, 1, '/group/schedule_send_message', 'undefined', '_2024031155538_395', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-31 10:25:38'),
(352, 1, '/group/schedule_send_message', 'undefined', '_2024031155606_951', 'F', 'Sender ID unlinked', '2024-01-31 10:30:02', 'Y', '2024-01-31 10:26:06'),
(353, 1, '/group/schedule_send_message', 'undefined', '_2024031155632_869', 'F', 'Sender ID unlinked', '2024-01-31 10:30:08', 'Y', '2024-01-31 10:26:32'),
(354, 1, '/group/schedule_send_message', 'undefined', '_2024031160424_481', 'F', 'Sender ID not found', '2024-01-31 10:34:24', 'Y', '2024-01-31 10:34:24'),
(355, 1, '/sender_id/add_sender_id', 'undefined', '1_202430160444_3268', 'S', 'Success', '2024-01-31 10:34:57', 'Y', '2024-01-31 10:34:44'),
(356, 1, '/sender_id/add_sender_id', 'undefined', '1_202430160645_9315', 'F', 'QRcode already scanned', '2024-01-31 10:36:45', 'Y', '2024-01-31 10:36:45'),
(357, 1, '/group/schedule_send_message', 'undefined', '_2024031160747_420', 'Y', 'Success', '2024-01-31 10:39:58', 'Y', '2024-01-31 10:37:47'),
(358, 1, '/group/schedule_send_message', 'undefined', '_2024031161458_957', 'F', 'Sender ID unlinked', '2024-01-31 10:52:15', 'Y', '2024-01-31 10:44:58'),
(359, 1, '/group/schedule_send_message', 'undefined', '_2024031161524_427', 'F', 'Sender ID unlinked', '2024-01-31 10:50:26', 'Y', '2024-01-31 10:45:25'),
(360, 1, '/sender_id/add_sender_id', 'undefined', '1_202430162148_5454', 'S', 'Success', '2024-01-31 10:52:04', 'Y', '2024-01-31 10:51:48'),
(361, 1, '/group/schedule_send_message', 'undefined', '_2024031162359_986', 'Y', 'Success', '2024-01-31 10:56:20', 'Y', '2024-01-31 10:53:59'),
(362, 1, '/group/schedule_send_message', 'undefined', '_2024031165548_443', 'F', 'Sender ID unlinked', '2024-01-31 11:29:25', 'Y', '2024-01-31 11:25:48'),
(363, 1, '/group/schedule_send_message', 'undefined', '_2024031171556_612', 'F', 'Sender ID not found', '2024-01-31 11:45:57', 'Y', '2024-01-31 11:45:56'),
(364, 1, '/sender_id/add_sender_id', 'undefined', '1_202430171619_5390', 'S', 'Success', '2024-01-31 11:46:30', 'Y', '2024-01-31 11:46:19'),
(365, 1, '/sender_id/add_sender_id', 'undefined', '1_202430171819_9087', 'F', 'QRcode already scanned', '2024-01-31 11:48:20', 'Y', '2024-01-31 11:48:19'),
(366, 1, '/group/schedule_send_message', 'undefined', '_2024031171910_230', 'Y', 'Success', '2024-01-31 11:51:12', 'Y', '2024-01-31 11:49:10'),
(367, 1, '/group/schedule_send_message', 'undefined', '_2024031172806_361', 'F', 'Sender ID unlinked', '2024-01-31 12:05:15', 'Y', '2024-01-31 11:58:06'),
(368, 1, '/group/schedule_send_message', 'undefined', '_2024031172825_274', 'F', 'Sender ID unlinked', '2024-01-31 12:02:01', 'Y', '2024-01-31 11:58:25');
INSERT INTO `api_log` (`api_log_id`, `user_id`, `api_url`, `ip_address`, `request_id`, `response_status`, `response_comments`, `response_date`, `api_log_status`, `api_log_entry_date`) VALUES
(369, 0, '/login', 'undefined', '97568186_58194611', 'S', 'Success', '2024-01-31 12:17:38', 'Y', '2024-01-31 12:17:38'),
(370, 1, '/logout', 'undefined', '1_202430194247_4455', 'S', 'Success', '2024-01-31 14:12:48', 'Y', '2024-01-31 14:12:47'),
(371, 0, '/login', 'undefined', '90229632_68703883', 'S', 'Success', '2024-02-01 04:05:23', 'Y', '2024-02-01 04:05:23'),
(372, 1, '/group/send_message', 'undefined', '_2024032093852_856', 'F', 'Sender ID not found', '2024-02-01 04:08:52', 'Y', '2024-02-01 04:08:52'),
(373, 1, '/sender_id/add_sender_id', 'undefined', '1_202431093921_2580', 'S', 'Success', '2024-02-01 04:09:32', 'Y', '2024-02-01 04:09:21'),
(374, 1, '/sender_id/add_sender_id', 'undefined', '1_202431094121_3470', 'F', 'QRcode already scanned', '2024-02-01 04:11:21', 'Y', '2024-02-01 04:11:21'),
(375, 1, '/group/send_message', 'undefined', '_2024032094145_556', 'F', 'Error occurred', '2024-02-01 04:13:02', 'Y', '2024-02-01 04:11:45'),
(376, 1, '/group/send_message', 'undefined', '_2024032094615_119', 'Y', 'Success', '2024-02-01 04:17:42', 'Y', '2024-02-01 04:16:15'),
(377, 1, '/group/schedule_send_message', 'undefined', '_2024032101435_542', 'Y', 'Success', '2024-02-01 04:50:28', 'Y', '2024-02-01 04:44:35'),
(378, 1, '/group/send_message', 'undefined', '_2024032102312_429', 'F', 'Sender ID unlinked', '2024-02-01 04:55:16', 'Y', '2024-02-01 04:53:12'),
(379, 1, '/sender_id/add_sender_id', 'undefined', '1_202431103313_7878', 'S', 'Success', '2024-02-01 05:03:30', 'Y', '2024-02-01 05:03:13'),
(380, 1, '/group/schedule_send_message', 'undefined', '_2024032103525_309', 'F', 'Sender ID unlinked', '2024-02-01 05:09:02', 'Y', '2024-02-01 05:05:25'),
(381, 1, '/sender_id/add_sender_id', 'undefined', '1_202431104518_5174', 'S', 'Success', '2024-02-01 05:15:35', 'Y', '2024-02-01 05:15:18'),
(382, 1, '/group/send_message', 'undefined', '_2024032104626_918', 'Y', 'Success', '2024-02-01 05:17:48', 'Y', '2024-02-01 05:16:26'),
(383, 1, '/group/send_message', 'undefined', '_2024032104807_758', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 05:18:07'),
(384, 1, '/sender_id/add_sender_id', 'undefined', '1_202431105242_9150', 'S', 'Success', '2024-02-01 05:22:54', 'Y', '2024-02-01 05:22:42'),
(385, 1, '/group/send_message', 'undefined', '_2024032105406_940', 'Y', 'Success', '2024-02-01 05:25:24', 'Y', '2024-02-01 05:24:06'),
(386, 1, '/group/send_message', 'undefined', '_2024032105601_708', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 05:26:01'),
(387, 1, '/sender_id/add_sender_id', 'undefined', '1_202431110013_7586', 'S', 'Success', '2024-02-01 05:30:24', 'Y', '2024-02-01 05:30:13'),
(388, 1, '/group/send_message', 'undefined', '_2024032110145_302', 'Y', 'Success', '2024-02-01 05:32:59', 'Y', '2024-02-01 05:31:45'),
(389, 1, '/group/send_message', 'undefined', '_2024032110344_107', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 05:33:44'),
(390, 1, '/logout', 'undefined', '1_202431120754_1421', 'S', 'Success', '2024-02-01 06:37:54', 'Y', '2024-02-01 06:37:54'),
(391, 0, '/login', 'undefined', '76922775_64382361', 'S', 'Success', '2024-02-05 06:10:49', 'Y', '2024-02-05 06:10:49'),
(392, 0, '/logout', 'undefined', '1_202435114442_3376', 'F', 'Invalid token', '2024-02-05 06:14:42', 'Y', '2024-02-05 06:14:42'),
(393, 0, '/login', 'undefined', '56644795_44581548', 'S', 'Success', '2024-02-05 06:17:24', 'Y', '2024-02-05 06:17:23'),
(394, 0, '/login', 'undefined', '68063006_15479558', 'S', 'Success', '2024-02-05 06:18:01', 'Y', '2024-02-05 06:18:01'),
(395, 1, '/group/send_message', 'undefined', 'pri_2024036114902_523', 'F', 'Sender ID not found', '2024-02-05 06:19:02', 'Y', '2024-02-05 06:19:02'),
(396, 1, '/sender_id/add_sender_id', 'undefined', '1_202435115141_6588', 'S', 'Success', '2024-02-05 06:21:52', 'Y', '2024-02-05 06:21:41'),
(397, 1, '/group/send_message', 'undefined', 'pri_2024036115309_127', 'F', 'Sender ID not found', '2024-02-05 06:23:09', 'Y', '2024-02-05 06:23:09'),
(398, 1, '/sender_id/add_sender_id', 'undefined', '1_202435115703_4920', 'S', 'Success', '2024-02-05 06:27:14', 'Y', '2024-02-05 06:27:03'),
(399, 0, '/login', 'undefined', '39852278_71827865', 'S', 'Success', '2024-02-05 06:28:28', 'Y', '2024-02-05 06:28:27'),
(400, 1, '/group/send_message', 'undefined', '_2024036115913_685', 'Y', 'Success', '2024-02-05 06:30:27', 'Y', '2024-02-05 06:29:13'),
(401, 1, '/group/send_message', 'undefined', '_2024036120234_554', 'F', 'Error occurred', '2024-02-05 06:34:17', 'Y', '2024-02-05 06:32:34'),
(402, 1, '/group/send_message', 'undefined', '_2024036120610_223', 'Y', 'Success', '2024-02-05 06:36:37', 'Y', '2024-02-05 06:36:10'),
(403, 1, '/group/send_message', 'undefined', '_2024036120725_248', 'F', 'Error occurred', '2024-02-05 06:37:52', 'Y', '2024-02-05 06:37:25'),
(404, 1, '/group/send_message', 'undefined', '_2024036121029_780', 'F', 'Error occurred', '2024-02-05 06:40:58', 'Y', '2024-02-05 06:40:29'),
(405, 1, '/group/send_message', 'undefined', '_2024036121323_994', 'Y', 'Success', '2024-02-05 06:43:53', 'Y', '2024-02-05 06:43:23'),
(406, 1, '/group/schedule_send_message', 'undefined', '_2024036121438_191', 'Y', 'Success', '2024-02-05 06:47:26', 'Y', '2024-02-05 06:44:38'),
(407, 1, '/group/schedule_send_message', 'undefined', '_2024036121642_380', 'Y', 'Success', '2024-02-05 06:49:28', 'Y', '2024-02-05 06:46:42'),
(408, 1, '/group/schedule_send_message', 'undefined', '_2024036121812_311', 'Y', 'Success', '2024-02-05 06:50:31', 'Y', '2024-02-05 06:48:12'),
(409, 1, '/logout', 'undefined', '1_202435122118_3055', 'S', 'Success', '2024-02-05 06:51:19', 'Y', '2024-02-05 06:51:18'),
(410, 0, '/login', 'undefined', '27195124_29161782', 'S', 'Success', '2024-02-08 09:43:07', 'Y', '2024-02-08 09:43:07'),
(411, 1, '/logout', 'undefined', '1_202438151320_8293', 'S', 'Success', '2024-02-08 09:43:21', 'Y', '2024-02-08 09:43:20'),
(412, 0, '/login', 'undefined', '24683444_36694460', 'S', 'Success', '2024-02-08 09:46:37', 'Y', '2024-02-08 09:46:37'),
(413, 0, '/login', 'undefined', '39556754_87748506', 'F', 'Invalid Password. Kindly try again with the valid details!', '2024-02-15 05:39:43', 'Y', '2024-02-15 05:39:43'),
(414, 0, '/login', 'undefined', '59858933_24291248', 'F', 'Invalid Password. Kindly try again with the valid details!', '2024-02-15 05:39:48', 'Y', '2024-02-15 05:39:48'),
(415, 0, '/login', 'undefined', '15548328_85819791', 'S', 'Success', '2024-02-15 05:39:56', 'Y', '2024-02-15 05:39:55'),
(416, 1, '/group/remove_members', 'undefined', '1_202445120056_5210', 'F', 'Sender ID unlinked', '2024-02-15 06:33:45', 'Y', '2024-02-15 06:30:56'),
(417, 1, '/sender_id/add_sender_id', 'undefined', '1_202445120425_9413', 'S', 'Success', '2024-02-15 06:34:38', 'Y', '2024-02-15 06:34:25'),
(418, 1, '/sender_id/add_sender_id', 'undefined', '1_202445120626_6980', 'F', 'QRcode already scanned', '2024-02-15 06:36:26', 'Y', '2024-02-15 06:36:26'),
(419, 1, '/group/remove_members', 'undefined', '1_202445120719_5098', 'S', 'Success', '2024-02-15 06:40:12', 'Y', '2024-02-15 06:37:19'),
(420, 1, '/group/add_members', 'undefined', '1_202445123314_6240', 'S', 'Success', '2024-02-15 07:04:24', 'Y', '2024-02-15 07:03:14'),
(421, 1, '/group/add_members', 'undefined', '1_202445124356_8165', 'S', 'Success', '2024-02-15 07:14:30', 'Y', '2024-02-15 07:13:56'),
(422, 1, '/group/add_members', 'undefined', '1_202445124949_5421', 'F', 'Error occurred', '2024-02-15 07:20:20', 'Y', '2024-02-15 07:19:49'),
(423, 1, '/group/promote_admin', 'undefined', '1_202445125237_1540', 'S', 'SUCCESS', '2024-02-15 07:23:06', 'Y', '2024-02-15 07:22:37'),
(424, 1, '/group/demote_admin', 'undefined', '1_202445130017_3516', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-15 07:30:17'),
(425, 0, '/login', 'undefined', '56060346_93944332', 'S', 'Success', '2024-02-15 07:34:21', 'Y', '2024-02-15 07:34:20'),
(426, 1, '/group/demote_admin', 'undefined', '1_202445130506_2428', 'S', 'SUCCESS', '2024-02-15 07:35:35', 'Y', '2024-02-15 07:35:06'),
(427, 1, '/group/remove_members', 'undefined', '1_202445130833_5510', 'S', 'Success', '2024-02-15 07:39:03', 'Y', '2024-02-15 07:38:33'),
(428, 0, '/login', 'undefined', '86477120_16461423', 'S', 'Success', '2024-02-22 06:23:24', 'Y', '2024-02-22 06:23:24'),
(429, 1, '/sender_id/add_sender_id', 'undefined', '1_202452115444_9540', 'S', 'Success', '2024-02-22 06:25:12', 'Y', '2024-02-22 06:24:45'),
(430, 1, '/sender_id/add_sender_id', 'undefined', '1_202452115845_8002', 'S', 'Success', '2024-02-22 06:28:59', 'Y', '2024-02-22 06:28:45'),
(431, 1, '/sender_id/add_sender_id', 'undefined', '1_202452115859_2045', 'S', 'Success', '2024-02-22 06:29:10', 'Y', '2024-02-22 06:28:59'),
(432, 1, '/sender_id/add_sender_id', 'undefined', '1_202452115929_1506', 'S', 'Success', '2024-02-22 06:29:40', 'Y', '2024-02-22 06:29:29'),
(433, 1, '/sender_id/add_sender_id', 'undefined', '1_202452121015_4305', 'S', 'Success', '2024-02-22 06:40:26', 'Y', '2024-02-22 06:40:15'),
(434, 1, '/sender_id/add_sender_id', 'undefined', '1_202452121426_4135', 'S', 'Success', '2024-02-22 06:44:37', 'Y', '2024-02-22 06:44:26'),
(435, 1, '/sender_id/add_sender_id', 'undefined', '1_202452121713_8328', 'S', 'Success', '2024-02-22 06:47:24', 'Y', '2024-02-22 06:47:13'),
(436, 1, '/sender_id/add_sender_id', 'undefined', '1_202452121929_7917', 'S', 'Success', '2024-02-22 06:49:39', 'Y', '2024-02-22 06:49:29'),
(437, 1, '/sender_id/add_sender_id', 'undefined', '1_202452122900_8758', 'S', 'Success', '2024-02-22 06:59:10', 'Y', '2024-02-22 06:59:00'),
(438, 1, '/sender_id/add_sender_id', 'undefined', '1_202452123645_2022', 'S', 'Success', '2024-02-22 07:06:56', 'Y', '2024-02-22 07:06:45'),
(439, 1, '/sender_id/add_sender_id', 'undefined', '1_202452124410_8921', 'S', 'Success', '2024-02-22 07:14:21', 'Y', '2024-02-22 07:14:10'),
(440, 1, '/sender_id/add_sender_id', 'undefined', '1_202452124722_9117', 'S', 'Success', '2024-02-22 07:17:32', 'Y', '2024-02-22 07:17:22'),
(441, 1, '/sender_id/add_sender_id', 'undefined', '1_202452124923_5373', 'F', 'QRcode already scanned', '2024-02-22 07:19:23', 'Y', '2024-02-22 07:19:23'),
(442, 1, '/sender_id/add_sender_id', 'undefined', '1_202452131753_8596', 'S', 'Success', '2024-02-22 07:48:05', 'Y', '2024-02-22 07:47:53'),
(443, 1, '/sender_id/add_sender_id', 'undefined', '1_202452131954_1415', 'F', 'QRcode already scanned', '2024-02-22 07:49:54', 'Y', '2024-02-22 07:49:54'),
(444, 1, '/sender_id/add_sender_id', 'undefined', '1_202452150331_3187', 'S', 'Success', '2024-02-22 09:33:45', 'Y', '2024-02-22 09:33:31'),
(445, 0, '/login', 'undefined', '88728280_51088013', 'S', 'Success', '2024-02-22 09:48:32', 'Y', '2024-02-22 09:48:32'),
(446, 1, '/sender_id/add_sender_id', 'undefined', '1_202452153332_8978', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-22 10:03:32'),
(447, 1, '/sender_id/add_sender_id', 'undefined', '1_202452153505_8328', 'S', 'Success', '2024-02-22 10:06:10', 'Y', '2024-02-22 10:05:05'),
(448, 1, '/sender_id/add_sender_id', 'undefined', '1_202452153708_5930', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-22 10:07:15'),
(449, 1, '/sender_id/add_sender_id', 'undefined', '1_202452153843_9006', 'S', 'Success', '2024-02-22 10:09:01', 'Y', '2024-02-22 10:08:43'),
(450, 1, '/sender_id/add_sender_id', 'undefined', '1_202452154032_1061', 'S', 'Success', '2024-02-22 10:10:50', 'Y', '2024-02-22 10:10:32'),
(451, 1, '/sender_id/add_sender_id', 'undefined', '1_202452154233_6295', 'F', 'QRcode already scanned', '2024-02-22 10:12:33', 'Y', '2024-02-22 10:12:33'),
(452, 1, '/sender_id/add_sender_id', 'undefined', '1_202452164010_3393', 'S', 'Success', '2024-02-22 11:10:21', 'Y', '2024-02-22 11:10:10'),
(453, 1, '/sender_id/add_sender_id', 'undefined', '1_202452164211_8233', 'F', 'QRcode already scanned', '2024-02-22 11:12:11', 'Y', '2024-02-22 11:12:11'),
(454, 1, '/logout', 'undefined', '1_202452164719_1876', 'S', 'Success', '2024-02-22 11:17:19', 'Y', '2024-02-22 11:17:19'),
(455, 0, '/login', 'undefined', '82262592_91324927', 'S', 'Success', '2024-02-22 11:17:47', 'Y', '2024-02-22 11:17:47'),
(456, 6, '/logout', 'undefined', '6_202452164758_3955', 'S', 'Success', '2024-02-22 11:17:58', 'Y', '2024-02-22 11:17:58'),
(457, 0, '/login', 'undefined', '83695393_74581649', 'S', 'Success', '2024-02-22 11:18:04', 'Y', '2024-02-22 11:18:04'),
(458, 1, '/sender_id/add_sender_id', 'undefined', '1_202452165403_3936', 'S', 'Success', '2024-02-22 11:24:14', 'Y', '2024-02-22 11:24:03'),
(459, 1, '/sender_id/add_sender_id', 'undefined', '1_202452165636_1362', 'S', 'Success', '2024-02-22 11:26:46', 'Y', '2024-02-22 11:26:36'),
(460, 1, '/sender_id/add_sender_id', 'undefined', '1_202452165914_6396', 'S', 'Success', '2024-02-22 11:29:23', 'Y', '2024-02-22 11:29:14'),
(461, 1, '/sender_id/add_sender_id', 'undefined', '1_202452170211_2056', 'S', 'Success', '2024-02-22 11:32:22', 'Y', '2024-02-22 11:32:11'),
(462, 1, '/sender_id/add_sender_id', 'undefined', '1_202452170412_2678', 'S', 'Success', '2024-02-22 11:34:23', 'Y', '2024-02-22 11:34:12'),
(463, 1, '/sender_id/add_sender_id', 'undefined', '1_202452170519_2404', 'S', 'Success', '2024-02-22 11:35:29', 'Y', '2024-02-22 11:35:19'),
(464, 1, '/sender_id/add_sender_id', 'undefined', '1_202452170719_3389', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-22 11:37:19'),
(465, 0, '/login', 'undefined', '15795484_28561802', 'S', 'Success', '2024-02-22 11:40:23', 'Y', '2024-02-22 11:40:23'),
(466, 0, '/login', 'undefined', '78751706_66486672', 'S', 'Success', '2024-02-24 05:31:54', 'Y', '2024-02-24 05:31:53'),
(467, 1, '/group/send_message', 'undefined', '_2024055110438_216', 'Y', 'Success', '2024-02-24 05:35:23', 'Y', '2024-02-24 05:34:38'),
(468, 1, '/group/only_admin_can_send_msg', 'undefined', '1_202454110713_8370', 'S', 'SUCCESS', '2024-02-24 05:37:38', 'Y', '2024-02-24 05:37:13'),
(469, 1, '/group/user_can_send_msg', 'undefined', '1_202454110807_6370', 'S', 'SUCCESS', '2024-02-24 05:38:31', 'Y', '2024-02-24 05:38:07'),
(470, 1, '/template/create_template', 'undefined', '_2024055111005_148', 'S', 'Success', '2024-02-24 05:40:05', 'Y', '2024-02-24 05:40:05'),
(471, 1, '/group/send_message', 'undefined', '_2024055111048_329', 'Y', 'Success', '2024-02-24 05:41:14', 'Y', '2024-02-24 05:40:48'),
(472, 0, '/login', 'undefined', '23407836_75543396', 'S', 'Success', '2024-02-24 05:46:24', 'Y', '2024-02-24 05:46:24'),
(473, 1, '/group/send_message', 'undefined', '_2024055111642_756', 'Y', 'Success', '2024-02-24 05:47:12', 'Y', '2024-02-24 05:46:42'),
(474, 0, '/logout', 'undefined', '1_202454112052_7863', 'F', 'Invalid token', '2024-02-24 05:50:52', 'Y', '2024-02-24 05:50:52'),
(475, 0, '/login', 'undefined', '61601860_79143965', 'S', 'Success', '2024-02-24 05:51:01', 'Y', '2024-02-24 05:51:01'),
(476, 1, '/logout', 'undefined', '1_202454112657_1918', 'S', 'Success', '2024-02-24 05:56:57', 'Y', '2024-02-24 05:56:57'),
(477, 0, '/login', 'undefined', '43230126_73116492', 'S', 'Success', '2024-02-24 06:03:34', 'Y', '2024-02-24 06:03:34'),
(478, 1, '/logout', 'undefined', '1_202454120545_9536', 'S', 'Success', '2024-02-24 06:35:45', 'Y', '2024-02-24 06:35:45'),
(479, 0, '/login', 'undefined', '66176446_85820537', 'S', 'Success', '2024-02-24 06:37:27', 'Y', '2024-02-24 06:37:27'),
(480, 1, '/group/add_members', 'undefined', '1_202454122138_5935', 'F', 'No contacts found', '2024-02-24 06:52:03', 'Y', '2024-02-24 06:51:38'),
(481, 1, '/group/add_members', 'undefined', '1_202454122443_8987', 'S', 'Success', '2024-02-24 06:55:09', 'Y', '2024-02-24 06:54:43'),
(482, 1, '/group/promote_admin', 'undefined', '1_202454122541_1358', 'S', 'SUCCESS', '2024-02-24 06:56:06', 'Y', '2024-02-24 06:55:41'),
(483, 1, '/group/demote_admin', 'undefined', '1_202454122721_5798', 'S', 'SUCCESS', '2024-02-24 06:57:46', 'Y', '2024-02-24 06:57:21'),
(484, 1, '/group/only_admin_can_send_msg', 'undefined', '1_202454123133_2002', 'S', 'SUCCESS', '2024-02-24 07:01:58', 'Y', '2024-02-24 07:01:33'),
(485, 1, '/group/user_can_send_msg', 'undefined', '1_202454123240_1750', 'S', 'SUCCESS', '2024-02-24 07:03:04', 'Y', '2024-02-24 07:02:40'),
(486, 1, '/group/remove_members', 'undefined', '1_202454123340_7492', 'S', 'Success', '2024-02-24 07:04:05', 'Y', '2024-02-24 07:03:40'),
(487, 0, '/login', 'undefined', '21968342_76598300', 'S', 'Success', '2024-02-26 04:45:56', 'Y', '2024-02-26 04:45:55'),
(488, 1, '/logout', 'undefined', '1_202456101606_5093', 'S', 'Success', '2024-02-26 04:46:07', 'Y', '2024-02-26 04:46:06'),
(489, 0, '/login', 'undefined', '62426531_24763369', 'S', 'Success', '2024-02-26 04:46:17', 'Y', '2024-02-26 04:46:17'),
(490, 2, '/logout', 'undefined', '2_202456101621_5424', 'S', 'Success', '2024-02-26 04:46:21', 'Y', '2024-02-26 04:46:21'),
(491, 0, '/login', 'undefined', '92307195_26450536', 'S', 'Success', '2024-02-26 04:46:33', 'Y', '2024-02-26 04:46:32'),
(492, 3, '/logout', 'undefined', '3_202456101637_9176', 'S', 'Success', '2024-02-26 04:46:37', 'Y', '2024-02-26 04:46:37'),
(493, 0, '/login', 'undefined', '43531353_99652383', 'S', 'Success', '2024-02-26 05:02:47', 'Y', '2024-02-26 05:02:47'),
(494, 1, '/logout', 'undefined', '1_202456103304_9202', 'S', 'Success', '2024-02-26 05:03:04', 'Y', '2024-02-26 05:03:04'),
(495, 0, '/login', 'undefined', '22467130_73187746', 'S', 'Success', '2024-02-26 05:06:40', 'Y', '2024-02-26 05:06:40'),
(496, 0, '/login', 'undefined', '26908451_28046047', 'S', 'Success', '2024-02-26 05:22:48', 'Y', '2024-02-26 05:22:48'),
(497, 1, '/sender_id/add_sender_id', 'undefined', '1_202456105458_6308', 'S', 'Success', '2024-02-26 05:25:11', 'Y', '2024-02-26 05:24:58'),
(498, 1, '/sender_id/add_sender_id', 'undefined', '1_202456105658_8704', 'S', 'Success', '2024-02-26 05:27:13', 'Y', '2024-02-26 05:26:58'),
(499, 1, '/sender_id/add_sender_id', 'undefined', '1_202456105858_3079', 'S', 'Success', '2024-02-26 05:29:16', 'Y', '2024-02-26 05:28:58'),
(500, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110059_7758', 'S', 'Success', '2024-02-26 05:31:18', 'Y', '2024-02-26 05:30:59'),
(501, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110259_3850', 'S', 'Success', '2024-02-26 05:33:14', 'Y', '2024-02-26 05:32:59'),
(502, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110315_9993', 'S', 'Success', '2024-02-26 05:33:44', 'Y', '2024-02-26 05:33:15'),
(503, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110459_2483', 'S', 'Success', '2024-02-26 05:35:17', 'Y', '2024-02-26 05:34:59'),
(504, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110517_4552', 'S', 'Success', '2024-02-26 05:35:36', 'Y', '2024-02-26 05:35:17'),
(505, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110536_1883', 'S', 'Success', '2024-02-26 05:35:54', 'Y', '2024-02-26 05:35:36'),
(506, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110554_7054', 'S', 'Success', '2024-02-26 05:36:12', 'Y', '2024-02-26 05:35:54'),
(507, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110659_5406', 'S', 'Success', '2024-02-26 05:37:15', 'Y', '2024-02-26 05:36:59'),
(508, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110716_6781', 'S', 'Success', '2024-02-26 05:37:33', 'Y', '2024-02-26 05:37:16'),
(509, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110733_9689', 'S', 'Success', '2024-02-26 05:37:51', 'Y', '2024-02-26 05:37:33'),
(510, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110751_7346', 'S', 'Success', '2024-02-26 05:38:08', 'Y', '2024-02-26 05:37:51'),
(511, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110808_1073', 'S', 'Success', '2024-02-26 05:38:26', 'Y', '2024-02-26 05:38:08'),
(512, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110826_1756', 'S', 'Success', '2024-02-26 05:38:43', 'Y', '2024-02-26 05:38:26'),
(513, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110843_6604', 'S', 'Success', '2024-02-26 05:39:01', 'Y', '2024-02-26 05:38:43'),
(514, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110901_5739', 'S', 'Success', '2024-02-26 05:39:19', 'Y', '2024-02-26 05:39:01'),
(515, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110919_5536', 'S', 'Success', '2024-02-26 05:39:37', 'Y', '2024-02-26 05:39:19'),
(516, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110937_7840', 'S', 'Success', '2024-02-26 05:39:59', 'Y', '2024-02-26 05:39:37'),
(517, 1, '/sender_id/add_sender_id', 'undefined', '1_202456110959_8808', 'S', 'Success', '2024-02-26 05:40:19', 'Y', '2024-02-26 05:39:59'),
(518, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111019_1358', 'S', 'Success', '2024-02-26 05:40:38', 'Y', '2024-02-26 05:40:19'),
(519, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111038_3871', 'S', 'Success', '2024-02-26 05:40:56', 'Y', '2024-02-26 05:40:38'),
(520, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111056_3611', 'S', 'Success', '2024-02-26 05:41:13', 'Y', '2024-02-26 05:40:56'),
(521, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111113_5348', 'S', 'Success', '2024-02-26 05:41:29', 'Y', '2024-02-26 05:41:13'),
(522, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111129_3530', 'S', 'Success', '2024-02-26 05:41:46', 'Y', '2024-02-26 05:41:29'),
(523, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111147_3485', 'S', 'Success', '2024-02-26 05:42:05', 'Y', '2024-02-26 05:41:47'),
(524, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111205_5547', 'S', 'Success', '2024-02-26 05:42:25', 'Y', '2024-02-26 05:42:05'),
(525, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111225_4163', 'S', 'Success', '2024-02-26 05:42:38', 'Y', '2024-02-26 05:42:25'),
(526, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111238_8539', 'S', 'Success', '2024-02-26 05:42:51', 'Y', '2024-02-26 05:42:38'),
(527, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111252_7530', 'S', 'Success', '2024-02-26 05:43:09', 'Y', '2024-02-26 05:42:52'),
(528, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111309_5943', 'S', 'Success', '2024-02-26 05:43:23', 'Y', '2024-02-26 05:43:09'),
(529, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111323_3935', 'S', 'Success', '2024-02-26 05:43:36', 'Y', '2024-02-26 05:43:23'),
(530, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111336_8388', 'S', 'Success', '2024-02-26 05:43:49', 'Y', '2024-02-26 05:43:36'),
(531, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111349_9834', 'S', 'Success', '2024-02-26 05:44:02', 'Y', '2024-02-26 05:43:49'),
(532, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111402_2344', 'S', 'Success', '2024-02-26 05:44:14', 'Y', '2024-02-26 05:44:02'),
(533, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111414_4477', 'S', 'Success', '2024-02-26 05:44:30', 'Y', '2024-02-26 05:44:14'),
(534, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111430_7584', 'S', 'Success', '2024-02-26 05:44:44', 'Y', '2024-02-26 05:44:30'),
(535, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111444_8059', 'S', 'Success', '2024-02-26 05:44:57', 'Y', '2024-02-26 05:44:44'),
(536, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111458_9107', 'S', 'Success', '2024-02-26 05:45:10', 'Y', '2024-02-26 05:44:58'),
(537, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111510_1354', 'S', 'Success', '2024-02-26 05:45:28', 'Y', '2024-02-26 05:45:10'),
(538, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111528_6737', 'S', 'Success', '2024-02-26 05:45:39', 'Y', '2024-02-26 05:45:28'),
(539, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111539_6709', 'S', 'Success', '2024-02-26 05:45:54', 'Y', '2024-02-26 05:45:39'),
(540, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111554_4346', 'S', 'Success', '2024-02-26 05:46:05', 'Y', '2024-02-26 05:45:54'),
(541, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111605_7809', 'S', 'Success', '2024-02-26 05:46:19', 'Y', '2024-02-26 05:46:05'),
(542, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111619_4843', 'S', 'Success', '2024-02-26 05:46:32', 'Y', '2024-02-26 05:46:19'),
(543, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111632_4136', 'S', 'Success', '2024-02-26 05:46:51', 'Y', '2024-02-26 05:46:32'),
(544, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111651_7417', 'S', 'Success', '2024-02-26 05:47:04', 'Y', '2024-02-26 05:46:51'),
(545, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111705_2034', 'S', 'Success', '2024-02-26 05:47:15', 'Y', '2024-02-26 05:47:05'),
(546, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111716_7564', 'S', 'Success', '2024-02-26 05:47:30', 'Y', '2024-02-26 05:47:16'),
(547, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111730_7353', 'S', 'Success', '2024-02-26 05:47:44', 'Y', '2024-02-26 05:47:30'),
(548, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111744_1917', 'S', 'Success', '2024-02-26 05:47:58', 'Y', '2024-02-26 05:47:44'),
(549, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111758_1495', 'S', 'Success', '2024-02-26 05:48:10', 'Y', '2024-02-26 05:47:58'),
(550, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111810_2933', 'S', 'Success', '2024-02-26 05:48:24', 'Y', '2024-02-26 05:48:10'),
(551, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111824_6819', 'S', 'Success', '2024-02-26 05:48:36', 'Y', '2024-02-26 05:48:24'),
(552, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111837_6132', 'S', 'Success', '2024-02-26 05:48:51', 'Y', '2024-02-26 05:48:37'),
(553, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111851_2937', 'S', 'Success', '2024-02-26 05:49:03', 'Y', '2024-02-26 05:48:51'),
(554, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111903_3590', 'S', 'Success', '2024-02-26 05:49:17', 'Y', '2024-02-26 05:49:03'),
(555, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111918_8208', 'S', 'Success', '2024-02-26 05:49:30', 'Y', '2024-02-26 05:49:18'),
(556, 1, '/sender_id/add_sender_id', 'undefined', '1_202456111930_9922', 'S', 'Success', '2024-02-26 05:49:46', 'Y', '2024-02-26 05:49:30'),
(557, 1, '/sender_id/add_sender_id', 'undefined', '1_202456112356_8030', 'S', 'Success', '2024-02-26 05:54:13', 'Y', '2024-02-26 05:53:56'),
(558, 1, '/sender_id/add_sender_id', 'undefined', '1_202456112557_4944', 'S', 'Success', '2024-02-26 05:56:08', 'Y', '2024-02-26 05:55:57'),
(559, 1, '/sender_id/add_sender_id', 'undefined', '1_202456112655_1212', 'S', 'Success', '2024-02-26 05:57:06', 'Y', '2024-02-26 05:56:55'),
(560, 1, '/sender_id/add_sender_id', 'undefined', '1_202456112855_9289', 'F', 'QRcode already scanned', '2024-02-26 05:58:55', 'Y', '2024-02-26 05:58:55'),
(561, 1, '/sender_id/add_sender_id', 'undefined', '1_202456113726_7283', 'S', 'Success', '2024-02-26 06:07:37', 'Y', '2024-02-26 06:07:26'),
(562, 1, '/sender_id/add_sender_id', 'undefined', '1_202456113926_7035', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-26 06:09:26'),
(563, 1, '/sender_id/add_sender_id', 'undefined', '1_202456114735_5550', 'S', 'Success', '2024-02-26 06:17:50', 'Y', '2024-02-26 06:17:35'),
(564, 1, '/sender_id/add_sender_id', 'undefined', '1_202456114750_6421', 'S', 'Success', '2024-02-26 06:18:02', 'Y', '2024-02-26 06:17:50'),
(565, 1, '/sender_id/add_sender_id', 'undefined', '1_202456114802_7677', 'S', 'Success', '2024-02-26 06:18:14', 'Y', '2024-02-26 06:18:02'),
(566, 1, '/sender_id/add_sender_id', 'undefined', '1_202456114814_9462', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-26 06:18:14'),
(567, 1, '/logout', 'undefined', '1_202456115030_6280', 'S', 'Success', '2024-02-26 06:20:31', 'Y', '2024-02-26 06:20:30'),
(568, 0, '/login', 'undefined', '13169494_70609720', 'S', 'Success', '2024-02-26 06:22:50', 'Y', '2024-02-26 06:22:50'),
(569, 1, '/sender_id/add_sender_id', 'undefined', '1_202456115323_3513', 'S', 'Success', '2024-02-26 06:23:33', 'Y', '2024-02-26 06:23:23'),
(570, 1, '/sender_id/add_sender_id', 'undefined', '1_202456115523_4510', 'F', 'QRcode already scanned', '2024-02-26 06:25:23', 'Y', '2024-02-26 06:25:23'),
(571, 1, '/sender_id/add_sender_id', 'undefined', '1_202456115748_7662', 'F', 'QRcode already scanned', '2024-02-26 06:27:48', 'Y', '2024-02-26 06:27:48'),
(572, 1, '/sender_id/add_sender_id', 'undefined', '1_202456115835_2668', 'F', 'QRcode already scanned', '2024-02-26 06:28:36', 'Y', '2024-02-26 06:28:35'),
(573, 1, '/sender_id/add_sender_id', 'undefined', '1_202456120149_2902', 'F', 'QRcode already scanned', '2024-02-26 06:31:49', 'Y', '2024-02-26 06:31:49'),
(574, 1, '/sender_id/add_sender_id', 'undefined', '1_202456120437_8904', 'F', 'QRcode already scanned', '2024-02-26 06:34:37', 'Y', '2024-02-26 06:34:37'),
(575, 1, '/sender_id/add_sender_id', 'undefined', '1_202456120843_4766', 'F', 'QRcode already scanned', '2024-02-26 06:38:43', 'Y', '2024-02-26 06:38:43'),
(576, 1, '/sender_id/delete_sender_id', 'undefined', '1_202456121324_3956', 'S', 'Success', '2024-02-26 06:43:24', 'Y', '2024-02-26 06:43:24'),
(577, 1, '/sender_id/add_sender_id', 'undefined', '1_202456121935_8885', 'S', 'Success', '2024-02-26 06:49:46', 'Y', '2024-02-26 06:49:35'),
(578, 1, '/sender_id/add_sender_id', 'undefined', '1_202456122135_9269', 'F', 'QRcode already scanned', '2024-02-26 06:51:35', 'Y', '2024-02-26 06:51:35'),
(579, 1, '/group/promote_admin', 'undefined', '1_202456122918_5429', 'F', 'Sender ID unlinked', '2024-02-26 07:01:39', 'Y', '2024-02-26 06:59:18'),
(580, 1, '/sender_id/add_sender_id', 'undefined', '1_202456123155_2434', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-26 07:01:55'),
(581, 1, '/sender_id/add_sender_id', 'undefined', '1_202456124247_6789', 'S', 'Success', '2024-02-26 07:12:57', 'Y', '2024-02-26 07:12:47'),
(582, 1, '/logout', 'undefined', '1_202456124257_3663', 'S', 'Success', '2024-02-26 07:12:57', 'Y', '2024-02-26 07:12:57'),
(583, 0, '/login', 'undefined', '92939909_56114151', 'S', 'Success', '2024-02-26 07:13:12', 'Y', '2024-02-26 07:13:12'),
(584, 1, '/sender_id/add_sender_id', 'undefined', '1_202456124329_6616', 'S', 'Success', '2024-02-26 07:13:40', 'Y', '2024-02-26 07:13:29'),
(585, 1, '/sender_id/add_sender_id', 'undefined', '1_202456124529_8324', 'F', 'QRcode already scanned', '2024-02-26 07:15:29', 'Y', '2024-02-26 07:15:29'),
(586, 1, '/group/promote_admin', 'undefined', '1_202456124946_2957', 'F', 'Sender ID unlinked', '2024-02-26 07:21:56', 'Y', '2024-02-26 07:19:46'),
(587, 1, '/sender_id/add_sender_id', 'undefined', '1_202456125326_3154', 'S', 'Success', '2024-02-26 07:23:38', 'Y', '2024-02-26 07:23:26'),
(588, 0, '/group/promote_admin', 'undefined', '1_202456124946_2957', 'F', 'Request already processed', '2024-02-26 07:24:43', 'Y', '2024-02-26 07:24:43'),
(589, 1, '/sender_id/add_sender_id', 'undefined', '1_202456125527_9719', 'F', 'QRcode already scanned', '2024-02-26 07:25:27', 'Y', '2024-02-26 07:25:27'),
(590, 1, '/group/promote_admin', 'undefined', '1_20ds24946_2957', 'F', 'Sender ID unlinked', '2024-02-26 07:27:38', 'Y', '2024-02-26 07:25:36'),
(591, 1, '/sender_id/add_sender_id', 'undefined', '1_202456125806_3751', 'S', 'Success', '2024-02-26 07:28:17', 'Y', '2024-02-26 07:28:06'),
(592, 1, '/group/promote_admin', 'undefined', '1_20ds24946sj57', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-26 07:29:36'),
(593, 1, '/sender_id/add_sender_id', 'undefined', '1_202456130007_1141', 'F', 'QRcode already scanned', '2024-02-26 07:30:07', 'Y', '2024-02-26 07:30:07'),
(594, 1, '/sender_id/add_sender_id', 'undefined', '1_202456130231_9080', 'S', 'Success', '2024-02-26 07:32:43', 'Y', '2024-02-26 07:32:31'),
(595, 1, '/group/promote_admin', 'undefined', '1_20ds24957', 'F', 'Sender ID unlinked', '2024-02-26 07:36:11', 'Y', '2024-02-26 07:34:09'),
(596, 1, '/sender_id/add_sender_id', 'undefined', '1_202456130925_7944', 'S', 'Success', '2024-02-26 07:39:52', 'Y', '2024-02-26 07:39:25'),
(597, 0, '/group/promote_admin', 'undefined', '1_20ds24957', 'F', 'Request already processed', '2024-02-26 07:41:27', 'Y', '2024-02-26 07:41:27'),
(598, 1, '/group/promote_admin', 'undefined', '1_dgf20ds24957', 'F', 'Sender ID unlinked', '2024-02-26 07:43:41', 'Y', '2024-02-26 07:41:38'),
(599, 1, '/sender_id/add_sender_id', 'undefined', '1_202456131351_6561', 'S', 'Success', '2024-02-26 07:44:03', 'Y', '2024-02-26 07:43:51'),
(600, 1, '/sender_id/add_sender_id', 'undefined', '1_202456131551_3602', 'F', 'QRcode already scanned', '2024-02-26 07:45:51', 'Y', '2024-02-26 07:45:51'),
(601, 1, '/group/add_members', 'undefined', '1_202456132222_3593', 'F', 'Sender ID unlinked', '2024-02-26 07:54:24', 'Y', '2024-02-26 07:52:22'),
(602, 1, '/sender_id/add_sender_id', 'undefined', '1_202456132452_8153', 'S', 'Success', '2024-02-26 07:55:05', 'Y', '2024-02-26 07:54:52'),
(603, 1, '/sender_id/add_sender_id', 'undefined', '1_202456132652_4164', 'F', 'QRcode already scanned', '2024-02-26 07:56:53', 'Y', '2024-02-26 07:56:52'),
(604, 1, '/group/send_message', 'undefined', '_2024057141721_812', 'F', 'Sender ID unlinked', '2024-02-26 08:49:25', 'Y', '2024-02-26 08:47:21'),
(605, 1, '/sender_id/add_sender_id', 'undefined', '1_202456141939_7717', 'S', 'Success', '2024-02-26 08:49:51', 'Y', '2024-02-26 08:49:39'),
(606, 1, '/sender_id/add_sender_id', 'undefined', '1_202456142139_8434', 'F', 'QRcode already scanned', '2024-02-26 08:51:39', 'Y', '2024-02-26 08:51:39'),
(607, 1, '/group/send_message', 'undefined', '_2024057142218_189', 'F', 'Sender ID unlinked', '2024-02-26 08:54:49', 'Y', '2024-02-26 08:52:18'),
(608, 1, '/sender_id/add_sender_id', 'undefined', '1_202456142531_3353', 'S', 'Success', '2024-02-26 08:55:42', 'Y', '2024-02-26 08:55:31'),
(609, 1, '/group/send_message', 'undefined', '_2024057145426_494', 'F', 'Sender ID unlinked', '2024-02-26 09:26:38', 'Y', '2024-02-26 09:24:26'),
(610, 0, '/login', 'undefined', '87360602_64531720', 'S', 'Success', '2024-02-26 14:33:26', 'Y', '2024-02-26 14:33:26'),
(611, 1, '/logout', 'undefined', '1_202456200334_1018', 'S', 'Success', '2024-02-26 14:33:35', 'Y', '2024-02-26 14:33:34'),
(612, 0, '/login', 'undefined', '23794432_70229256', 'S', 'Success', '2024-02-26 14:33:40', 'Y', '2024-02-26 14:33:40'),
(613, 1, '/sender_id/add_sender_id', 'undefined', '1_202456200401_3654', 'S', 'Success', '2024-02-26 14:34:11', 'Y', '2024-02-26 14:34:01'),
(614, 1, '/group/promote_admin', 'undefined', '1_202456201142_1465', 'S', 'SUCCESS', '2024-02-26 14:43:16', 'Y', '2024-02-26 14:41:42'),
(615, 1, '/group/demote_admin', 'undefined', '1_202456201409_5857', 'S', 'SUCCESS', '2024-02-26 14:44:37', 'Y', '2024-02-26 14:44:09'),
(616, 1, '/group/promote_admin', 'undefined', '1_202456201746_1839', 'S', 'SUCCESS', '2024-02-26 14:48:17', 'Y', '2024-02-26 14:47:46'),
(617, 1, '/group/demote_admin', 'undefined', '1_202456201956_6548', 'F', 'Error occurred', '2024-02-26 14:50:27', 'Y', '2024-02-26 14:49:56'),
(618, 1, '/group/promote_admin', 'undefined', '1_202456202945_9944', 'S', 'SUCCESS', '2024-02-26 15:00:16', 'Y', '2024-02-26 14:59:45'),
(619, 1, '/group/demote_admin', 'undefined', '1_202456203104_1533', 'S', 'SUCCESS', '2024-02-26 15:01:36', 'Y', '2024-02-26 15:01:04'),
(620, 0, '/login', 'undefined', '16141513_23709921', 'S', 'Success', '2024-02-26 15:07:32', 'Y', '2024-02-26 15:07:31'),
(621, 1, '/sender_id/add_sender_id', 'undefined', '1_202456205214_4015', 'S', 'Success', '2024-02-26 15:22:24', 'Y', '2024-02-26 15:22:14'),
(622, 1, '/sender_id/add_sender_id', 'undefined', '1_202456205414_6156', 'F', 'QRcode already scanned', '2024-02-26 15:24:14', 'Y', '2024-02-26 15:24:14'),
(623, 1, '/logout', 'undefined', '1_202456210250_1794', 'S', 'Success', '2024-02-26 15:32:51', 'Y', '2024-02-26 15:32:50');

-- --------------------------------------------------------

--
-- Table structure for table `cron_compose`
--

CREATE TABLE IF NOT EXISTS `cron_compose` (
  `cron_com_id` int NOT NULL,
  `com_msg_id` int NOT NULL,
  `com_msg_media_id` int NOT NULL,
  `user_id` int NOT NULL,
  `group_master_id` int NOT NULL,
  `cron_status` varchar(1) NOT NULL,
  `schedule_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `reschedule_date` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `cron_compose`
--

INSERT INTO `cron_compose` (`cron_com_id`, `com_msg_id`, `com_msg_media_id`, `user_id`, `group_master_id`, `cron_status`, `schedule_date`, `reschedule_date`) VALUES
(1, 87, 88, 1, 1, 'Y', '2024-02-05 06:47:26', NULL),
(2, 88, 89, 1, 1, 'Y', '2024-02-05 06:49:27', NULL),
(3, 89, 90, 1, 1, 'Y', '2024-02-05 06:50:31', NULL),
(4, 89, 91, 1, 1, 'Y', '2024-02-05 06:50:31', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `group_contacts`
--

CREATE TABLE IF NOT EXISTS `group_contacts` (
  `group_contacts_id` int NOT NULL,
  `user_id` int NOT NULL,
  `group_master_id` int NOT NULL,
  `campaign_name` varchar(30) NOT NULL,
  `mobile_no` varchar(30) NOT NULL,
  `mobile_id` varchar(30) DEFAULT NULL,
  `comments` varchar(50) NOT NULL,
  `group_contacts_status` char(1) NOT NULL,
  `group_contacts_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `remove_comments` varchar(50) DEFAULT NULL,
  `admin_status` varchar(1) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=772 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT;

--
-- Dumping data for table `group_contacts`
--

INSERT INTO `group_contacts` (`group_contacts_id`, `user_id`, `group_master_id`, `campaign_name`, `mobile_no`, `mobile_id`, `comments`, `group_contacts_status`, `group_contacts_entry_date`, `remove_comments`, `admin_status`) VALUES
(1, 1, 1, 'ca_TESTING_023_1', '919361419661', '919361419661', 'Success', 'R', '2024-01-23 08:02:57', 'Testing', NULL),
(2, 1, 1, 'ca_TESTING_023_2', '916380885546', '916380885546', 'Success', 'R', '2024-01-23 08:05:26', 'Testing', 'R'),
(3, 1, 1, 'ca_TESTING_025_3', '916369841530', '916369841530', 'Success', 'R', '2024-01-25 06:22:51', 'testing', NULL),
(4, 1, 1, 'ca_TESTING_046_4', '919025167792', '919025167792', 'Success', 'Y', '2024-02-15 07:04:20', NULL, NULL),
(5, 1, 1, 'ca_TESTING_046_4', '919786448157', '919786448157', 'Success', 'Y', '2024-02-15 07:04:22', NULL, NULL),
(6, 1, 1, 'ca_TESTING_046_5', '916380747454', '916380747454', 'Success', 'Y', '2024-02-15 07:14:29', NULL, NULL),
(7, 1, 1, 'ca_TESTING_046_6', '917904778285', '917904778285', 'Success', 'Y', '2024-02-15 07:20:20', NULL, 'Y'),
(9, 1, 11, 'cron_campaign', '916380885546', '916380885546', 'Success', 'Y', '2024-02-22 10:40:20', NULL, NULL),
(10, 1, 11, 'cron_campaign', '916305782559', '916305782559', 'Success', 'Y', '2024-02-22 10:40:20', NULL, NULL),
(11, 1, 11, 'cron_campaign', '917904778285', '917904778285', 'Success', 'Y', '2024-02-22 10:40:20', NULL, NULL),
(12, 1, 8, 'cron_campaign', '916380885546', '916380885546', 'Success', 'Y', '2024-02-22 10:40:20', NULL, NULL),
(13, 1, 8, 'cron_campaign', '916305782559', '916305782559', 'Success', 'Y', '2024-02-22 10:40:20', NULL, NULL),
(14, 1, 8, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-22 10:40:20', NULL, NULL),
(15, 1, 9, 'cron_campaign', '916380885546', '916380885546', 'Success', 'Y', '2024-02-22 10:40:20', NULL, NULL),
(16, 1, 9, 'cron_campaign', '916305782559', '916305782559', 'Success', 'Y', '2024-02-22 10:40:20', NULL, NULL),
(17, 1, 10, 'cron_campaign', '916380747454', '916380747454', 'Success', 'Y', '2024-02-22 10:40:21', NULL, NULL),
(18, 1, 10, 'cron_campaign', '919786448157', '919786448157', 'Success', 'Y', '2024-02-22 10:40:21', NULL, NULL),
(19, 1, 10, 'cron_campaign', '919894606748', '919894606748', 'Success', 'Y', '2024-02-22 10:40:21', NULL, NULL),
(20, 1, 10, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-22 10:40:21', NULL, NULL),
(21, 1, 10, 'cron_campaign', '916380885546', '916380885546', 'Success', 'Y', '2024-02-22 10:40:21', NULL, NULL),
(22, 1, 10, 'cron_campaign', '916305782559', '916305782559', 'Success', 'Y', '2024-02-22 10:40:21', NULL, NULL),
(23, 1, 10, 'cron_campaign', '919025167792', '919025167792', 'Success', 'Y', '2024-02-22 10:40:22', NULL, NULL),
(24, 1, 10, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-22 10:40:22', NULL, NULL),
(25, 1, 10, 'cron_campaign', '919363113380', '919363113380', 'Success', 'Y', '2024-02-22 10:40:22', NULL, NULL),
(43, 1, 12, 'cron_campaign', '916380747454', '916380747454', 'Success', 'Y', '2024-02-22 10:55:21', NULL, NULL),
(44, 1, 12, 'cron_campaign', '916305782559', '916305782559', 'Success', 'Y', '2024-02-22 10:55:21', NULL, NULL),
(45, 1, 12, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-22 10:55:21', NULL, NULL),
(46, 1, 13, 'cron_campaign', '916305782559', '916305782559', 'Success', 'Y', '2024-02-22 11:00:19', NULL, NULL),
(47, 1, 13, 'cron_campaign', '916380885546', '916380885546', 'Success', 'Y', '2024-02-22 11:00:20', NULL, NULL),
(48, 1, 15, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:36:36', NULL, NULL),
(49, 1, 16, 'cron_campaign', '919502657666', '919502657666', 'Success', 'Y', '2024-02-22 11:36:36', NULL, NULL),
(50, 1, 16, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:36:36', NULL, NULL),
(51, 1, 16, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:36:37', NULL, NULL),
(52, 1, 16, 'cron_campaign', '918328464985', '918328464985', 'Success', 'Y', '2024-02-22 11:36:37', NULL, NULL),
(53, 1, 16, 'cron_campaign', '918008278398', '918008278398', 'Success', 'Y', '2024-02-22 11:36:37', NULL, NULL),
(54, 1, 16, 'cron_campaign', '919347478229', '919347478229', 'Success', 'Y', '2024-02-22 11:36:37', NULL, NULL),
(55, 1, 16, 'cron_campaign', '919010507528', '919010507528', 'Success', 'Y', '2024-02-22 11:36:37', NULL, NULL),
(56, 1, 16, 'cron_campaign', '918074490863', '918074490863', 'Success', 'Y', '2024-02-22 11:36:37', NULL, NULL),
(57, 1, 16, 'cron_campaign', '918179455249', '918179455249', 'Success', 'Y', '2024-02-22 11:36:37', NULL, NULL),
(58, 1, 16, 'cron_campaign', '919441262259', '919441262259', 'Success', 'Y', '2024-02-22 11:36:37', NULL, NULL),
(59, 1, 16, 'cron_campaign', '919398595735', '919398595735', 'Success', 'Y', '2024-02-22 11:36:37', NULL, NULL),
(60, 1, 16, 'cron_campaign', '919177631148', '919177631148', 'Success', 'Y', '2024-02-22 11:36:37', NULL, NULL),
(61, 1, 16, 'cron_campaign', '919676958543', '919676958543', 'Success', 'Y', '2024-02-22 11:36:37', NULL, NULL),
(62, 1, 16, 'cron_campaign', '917780654958', '917780654958', 'Success', 'Y', '2024-02-22 11:36:37', NULL, NULL),
(63, 1, 16, 'cron_campaign', '917997830271', '917997830271', 'Success', 'Y', '2024-02-22 11:36:37', NULL, NULL),
(64, 1, 16, 'cron_campaign', '917337491141', '917337491141', 'Success', 'Y', '2024-02-22 11:36:38', NULL, NULL),
(65, 1, 16, 'cron_campaign', '919177558496', '919177558496', 'Success', 'Y', '2024-02-22 11:36:38', NULL, NULL),
(66, 1, 16, 'cron_campaign', '919052090038', '919052090038', 'Success', 'Y', '2024-02-22 11:36:38', NULL, NULL),
(67, 1, 16, 'cron_campaign', '919490346724', '919490346724', 'Success', 'Y', '2024-02-22 11:36:38', NULL, NULL),
(68, 1, 16, 'cron_campaign', '919652096853', '919652096853', 'Success', 'Y', '2024-02-22 11:36:38', NULL, NULL),
(69, 1, 16, 'cron_campaign', '917993379247', '917993379247', 'Success', 'Y', '2024-02-22 11:36:39', NULL, NULL),
(70, 1, 16, 'cron_campaign', '917981669747', '917981669747', 'Success', 'Y', '2024-02-22 11:36:40', NULL, NULL),
(71, 1, 16, 'cron_campaign', '917095928214', '917095928214', 'Success', 'Y', '2024-02-22 11:36:40', NULL, NULL),
(72, 1, 16, 'cron_campaign', '919491934069', '919491934069', 'Success', 'Y', '2024-02-22 11:36:40', NULL, NULL),
(73, 1, 16, 'cron_campaign', '919110308640', '919110308640', 'Success', 'Y', '2024-02-22 11:36:40', NULL, NULL),
(74, 1, 16, 'cron_campaign', '919553599349', '919553599349', 'Success', 'Y', '2024-02-22 11:36:40', NULL, NULL),
(75, 1, 16, 'cron_campaign', '916281066901', '916281066901', 'Success', 'Y', '2024-02-22 11:36:40', NULL, NULL),
(76, 1, 16, 'cron_campaign', '916302926084', '916302926084', 'Success', 'Y', '2024-02-22 11:36:40', NULL, NULL),
(77, 1, 16, 'cron_campaign', '916303284754', '916303284754', 'Success', 'Y', '2024-02-22 11:36:41', NULL, NULL),
(78, 1, 16, 'cron_campaign', '917013607406', '917013607406', 'Success', 'Y', '2024-02-22 11:36:41', NULL, NULL),
(79, 1, 16, 'cron_campaign', '917013861423', '917013861423', 'Success', 'Y', '2024-02-22 11:36:41', NULL, NULL),
(80, 1, 16, 'cron_campaign', '917286801662', '917286801662', 'Success', 'Y', '2024-02-22 11:36:41', NULL, NULL),
(81, 1, 16, 'cron_campaign', '917287003485', '917287003485', 'Success', 'Y', '2024-02-22 11:36:41', NULL, NULL),
(82, 1, 16, 'cron_campaign', '917331128715', '917331128715', 'Success', 'Y', '2024-02-22 11:36:41', NULL, NULL),
(83, 1, 16, 'cron_campaign', '917780375195', '917780375195', 'Success', 'Y', '2024-02-22 11:36:41', NULL, NULL),
(84, 1, 16, 'cron_campaign', '917799168329', '917799168329', 'Success', 'Y', '2024-02-22 11:36:42', NULL, NULL),
(85, 1, 16, 'cron_campaign', '917981345956', '917981345956', 'Success', 'Y', '2024-02-22 11:36:42', NULL, NULL),
(86, 1, 16, 'cron_campaign', '917981353358', '917981353358', 'Success', 'Y', '2024-02-22 11:36:42', NULL, NULL),
(87, 1, 16, 'cron_campaign', '917989491255', '917989491255', 'Success', 'Y', '2024-02-22 11:36:42', NULL, NULL),
(88, 1, 16, 'cron_campaign', '917989811109', '917989811109', 'Success', 'Y', '2024-02-22 11:36:42', NULL, NULL),
(89, 1, 16, 'cron_campaign', '918008729591', '918008729591', 'Success', 'Y', '2024-02-22 11:36:42', NULL, NULL),
(90, 1, 16, 'cron_campaign', '918106818046', '918106818046', 'Success', 'Y', '2024-02-22 11:36:42', NULL, NULL),
(91, 1, 16, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:36:42', NULL, NULL),
(92, 1, 16, 'cron_campaign', '918142904881', '918142904881', 'Success', 'Y', '2024-02-22 11:36:42', NULL, NULL),
(93, 1, 16, 'cron_campaign', '918179279464', '918179279464', 'Success', 'Y', '2024-02-22 11:36:42', NULL, NULL),
(94, 1, 16, 'cron_campaign', '918186903145', '918186903145', 'Success', 'Y', '2024-02-22 11:36:42', NULL, NULL),
(95, 1, 16, 'cron_campaign', '918328494530', '918328494530', 'Success', 'Y', '2024-02-22 11:36:43', NULL, NULL),
(96, 1, 16, 'cron_campaign', '918331023268', '918331023268', 'Success', 'Y', '2024-02-22 11:36:43', NULL, NULL),
(97, 1, 16, 'cron_campaign', '918374905369', '918374905369', 'Success', 'Y', '2024-02-22 11:36:43', NULL, NULL),
(98, 1, 16, 'cron_campaign', '918374972212', '918374972212', 'Success', 'Y', '2024-02-22 11:36:43', NULL, NULL),
(99, 1, 16, 'cron_campaign', '918498899314', '918498899314', 'Success', 'Y', '2024-02-22 11:36:43', NULL, NULL),
(100, 1, 16, 'cron_campaign', '918500110908', '918500110908', 'Success', 'Y', '2024-02-22 11:36:43', NULL, NULL),
(101, 1, 16, 'cron_campaign', '918500850173', '918500850173', 'Success', 'Y', '2024-02-22 11:36:43', NULL, NULL),
(102, 1, 16, 'cron_campaign', '918500861319', '918500861319', 'Success', 'Y', '2024-02-22 11:36:44', NULL, NULL),
(103, 1, 16, 'cron_campaign', '918639327384', '918639327384', 'Success', 'Y', '2024-02-22 11:36:44', NULL, NULL),
(104, 1, 16, 'cron_campaign', '918688327516', '918688327516', 'Success', 'Y', '2024-02-22 11:36:44', NULL, NULL),
(105, 1, 16, 'cron_campaign', '918790556151', '918790556151', 'Success', 'Y', '2024-02-22 11:36:44', NULL, NULL),
(106, 1, 16, 'cron_campaign', '918790676402', '918790676402', 'Success', 'Y', '2024-02-22 11:36:44', NULL, NULL),
(107, 1, 16, 'cron_campaign', '918985761462', '918985761462', 'Success', 'Y', '2024-02-22 11:36:44', NULL, NULL),
(108, 1, 16, 'cron_campaign', '919100975971', '919100975971', 'Success', 'Y', '2024-02-22 11:36:44', NULL, NULL),
(109, 1, 16, 'cron_campaign', '919290550999', '919290550999', 'Success', 'Y', '2024-02-22 11:36:44', NULL, NULL),
(110, 1, 16, 'cron_campaign', '919391782250', '919391782250', 'Success', 'Y', '2024-02-22 11:36:45', NULL, NULL),
(111, 1, 16, 'cron_campaign', '919440008760', '919440008760', 'Success', 'Y', '2024-02-22 11:36:45', NULL, NULL),
(112, 1, 16, 'cron_campaign', '919440151049', '919440151049', 'Success', 'Y', '2024-02-22 11:36:45', NULL, NULL),
(113, 1, 16, 'cron_campaign', '919440203450', '919440203450', 'Success', 'Y', '2024-02-22 11:36:45', NULL, NULL),
(114, 1, 16, 'cron_campaign', '919440241667', '919440241667', 'Success', 'Y', '2024-02-22 11:36:45', NULL, NULL),
(115, 1, 16, 'cron_campaign', '919491783926', '919491783926', 'Success', 'Y', '2024-02-22 11:36:45', NULL, NULL),
(116, 1, 16, 'cron_campaign', '919491817006', '919491817006', 'Success', 'Y', '2024-02-22 11:36:45', NULL, NULL),
(117, 1, 16, 'cron_campaign', '919491927674', '919491927674', 'Success', 'Y', '2024-02-22 11:36:45', NULL, NULL),
(118, 1, 16, 'cron_campaign', '919492265836', '919492265836', 'Success', 'Y', '2024-02-22 11:36:46', NULL, NULL),
(119, 1, 16, 'cron_campaign', '919494123201', '919494123201', 'Success', 'Y', '2024-02-22 11:36:46', NULL, NULL),
(120, 1, 16, 'cron_campaign', '919494433616', '919494433616', 'Success', 'Y', '2024-02-22 11:36:46', NULL, NULL),
(121, 1, 16, 'cron_campaign', '919494589355', '919494589355', 'Success', 'Y', '2024-02-22 11:36:46', NULL, NULL),
(122, 1, 16, 'cron_campaign', '919542359778', '919542359778', 'Success', 'Y', '2024-02-22 11:36:46', NULL, NULL),
(123, 1, 16, 'cron_campaign', '919550096955', '919550096955', 'Success', 'Y', '2024-02-22 11:36:46', NULL, NULL),
(124, 1, 16, 'cron_campaign', '919618681214', '919618681214', 'Success', 'Y', '2024-02-22 11:36:46', NULL, NULL),
(125, 1, 16, 'cron_campaign', '919652885898', '919652885898', 'Success', 'Y', '2024-02-22 11:36:46', NULL, NULL),
(126, 1, 16, 'cron_campaign', '919666021666', '919666021666', 'Success', 'Y', '2024-02-22 11:36:46', NULL, NULL),
(127, 1, 16, 'cron_campaign', '919676015490', '919676015490', 'Success', 'Y', '2024-02-22 11:36:46', NULL, NULL),
(128, 1, 16, 'cron_campaign', '919676778875', '919676778875', 'Success', 'Y', '2024-02-22 11:36:46', NULL, NULL),
(129, 1, 16, 'cron_campaign', '919704003692', '919704003692', 'Success', 'Y', '2024-02-22 11:36:46', NULL, NULL),
(130, 1, 16, 'cron_campaign', '919705080547', '919705080547', 'Success', 'Y', '2024-02-22 11:36:47', NULL, NULL),
(131, 1, 16, 'cron_campaign', '919866818348', '919866818348', 'Success', 'Y', '2024-02-22 11:36:47', NULL, NULL),
(132, 1, 16, 'cron_campaign', '919908224770', '919908224770', 'Success', 'Y', '2024-02-22 11:36:47', NULL, NULL),
(133, 1, 16, 'cron_campaign', '919908315179', '919908315179', 'Success', 'Y', '2024-02-22 11:36:47', NULL, NULL),
(134, 1, 16, 'cron_campaign', '919908737374', '919908737374', 'Success', 'Y', '2024-02-22 11:36:47', NULL, NULL),
(135, 1, 16, 'cron_campaign', '919908743205', '919908743205', 'Success', 'Y', '2024-02-22 11:36:47', NULL, NULL),
(136, 1, 16, 'cron_campaign', '919949108905', '919949108905', 'Success', 'Y', '2024-02-22 11:36:47', NULL, NULL),
(137, 1, 16, 'cron_campaign', '919959042414', '919959042414', 'Success', 'Y', '2024-02-22 11:36:47', NULL, NULL),
(138, 1, 16, 'cron_campaign', '919959286540', '919959286540', 'Success', 'Y', '2024-02-22 11:36:48', NULL, NULL),
(139, 1, 16, 'cron_campaign', '919959460435', '919959460435', 'Success', 'Y', '2024-02-22 11:36:48', NULL, NULL),
(140, 1, 16, 'cron_campaign', '919963116240', '919963116240', 'Success', 'Y', '2024-02-22 11:36:48', NULL, NULL),
(141, 1, 16, 'cron_campaign', '919963934883', '919963934883', 'Success', 'Y', '2024-02-22 11:36:48', NULL, NULL),
(142, 1, 16, 'cron_campaign', '919963937347', '919963937347', 'Success', 'Y', '2024-02-22 11:36:48', NULL, NULL),
(143, 1, 16, 'cron_campaign', '919966254954', '919966254954', 'Success', 'Y', '2024-02-22 11:36:48', NULL, NULL),
(144, 1, 16, 'cron_campaign', '919989074264', '919989074264', 'Success', 'Y', '2024-02-22 11:36:48', NULL, NULL),
(145, 1, 17, 'cron_campaign', '919502657666', '919502657666', 'Success', 'Y', '2024-02-22 11:36:49', NULL, NULL),
(146, 1, 17, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:36:49', NULL, NULL),
(147, 1, 17, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:36:49', NULL, NULL),
(148, 1, 17, 'cron_campaign', '919391212326', '919391212326', 'Success', 'Y', '2024-02-22 11:36:49', NULL, NULL),
(149, 1, 17, 'cron_campaign', '919502211021', '919502211021', 'Success', 'Y', '2024-02-22 11:36:49', NULL, NULL),
(150, 1, 17, 'cron_campaign', '919989240125', '919989240125', 'Success', 'Y', '2024-02-22 11:36:49', NULL, NULL),
(151, 1, 17, 'cron_campaign', '919100500120', '919100500120', 'Success', 'Y', '2024-02-22 11:36:49', NULL, NULL),
(152, 1, 17, 'cron_campaign', '917382410047', '917382410047', 'Success', 'Y', '2024-02-22 11:36:49', NULL, NULL),
(153, 1, 17, 'cron_campaign', '917036358319', '917036358319', 'Success', 'Y', '2024-02-22 11:36:50', NULL, NULL),
(154, 1, 17, 'cron_campaign', '919390768299', '919390768299', 'Success', 'Y', '2024-02-22 11:36:50', NULL, NULL),
(155, 1, 17, 'cron_campaign', '917989654166', '917989654166', 'Success', 'Y', '2024-02-22 11:36:50', NULL, NULL),
(156, 1, 17, 'cron_campaign', '918978046095', '918978046095', 'Success', 'Y', '2024-02-22 11:36:50', NULL, NULL),
(157, 1, 17, 'cron_campaign', '919652097030', '919652097030', 'Success', 'Y', '2024-02-22 11:36:50', NULL, NULL),
(158, 1, 17, 'cron_campaign', '916281962456', '916281962456', 'Success', 'Y', '2024-02-22 11:36:50', NULL, NULL),
(159, 1, 17, 'cron_campaign', '919347539101', '919347539101', 'Success', 'Y', '2024-02-22 11:36:50', NULL, NULL),
(160, 1, 17, 'cron_campaign', '918919985899', '918919985899', 'Success', 'Y', '2024-02-22 11:36:50', NULL, NULL),
(161, 1, 17, 'cron_campaign', '919394969798', '919394969798', 'Success', 'Y', '2024-02-22 11:36:51', NULL, NULL),
(162, 1, 17, 'cron_campaign', '919493100101', '919493100101', 'Success', 'Y', '2024-02-22 11:36:51', NULL, NULL),
(163, 1, 17, 'cron_campaign', '919491914999', '919491914999', 'Success', 'Y', '2024-02-22 11:36:51', NULL, NULL),
(164, 1, 17, 'cron_campaign', '919493043886', '919493043886', 'Success', 'Y', '2024-02-22 11:36:51', NULL, NULL),
(165, 1, 17, 'cron_campaign', '917993517681', '917993517681', 'Success', 'Y', '2024-02-22 11:36:51', NULL, NULL),
(166, 1, 17, 'cron_campaign', '917995986580', '917995986580', 'Success', 'Y', '2024-02-22 11:36:51', NULL, NULL),
(167, 1, 17, 'cron_campaign', '919704285672', '919704285672', 'Success', 'Y', '2024-02-22 11:36:51', NULL, NULL),
(168, 1, 17, 'cron_campaign', '919652445806', '919652445806', 'Success', 'Y', '2024-02-22 11:36:51', NULL, NULL),
(169, 1, 17, 'cron_campaign', '919182578411', '919182578411', 'Success', 'Y', '2024-02-22 11:36:52', NULL, NULL),
(170, 1, 17, 'cron_campaign', '916281021672', '916281021672', 'Success', 'Y', '2024-02-22 11:36:52', NULL, NULL),
(171, 1, 17, 'cron_campaign', '916281489280', '916281489280', 'Success', 'Y', '2024-02-22 11:36:52', NULL, NULL),
(172, 1, 17, 'cron_campaign', '916304878912', '916304878912', 'Success', 'Y', '2024-02-22 11:36:52', NULL, NULL),
(173, 1, 17, 'cron_campaign', '916305177272', '916305177272', 'Success', 'Y', '2024-02-22 11:36:52', NULL, NULL),
(174, 1, 17, 'cron_campaign', '916305196937', '916305196937', 'Success', 'Y', '2024-02-22 11:36:52', NULL, NULL),
(175, 1, 17, 'cron_campaign', '917032027256', '917032027256', 'Success', 'Y', '2024-02-22 11:36:52', NULL, NULL),
(176, 1, 17, 'cron_campaign', '917032324148', '917032324148', 'Success', 'Y', '2024-02-22 11:36:52', NULL, NULL),
(177, 1, 17, 'cron_campaign', '917569767824', '917569767824', 'Success', 'Y', '2024-02-22 11:36:52', NULL, NULL),
(178, 1, 17, 'cron_campaign', '917675825550', '917675825550', 'Success', 'Y', '2024-02-22 11:36:53', NULL, NULL),
(179, 1, 17, 'cron_campaign', '917702491859', '917702491859', 'Success', 'Y', '2024-02-22 11:36:53', NULL, NULL),
(180, 1, 17, 'cron_campaign', '917702777345', '917702777345', 'Success', 'Y', '2024-02-22 11:36:53', NULL, NULL),
(181, 1, 17, 'cron_campaign', '917760215131', '917760215131', 'Success', 'Y', '2024-02-22 11:36:53', NULL, NULL),
(182, 1, 17, 'cron_campaign', '917893362289', '917893362289', 'Success', 'Y', '2024-02-22 11:36:53', NULL, NULL),
(183, 1, 17, 'cron_campaign', '917893479817', '917893479817', 'Success', 'Y', '2024-02-22 11:36:53', NULL, NULL),
(184, 1, 17, 'cron_campaign', '917981630591', '917981630591', 'Success', 'Y', '2024-02-22 11:36:53', NULL, NULL),
(185, 1, 17, 'cron_campaign', '917989521092', '917989521092', 'Success', 'Y', '2024-02-22 11:36:53', NULL, NULL),
(186, 1, 17, 'cron_campaign', '917993314340', '917993314340', 'Success', 'Y', '2024-02-22 11:36:53', NULL, NULL),
(187, 1, 17, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:36:53', NULL, NULL),
(188, 1, 17, 'cron_campaign', '918185941861', '918185941861', 'Success', 'Y', '2024-02-22 11:36:53', NULL, NULL),
(189, 1, 17, 'cron_campaign', '918309062544', '918309062544', 'Success', 'Y', '2024-02-22 11:36:54', NULL, NULL),
(190, 1, 17, 'cron_campaign', '918374169834', '918374169834', 'Success', 'Y', '2024-02-22 11:36:54', NULL, NULL),
(191, 1, 17, 'cron_campaign', '918500274602', '918500274602', 'Success', 'Y', '2024-02-22 11:36:54', NULL, NULL),
(192, 1, 17, 'cron_campaign', '919063398681', '919063398681', 'Success', 'Y', '2024-02-22 11:36:54', NULL, NULL),
(193, 1, 17, 'cron_campaign', '919100806476', '919100806476', 'Success', 'Y', '2024-02-22 11:36:54', NULL, NULL),
(194, 1, 17, 'cron_campaign', '919110526664', '919110526664', 'Success', 'Y', '2024-02-22 11:36:54', NULL, NULL),
(195, 1, 17, 'cron_campaign', '919110547994', '919110547994', 'Success', 'Y', '2024-02-22 11:36:54', NULL, NULL),
(196, 1, 17, 'cron_campaign', '919177531532', '919177531532', 'Success', 'Y', '2024-02-22 11:36:54', NULL, NULL),
(197, 1, 17, 'cron_campaign', '919347334094', '919347334094', 'Success', 'Y', '2024-02-22 11:36:54', NULL, NULL),
(198, 1, 17, 'cron_campaign', '919391250575', '919391250575', 'Success', 'Y', '2024-02-22 11:36:55', NULL, NULL),
(199, 1, 17, 'cron_campaign', '919391879848', '919391879848', 'Success', 'Y', '2024-02-22 11:36:55', NULL, NULL),
(200, 1, 17, 'cron_campaign', '919398703169', '919398703169', 'Success', 'Y', '2024-02-22 11:36:55', NULL, NULL),
(201, 1, 17, 'cron_campaign', '919440554790', '919440554790', 'Success', 'Y', '2024-02-22 11:36:55', NULL, NULL),
(202, 1, 17, 'cron_campaign', '919441065998', '919441065998', 'Success', 'Y', '2024-02-22 11:36:55', NULL, NULL),
(203, 1, 17, 'cron_campaign', '919490608343', '919490608343', 'Success', 'Y', '2024-02-22 11:36:55', NULL, NULL),
(204, 1, 17, 'cron_campaign', '919502358148', '919502358148', 'Success', 'Y', '2024-02-22 11:36:55', NULL, NULL),
(205, 1, 17, 'cron_campaign', '919553807304', '919553807304', 'Success', 'Y', '2024-02-22 11:36:55', NULL, NULL),
(206, 1, 17, 'cron_campaign', '919573364188', '919573364188', 'Success', 'Y', '2024-02-22 11:36:55', NULL, NULL),
(207, 1, 17, 'cron_campaign', '919581927069', '919581927069', 'Success', 'Y', '2024-02-22 11:36:55', NULL, NULL),
(208, 1, 17, 'cron_campaign', '919603047450', '919603047450', 'Success', 'Y', '2024-02-22 11:36:55', NULL, NULL),
(209, 1, 17, 'cron_campaign', '919618583306', '919618583306', 'Success', 'Y', '2024-02-22 11:36:55', NULL, NULL),
(210, 1, 17, 'cron_campaign', '919652424415', '919652424415', 'Success', 'Y', '2024-02-22 11:36:55', NULL, NULL),
(211, 1, 17, 'cron_campaign', '919652460580', '919652460580', 'Success', 'Y', '2024-02-22 11:36:56', NULL, NULL),
(212, 1, 17, 'cron_campaign', '919666039888', '919666039888', 'Success', 'Y', '2024-02-22 11:36:56', NULL, NULL),
(213, 1, 17, 'cron_campaign', '919676721152', '919676721152', 'Success', 'Y', '2024-02-22 11:36:56', NULL, NULL),
(214, 1, 17, 'cron_campaign', '919701220857', '919701220857', 'Success', 'Y', '2024-02-22 11:36:56', NULL, NULL),
(215, 1, 17, 'cron_campaign', '919701485663', '919701485663', 'Success', 'Y', '2024-02-22 11:36:56', NULL, NULL),
(216, 1, 17, 'cron_campaign', '919704553794', '919704553794', 'Success', 'Y', '2024-02-22 11:36:56', NULL, NULL),
(217, 1, 17, 'cron_campaign', '919705826269', '919705826269', 'Success', 'Y', '2024-02-22 11:36:56', NULL, NULL),
(218, 1, 17, 'cron_campaign', '919849526433', '919849526433', 'Success', 'Y', '2024-02-22 11:36:57', NULL, NULL),
(219, 1, 17, 'cron_campaign', '919866544488', '919866544488', 'Success', 'Y', '2024-02-22 11:36:57', NULL, NULL),
(220, 1, 17, 'cron_campaign', '919866701029', '919866701029', 'Success', 'Y', '2024-02-22 11:36:57', NULL, NULL),
(221, 1, 17, 'cron_campaign', '919949717791', '919949717791', 'Success', 'Y', '2024-02-22 11:36:57', NULL, NULL),
(222, 1, 17, 'cron_campaign', '919951753360', '919951753360', 'Success', 'Y', '2024-02-22 11:36:57', NULL, NULL),
(223, 1, 18, 'cron_campaign', '919502657666', '919502657666', 'Success', 'Y', '2024-02-22 11:36:57', NULL, NULL),
(224, 1, 18, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:36:57', NULL, NULL),
(225, 1, 18, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:36:57', NULL, NULL),
(226, 1, 18, 'cron_campaign', '919550724248', '919550724248', 'Success', 'Y', '2024-02-22 11:36:58', NULL, NULL),
(227, 1, 18, 'cron_campaign', '919949210374', '919949210374', 'Success', 'Y', '2024-02-22 11:36:58', NULL, NULL),
(228, 1, 18, 'cron_campaign', '919666893760', '919666893760', 'Success', 'Y', '2024-02-22 11:36:58', NULL, NULL),
(229, 1, 18, 'cron_campaign', '919502647495', '919502647495', 'Success', 'Y', '2024-02-22 11:36:58', NULL, NULL),
(230, 1, 18, 'cron_campaign', '919573916050', '919573916050', 'Success', 'Y', '2024-02-22 11:36:58', NULL, NULL),
(231, 1, 18, 'cron_campaign', '919985920056', '919985920056', 'Success', 'Y', '2024-02-22 11:36:58', NULL, NULL),
(232, 1, 18, 'cron_campaign', '919550882670', '919550882670', 'Success', 'Y', '2024-02-22 11:36:58', NULL, NULL),
(233, 1, 18, 'cron_campaign', '919346783687', '919346783687', 'Success', 'Y', '2024-02-22 11:36:58', NULL, NULL),
(234, 1, 18, 'cron_campaign', '919676990020', '919676990020', 'Success', 'Y', '2024-02-22 11:36:58', NULL, NULL),
(235, 1, 18, 'cron_campaign', '919441072861', '919441072861', 'Success', 'Y', '2024-02-22 11:36:58', NULL, NULL),
(236, 1, 18, 'cron_campaign', '919666536406', '919666536406', 'Success', 'Y', '2024-02-22 11:36:58', NULL, NULL),
(237, 1, 18, 'cron_campaign', '919440312338', '919440312338', 'Success', 'Y', '2024-02-22 11:36:58', NULL, NULL),
(238, 1, 18, 'cron_campaign', '919849670916', '919849670916', 'Success', 'Y', '2024-02-22 11:36:58', NULL, NULL),
(239, 1, 18, 'cron_campaign', '917731893539', '917731893539', 'Success', 'Y', '2024-02-22 11:36:59', NULL, NULL),
(240, 1, 18, 'cron_campaign', '917338558474', '917338558474', 'Success', 'Y', '2024-02-22 11:36:59', NULL, NULL),
(241, 1, 18, 'cron_campaign', '917601091880', '917601091880', 'Success', 'Y', '2024-02-22 11:36:59', NULL, NULL),
(242, 1, 18, 'cron_campaign', '12166122807', '12166122807', 'Success', 'Y', '2024-02-22 11:36:59', NULL, NULL),
(243, 1, 18, 'cron_campaign', '916304068209', '916304068209', 'Success', 'Y', '2024-02-22 11:36:59', NULL, NULL),
(244, 1, 18, 'cron_campaign', '917013602154', '917013602154', 'Success', 'Y', '2024-02-22 11:36:59', NULL, NULL),
(245, 1, 18, 'cron_campaign', '917036615814', '917036615814', 'Success', 'Y', '2024-02-22 11:36:59', NULL, NULL),
(246, 1, 18, 'cron_campaign', '917382110273', '917382110273', 'Success', 'Y', '2024-02-22 11:36:59', NULL, NULL),
(247, 1, 18, 'cron_campaign', '917455077166', '917455077166', 'Success', 'Y', '2024-02-22 11:36:59', NULL, NULL),
(248, 1, 18, 'cron_campaign', '917702463237', '917702463237', 'Success', 'Y', '2024-02-22 11:36:59', NULL, NULL),
(249, 1, 18, 'cron_campaign', '917718950788', '917718950788', 'Success', 'Y', '2024-02-22 11:36:59', NULL, NULL),
(250, 1, 18, 'cron_campaign', '917893132462', '917893132462', 'Success', 'Y', '2024-02-22 11:36:59', NULL, NULL),
(251, 1, 18, 'cron_campaign', '917893672960', '917893672960', 'Success', 'Y', '2024-02-22 11:36:59', NULL, NULL),
(252, 1, 18, 'cron_campaign', '917989033738', '917989033738', 'Success', 'Y', '2024-02-22 11:37:00', NULL, NULL),
(253, 1, 18, 'cron_campaign', '917989707106', '917989707106', 'Success', 'Y', '2024-02-22 11:37:00', NULL, NULL),
(254, 1, 18, 'cron_campaign', '917997004332', '917997004332', 'Success', 'Y', '2024-02-22 11:37:00', NULL, NULL),
(255, 1, 18, 'cron_campaign', '918008297141', '918008297141', 'Success', 'Y', '2024-02-22 11:37:00', NULL, NULL),
(256, 1, 18, 'cron_campaign', '918008924597', '918008924597', 'Success', 'Y', '2024-02-22 11:37:00', NULL, NULL),
(257, 1, 18, 'cron_campaign', '918074359882', '918074359882', 'Success', 'Y', '2024-02-22 11:37:00', NULL, NULL),
(258, 1, 18, 'cron_campaign', '918099129242', '918099129242', 'Success', 'Y', '2024-02-22 11:37:00', NULL, NULL),
(259, 1, 18, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:00', NULL, NULL),
(260, 1, 18, 'cron_campaign', '918210849927', '918210849927', 'Success', 'Y', '2024-02-22 11:37:00', NULL, NULL),
(261, 1, 18, 'cron_campaign', '918374957049', '918374957049', 'Success', 'Y', '2024-02-22 11:37:00', NULL, NULL),
(262, 1, 18, 'cron_campaign', '918498057352', '918498057352', 'Success', 'Y', '2024-02-22 11:37:00', NULL, NULL),
(263, 1, 18, 'cron_campaign', '918498815950', '918498815950', 'Success', 'Y', '2024-02-22 11:37:00', NULL, NULL),
(264, 1, 18, 'cron_campaign', '918500274722', '918500274722', 'Success', 'Y', '2024-02-22 11:37:00', NULL, NULL),
(265, 1, 18, 'cron_campaign', '918500274748', '918500274748', 'Success', 'Y', '2024-02-22 11:37:01', NULL, NULL),
(266, 1, 18, 'cron_campaign', '918688654544', '918688654544', 'Success', 'Y', '2024-02-22 11:37:01', NULL, NULL),
(267, 1, 18, 'cron_campaign', '918790813553', '918790813553', 'Success', 'Y', '2024-02-22 11:37:01', NULL, NULL),
(268, 1, 18, 'cron_campaign', '918790890345', '918790890345', 'Success', 'Y', '2024-02-22 11:37:01', NULL, NULL),
(269, 1, 18, 'cron_campaign', '918885683040', '918885683040', 'Success', 'Y', '2024-02-22 11:37:01', NULL, NULL),
(270, 1, 18, 'cron_campaign', '919133536942', '919133536942', 'Success', 'Y', '2024-02-22 11:37:01', NULL, NULL),
(271, 1, 18, 'cron_campaign', '919177446123', '919177446123', 'Success', 'Y', '2024-02-22 11:37:01', NULL, NULL),
(272, 1, 18, 'cron_campaign', '919177582869', '919177582869', 'Success', 'Y', '2024-02-22 11:37:01', NULL, NULL),
(273, 1, 18, 'cron_campaign', '919182608435', '919182608435', 'Success', 'Y', '2024-02-22 11:37:01', NULL, NULL),
(274, 1, 18, 'cron_campaign', '919436845080', '919436845080', 'Success', 'Y', '2024-02-22 11:37:01', NULL, NULL),
(275, 1, 18, 'cron_campaign', '919440616650', '919440616650', 'Success', 'Y', '2024-02-22 11:37:01', NULL, NULL),
(276, 1, 18, 'cron_campaign', '919490733962', '919490733962', 'Success', 'Y', '2024-02-22 11:37:01', NULL, NULL),
(277, 1, 18, 'cron_campaign', '919491325100', '919491325100', 'Success', 'Y', '2024-02-22 11:37:02', NULL, NULL),
(278, 1, 18, 'cron_campaign', '919494338644', '919494338644', 'Success', 'Y', '2024-02-22 11:37:02', NULL, NULL),
(279, 1, 18, 'cron_campaign', '919494589602', '919494589602', 'Success', 'Y', '2024-02-22 11:37:02', NULL, NULL),
(280, 1, 18, 'cron_campaign', '919502190940', '919502190940', 'Success', 'Y', '2024-02-22 11:37:02', NULL, NULL),
(281, 1, 18, 'cron_campaign', '919502199956', '919502199956', 'Success', 'Y', '2024-02-22 11:37:02', NULL, NULL),
(282, 1, 18, 'cron_campaign', '919550555214', '919550555214', 'Success', 'Y', '2024-02-22 11:37:02', NULL, NULL),
(283, 1, 18, 'cron_campaign', '919550931917', '919550931917', 'Success', 'Y', '2024-02-22 11:37:02', NULL, NULL),
(284, 1, 18, 'cron_campaign', '919581608919', '919581608919', 'Success', 'Y', '2024-02-22 11:37:02', NULL, NULL),
(285, 1, 18, 'cron_campaign', '919618615105', '919618615105', 'Success', 'Y', '2024-02-22 11:37:02', NULL, NULL),
(286, 1, 18, 'cron_campaign', '919666083804', '919666083804', 'Success', 'Y', '2024-02-22 11:37:02', NULL, NULL),
(287, 1, 18, 'cron_campaign', '919676063827', '919676063827', 'Success', 'Y', '2024-02-22 11:37:02', NULL, NULL),
(288, 1, 18, 'cron_campaign', '919676213962', '919676213962', 'Success', 'Y', '2024-02-22 11:37:03', NULL, NULL),
(289, 1, 18, 'cron_campaign', '919676566239', '919676566239', 'Success', 'Y', '2024-02-22 11:37:03', NULL, NULL),
(290, 1, 18, 'cron_campaign', '919701238478', '919701238478', 'Success', 'Y', '2024-02-22 11:37:03', NULL, NULL),
(291, 1, 18, 'cron_campaign', '919849163743', '919849163743', 'Success', 'Y', '2024-02-22 11:37:03', NULL, NULL),
(292, 1, 18, 'cron_campaign', '919849529714', '919849529714', 'Success', 'Y', '2024-02-22 11:37:04', NULL, NULL),
(293, 1, 18, 'cron_campaign', '919866741874', '919866741874', 'Success', 'Y', '2024-02-22 11:37:04', NULL, NULL),
(294, 1, 18, 'cron_campaign', '919866954232', '919866954232', 'Success', 'Y', '2024-02-22 11:37:04', NULL, NULL),
(295, 1, 18, 'cron_campaign', '919866996618', '919866996618', 'Success', 'Y', '2024-02-22 11:37:04', NULL, NULL),
(296, 1, 18, 'cron_campaign', '919908527216', '919908527216', 'Success', 'Y', '2024-02-22 11:37:04', NULL, NULL),
(297, 1, 18, 'cron_campaign', '919908675275', '919908675275', 'Success', 'Y', '2024-02-22 11:37:04', NULL, NULL),
(298, 1, 18, 'cron_campaign', '919989690849', '919989690849', 'Success', 'Y', '2024-02-22 11:37:04', NULL, NULL),
(299, 1, 19, 'cron_campaign', '919502657666', '919502657666', 'Success', 'Y', '2024-02-22 11:37:05', NULL, NULL),
(300, 1, 19, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:05', NULL, NULL),
(301, 1, 19, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:05', NULL, NULL),
(302, 1, 19, 'cron_campaign', '919440223570', '919440223570', 'Success', 'Y', '2024-02-22 11:37:05', NULL, NULL),
(303, 1, 19, 'cron_campaign', '917095527469', '917095527469', 'Success', 'Y', '2024-02-22 11:37:05', NULL, NULL),
(304, 1, 19, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:05', NULL, NULL),
(305, 1, 20, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:06', NULL, NULL),
(306, 1, 20, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:06', NULL, NULL),
(307, 1, 20, 'cron_campaign', '917013949342', '917013949342', 'Success', 'Y', '2024-02-22 11:37:06', NULL, NULL),
(308, 1, 20, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:06', NULL, NULL),
(309, 1, 20, 'cron_campaign', '919948583983', '919948583983', 'Success', 'Y', '2024-02-22 11:37:06', NULL, NULL),
(310, 1, 21, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:06', NULL, NULL),
(311, 1, 21, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:06', NULL, NULL),
(312, 1, 21, 'cron_campaign', '919550787337', '919550787337', 'Success', 'Y', '2024-02-22 11:37:07', NULL, NULL),
(313, 1, 21, 'cron_campaign', '919666386238', '919666386238', 'Success', 'Y', '2024-02-22 11:37:07', NULL, NULL),
(314, 1, 21, 'cron_campaign', '917760215131', '917760215131', 'Success', 'Y', '2024-02-22 11:37:07', NULL, NULL),
(315, 1, 21, 'cron_campaign', '918008967247', '918008967247', 'Success', 'Y', '2024-02-22 11:37:07', NULL, NULL),
(316, 1, 21, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:07', NULL, NULL),
(317, 1, 21, 'cron_campaign', '919052722567', '919052722567', 'Success', 'Y', '2024-02-22 11:37:07', NULL, NULL),
(318, 1, 21, 'cron_campaign', '919666204860', '919666204860', 'Success', 'Y', '2024-02-22 11:37:07', NULL, NULL),
(319, 1, 21, 'cron_campaign', '919963691020', '919963691020', 'Success', 'Y', '2024-02-22 11:37:07', NULL, NULL),
(320, 1, 22, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:08', NULL, NULL),
(321, 1, 22, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:08', NULL, NULL),
(322, 1, 22, 'cron_campaign', '919290044235', '919290044235', 'Success', 'Y', '2024-02-22 11:37:08', NULL, NULL),
(323, 1, 22, 'cron_campaign', '919396745417', '919396745417', 'Success', 'Y', '2024-02-22 11:37:08', NULL, NULL),
(324, 1, 22, 'cron_campaign', '918179446939', '918179446939', 'Success', 'Y', '2024-02-22 11:37:08', NULL, NULL),
(325, 1, 22, 'cron_campaign', '917286954663', '917286954663', 'Success', 'Y', '2024-02-22 11:37:08', NULL, NULL),
(326, 1, 22, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:08', NULL, NULL),
(327, 1, 22, 'cron_campaign', '919553889189', '919553889189', 'Success', 'Y', '2024-02-22 11:37:08', NULL, NULL),
(328, 1, 22, 'cron_campaign', '919866165073', '919866165073', 'Success', 'Y', '2024-02-22 11:37:08', NULL, NULL),
(329, 1, 23, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:10', NULL, NULL),
(330, 1, 23, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:10', NULL, NULL),
(331, 1, 23, 'cron_campaign', '918186929168', '918186929168', 'Success', 'Y', '2024-02-22 11:37:10', NULL, NULL),
(332, 1, 23, 'cron_campaign', '919573637525', '919573637525', 'Success', 'Y', '2024-02-22 11:37:10', NULL, NULL),
(333, 1, 23, 'cron_campaign', '919959356929', '919959356929', 'Success', 'Y', '2024-02-22 11:37:10', NULL, NULL),
(334, 1, 23, 'cron_campaign', '919491783626', '919491783626', 'Success', 'Y', '2024-02-22 11:37:10', NULL, NULL),
(335, 1, 23, 'cron_campaign', '919704722789', '919704722789', 'Success', 'Y', '2024-02-22 11:37:10', NULL, NULL),
(336, 1, 23, 'cron_campaign', '919885079318', '919885079318', 'Success', 'Y', '2024-02-22 11:37:11', NULL, NULL),
(337, 1, 23, 'cron_campaign', '916302781257', '916302781257', 'Success', 'Y', '2024-02-22 11:37:11', NULL, NULL),
(338, 1, 23, 'cron_campaign', '916304732212', '916304732212', 'Success', 'Y', '2024-02-22 11:37:11', NULL, NULL),
(339, 1, 23, 'cron_campaign', '917760215131', '917760215131', 'Success', 'Y', '2024-02-22 11:37:11', NULL, NULL),
(340, 1, 23, 'cron_campaign', '917995404221', '917995404221', 'Success', 'Y', '2024-02-22 11:37:11', NULL, NULL),
(341, 1, 23, 'cron_campaign', '918096625899', '918096625899', 'Success', 'Y', '2024-02-22 11:37:11', NULL, NULL),
(342, 1, 23, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:12', NULL, NULL),
(343, 1, 23, 'cron_campaign', '918341104110', '918341104110', 'Success', 'Y', '2024-02-22 11:37:12', NULL, NULL),
(344, 1, 23, 'cron_campaign', '918522995919', '918522995919', 'Success', 'Y', '2024-02-22 11:37:12', NULL, NULL),
(345, 1, 23, 'cron_campaign', '918622989999', '918622989999', 'Success', 'Y', '2024-02-22 11:37:12', NULL, NULL),
(346, 1, 23, 'cron_campaign', '918883741149', '918883741149', 'Success', 'Y', '2024-02-22 11:37:12', NULL, NULL),
(347, 1, 23, 'cron_campaign', '919666235666', '919666235666', 'Success', 'Y', '2024-02-22 11:37:12', NULL, NULL),
(348, 1, 23, 'cron_campaign', '919704019466', '919704019466', 'Success', 'Y', '2024-02-22 11:37:13', NULL, NULL),
(349, 1, 23, 'cron_campaign', '919959627219', '919959627219', 'Success', 'Y', '2024-02-22 11:37:13', NULL, NULL),
(350, 1, 23, 'cron_campaign', '919966196573', '919966196573', 'Success', 'Y', '2024-02-22 11:37:13', NULL, NULL),
(351, 1, 24, 'cron_campaign', '919502657666', '919502657666', 'Success', 'Y', '2024-02-22 11:37:14', NULL, NULL),
(352, 1, 24, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:14', NULL, NULL),
(353, 1, 24, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:14', NULL, NULL),
(354, 1, 24, 'cron_campaign', '919441011271', '919441011271', 'Success', 'Y', '2024-02-22 11:37:14', NULL, NULL),
(355, 1, 24, 'cron_campaign', '918019527608', '918019527608', 'Success', 'Y', '2024-02-22 11:37:15', NULL, NULL),
(356, 1, 24, 'cron_campaign', '919908001590', '919908001590', 'Success', 'Y', '2024-02-22 11:37:15', NULL, NULL),
(357, 1, 24, 'cron_campaign', '919000822921', '919000822921', 'Success', 'Y', '2024-02-22 11:37:15', NULL, NULL),
(358, 1, 24, 'cron_campaign', '919490027016', '919490027016', 'Success', 'Y', '2024-02-22 11:37:15', NULL, NULL),
(359, 1, 24, 'cron_campaign', '919553703579', '919553703579', 'Success', 'Y', '2024-02-22 11:37:15', NULL, NULL),
(360, 1, 24, 'cron_campaign', '916302541708', '916302541708', 'Success', 'Y', '2024-02-22 11:37:15', NULL, NULL),
(361, 1, 24, 'cron_campaign', '919989893563', '919989893563', 'Success', 'Y', '2024-02-22 11:37:15', NULL, NULL),
(362, 1, 24, 'cron_campaign', '916303544391', '916303544391', 'Success', 'Y', '2024-02-22 11:37:16', NULL, NULL),
(363, 1, 24, 'cron_campaign', '917095527469', '917095527469', 'Success', 'Y', '2024-02-22 11:37:16', NULL, NULL),
(364, 1, 24, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:16', NULL, NULL),
(365, 1, 24, 'cron_campaign', '918297375763', '918297375763', 'Success', 'Y', '2024-02-22 11:37:16', NULL, NULL),
(366, 1, 24, 'cron_campaign', '919441155165', '919441155165', 'Success', 'Y', '2024-02-22 11:37:16', NULL, NULL),
(367, 1, 24, 'cron_campaign', '919490971785', '919490971785', 'Success', 'Y', '2024-02-22 11:37:16', NULL, NULL),
(368, 1, 24, 'cron_campaign', '919494327600', '919494327600', 'Success', 'Y', '2024-02-22 11:37:17', NULL, NULL),
(369, 1, 24, 'cron_campaign', '919550262700', '919550262700', 'Success', 'Y', '2024-02-22 11:37:17', NULL, NULL),
(370, 1, 24, 'cron_campaign', '919573911554', '919573911554', 'Success', 'Y', '2024-02-22 11:37:17', NULL, NULL),
(371, 1, 24, 'cron_campaign', '919963938626', '919963938626', 'Success', 'Y', '2024-02-22 11:37:17', NULL, NULL),
(372, 1, 24, 'cron_campaign', '919966162724', '919966162724', 'Success', 'Y', '2024-02-22 11:37:17', NULL, NULL),
(373, 1, 25, 'cron_campaign', '919502657666', '919502657666', 'Success', 'Y', '2024-02-22 11:37:18', NULL, NULL),
(374, 1, 25, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:18', NULL, NULL),
(375, 1, 25, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:18', NULL, NULL),
(376, 1, 25, 'cron_campaign', '917386373722', '917386373722', 'Success', 'Y', '2024-02-22 11:37:18', NULL, NULL),
(377, 1, 25, 'cron_campaign', '918499852179', '918499852179', 'Success', 'Y', '2024-02-22 11:37:18', NULL, NULL),
(378, 1, 25, 'cron_campaign', '919121262030', '919121262030', 'Success', 'Y', '2024-02-22 11:37:18', NULL, NULL),
(379, 1, 25, 'cron_campaign', '918500726867', '918500726867', 'Success', 'Y', '2024-02-22 11:37:19', NULL, NULL),
(380, 1, 25, 'cron_campaign', '919440765104', '919440765104', 'Success', 'Y', '2024-02-22 11:37:19', NULL, NULL),
(381, 1, 25, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:19', NULL, NULL),
(382, 1, 25, 'cron_campaign', '919030023449', '919030023449', 'Success', 'Y', '2024-02-22 11:37:19', NULL, NULL),
(383, 1, 25, 'cron_campaign', '919398093820', '919398093820', 'Success', 'Y', '2024-02-22 11:37:19', NULL, NULL),
(384, 1, 25, 'cron_campaign', '919440364545', '919440364545', 'Success', 'Y', '2024-02-22 11:37:19', NULL, NULL),
(385, 1, 25, 'cron_campaign', '919848161811', '919848161811', 'Success', 'Y', '2024-02-22 11:37:19', NULL, NULL),
(386, 1, 25, 'cron_campaign', '919908189868', '919908189868', 'Success', 'Y', '2024-02-22 11:37:19', NULL, NULL),
(387, 1, 26, 'cron_campaign', '919502657666', '919502657666', 'Success', 'Y', '2024-02-22 11:37:20', NULL, NULL),
(388, 1, 26, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:20', NULL, NULL),
(389, 1, 26, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:20', NULL, NULL),
(390, 1, 26, 'cron_campaign', '919959883815', '919959883815', 'Success', 'Y', '2024-02-22 11:37:20', NULL, NULL),
(391, 1, 26, 'cron_campaign', '919642565999', '919642565999', 'Success', 'Y', '2024-02-22 11:37:21', NULL, NULL),
(392, 1, 26, 'cron_campaign', '919493575325', '919493575325', 'Success', 'Y', '2024-02-22 11:37:21', NULL, NULL),
(393, 1, 26, 'cron_campaign', '918886439774', '918886439774', 'Success', 'Y', '2024-02-22 11:37:21', NULL, NULL),
(394, 1, 26, 'cron_campaign', '919100598004', '919100598004', 'Success', 'Y', '2024-02-22 11:37:22', NULL, NULL),
(395, 1, 26, 'cron_campaign', '918142723953', '918142723953', 'Success', 'Y', '2024-02-22 11:37:22', NULL, NULL),
(396, 1, 26, 'cron_campaign', '919704851273', '919704851273', 'Success', 'Y', '2024-02-22 11:37:22', NULL, NULL),
(397, 1, 26, 'cron_campaign', '919393195999', '919393195999', 'Success', 'Y', '2024-02-22 11:37:22', NULL, NULL),
(398, 1, 26, 'cron_campaign', '918179867972', '918179867972', 'Success', 'Y', '2024-02-22 11:37:23', NULL, NULL),
(399, 1, 26, 'cron_campaign', '917981686465', '917981686465', 'Success', 'Y', '2024-02-22 11:37:23', NULL, NULL),
(400, 1, 26, 'cron_campaign', '79143960847', '79143960847', 'Success', 'Y', '2024-02-22 11:37:23', NULL, NULL),
(401, 1, 26, 'cron_campaign', '918106447275', '918106447275', 'Success', 'Y', '2024-02-22 11:37:23', NULL, NULL),
(402, 1, 26, 'cron_campaign', '919440312338', '919440312338', 'Success', 'Y', '2024-02-22 11:37:23', NULL, NULL),
(403, 1, 26, 'cron_campaign', '918500102139', '918500102139', 'Success', 'Y', '2024-02-22 11:37:24', NULL, NULL),
(404, 1, 26, 'cron_campaign', '919337601191', '919337601191', 'Success', 'Y', '2024-02-22 11:37:24', NULL, NULL),
(405, 1, 26, 'cron_campaign', '916302291582', '916302291582', 'Success', 'Y', '2024-02-22 11:37:24', NULL, NULL),
(406, 1, 26, 'cron_campaign', '916309865109', '916309865109', 'Success', 'Y', '2024-02-22 11:37:24', NULL, NULL),
(407, 1, 26, 'cron_campaign', '917036423837', '917036423837', 'Success', 'Y', '2024-02-22 11:37:24', NULL, NULL),
(408, 1, 26, 'cron_campaign', '917382772002', '917382772002', 'Success', 'Y', '2024-02-22 11:37:24', NULL, NULL),
(409, 1, 26, 'cron_campaign', '917396813921', '917396813921', 'Success', 'Y', '2024-02-22 11:37:24', NULL, NULL),
(410, 1, 26, 'cron_campaign', '917680030310', '917680030310', 'Success', 'Y', '2024-02-22 11:37:24', NULL, NULL),
(411, 1, 26, 'cron_campaign', '917680057092', '917680057092', 'Success', 'Y', '2024-02-22 11:37:24', NULL, NULL),
(412, 1, 26, 'cron_campaign', '917981711373', '917981711373', 'Success', 'Y', '2024-02-22 11:37:25', NULL, NULL),
(413, 1, 26, 'cron_campaign', '917997630728', '917997630728', 'Success', 'Y', '2024-02-22 11:37:25', NULL, NULL),
(414, 1, 26, 'cron_campaign', '918008242604', '918008242604', 'Success', 'Y', '2024-02-22 11:37:25', NULL, NULL),
(415, 1, 26, 'cron_campaign', '918074565313', '918074565313', 'Success', 'Y', '2024-02-22 11:37:25', NULL, NULL),
(416, 1, 26, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:25', NULL, NULL),
(417, 1, 26, 'cron_campaign', '918184928822', '918184928822', 'Success', 'Y', '2024-02-22 11:37:25', NULL, NULL),
(418, 1, 26, 'cron_campaign', '918309586463', '918309586463', 'Success', 'Y', '2024-02-22 11:37:25', NULL, NULL),
(419, 1, 26, 'cron_campaign', '918374889218', '918374889218', 'Success', 'Y', '2024-02-22 11:37:25', NULL, NULL),
(420, 1, 26, 'cron_campaign', '918801434718', '918801434718', 'Success', 'Y', '2024-02-22 11:37:26', NULL, NULL),
(421, 1, 26, 'cron_campaign', '918886663006', '918886663006', 'Success', 'Y', '2024-02-22 11:37:26', NULL, NULL),
(422, 1, 26, 'cron_campaign', '918985465212', '918985465212', 'Success', 'Y', '2024-02-22 11:37:26', NULL, NULL),
(423, 1, 26, 'cron_campaign', '919000364281', '919000364281', 'Success', 'Y', '2024-02-22 11:37:26', NULL, NULL),
(424, 1, 26, 'cron_campaign', '919010245812', '919010245812', 'Success', 'Y', '2024-02-22 11:37:26', NULL, NULL),
(425, 1, 26, 'cron_campaign', '919014980798', '919014980798', 'Success', 'Y', '2024-02-22 11:37:26', NULL, NULL),
(426, 1, 26, 'cron_campaign', '919100466496', '919100466496', 'Success', 'Y', '2024-02-22 11:37:27', NULL, NULL),
(427, 1, 26, 'cron_campaign', '919109732546', '919109732546', 'Success', 'Y', '2024-02-22 11:37:27', NULL, NULL),
(428, 1, 26, 'cron_campaign', '919177252213', '919177252213', 'Success', 'Y', '2024-02-22 11:37:27', NULL, NULL),
(429, 1, 26, 'cron_campaign', '919398261986', '919398261986', 'Success', 'Y', '2024-02-22 11:37:27', NULL, NULL),
(430, 1, 26, 'cron_campaign', '919490637640', '919490637640', 'Success', 'Y', '2024-02-22 11:37:27', NULL, NULL),
(431, 1, 26, 'cron_campaign', '919491325139', '919491325139', 'Success', 'Y', '2024-02-22 11:37:27', NULL, NULL),
(432, 1, 26, 'cron_campaign', '919550204973', '919550204973', 'Success', 'Y', '2024-02-22 11:37:27', NULL, NULL),
(433, 1, 26, 'cron_campaign', '919553392823', '919553392823', 'Success', 'Y', '2024-02-22 11:37:27', NULL, NULL),
(434, 1, 26, 'cron_campaign', '919573439575', '919573439575', 'Success', 'Y', '2024-02-22 11:37:27', NULL, NULL),
(435, 1, 26, 'cron_campaign', '919573797167', '919573797167', 'Success', 'Y', '2024-02-22 11:37:28', NULL, NULL),
(436, 1, 26, 'cron_campaign', '919603027029', '919603027029', 'Success', 'Y', '2024-02-22 11:37:28', NULL, NULL),
(437, 1, 26, 'cron_campaign', '919642908519', '919642908519', 'Success', 'Y', '2024-02-22 11:37:28', NULL, NULL),
(438, 1, 26, 'cron_campaign', '919666028889', '919666028889', 'Success', 'Y', '2024-02-22 11:37:28', NULL, NULL),
(439, 1, 26, 'cron_campaign', '919676036503', '919676036503', 'Success', 'Y', '2024-02-22 11:37:28', NULL, NULL),
(440, 1, 26, 'cron_campaign', '919676939648', '919676939648', 'Success', 'Y', '2024-02-22 11:37:28', NULL, NULL),
(441, 1, 26, 'cron_campaign', '919701702568', '919701702568', 'Success', 'Y', '2024-02-22 11:37:28', NULL, NULL),
(442, 1, 26, 'cron_campaign', '919701702747', '919701702747', 'Success', 'Y', '2024-02-22 11:37:28', NULL, NULL),
(443, 1, 26, 'cron_campaign', '919703273463', '919703273463', 'Success', 'Y', '2024-02-22 11:37:28', NULL, NULL),
(444, 1, 26, 'cron_campaign', '919705488817', '919705488817', 'Success', 'Y', '2024-02-22 11:37:28', NULL, NULL),
(445, 1, 26, 'cron_campaign', '919848117654', '919848117654', 'Success', 'Y', '2024-02-22 11:37:29', NULL, NULL),
(446, 1, 26, 'cron_campaign', '919848249132', '919848249132', 'Success', 'Y', '2024-02-22 11:37:29', NULL, NULL),
(447, 1, 26, 'cron_campaign', '919908885278', '919908885278', 'Success', 'Y', '2024-02-22 11:37:29', NULL, NULL),
(448, 1, 26, 'cron_campaign', '919908970537', '919908970537', 'Success', 'Y', '2024-02-22 11:37:29', NULL, NULL),
(449, 1, 26, 'cron_campaign', '919912587263', '919912587263', 'Success', 'Y', '2024-02-22 11:37:29', NULL, NULL),
(450, 1, 26, 'cron_campaign', '919912604070', '919912604070', 'Success', 'Y', '2024-02-22 11:37:29', NULL, NULL),
(451, 1, 26, 'cron_campaign', '919933226633', '919933226633', 'Success', 'Y', '2024-02-22 11:37:30', NULL, NULL),
(452, 1, 26, 'cron_campaign', '919963233568', '919963233568', 'Success', 'Y', '2024-02-22 11:37:30', NULL, NULL),
(453, 1, 27, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:30', NULL, NULL),
(454, 1, 27, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:30', NULL, NULL),
(455, 1, 27, 'cron_campaign', '919652831119', '919652831119', 'Success', 'Y', '2024-02-22 11:37:30', NULL, NULL),
(456, 1, 27, 'cron_campaign', '918985079269', '918985079269', 'Success', 'Y', '2024-02-22 11:37:30', NULL, NULL),
(457, 1, 27, 'cron_campaign', '919948840240', '919948840240', 'Success', 'Y', '2024-02-22 11:37:30', NULL, NULL),
(458, 1, 27, 'cron_campaign', '918121727929', '918121727929', 'Success', 'Y', '2024-02-22 11:37:30', NULL, NULL),
(459, 1, 27, 'cron_campaign', '919989616585', '919989616585', 'Success', 'Y', '2024-02-22 11:37:31', NULL, NULL),
(460, 1, 27, 'cron_campaign', '918885141432', '918885141432', 'Success', 'Y', '2024-02-22 11:37:31', NULL, NULL),
(461, 1, 27, 'cron_campaign', '919059544565', '919059544565', 'Success', 'Y', '2024-02-22 11:37:31', NULL, NULL),
(462, 1, 27, 'cron_campaign', '917396234667', '917396234667', 'Success', 'Y', '2024-02-22 11:37:31', NULL, NULL);
INSERT INTO `group_contacts` (`group_contacts_id`, `user_id`, `group_master_id`, `campaign_name`, `mobile_no`, `mobile_id`, `comments`, `group_contacts_status`, `group_contacts_entry_date`, `remove_comments`, `admin_status`) VALUES
(463, 1, 27, 'cron_campaign', '918074602070', '918074602070', 'Success', 'Y', '2024-02-22 11:37:31', NULL, NULL),
(464, 1, 27, 'cron_campaign', '918106199447', '918106199447', 'Success', 'Y', '2024-02-22 11:37:31', NULL, NULL),
(465, 1, 27, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:31', NULL, NULL),
(466, 1, 27, 'cron_campaign', '918179574510', '918179574510', 'Success', 'Y', '2024-02-22 11:37:31', NULL, NULL),
(467, 1, 27, 'cron_campaign', '918328400058', '918328400058', 'Success', 'Y', '2024-02-22 11:37:31', NULL, NULL),
(468, 1, 27, 'cron_campaign', '918688210143', '918688210143', 'Success', 'Y', '2024-02-22 11:37:31', NULL, NULL),
(469, 1, 27, 'cron_campaign', '919121559968', '919121559968', 'Success', 'Y', '2024-02-22 11:37:31', NULL, NULL),
(470, 1, 27, 'cron_campaign', '919177753209', '919177753209', 'Success', 'Y', '2024-02-22 11:37:31', NULL, NULL),
(471, 1, 27, 'cron_campaign', '919182725922', '919182725922', 'Success', 'Y', '2024-02-22 11:37:32', NULL, NULL),
(472, 1, 27, 'cron_campaign', '919310405394', '919310405394', 'Success', 'Y', '2024-02-22 11:37:32', NULL, NULL),
(473, 1, 27, 'cron_campaign', '919581336224', '919581336224', 'Success', 'Y', '2024-02-22 11:37:32', NULL, NULL),
(474, 1, 27, 'cron_campaign', '919849217906', '919849217906', 'Success', 'Y', '2024-02-22 11:37:32', NULL, NULL),
(475, 1, 27, 'cron_campaign', '919885538922', '919885538922', 'Success', 'Y', '2024-02-22 11:37:32', NULL, NULL),
(476, 1, 28, 'cron_campaign', '919502657666', '919502657666', 'Success', 'Y', '2024-02-22 11:37:32', NULL, NULL),
(477, 1, 28, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:32', NULL, NULL),
(478, 1, 28, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:33', NULL, NULL),
(479, 1, 28, 'cron_campaign', '919676953479', '919676953479', 'Success', 'Y', '2024-02-22 11:37:33', NULL, NULL),
(480, 1, 28, 'cron_campaign', '918639986867', '918639986867', 'Success', 'Y', '2024-02-22 11:37:33', NULL, NULL),
(481, 1, 28, 'cron_campaign', '917095405835', '917095405835', 'Success', 'Y', '2024-02-22 11:37:33', NULL, NULL),
(482, 1, 28, 'cron_campaign', '919347758943', '919347758943', 'Success', 'Y', '2024-02-22 11:37:34', NULL, NULL),
(483, 1, 28, 'cron_campaign', '919849182205', '919849182205', 'Success', 'Y', '2024-02-22 11:37:34', NULL, NULL),
(484, 1, 28, 'cron_campaign', '918555887897', '918555887897', 'Success', 'Y', '2024-02-22 11:37:34', NULL, NULL),
(485, 1, 28, 'cron_campaign', '919010615878', '919010615878', 'Success', 'Y', '2024-02-22 11:37:34', NULL, NULL),
(486, 1, 28, 'cron_campaign', '919398868048', '919398868048', 'Success', 'Y', '2024-02-22 11:37:34', NULL, NULL),
(487, 1, 28, 'cron_campaign', '916281895359', '916281895359', 'Success', 'Y', '2024-02-22 11:37:34', NULL, NULL),
(488, 1, 28, 'cron_campaign', '916300528531', '916300528531', 'Success', 'Y', '2024-02-22 11:37:34', NULL, NULL),
(489, 1, 28, 'cron_campaign', '916301270898', '916301270898', 'Success', 'Y', '2024-02-22 11:37:34', NULL, NULL),
(490, 1, 28, 'cron_campaign', '916303140923', '916303140923', 'Success', 'Y', '2024-02-22 11:37:34', NULL, NULL),
(491, 1, 28, 'cron_campaign', '916304191747', '916304191747', 'Success', 'Y', '2024-02-22 11:37:34', NULL, NULL),
(492, 1, 28, 'cron_campaign', '916304864689', '916304864689', 'Success', 'Y', '2024-02-22 11:37:34', NULL, NULL),
(493, 1, 28, 'cron_campaign', '917032744806', '917032744806', 'Success', 'Y', '2024-02-22 11:37:34', NULL, NULL),
(494, 1, 28, 'cron_campaign', '917337220507', '917337220507', 'Success', 'Y', '2024-02-22 11:37:35', NULL, NULL),
(495, 1, 28, 'cron_campaign', '917780208392', '917780208392', 'Success', 'Y', '2024-02-22 11:37:35', NULL, NULL),
(496, 1, 28, 'cron_campaign', '917780246576', '917780246576', 'Success', 'Y', '2024-02-22 11:37:35', NULL, NULL),
(497, 1, 28, 'cron_campaign', '917780493262', '917780493262', 'Success', 'Y', '2024-02-22 11:37:35', NULL, NULL),
(498, 1, 28, 'cron_campaign', '917842161904', '917842161904', 'Success', 'Y', '2024-02-22 11:37:35', NULL, NULL),
(499, 1, 28, 'cron_campaign', '917893952034', '917893952034', 'Success', 'Y', '2024-02-22 11:37:35', NULL, NULL),
(500, 1, 28, 'cron_campaign', '917993528018', '917993528018', 'Success', 'Y', '2024-02-22 11:37:35', NULL, NULL),
(501, 1, 28, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:35', NULL, NULL),
(502, 1, 28, 'cron_campaign', '918179840095', '918179840095', 'Success', 'Y', '2024-02-22 11:37:35', NULL, NULL),
(503, 1, 28, 'cron_campaign', '918374734479', '918374734479', 'Success', 'Y', '2024-02-22 11:37:35', NULL, NULL),
(504, 1, 28, 'cron_campaign', '918688224393', '918688224393', 'Success', 'Y', '2024-02-22 11:37:36', NULL, NULL),
(505, 1, 28, 'cron_campaign', '918978424256', '918978424256', 'Success', 'Y', '2024-02-22 11:37:36', NULL, NULL),
(506, 1, 28, 'cron_campaign', '919000633489', '919000633489', 'Success', 'Y', '2024-02-22 11:37:36', NULL, NULL),
(507, 1, 28, 'cron_campaign', '919000888336', '919000888336', 'Success', 'Y', '2024-02-22 11:37:36', NULL, NULL),
(508, 1, 28, 'cron_campaign', '919014456294', '919014456294', 'Success', 'Y', '2024-02-22 11:37:36', NULL, NULL),
(509, 1, 28, 'cron_campaign', '919014887917', '919014887917', 'Success', 'Y', '2024-02-22 11:37:36', NULL, NULL),
(510, 1, 28, 'cron_campaign', '919182875071', '919182875071', 'Success', 'Y', '2024-02-22 11:37:36', NULL, NULL),
(511, 1, 28, 'cron_campaign', '919381480155', '919381480155', 'Success', 'Y', '2024-02-22 11:37:36', NULL, NULL),
(512, 1, 28, 'cron_campaign', '919391933251', '919391933251', 'Success', 'Y', '2024-02-22 11:37:36', NULL, NULL),
(513, 1, 28, 'cron_campaign', '919392110775', '919392110775', 'Success', 'Y', '2024-02-22 11:37:36', NULL, NULL),
(514, 1, 28, 'cron_campaign', '919398048652', '919398048652', 'Success', 'Y', '2024-02-22 11:37:36', NULL, NULL),
(515, 1, 28, 'cron_campaign', '919493703507', '919493703507', 'Success', 'Y', '2024-02-22 11:37:36', NULL, NULL),
(516, 1, 28, 'cron_campaign', '919494390937', '919494390937', 'Success', 'Y', '2024-02-22 11:37:36', NULL, NULL),
(517, 1, 28, 'cron_campaign', '919553388818', '919553388818', 'Success', 'Y', '2024-02-22 11:37:36', NULL, NULL),
(518, 1, 28, 'cron_campaign', '919573717455', '919573717455', 'Success', 'Y', '2024-02-22 11:37:37', NULL, NULL),
(519, 1, 28, 'cron_campaign', '919573745504', '919573745504', 'Success', 'Y', '2024-02-22 11:37:37', NULL, NULL),
(520, 1, 28, 'cron_campaign', '919618894245', '919618894245', 'Success', 'Y', '2024-02-22 11:37:37', NULL, NULL),
(521, 1, 28, 'cron_campaign', '919642908519', '919642908519', 'Success', 'Y', '2024-02-22 11:37:37', NULL, NULL),
(522, 1, 28, 'cron_campaign', '919652506169', '919652506169', 'Success', 'Y', '2024-02-22 11:37:37', NULL, NULL),
(523, 1, 28, 'cron_campaign', '919704017076', '919704017076', 'Success', 'Y', '2024-02-22 11:37:37', NULL, NULL),
(524, 1, 28, 'cron_campaign', '919849487131', '919849487131', 'Success', 'Y', '2024-02-22 11:37:37', NULL, NULL),
(525, 1, 28, 'cron_campaign', '919866729934', '919866729934', 'Success', 'Y', '2024-02-22 11:37:37', NULL, NULL),
(526, 1, 28, 'cron_campaign', '919908885278', '919908885278', 'Success', 'Y', '2024-02-22 11:37:37', NULL, NULL),
(527, 1, 28, 'cron_campaign', '919989802096', '919989802096', 'Success', 'Y', '2024-02-22 11:37:37', NULL, NULL),
(528, 1, 29, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:38', NULL, NULL),
(529, 1, 29, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:38', NULL, NULL),
(530, 1, 29, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:38', NULL, NULL),
(531, 1, 30, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:39', NULL, NULL),
(532, 1, 30, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:39', NULL, NULL),
(533, 1, 30, 'cron_campaign', '919848020773', '919848020773', 'Success', 'Y', '2024-02-22 11:37:39', NULL, NULL),
(534, 1, 30, 'cron_campaign', '917032751753', '917032751753', 'Success', 'Y', '2024-02-22 11:37:39', NULL, NULL),
(535, 1, 30, 'cron_campaign', '918008592028', '918008592028', 'Success', 'Y', '2024-02-22 11:37:39', NULL, NULL),
(536, 1, 30, 'cron_campaign', '919705906356', '919705906356', 'Success', 'Y', '2024-02-22 11:37:39', NULL, NULL),
(537, 1, 30, 'cron_campaign', '918106672018', '918106672018', 'Success', 'Y', '2024-02-22 11:37:39', NULL, NULL),
(538, 1, 30, 'cron_campaign', '917036960024', '917036960024', 'Success', 'Y', '2024-02-22 11:37:39', NULL, NULL),
(539, 1, 30, 'cron_campaign', '917799033078', '917799033078', 'Success', 'Y', '2024-02-22 11:37:39', NULL, NULL),
(540, 1, 30, 'cron_campaign', '918008013174', '918008013174', 'Success', 'Y', '2024-02-22 11:37:39', NULL, NULL),
(541, 1, 30, 'cron_campaign', '918074055596', '918074055596', 'Success', 'Y', '2024-02-22 11:37:40', NULL, NULL),
(542, 1, 30, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:40', NULL, NULL),
(543, 1, 30, 'cron_campaign', '918185959140', '918185959140', 'Success', 'Y', '2024-02-22 11:37:40', NULL, NULL),
(544, 1, 30, 'cron_campaign', '918555960044', '918555960044', 'Success', 'Y', '2024-02-22 11:37:40', NULL, NULL),
(545, 1, 30, 'cron_campaign', '919391285077', '919391285077', 'Success', 'Y', '2024-02-22 11:37:41', NULL, NULL),
(546, 1, 30, 'cron_campaign', '919550582271', '919550582271', 'Success', 'Y', '2024-02-22 11:37:41', NULL, NULL),
(547, 1, 30, 'cron_campaign', '919618874407', '919618874407', 'Success', 'Y', '2024-02-22 11:37:42', NULL, NULL),
(548, 1, 30, 'cron_campaign', '919949212796', '919949212796', 'Success', 'Y', '2024-02-22 11:37:42', NULL, NULL),
(549, 1, 30, 'cron_campaign', '919949822629', '919949822629', 'Success', 'Y', '2024-02-22 11:37:42', NULL, NULL),
(550, 1, 30, 'cron_campaign', '919959335641', '919959335641', 'Success', 'Y', '2024-02-22 11:37:43', NULL, NULL),
(551, 1, 30, 'cron_campaign', '919989241443', '919989241443', 'Success', 'Y', '2024-02-22 11:37:43', NULL, NULL),
(552, 1, 31, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:43', NULL, NULL),
(553, 1, 31, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:43', NULL, NULL),
(554, 1, 31, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:44', NULL, NULL),
(555, 1, 32, 'cron_campaign', '919502657666', '919502657666', 'Success', 'Y', '2024-02-22 11:37:44', NULL, NULL),
(556, 1, 32, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:44', NULL, NULL),
(557, 1, 32, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:44', NULL, NULL),
(558, 1, 32, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:44', NULL, NULL),
(559, 1, 33, 'cron_campaign', '919502657666', '919502657666', 'Success', 'Y', '2024-02-22 11:37:45', NULL, NULL),
(560, 1, 33, 'cron_campaign', '919550092856', '919550092856', 'Success', 'Y', '2024-02-22 11:37:45', NULL, NULL),
(561, 1, 33, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:45', NULL, NULL),
(562, 1, 33, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:45', NULL, NULL),
(563, 1, 33, 'cron_campaign', '918179202713', '918179202713', 'Success', 'Y', '2024-02-22 11:37:45', NULL, NULL),
(564, 1, 33, 'cron_campaign', '917569304942', '917569304942', 'Success', 'Y', '2024-02-22 11:37:46', NULL, NULL),
(565, 1, 33, 'cron_campaign', '916301398378', '916301398378', 'Success', 'Y', '2024-02-22 11:37:46', NULL, NULL),
(566, 1, 33, 'cron_campaign', '916302898416', '916302898416', 'Success', 'Y', '2024-02-22 11:37:46', NULL, NULL),
(567, 1, 33, 'cron_campaign', '918121590243', '918121590243', 'Success', 'Y', '2024-02-22 11:37:46', NULL, NULL),
(568, 1, 33, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:46', NULL, NULL),
(569, 1, 33, 'cron_campaign', '918179297008', '918179297008', 'Success', 'Y', '2024-02-22 11:37:46', NULL, NULL),
(570, 1, 33, 'cron_campaign', '918919063947', '918919063947', 'Success', 'Y', '2024-02-22 11:37:46', NULL, NULL),
(571, 1, 33, 'cron_campaign', '919492347274', '919492347274', 'Success', 'Y', '2024-02-22 11:37:46', NULL, NULL),
(572, 1, 33, 'cron_campaign', '919963656486', '919963656486', 'Success', 'Y', '2024-02-22 11:37:46', NULL, NULL),
(573, 1, 34, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:47', NULL, NULL),
(574, 1, 34, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:47', NULL, NULL),
(575, 1, 34, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:47', NULL, NULL),
(576, 1, 35, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:48', NULL, NULL),
(577, 1, 35, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:48', NULL, NULL),
(578, 1, 35, 'cron_campaign', '919396745417', '919396745417', 'Success', 'Y', '2024-02-22 11:37:48', NULL, NULL),
(579, 1, 35, 'cron_campaign', '918897389300', '918897389300', 'Success', 'Y', '2024-02-22 11:37:48', NULL, NULL),
(580, 1, 35, 'cron_campaign', '916281513258', '916281513258', 'Success', 'Y', '2024-02-22 11:37:48', NULL, NULL),
(581, 1, 35, 'cron_campaign', '916303778757', '916303778757', 'Success', 'Y', '2024-02-22 11:37:48', NULL, NULL),
(582, 1, 35, 'cron_campaign', '917760215131', '917760215131', 'Success', 'Y', '2024-02-22 11:37:48', NULL, NULL),
(583, 1, 35, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:48', NULL, NULL),
(584, 1, 35, 'cron_campaign', '919182638074', '919182638074', 'Success', 'Y', '2024-02-22 11:37:48', NULL, NULL),
(585, 1, 35, 'cron_campaign', '919502799451', '919502799451', 'Success', 'Y', '2024-02-22 11:37:48', NULL, NULL),
(586, 1, 36, 'cron_campaign', '919502657666', '919502657666', 'Success', 'Y', '2024-02-22 11:37:49', NULL, NULL),
(587, 1, 36, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:49', NULL, NULL),
(588, 1, 36, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:49', NULL, NULL),
(589, 1, 36, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:49', NULL, NULL),
(590, 1, 37, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:50', NULL, NULL),
(591, 1, 37, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:50', NULL, NULL),
(592, 1, 37, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:50', NULL, NULL),
(593, 1, 38, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:50', NULL, NULL),
(594, 1, 38, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:50', NULL, NULL),
(595, 1, 38, 'cron_campaign', '917760215131', '917760215131', 'Success', 'Y', '2024-02-22 11:37:51', NULL, NULL),
(596, 1, 38, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:51', NULL, NULL),
(597, 1, 39, 'cron_campaign', '919550092856', '919550092856', 'Success', 'Y', '2024-02-22 11:37:51', NULL, NULL),
(598, 1, 39, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:51', NULL, NULL),
(599, 1, 39, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:51', NULL, NULL),
(600, 1, 39, 'cron_campaign', '919491531589', '919491531589', 'Success', 'Y', '2024-02-22 11:37:51', NULL, NULL),
(601, 1, 39, 'cron_campaign', '918099072385', '918099072385', 'Success', 'Y', '2024-02-22 11:37:51', NULL, NULL),
(602, 1, 39, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:51', NULL, NULL),
(603, 1, 39, 'cron_campaign', '919310405394', '919310405394', 'Success', 'Y', '2024-02-22 11:37:52', NULL, NULL),
(604, 1, 39, 'cron_campaign', '919381440554', '919381440554', 'Success', 'Y', '2024-02-22 11:37:52', NULL, NULL),
(605, 1, 40, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:52', NULL, NULL),
(606, 1, 40, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:52', NULL, NULL),
(607, 1, 40, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:52', NULL, NULL),
(608, 1, 41, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:53', NULL, NULL),
(609, 1, 41, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:53', NULL, NULL),
(610, 1, 41, 'cron_campaign', '917760215131', '917760215131', 'Success', 'Y', '2024-02-22 11:37:53', NULL, NULL),
(611, 1, 41, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:53', NULL, NULL),
(612, 1, 42, 'cron_campaign', '919502657666', '919502657666', 'Success', 'Y', '2024-02-22 11:37:54', NULL, NULL),
(613, 1, 42, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:54', NULL, NULL),
(614, 1, 42, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:54', NULL, NULL),
(615, 1, 42, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:54', NULL, NULL),
(616, 1, 43, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:54', NULL, NULL),
(617, 1, 43, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:54', NULL, NULL),
(618, 1, 43, 'cron_campaign', '919494574101', '919494574101', 'Success', 'Y', '2024-02-22 11:37:55', NULL, NULL),
(619, 1, 43, 'cron_campaign', '917760215131', '917760215131', 'Success', 'Y', '2024-02-22 11:37:55', NULL, NULL),
(620, 1, 43, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:55', NULL, NULL),
(621, 1, 43, 'cron_campaign', '919676134029', '919676134029', 'Success', 'Y', '2024-02-22 11:37:55', NULL, NULL),
(622, 1, 43, 'cron_campaign', '919704808034', '919704808034', 'Success', 'Y', '2024-02-22 11:37:55', NULL, NULL),
(623, 1, 44, 'cron_campaign', '919502657666', '919502657666', 'Success', 'Y', '2024-02-22 11:37:55', NULL, NULL),
(624, 1, 44, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:55', NULL, NULL),
(625, 1, 44, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:56', NULL, NULL),
(626, 1, 44, 'cron_campaign', '917842735182', '917842735182', 'Success', 'Y', '2024-02-22 11:37:56', NULL, NULL),
(627, 1, 44, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:56', NULL, NULL),
(628, 1, 45, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:56', NULL, NULL),
(629, 1, 45, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:57', NULL, NULL),
(630, 1, 45, 'cron_campaign', '917760215131', '917760215131', 'Success', 'Y', '2024-02-22 11:37:57', NULL, NULL),
(631, 1, 45, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:57', NULL, NULL),
(632, 1, 46, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:57', NULL, NULL),
(633, 1, 46, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:57', NULL, NULL),
(634, 1, 46, 'cron_campaign', '917760215131', '917760215131', 'Success', 'Y', '2024-02-22 11:37:57', NULL, NULL),
(635, 1, 46, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:58', NULL, NULL),
(636, 1, 47, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:58', NULL, NULL),
(637, 1, 47, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:58', NULL, NULL),
(638, 1, 47, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:58', NULL, NULL),
(639, 1, 48, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:37:59', NULL, NULL),
(640, 1, 48, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:37:59', NULL, NULL),
(641, 1, 48, 'cron_campaign', '917989911079', '917989911079', 'Success', 'Y', '2024-02-22 11:37:59', NULL, NULL),
(642, 1, 48, 'cron_campaign', '917760215131', '917760215131', 'Success', 'Y', '2024-02-22 11:37:59', NULL, NULL),
(643, 1, 48, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:37:59', NULL, NULL),
(644, 1, 48, 'cron_campaign', '918897537269', '918897537269', 'Success', 'Y', '2024-02-22 11:37:59', NULL, NULL),
(645, 1, 48, 'cron_campaign', '919000327879', '919000327879', 'Success', 'Y', '2024-02-22 11:37:59', NULL, NULL),
(646, 1, 48, 'cron_campaign', '919550250481', '919550250481', 'Success', 'Y', '2024-02-22 11:37:59', NULL, NULL),
(647, 1, 49, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:38:00', NULL, NULL),
(648, 1, 49, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:38:00', NULL, NULL),
(649, 1, 49, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:38:00', NULL, NULL),
(650, 1, 50, 'cron_campaign', '919502657666', '919502657666', 'Success', 'Y', '2024-02-22 11:38:01', NULL, NULL),
(651, 1, 50, 'cron_campaign', '916309253815', '916309253815', 'Success', 'Y', '2024-02-22 11:38:01', NULL, NULL),
(652, 1, 50, 'cron_campaign', '919063936121', '919063936121', 'Success', 'Y', '2024-02-22 11:38:01', NULL, NULL),
(653, 1, 50, 'cron_campaign', '918897333343', '918897333343', 'Success', 'Y', '2024-02-22 11:38:01', NULL, NULL),
(654, 1, 50, 'cron_campaign', '919381076358', '919381076358', 'Success', 'Y', '2024-02-22 11:38:01', NULL, NULL),
(655, 1, 50, 'cron_campaign', '916281310972', '916281310972', 'Success', 'Y', '2024-02-22 11:38:01', NULL, NULL),
(656, 1, 50, 'cron_campaign', '916281779553', '916281779553', 'Success', 'Y', '2024-02-22 11:38:01', NULL, NULL),
(657, 1, 50, 'cron_campaign', '916281893191', '916281893191', 'Success', 'Y', '2024-02-22 11:38:01', NULL, NULL),
(658, 1, 50, 'cron_campaign', '916295850997', '916295850997', 'Success', 'Y', '2024-02-22 11:38:01', NULL, NULL),
(659, 1, 50, 'cron_campaign', '916300452788', '916300452788', 'Success', 'Y', '2024-02-22 11:38:01', NULL, NULL),
(660, 1, 50, 'cron_campaign', '916303169303', '916303169303', 'Success', 'Y', '2024-02-22 11:38:01', NULL, NULL),
(661, 1, 50, 'cron_campaign', '917013321627', '917013321627', 'Success', 'Y', '2024-02-22 11:38:01', NULL, NULL),
(662, 1, 50, 'cron_campaign', '917095932520', '917095932520', 'Success', 'Y', '2024-02-22 11:38:02', NULL, NULL),
(663, 1, 50, 'cron_campaign', '917569927282', '917569927282', 'Success', 'Y', '2024-02-22 11:38:02', NULL, NULL),
(664, 1, 50, 'cron_campaign', '917680848494', '917680848494', 'Success', 'Y', '2024-02-22 11:38:02', NULL, NULL),
(665, 1, 50, 'cron_campaign', '917702365373', '917702365373', 'Success', 'Y', '2024-02-22 11:38:02', NULL, NULL),
(666, 1, 50, 'cron_campaign', '917702628225', '917702628225', 'Success', 'Y', '2024-02-22 11:38:02', NULL, NULL),
(667, 1, 50, 'cron_campaign', '917760215131', '917760215131', 'Success', 'Y', '2024-02-22 11:38:02', NULL, NULL),
(668, 1, 50, 'cron_campaign', '917794989340', '917794989340', 'Success', 'Y', '2024-02-22 11:38:02', NULL, NULL),
(669, 1, 50, 'cron_campaign', '917893936457', '917893936457', 'Success', 'Y', '2024-02-22 11:38:03', NULL, NULL),
(670, 1, 50, 'cron_campaign', '917893943032', '917893943032', 'Success', 'Y', '2024-02-22 11:38:03', NULL, NULL),
(671, 1, 50, 'cron_campaign', '917993355866', '917993355866', 'Success', 'Y', '2024-02-22 11:38:03', NULL, NULL),
(672, 1, 50, 'cron_campaign', '917995531553', '917995531553', 'Success', 'Y', '2024-02-22 11:38:03', NULL, NULL),
(673, 1, 50, 'cron_campaign', '917995550102', '917995550102', 'Success', 'Y', '2024-02-22 11:38:03', NULL, NULL),
(674, 1, 50, 'cron_campaign', '918008282559', '918008282559', 'Success', 'Y', '2024-02-22 11:38:04', NULL, NULL),
(675, 1, 50, 'cron_campaign', '918121865103', '918121865103', 'Success', 'Y', '2024-02-22 11:38:04', NULL, NULL),
(676, 1, 50, 'cron_campaign', '918179918896', '918179918896', 'Success', 'Y', '2024-02-22 11:38:04', NULL, NULL),
(677, 1, 50, 'cron_campaign', '918186825183', '918186825183', 'Success', 'Y', '2024-02-22 11:38:04', NULL, NULL),
(678, 1, 50, 'cron_campaign', '918247779377', '918247779377', 'Success', 'Y', '2024-02-22 11:38:04', NULL, NULL),
(679, 1, 50, 'cron_campaign', '918328383186', '918328383186', 'Success', 'Y', '2024-02-22 11:38:04', NULL, NULL),
(680, 1, 50, 'cron_campaign', '918330970619', '918330970619', 'Success', 'Y', '2024-02-22 11:38:04', NULL, NULL),
(681, 1, 50, 'cron_campaign', '918340821429', '918340821429', 'Success', 'Y', '2024-02-22 11:38:04', NULL, NULL),
(682, 1, 50, 'cron_campaign', '918367092163', '918367092163', 'Success', 'Y', '2024-02-22 11:38:04', NULL, NULL),
(683, 1, 50, 'cron_campaign', '918367471363', '918367471363', 'Success', 'Y', '2024-02-22 11:38:04', NULL, NULL),
(684, 1, 50, 'cron_campaign', '918374767783', '918374767783', 'Success', 'Y', '2024-02-22 11:38:05', NULL, NULL),
(685, 1, 50, 'cron_campaign', '918374905369', '918374905369', 'Success', 'Y', '2024-02-22 11:38:05', NULL, NULL),
(686, 1, 50, 'cron_campaign', '918500194525', '918500194525', 'Success', 'Y', '2024-02-22 11:38:05', NULL, NULL),
(687, 1, 50, 'cron_campaign', '918500270890', '918500270890', 'Success', 'Y', '2024-02-22 11:38:05', NULL, NULL),
(688, 1, 50, 'cron_campaign', '918500324368', '918500324368', 'Success', 'Y', '2024-02-22 11:38:05', NULL, NULL),
(689, 1, 50, 'cron_campaign', '918500903286', '918500903286', 'Success', 'Y', '2024-02-22 11:38:05', NULL, NULL),
(690, 1, 50, 'cron_campaign', '918500949738', '918500949738', 'Success', 'Y', '2024-02-22 11:38:05', NULL, NULL),
(691, 1, 50, 'cron_campaign', '918500962674', '918500962674', 'Success', 'Y', '2024-02-22 11:38:05', NULL, NULL),
(692, 1, 50, 'cron_campaign', '918688133310', '918688133310', 'Success', 'Y', '2024-02-22 11:38:05', NULL, NULL),
(693, 1, 50, 'cron_campaign', '918688755615', '918688755615', 'Success', 'Y', '2024-02-22 11:38:05', NULL, NULL),
(694, 1, 50, 'cron_campaign', '918790541375', '918790541375', 'Success', 'Y', '2024-02-22 11:38:06', NULL, NULL),
(695, 1, 50, 'cron_campaign', '918790557561', '918790557561', 'Success', 'Y', '2024-02-22 11:38:06', NULL, NULL),
(696, 1, 50, 'cron_campaign', '918897122110', '918897122110', 'Success', 'Y', '2024-02-22 11:38:06', NULL, NULL),
(697, 1, 50, 'cron_campaign', '918897566368', '918897566368', 'Success', 'Y', '2024-02-22 11:38:06', NULL, NULL),
(698, 1, 50, 'cron_campaign', '918897715697', '918897715697', 'Success', 'Y', '2024-02-22 11:38:06', NULL, NULL),
(699, 1, 50, 'cron_campaign', '918901027075', '918901027075', 'Success', 'Y', '2024-02-22 11:38:06', NULL, NULL),
(700, 1, 50, 'cron_campaign', '918978150565', '918978150565', 'Success', 'Y', '2024-02-22 11:38:06', NULL, NULL),
(701, 1, 50, 'cron_campaign', '918978743225', '918978743225', 'Success', 'Y', '2024-02-22 11:38:06', NULL, NULL),
(702, 1, 50, 'cron_campaign', '919000558402', '919000558402', 'Success', 'Y', '2024-02-22 11:38:06', NULL, NULL),
(703, 1, 50, 'cron_campaign', '919000727919', '919000727919', 'Success', 'Y', '2024-02-22 11:38:06', NULL, NULL),
(704, 1, 50, 'cron_campaign', '919059164315', '919059164315', 'Success', 'Y', '2024-02-22 11:38:07', NULL, NULL),
(705, 1, 50, 'cron_campaign', '919100929999', '919100929999', 'Success', 'Y', '2024-02-22 11:38:07', NULL, NULL),
(706, 1, 50, 'cron_campaign', '919160151914', '919160151914', 'Success', 'Y', '2024-02-22 11:38:07', NULL, NULL),
(707, 1, 50, 'cron_campaign', '919177298136', '919177298136', 'Success', 'Y', '2024-02-22 11:38:07', NULL, NULL),
(708, 1, 50, 'cron_campaign', '919177798583', '919177798583', 'Success', 'Y', '2024-02-22 11:38:07', NULL, NULL),
(709, 1, 50, 'cron_campaign', '919182318399', '919182318399', 'Success', 'Y', '2024-02-22 11:38:07', NULL, NULL),
(710, 1, 50, 'cron_campaign', '919346459515', '919346459515', 'Success', 'Y', '2024-02-22 11:38:07', NULL, NULL),
(711, 1, 50, 'cron_campaign', '919347453510', '919347453510', 'Success', 'Y', '2024-02-22 11:38:07', NULL, NULL),
(712, 1, 50, 'cron_campaign', '919381348640', '919381348640', 'Success', 'Y', '2024-02-22 11:38:07', NULL, NULL),
(713, 1, 50, 'cron_campaign', '919390499209', '919390499209', 'Success', 'Y', '2024-02-22 11:38:07', NULL, NULL),
(714, 1, 50, 'cron_campaign', '919391466573', '919391466573', 'Success', 'Y', '2024-02-22 11:38:07', NULL, NULL),
(715, 1, 50, 'cron_campaign', '919398399481', '919398399481', 'Success', 'Y', '2024-02-22 11:38:08', NULL, NULL),
(716, 1, 50, 'cron_campaign', '919398585784', '919398585784', 'Success', 'Y', '2024-02-22 11:38:08', NULL, NULL),
(717, 1, 50, 'cron_campaign', '919440252451', '919440252451', 'Success', 'Y', '2024-02-22 11:38:08', NULL, NULL),
(718, 1, 50, 'cron_campaign', '919440283469', '919440283469', 'Success', 'Y', '2024-02-22 11:38:08', NULL, NULL),
(719, 1, 50, 'cron_campaign', '919440560513', '919440560513', 'Success', 'Y', '2024-02-22 11:38:08', NULL, NULL),
(720, 1, 50, 'cron_campaign', '919440754430', '919440754430', 'Success', 'Y', '2024-02-22 11:38:08', NULL, NULL),
(721, 1, 50, 'cron_campaign', '919440999931', '919440999931', 'Success', 'Y', '2024-02-22 11:38:08', NULL, NULL),
(722, 1, 50, 'cron_campaign', '919441119352', '919441119352', 'Success', 'Y', '2024-02-22 11:38:08', NULL, NULL),
(723, 1, 50, 'cron_campaign', '919441160900', '919441160900', 'Success', 'Y', '2024-02-22 11:38:08', NULL, NULL),
(724, 1, 50, 'cron_campaign', '919441179966', '919441179966', 'Success', 'Y', '2024-02-22 11:38:08', NULL, NULL),
(725, 1, 50, 'cron_campaign', '919441320690', '919441320690', 'Success', 'Y', '2024-02-22 11:38:09', NULL, NULL),
(726, 1, 50, 'cron_campaign', '919441328728', '919441328728', 'Success', 'Y', '2024-02-22 11:38:09', NULL, NULL),
(727, 1, 50, 'cron_campaign', '919490057595', '919490057595', 'Success', 'Y', '2024-02-22 11:38:09', NULL, NULL),
(728, 1, 50, 'cron_campaign', '919490065215', '919490065215', 'Success', 'Y', '2024-02-22 11:38:09', NULL, NULL),
(729, 1, 50, 'cron_campaign', '919490088367', '919490088367', 'Success', 'Y', '2024-02-22 11:38:09', NULL, NULL),
(730, 1, 50, 'cron_campaign', '919490563894', '919490563894', 'Success', 'Y', '2024-02-22 11:38:09', NULL, NULL),
(731, 1, 50, 'cron_campaign', '919490566308', '919490566308', 'Success', 'Y', '2024-02-22 11:38:09', NULL, NULL),
(732, 1, 50, 'cron_campaign', '919490904247', '919490904247', 'Success', 'Y', '2024-02-22 11:38:09', NULL, NULL),
(733, 1, 50, 'cron_campaign', '919491727938', '919491727938', 'Success', 'Y', '2024-02-22 11:38:09', NULL, NULL),
(734, 1, 50, 'cron_campaign', '919491933133', '919491933133', 'Success', 'Y', '2024-02-22 11:38:09', NULL, NULL),
(735, 1, 50, 'cron_campaign', '919492546484', '919492546484', 'Success', 'Y', '2024-02-22 11:38:09', NULL, NULL),
(736, 1, 50, 'cron_campaign', '919492761965', '919492761965', 'Success', 'Y', '2024-02-22 11:38:09', NULL, NULL),
(737, 1, 50, 'cron_campaign', '919492763326', '919492763326', 'Success', 'Y', '2024-02-22 11:38:09', NULL, NULL),
(738, 1, 50, 'cron_campaign', '919493044218', '919493044218', 'Success', 'Y', '2024-02-22 11:38:10', NULL, NULL),
(739, 1, 50, 'cron_campaign', '919493083766', '919493083766', 'Success', 'Y', '2024-02-22 11:38:10', NULL, NULL),
(740, 1, 50, 'cron_campaign', '919494163484', '919494163484', 'Success', 'Y', '2024-02-22 11:38:10', NULL, NULL),
(741, 1, 50, 'cron_campaign', '919494200211', '919494200211', 'Success', 'Y', '2024-02-22 11:38:10', NULL, NULL),
(742, 1, 50, 'cron_campaign', '919494204367', '919494204367', 'Success', 'Y', '2024-02-22 11:38:10', NULL, NULL),
(743, 1, 50, 'cron_campaign', '919494206997', '919494206997', 'Success', 'Y', '2024-02-22 11:38:10', NULL, NULL),
(744, 1, 50, 'cron_campaign', '919494468739', '919494468739', 'Success', 'Y', '2024-02-22 11:38:10', NULL, NULL),
(745, 1, 50, 'cron_campaign', '919494519562', '919494519562', 'Success', 'Y', '2024-02-22 11:38:10', NULL, NULL),
(746, 1, 50, 'cron_campaign', '919505141548', '919505141548', 'Success', 'Y', '2024-02-22 11:38:10', NULL, NULL),
(747, 1, 50, 'cron_campaign', '919515448558', '919515448558', 'Success', 'Y', '2024-02-22 11:38:10', NULL, NULL),
(748, 1, 50, 'cron_campaign', '919515848338', '919515848338', 'Success', 'Y', '2024-02-22 11:38:10', NULL, NULL),
(749, 1, 50, 'cron_campaign', '919533371922', '919533371922', 'Success', 'Y', '2024-02-22 11:38:10', NULL, NULL),
(750, 1, 50, 'cron_campaign', '919542160935', '919542160935', 'Success', 'Y', '2024-02-22 11:38:11', NULL, NULL),
(751, 1, 50, 'cron_campaign', '919550097836', '919550097836', 'Success', 'Y', '2024-02-22 11:38:11', NULL, NULL),
(752, 1, 50, 'cron_campaign', '919550322143', '919550322143', 'Success', 'Y', '2024-02-22 11:38:11', NULL, NULL),
(753, 1, 50, 'cron_campaign', '919573031806', '919573031806', 'Success', 'Y', '2024-02-22 11:38:11', NULL, NULL),
(754, 1, 50, 'cron_campaign', '919676909862', '919676909862', 'Success', 'Y', '2024-02-22 11:38:11', NULL, NULL),
(755, 1, 50, 'cron_campaign', '919701310880', '919701310880', 'Success', 'Y', '2024-02-22 11:38:11', NULL, NULL),
(756, 1, 50, 'cron_campaign', '919701406264', '919701406264', 'Success', 'Y', '2024-02-22 11:38:11', NULL, NULL),
(757, 1, 50, 'cron_campaign', '919703734352', '919703734352', 'Success', 'Y', '2024-02-22 11:38:11', NULL, NULL),
(758, 1, 50, 'cron_campaign', '919848528562', '919848528562', 'Success', 'Y', '2024-02-22 11:38:11', NULL, NULL),
(759, 1, 50, 'cron_campaign', '919866996697', '919866996697', 'Success', 'Y', '2024-02-22 11:38:11', NULL, NULL),
(760, 1, 50, 'cron_campaign', '919908667723', '919908667723', 'Success', 'Y', '2024-02-22 11:38:11', NULL, NULL),
(761, 1, 50, 'cron_campaign', '919945793194', '919945793194', 'Success', 'Y', '2024-02-22 11:38:11', NULL, NULL),
(762, 1, 50, 'cron_campaign', '919948165470', '919948165470', 'Success', 'Y', '2024-02-22 11:38:11', NULL, NULL),
(763, 1, 50, 'cron_campaign', '919949304772', '919949304772', 'Success', 'Y', '2024-02-22 11:38:12', NULL, NULL),
(764, 1, 50, 'cron_campaign', '919963017994', '919963017994', 'Success', 'Y', '2024-02-22 11:38:12', NULL, NULL),
(765, 1, 50, 'cron_campaign', '919963686416', '919963686416', 'Success', 'Y', '2024-02-22 11:38:12', NULL, NULL),
(766, 1, 50, 'cron_campaign', '919963877051', '919963877051', 'Success', 'Y', '2024-02-22 11:38:12', NULL, NULL),
(767, 1, 50, 'cron_campaign', '919966765684', '919966765684', 'Success', 'Y', '2024-02-22 11:38:12', NULL, NULL),
(768, 1, 50, 'cron_campaign', '919985178481', '919985178481', 'Success', 'Y', '2024-02-22 11:38:12', NULL, NULL),
(769, 1, 50, 'cron_campaign', '919989666652', '919989666652', 'Success', 'Y', '2024-02-22 11:38:12', NULL, NULL),
(770, 1, 10, 'ca_Cmpgn 5_055_NaN', '919686193535', '919686193535', 'Success', 'R', '2024-02-24 06:55:09', 'Remove', 'R'),
(771, 1, 12, 'cron_campaign', '916380885546', '916380885546', 'Success', 'Y', '2024-02-24 07:50:20', NULL, NULL),
(772, 1, 51, 'cron_campaign', '919786448157', '919786448157', 'Success', 'Y', '2024-02-26 05:26:03', NULL, NULL),
(773, 1, 51, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:03', NULL, NULL),
(774, 1, 51, 'cron_campaign', '916380747454', '916380747454', 'Success', 'Y', '2024-02-26 05:26:03', NULL, NULL),
(775, 1, 51, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-26 05:26:03', NULL, NULL),
(776, 1, 51, 'cron_campaign', '916380885546', '916380885546', 'Success', 'Y', '2024-02-26 05:26:03', NULL, NULL),
(777, 1, 51, 'cron_campaign', '919025167792', '919025167792', 'Success', 'Y', '2024-02-26 05:26:04', NULL, NULL),
(778, 1, 51, 'cron_campaign', '917904778285', '917904778285', 'Success', 'Y', '2024-02-26 05:26:04', NULL, NULL),
(779, 1, 52, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:04', NULL, NULL),
(780, 1, 52, 'cron_campaign', '917904778285', '917904778285', 'Success', 'Y', '2024-02-26 05:26:04', NULL, NULL),
(781, 1, 53, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:05', NULL, NULL),
(782, 1, 53, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-26 05:26:05', NULL, NULL),
(783, 1, 53, 'cron_campaign', '917904778285', '917904778285', 'Success', 'Y', '2024-02-26 05:26:05', NULL, NULL),
(784, 1, 54, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:05', NULL, NULL),
(785, 1, 54, 'cron_campaign', '917904778285', '917904778285', 'Success', 'Y', '2024-02-26 05:26:05', NULL, NULL),
(786, 1, 55, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:06', NULL, NULL),
(787, 1, 55, 'cron_campaign', '917904778285', '917904778285', 'Success', 'Y', '2024-02-26 05:26:06', NULL, NULL),
(788, 1, 56, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:06', NULL, NULL),
(789, 1, 56, 'cron_campaign', '917904778285', '917904778285', 'Success', 'Y', '2024-02-26 05:26:07', NULL, NULL),
(790, 1, 57, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:07', NULL, NULL),
(791, 1, 57, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-26 05:26:07', NULL, NULL),
(792, 1, 58, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:08', NULL, NULL),
(793, 1, 58, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-26 05:26:08', NULL, NULL),
(794, 1, 59, 'cron_campaign', '919786448157', '919786448157', 'Success', 'Y', '2024-02-26 05:26:09', NULL, NULL),
(795, 1, 59, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:09', NULL, NULL),
(796, 1, 59, 'cron_campaign', '916380747454', '916380747454', 'Success', 'Y', '2024-02-26 05:26:09', NULL, NULL),
(797, 1, 59, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-26 05:26:09', NULL, NULL),
(798, 1, 59, 'cron_campaign', '916380885546', '916380885546', 'Success', 'Y', '2024-02-26 05:26:09', NULL, NULL),
(799, 1, 59, 'cron_campaign', '919025167792', '919025167792', 'Success', 'Y', '2024-02-26 05:26:09', NULL, NULL),
(800, 1, 59, 'cron_campaign', '917904778285', '917904778285', 'Success', 'Y', '2024-02-26 05:26:09', NULL, NULL),
(801, 1, 60, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:09', NULL, NULL),
(802, 1, 60, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 05:26:09', NULL, NULL),
(803, 1, 61, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:10', NULL, NULL),
(804, 1, 61, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 05:26:10', NULL, NULL),
(805, 1, 62, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:10', NULL, NULL),
(806, 1, 62, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 05:26:10', NULL, NULL),
(807, 1, 63, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:11', NULL, NULL),
(808, 1, 63, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 05:26:12', NULL, NULL),
(809, 1, 64, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:12', NULL, NULL),
(810, 1, 64, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 05:26:12', NULL, NULL),
(811, 1, 65, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:13', NULL, NULL),
(812, 1, 65, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 05:26:13', NULL, NULL),
(813, 1, 66, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:13', NULL, NULL),
(814, 1, 66, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 05:26:14', NULL, NULL),
(815, 1, 67, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:15', NULL, NULL),
(816, 1, 67, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 05:26:15', NULL, NULL),
(817, 1, 68, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:15', NULL, NULL),
(818, 1, 68, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 05:26:15', NULL, NULL),
(819, 1, 69, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:16', NULL, NULL),
(820, 1, 69, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 05:26:16', NULL, NULL),
(821, 1, 70, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:16', NULL, NULL),
(822, 1, 70, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 05:26:16', NULL, NULL),
(823, 1, 71, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 05:26:17', NULL, NULL),
(824, 1, 71, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 05:26:17', NULL, NULL),
(825, 1, 14, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:20:21', NULL, NULL),
(826, 1, 14, 'cron_campaign', '919786448157', '919786448157', 'Success', 'Y', '2024-02-26 06:20:21', NULL, NULL),
(827, 1, 14, 'cron_campaign', '916380747454', '916380747454', 'Success', 'Y', '2024-02-26 06:20:21', NULL, NULL),
(828, 1, 14, 'cron_campaign', '917904778285', '917904778285', 'Success', 'Y', '2024-02-26 06:20:22', NULL, NULL),
(829, 1, 14, 'cron_campaign', '919025167792', '919025167792', 'Success', 'Y', '2024-02-26 06:20:22', NULL, NULL),
(830, 1, 72, 'cron_campaign', '919786448157', '919786448157', 'Success', 'Y', '2024-02-26 06:51:59', NULL, NULL),
(831, 1, 72, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:51:59', NULL, NULL),
(832, 1, 72, 'cron_campaign', '916380747454', '916380747454', 'Success', 'Y', '2024-02-26 06:51:59', NULL, NULL),
(833, 1, 72, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-26 06:52:00', NULL, NULL),
(834, 1, 72, 'cron_campaign', '916380885546', '916380885546', 'Success', 'Y', '2024-02-26 06:52:00', NULL, NULL),
(835, 1, 72, 'cron_campaign', '919025167792', '919025167792', 'Success', 'Y', '2024-02-26 06:52:00', NULL, NULL),
(836, 1, 72, 'cron_campaign', '917904778285', '917904778285', 'Success', 'Y', '2024-02-26 06:52:00', NULL, NULL),
(837, 1, 73, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:01', NULL, NULL),
(838, 1, 73, 'cron_campaign', '917904778285', '917904778285', 'Success', 'Y', '2024-02-26 06:52:01', NULL, NULL),
(839, 1, 74, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:01', NULL, NULL),
(840, 1, 74, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-26 06:52:01', NULL, NULL),
(841, 1, 74, 'cron_campaign', '917904778285', '917904778285', 'Success', 'Y', '2024-02-26 06:52:01', NULL, NULL),
(842, 1, 75, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:02', NULL, NULL),
(843, 1, 75, 'cron_campaign', '917904778285', '917904778285', 'Success', 'Y', '2024-02-26 06:52:02', NULL, NULL),
(844, 1, 76, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:02', NULL, NULL),
(845, 1, 76, 'cron_campaign', '917904778285', '917904778285', 'Success', 'Y', '2024-02-26 06:52:02', NULL, NULL),
(846, 1, 77, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:03', NULL, NULL),
(847, 1, 77, 'cron_campaign', '917904778285', '917904778285', 'Success', 'Y', '2024-02-26 06:52:03', NULL, NULL),
(848, 1, 78, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:03', NULL, NULL),
(849, 1, 78, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-26 06:52:03', NULL, NULL),
(850, 1, 79, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:04', NULL, NULL),
(851, 1, 79, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-26 06:52:04', NULL, NULL),
(852, 1, 80, 'cron_campaign', '919786448157', '919786448157', 'Success', 'Y', '2024-02-26 06:52:05', NULL, 'R'),
(853, 1, 80, 'cron_campaign', '918838964597', '918838964597', 'already admin', 'N', '2024-02-26 06:52:05', NULL, NULL),
(854, 1, 80, 'cron_campaign', '916380747454', '916380747454', 'Success', 'Y', '2024-02-26 06:52:05', NULL, 'R'),
(855, 1, 80, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-26 06:52:05', NULL, 'R'),
(856, 1, 80, 'cron_campaign', '916380885546', '916380885546', 'Success', 'Y', '2024-02-26 06:52:05', NULL, 'R'),
(857, 1, 80, 'cron_campaign', '919025167792', '919025167792', 'Success', 'Y', '2024-02-26 06:52:05', NULL, 'R'),
(858, 1, 80, 'cron_campaign', '917904778285', '917904778285', 'Success', 'Y', '2024-02-26 06:52:05', NULL, 'R'),
(859, 1, 81, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:06', NULL, NULL),
(860, 1, 81, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 06:52:06', NULL, NULL),
(861, 1, 82, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:06', NULL, NULL),
(862, 1, 82, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 06:52:06', NULL, NULL),
(863, 1, 83, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:07', NULL, NULL),
(864, 1, 83, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 06:52:07', NULL, NULL),
(865, 1, 84, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:07', NULL, NULL),
(866, 1, 84, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 06:52:07', NULL, NULL),
(867, 1, 85, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:08', NULL, NULL),
(868, 1, 85, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 06:52:08', NULL, NULL),
(869, 1, 86, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:08', NULL, NULL),
(870, 1, 86, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 06:52:08', NULL, NULL),
(871, 1, 87, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:09', NULL, NULL),
(872, 1, 87, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 06:52:09', NULL, NULL),
(873, 1, 88, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:09', NULL, NULL),
(874, 1, 88, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 06:52:09', NULL, NULL),
(875, 1, 89, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:10', NULL, NULL),
(876, 1, 89, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 06:52:10', NULL, NULL),
(877, 1, 90, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:10', NULL, NULL),
(878, 1, 90, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 06:52:10', NULL, NULL),
(879, 1, 91, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:11', NULL, NULL),
(880, 1, 91, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 06:52:11', NULL, NULL),
(881, 1, 92, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 06:52:12', NULL, NULL),
(882, 1, 92, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 06:52:12', NULL, NULL),
(883, 1, 93, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:11', NULL, NULL),
(884, 1, 93, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 14:35:11', NULL, NULL),
(885, 1, 80, 'cron_campaign', '919894606748', '919894606748', 'Failure', 'N', '2024-02-26 14:35:12', NULL, 'F'),
(886, 1, 80, 'cron_campaign', '919445603329', '919445603329', 'Failure', 'N', '2024-02-26 14:35:12', NULL, 'F'),
(887, 1, 80, 'cron_campaign', '919344145033', '919344145033', 'Failure', 'N', '2024-02-26 14:35:12', NULL, 'F'),
(888, 1, 80, 'cron_campaign', '919363113380', '919363113380', 'Failure', 'N', '2024-02-26 14:35:12', NULL, 'F'),
(889, 1, 94, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:15', NULL, NULL),
(890, 1, 94, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 14:35:15', NULL, NULL),
(891, 1, 95, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:15', NULL, NULL),
(892, 1, 95, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 14:35:16', NULL, NULL),
(893, 1, 96, 'cron_campaign', '919150794800', '919150794800', 'Success', 'Y', '2024-02-26 14:35:18', NULL, NULL),
(894, 1, 96, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:18', NULL, NULL),
(895, 1, 96, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-26 14:35:18', NULL, NULL),
(896, 1, 96, 'cron_campaign', '916369841530', '916369841530', 'Success', 'Y', '2024-02-26 14:35:18', NULL, NULL),
(897, 1, 97, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:19', NULL, NULL),
(898, 1, 97, 'cron_campaign', '916369841530', '916369841530', 'Success', 'Y', '2024-02-26 14:35:19', NULL, NULL),
(899, 1, 97, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 14:35:19', NULL, NULL),
(900, 1, 98, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:19', NULL, NULL),
(901, 1, 98, 'cron_campaign', '916369841530', '916369841530', 'Success', 'Y', '2024-02-26 14:35:20', NULL, NULL),
(902, 1, 99, 'cron_campaign', '919786448157', '919786448157', 'Success', 'Y', '2024-02-26 14:35:21', NULL, NULL),
(903, 1, 99, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:21', NULL, NULL),
(904, 1, 99, 'cron_campaign', '916380747454', '916380747454', 'Success', 'Y', '2024-02-26 14:35:21', NULL, NULL),
(905, 1, 99, 'cron_campaign', '919025167792', '919025167792', 'Success', 'Y', '2024-02-26 14:35:21', NULL, NULL),
(906, 1, 99, 'cron_campaign', '917904778285', '917904778285', 'Success', 'Y', '2024-02-26 14:35:21', NULL, NULL);
INSERT INTO `group_contacts` (`group_contacts_id`, `user_id`, `group_master_id`, `campaign_name`, `mobile_no`, `mobile_id`, `comments`, `group_contacts_status`, `group_contacts_entry_date`, `remove_comments`, `admin_status`) VALUES
(907, 1, 100, 'cron_campaign', '919150794800', '919150794800', 'Success', 'Y', '2024-02-26 14:35:22', NULL, NULL),
(908, 1, 100, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:22', NULL, NULL),
(909, 1, 100, 'cron_campaign', '916369841530', '916369841530', 'Success', 'Y', '2024-02-26 14:35:22', NULL, NULL),
(910, 1, 100, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 14:35:22', NULL, NULL),
(911, 1, 101, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:24', NULL, NULL),
(912, 1, 101, 'cron_campaign', '919965014814', '919965014814', 'Success', 'Y', '2024-02-26 14:35:24', NULL, NULL),
(913, 1, 100, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-26 14:35:24', NULL, NULL),
(914, 1, 100, 'cron_campaign', '916380885546', '916380885546', 'Success', 'Y', '2024-02-26 14:35:24', NULL, NULL),
(915, 1, 101, 'cron_campaign', '919894606748', '919894606748', 'Success', 'Y', '2024-02-26 14:35:26', NULL, NULL),
(916, 1, 101, 'cron_campaign', '919786448157', '919786448157', 'Success', 'Y', '2024-02-26 14:35:26', NULL, NULL),
(917, 1, 101, 'cron_campaign', '916380747454', '916380747454', 'Success', 'Y', '2024-02-26 14:35:26', NULL, NULL),
(918, 1, 101, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-26 14:35:26', NULL, NULL),
(919, 1, 101, 'cron_campaign', '916380885546', '916380885546', 'Success', 'Y', '2024-02-26 14:35:26', NULL, NULL),
(920, 1, 101, 'cron_campaign', '919025167792', '919025167792', 'Success', 'Y', '2024-02-26 14:35:26', NULL, NULL),
(921, 1, 101, 'cron_campaign', '918919669165', '918919669165', 'Success', 'Y', '2024-02-26 14:35:26', NULL, NULL),
(922, 1, 101, 'cron_campaign', '919363113380', '919363113380', 'Success', 'Y', '2024-02-26 14:35:26', NULL, NULL),
(923, 1, 99, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-26 14:35:27', NULL, NULL),
(924, 1, 99, 'cron_campaign', '919344145033', '919344145033', 'Success', 'Y', '2024-02-26 14:35:27', NULL, NULL),
(925, 1, 102, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:27', NULL, NULL),
(926, 1, 102, 'cron_campaign', '919894850704', '919894850704', 'Success', 'Y', '2024-02-26 14:35:28', NULL, NULL),
(927, 1, 102, 'cron_campaign', '916380885546', '916380885546', 'Success', 'Y', '2024-02-26 14:35:28', NULL, NULL),
(928, 1, 103, 'cron_campaign', '919566041612', '919566041612', 'Success', 'Y', '2024-02-26 14:35:29', NULL, NULL),
(929, 1, 103, 'cron_campaign', '919894168507', '919894168507', 'Success', 'Y', '2024-02-26 14:35:30', NULL, NULL),
(930, 1, 103, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:30', NULL, NULL),
(931, 1, 103, 'cron_campaign', '919786836957', '919786836957', 'Success', 'Y', '2024-02-26 14:35:30', NULL, NULL),
(932, 1, 103, 'cron_campaign', '917598142188', '917598142188', 'Success', 'Y', '2024-02-26 14:35:30', NULL, NULL),
(933, 1, 103, 'cron_campaign', '918903399027', '918903399027', 'Success', 'Y', '2024-02-26 14:35:30', NULL, NULL),
(934, 1, 103, 'cron_campaign', '918056841132', '918056841132', 'Success', 'Y', '2024-02-26 14:35:30', NULL, NULL),
(935, 1, 103, 'cron_campaign', '918248207053', '918248207053', 'Success', 'Y', '2024-02-26 14:35:30', NULL, NULL),
(936, 1, 103, 'cron_campaign', '918754318708', '918754318708', 'Success', 'Y', '2024-02-26 14:35:30', NULL, NULL),
(937, 1, 103, 'cron_campaign', '919465223801', '919465223801', 'Success', 'Y', '2024-02-26 14:35:30', NULL, NULL),
(938, 1, 104, 'cron_campaign', '916385162177', '916385162177', 'Success', 'Y', '2024-02-26 14:35:35', NULL, NULL),
(939, 1, 104, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:35', NULL, NULL),
(940, 1, 104, 'cron_campaign', '916382125646', '916382125646', 'Success', 'Y', '2024-02-26 14:35:35', NULL, NULL),
(941, 1, 104, 'cron_campaign', '919751682128', '919751682128', 'Success', 'Y', '2024-02-26 14:35:35', NULL, NULL),
(942, 1, 104, 'cron_campaign', '918508022264', '918508022264', 'Success', 'Y', '2024-02-26 14:35:35', NULL, NULL),
(943, 1, 104, 'cron_campaign', '919943161545', '919943161545', 'Success', 'Y', '2024-02-26 14:35:35', NULL, NULL),
(944, 1, 104, 'cron_campaign', '919940900823', '919940900823', 'Success', 'Y', '2024-02-26 14:35:35', NULL, NULL),
(945, 1, 105, 'cron_campaign', '919894606748', '919894606748', 'Success', 'Y', '2024-02-26 14:35:39', NULL, NULL),
(946, 1, 105, 'cron_campaign', '919786448157', '919786448157', 'Success', 'Y', '2024-02-26 14:35:39', NULL, NULL),
(947, 1, 105, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:39', NULL, NULL),
(948, 1, 105, 'cron_campaign', '919361419661', '919361419661', 'Success', 'Y', '2024-02-26 14:35:39', NULL, NULL),
(949, 1, 105, 'cron_campaign', '916380885546', '916380885546', 'Success', 'Y', '2024-02-26 14:35:39', NULL, NULL),
(950, 1, 106, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:40', NULL, NULL),
(951, 1, 106, 'cron_campaign', '916379222191', '916379222191', 'Success', 'Y', '2024-02-26 14:35:40', NULL, NULL),
(952, 1, 106, 'cron_campaign', '918903399027', '918903399027', 'Success', 'Y', '2024-02-26 14:35:41', NULL, NULL),
(953, 1, 106, 'cron_campaign', '918056841132', '918056841132', 'Success', 'Y', '2024-02-26 14:35:41', NULL, NULL),
(954, 1, 106, 'cron_campaign', '919994167977', '919994167977', 'Success', 'Y', '2024-02-26 14:35:41', NULL, NULL),
(955, 1, 107, 'cron_campaign', '918110967610', '918110967610', 'Success', 'Y', '2024-02-26 14:35:41', NULL, NULL),
(956, 1, 107, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:41', NULL, NULL),
(957, 1, 107, 'cron_campaign', '919344027758', '919344027758', 'Success', 'Y', '2024-02-26 14:35:42', NULL, NULL),
(958, 1, 108, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:43', NULL, NULL),
(959, 1, 108, 'cron_campaign', '919786836957', '919786836957', 'Success', 'Y', '2024-02-26 14:35:43', NULL, NULL),
(960, 1, 108, 'cron_campaign', '918220296838', '918220296838', 'Success', 'Y', '2024-02-26 14:35:43', NULL, NULL),
(961, 1, 108, 'cron_campaign', '919092338158', '919092338158', 'Success', 'Y', '2024-02-26 14:35:43', NULL, NULL),
(962, 1, 109, 'cron_campaign', '918110967610', '918110967610', 'Success', 'Y', '2024-02-26 14:35:45', NULL, NULL),
(963, 1, 109, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:45', NULL, NULL),
(964, 1, 109, 'cron_campaign', '918903399027', '918903399027', 'Success', 'Y', '2024-02-26 14:35:45', NULL, NULL),
(965, 1, 109, 'cron_campaign', '918056841132', '918056841132', 'Success', 'Y', '2024-02-26 14:35:45', NULL, NULL),
(966, 1, 110, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:47', NULL, NULL),
(967, 1, 110, 'cron_campaign', '918754626013', '918754626013', 'Success', 'Y', '2024-02-26 14:35:47', NULL, NULL),
(968, 1, 110, 'cron_campaign', '917598142188', '917598142188', 'Success', 'Y', '2024-02-26 14:35:47', NULL, NULL),
(969, 1, 110, 'cron_campaign', '918903399027', '918903399027', 'Success', 'Y', '2024-02-26 14:35:47', NULL, NULL),
(970, 1, 110, 'cron_campaign', '918056841132', '918056841132', 'Success', 'Y', '2024-02-26 14:35:47', NULL, NULL),
(971, 1, 111, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:51', NULL, NULL),
(972, 1, 112, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:54', NULL, NULL),
(973, 1, 112, 'cron_campaign', '919786836957', '919786836957', 'Success', 'Y', '2024-02-26 14:35:54', NULL, NULL),
(974, 1, 112, 'cron_campaign', '916379222191', '916379222191', 'Success', 'Y', '2024-02-26 14:35:54', NULL, NULL),
(975, 1, 112, 'cron_campaign', '918903399027', '918903399027', 'Success', 'Y', '2024-02-26 14:35:54', NULL, NULL),
(976, 1, 112, 'cron_campaign', '918056841132', '918056841132', 'Success', 'Y', '2024-02-26 14:35:54', NULL, NULL),
(977, 1, 113, 'cron_campaign', '919566041612', '919566041612', 'Success', 'Y', '2024-02-26 14:35:55', NULL, NULL),
(978, 1, 113, 'cron_campaign', '916374804148', '916374804148', 'Success', 'Y', '2024-02-26 14:35:55', NULL, NULL),
(979, 1, 113, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 14:35:55', NULL, NULL),
(980, 1, 113, 'cron_campaign', '917868800395', '917868800395', 'Success', 'Y', '2024-02-26 14:35:55', NULL, NULL),
(981, 1, 113, 'cron_campaign', '919786836957', '919786836957', 'Success', 'Y', '2024-02-26 14:35:55', NULL, NULL),
(982, 1, 113, 'cron_campaign', '917598142188', '917598142188', 'Success', 'Y', '2024-02-26 14:35:55', NULL, NULL),
(983, 1, 113, 'cron_campaign', '916379222191', '916379222191', 'Success', 'Y', '2024-02-26 14:35:55', NULL, NULL),
(984, 1, 113, 'cron_campaign', '918903399027', '918903399027', 'Success', 'Y', '2024-02-26 14:35:55', NULL, NULL),
(985, 1, 113, 'cron_campaign', '918220296838', '918220296838', 'Success', 'Y', '2024-02-26 14:35:55', NULL, NULL),
(986, 1, 113, 'cron_campaign', '919092338158', '919092338158', 'Success', 'Y', '2024-02-26 14:35:55', NULL, NULL),
(987, 1, 113, 'cron_campaign', '918056841132', '918056841132', 'Success', 'Y', '2024-02-26 14:35:56', NULL, NULL),
(988, 1, 113, 'cron_campaign', '916380318534', '916380318534', 'Success', 'Y', '2024-02-26 14:35:56', NULL, NULL),
(989, 1, 113, 'cron_campaign', '919789508683', '919789508683', 'Success', 'Y', '2024-02-26 14:35:56', NULL, NULL),
(990, 1, 114, 'cron_campaign', '916382442054', '916382442054', 'Success', 'Y', '2024-02-26 15:23:29', NULL, NULL),
(991, 1, 115, 'cron_campaign', '916385712604', '916385712604', 'Success', 'Y', '2024-02-26 15:23:30', NULL, NULL),
(992, 1, 102, 'cron_campaign', '918919669165', '918919669165', 'Success', 'Y', '2024-02-26 15:23:36', NULL, NULL),
(993, 1, 102, 'cron_campaign', '919363113380', '919363113380', 'Success', 'Y', '2024-02-26 15:23:36', NULL, NULL),
(994, 1, 116, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 15:23:39', NULL, NULL),
(995, 1, 117, 'cron_campaign', '916385712604', '916385712604', 'Success', 'Y', '2024-02-26 15:23:43', NULL, NULL),
(996, 1, 118, 'cron_campaign', '919047692579', '919047692579', 'Success', 'Y', '2024-02-26 15:23:44', NULL, NULL),
(997, 1, 119, 'cron_campaign', '919360474824', '919360474824', 'Success', 'Y', '2024-02-26 15:23:44', NULL, NULL),
(998, 1, 120, 'cron_campaign', '917708497584', '917708497584', 'Success', 'Y', '2024-02-26 15:23:47', NULL, NULL),
(999, 1, 121, 'cron_campaign', '916381395633', '916381395633', 'Success', 'Y', '2024-02-26 15:23:48', NULL, NULL),
(1000, 1, 122, 'cron_campaign', '918637664692', '918637664692', 'Success', 'Y', '2024-02-26 15:23:48', NULL, NULL),
(1001, 1, 123, 'cron_campaign', '919698463227', '919698463227', 'Success', 'Y', '2024-02-26 15:23:52', NULL, NULL),
(1002, 1, 124, 'cron_campaign', '919566041612', '919566041612', 'Success', 'Y', '2024-02-26 15:23:52', NULL, NULL),
(1003, 1, 125, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 15:23:56', NULL, NULL),
(1004, 1, 126, 'cron_campaign', '916381395633', '916381395633', 'Success', 'Y', '2024-02-26 15:24:01', NULL, NULL),
(1005, 1, 127, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 15:24:01', NULL, NULL),
(1006, 1, 128, 'cron_campaign', '919566041612', '919566041612', 'Success', 'Y', '2024-02-26 15:24:02', NULL, NULL),
(1007, 1, 129, 'cron_campaign', '918838964597', '918838964597', 'Success', 'Y', '2024-02-26 15:24:02', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `group_contacts_backup`
--

CREATE TABLE IF NOT EXISTS `group_contacts_backup` (
  `group_contacts_id` int NOT NULL,
  `user_id` int NOT NULL,
  `group_master_id` int NOT NULL,
  `campaign_name` varchar(30) NOT NULL,
  `mobile_no` varchar(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `mobile_id` varchar(30) DEFAULT NULL,
  `comments` varchar(50) NOT NULL,
  `group_contacts_status` char(1) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `group_contacts_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `remove_comments` varchar(50) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT;

--
-- Dumping data for table `group_contacts_backup`
--

INSERT INTO `group_contacts_backup` (`group_contacts_id`, `user_id`, `group_master_id`, `campaign_name`, `mobile_no`, `mobile_id`, `comments`, `group_contacts_status`, `group_contacts_entry_date`, `remove_comments`) VALUES
(4, 2, 2, 'ca_testing_189_4', 'Arun Sir', 'Arun Sir', '', 'Y', '2023-07-08 11:28:29', NULL),
(8, 1, 5, 'ca_test_group_309_8', '919363113380', 'yjtec23_919363113380', '', 'F', '2023-11-05 10:51:43', NULL),
(9, 1, 6, 'ca_test10_group_309_9', 'yjtec23_919363113380', 'yjtec23_919363113380', '', 'Y', '2023-11-05 13:34:43', NULL),
(10, 1, 7, 'ca_sample_grp_309_10', 'yjtec23_919363113380', 'yjtec23_919363113380', '', 'Y', '2023-11-05 13:55:27', NULL),
(11, 1, 7, 'ca_sample_grp_309_11', 'yjtec23_919445603329', 'yjtec23_919445603329', '', 'Y', '2023-11-05 14:29:49', NULL),
(12, 1, 7, 'ca_sample_grp_309_11', 'yjtec23_919445603328', 'yjtec23_919445603328', '', 'Y', '2023-11-05 14:29:49', NULL),
(13, 1, 9, 'ca_hello_group_310_13', '919361419661', '919361419661', '', 'Y', '2023-11-07 14:44:11', NULL),
(14, 1, 9, 'ca_hello_group_310_13', '919363113380', '919363113380', '', 'Y', '2023-11-07 14:44:11', NULL),
(15, 1, 9, 'ca_hello_group_311_15', '919445603329', '919445603329', '', 'Y', '2023-11-07 05:17:43', NULL),
(16, 1, 9, 'ca_hello_group_311_15', '919363113388', '919363113388', '', 'F', '2023-11-07 05:17:43', NULL),
(17, 1, 9, 'ca_hello_group_311_51', '919363113389', '919363113389', '', 'F', '2023-11-07 05:27:13', NULL),
(18, 1, 9, 'ca_hello_group_311_51', '919894606748', '919894606748', '', 'Y', '2023-11-07 05:27:13', NULL),
(19, 1, 9, 'ca_hello_group_311_11', '918838964597', '918838964597', '', 'Y', '2023-11-07 05:40:59', NULL),
(20, 1, 9, 'ca_hello_group_311_11', '917092362325', '917092362325', '', 'F', '2023-11-07 05:40:59', NULL),
(21, 1, 10, 'ca_testing from web_311_111', '918838964597', '918838964597', '', 'Y', '2023-11-07 06:05:57', NULL),
(22, 1, 10, 'ca_testing from web_311_111', '917092362325', '917092362325', '', 'F', '2023-11-07 06:05:58', NULL),
(23, 1, 10, 'ca_testing from web_311_1111', '919361419661', '919361419661', '', 'Y', '2023-11-07 10:26:40', NULL),
(24, 1, 10, 'ca_testing from web_311_1111', '918838964597', '918838964597', '', 'Y', '2023-11-07 10:26:40', NULL),
(25, 1, 10, 'ca_testing from web_311_11111', '919363113380', '919363113380', 'Success', 'Y', '2023-11-07 13:06:00', NULL),
(26, 1, 10, 'ca_testing from web_311_11111', '918838964597', '918838964597', 'Mobile number already in the group', 'F', '2023-11-07 13:06:00', NULL),
(27, 1, 11, 'ca_Test_311_12', '918838964597', '918838964597', 'Success', 'Y', '2023-11-07 14:45:33', NULL),
(28, 1, 11, 'ca_Test_311_12', '919344145033', '919344145033', 'Success', 'Y', '2023-11-07 14:45:34', NULL),
(29, 1, 11, 'ca_Test_311_13', '916380885546', '916380885546', 'Success', 'Y', '2023-11-07 14:53:45', NULL),
(30, 1, 11, 'ca_Test_311_14', '919894850704', '919894850704', 'Success', 'Y', '2023-11-08 14:56:54', NULL),
(31, 2, 12, 'ca_testing_315_15', '919344145033', '919344145033', 'Success', 'Y', '2023-11-11 06:35:12', NULL),
(32, 2, 12, 'ca_testing_315_16', '918838964597', '918838964597', 'Success', 'Y', '2023-11-11 06:37:23', NULL),
(33, 2, 12, 'ca_testing_315_17', '916380747454', '916380747454', 'Success', 'Y', '2023-11-11 06:48:15', NULL),
(34, 2, 12, 'ca_testing_315_18', '919361419661', '919361419661', 'Success', 'Y', '2023-11-11 06:56:47', NULL),
(35, 2, 12, 'ca_testing_315_18', '919344145033', '919344145033', 'Mobile number already in the group', 'F', '2023-11-11 06:56:47', NULL),
(36, 2, 13, 'ca_checking_315_19', '919344145033', '919344145033', 'Success', 'Y', '2023-11-11 07:53:06', NULL),
(39, 1, 15, 'ca_Testing Group_012_22', '919965014814', '919965014814', 'Success', 'Y', '2024-01-12 05:49:22', NULL),
(40, 1, 16, 'ca_Demo_013_23', '916380885546', '916380885546', 'Success', 'R', '2024-01-13 05:16:10', 'Testing'),
(41, 1, 16, 'ca_Demo_013_24', '919361419661', '919361419661', 'Success', 'R', '2024-01-13 05:17:30', 'Testing'),
(42, 1, 16, 'ca_Demo_017_25', '919965014814', '919965014814', 'Success', 'R', '2024-01-17 09:16:10', 'Testing'),
(43, 1, 16, 'ca_Demo_017_26', '916380885546', '916380885546', 'Success', 'Y', '2024-01-17 09:45:00', NULL),
(44, 1, 16, 'ca_Demo_017_27', '919361419661', '919361419661', 'Success', 'Y', '2024-01-17 09:46:39', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `group_master`
--

CREATE TABLE IF NOT EXISTS `group_master` (
  `group_master_id` int NOT NULL,
  `user_id` int NOT NULL,
  `sender_master_id` int NOT NULL,
  `group_name` varchar(250) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `total_count` int NOT NULL,
  `success_count` int DEFAULT NULL,
  `failure_count` int DEFAULT NULL,
  `is_created_by_api` char(1) NOT NULL,
  `group_master_status` char(1) NOT NULL,
  `group_master_entdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `group_updated_date` timestamp NULL DEFAULT NULL,
  `group_link` varchar(200) DEFAULT NULL,
  `group_qrcode` varchar(500) DEFAULT NULL,
  `admin_count` int DEFAULT NULL,
  `members_count` int DEFAULT NULL,
  `is_admin_only_msg` char(1) NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT;

--
-- Dumping data for table `group_master`
--

INSERT INTO `group_master` (`group_master_id`, `user_id`, `sender_master_id`, `group_name`, `total_count`, `success_count`, `failure_count`, `is_created_by_api`, `group_master_status`, `group_master_entdate`, `group_updated_date`, `group_link`, `group_qrcode`, `admin_count`, `members_count`, `is_admin_only_msg`) VALUES
(1, 1, 1, 'TESTING', 4, 4, 0, 'Y', 'Y', '2024-01-23 02:32:57', '2024-02-26 06:20:19', 'https://chat.whatsapp.com/Dv2ZnRdzMfG5PiEw5raEfn', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/TESTING.png', 1, 5, 'N'),
(2, 1, 7, 'Test', 1, 1, 0, 'Y', 'Y', '2024-02-22 05:42:52', '2024-02-22 09:15:24', 'https://chat.whatsapp.com/KLpriZ6qeu4FAg0w7B80R4', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Test.png', 1, 1, 'N'),
(8, 1, 12, 'Test3 को', 2, 3, 0, 'Y', 'Y', '2024-02-22 07:54:29', '2024-02-22 07:48:32', 'https://chat.whatsapp.com/DKZbFb96oDPJDRZNfmM1Bm', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Test3 को.png', 1, 3, 'N'),
(9, 1, 12, 'Test', 1, 2, 0, 'Y', 'Y', '2024-02-22 07:06:15', '2024-02-22 09:15:24', 'https://chat.whatsapp.com/DDGSxh9fhkwInIIGD11ap9', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Test.png', 1, 2, 'N'),
(10, 1, 12, 'Cmpgn 5', 8, 9, 0, 'Y', 'Y', '2023-11-23 10:41:57', '2024-02-24 07:04:05', 'https://chat.whatsapp.com/Hbu1RcszYIsGgmtAdLYlWs', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Cmpgn 5.png', 1, 9, 'N'),
(11, 1, 12, 'Test cron', 3, 3, 0, 'Y', 'Y', '2024-02-22 09:26:43', '2024-02-26 06:50:21', 'https://chat.whatsapp.com/Gth4Xyaf9B296BOROhxvmD', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Test cron.png', 1, 3, 'N'),
(12, 1, 12, 'Test grp 5', 3, 4, 0, 'Y', 'Y', '2024-02-22 10:49:39', '2024-02-24 07:50:20', 'https://chat.whatsapp.com/FNtBUy5na5dGVX85LafIoS', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Test grp 5.png', 1, 4, 'N'),
(13, 1, 12, 'Test 2', 1, 2, 0, 'Y', 'Y', '2024-02-22 07:05:18', '2024-02-22 11:00:19', 'https://chat.whatsapp.com/JyNm92rHfCfKjMnQFuKpUP', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Test 2.png', 1, 2, 'N'),
(14, 1, 13, 'TESTING', 4, 5, 0, 'Y', 'Y', '2024-02-15 07:28:19', '2024-02-26 06:20:19', 'https://chat.whatsapp.com/Dv2ZnRdzMfG5PiEw5raEfn', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/TESTING.png', 1, 5, 'N'),
(15, 1, 15, 'DES', 1, 1, 0, 'Y', 'Y', '2024-02-22 10:48:58', '2024-02-22 11:36:36', 'https://chat.whatsapp.com/FpvPduP1xHb4hTxT6vhhMu', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/DES.png', 1, 1, 'N'),
(16, 1, 15, 'Amadalavalasa-బాబు తో నేను', 96, 96, 0, 'Y', 'Y', '2024-02-22 11:22:59', '2024-02-22 11:36:36', 'https://chat.whatsapp.com/BMNcIjaaNwiDuS9DNIhz6R', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Amadalavalasa-బాబు తో నేను.png', 1, 96, 'N'),
(17, 1, 15, 'Narasannapeta-బాబు తో నేను', 78, 78, 0, 'Y', 'Y', '2024-02-22 11:08:04', '2024-02-22 11:36:49', 'https://chat.whatsapp.com/IPIfZZEajyrILt6ORGzkO4', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Narasannapeta-బాబు తో నేను.png', 1, 78, 'N'),
(18, 1, 15, 'Tekkali-బాబు తో నేను', 76, 76, 0, 'Y', 'Y', '2024-02-22 10:49:25', '2024-02-22 11:36:57', 'https://chat.whatsapp.com/L0v7ATYP8MWGekmMtykaFU', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Tekkali-బాబు తో నేను.png', 1, 76, 'N'),
(19, 1, 15, 'Etcherla-బాబు తో నేను', 6, 6, 0, 'Y', 'Y', '2024-02-22 10:49:25', '2024-02-22 11:37:05', 'https://chat.whatsapp.com/F5CITTBn2H9LkgjuOceOEy', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Etcherla-బాబు తో నేను.png', 1, 6, 'N'),
(20, 1, 15, 'Gajuwaka-బాబు తో నేను', 5, 5, 0, 'Y', 'Y', '2024-02-22 10:49:25', '2024-02-22 11:37:05', 'https://chat.whatsapp.com/FhNIfSufFdl2e4a6UYoXyO', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Gajuwaka-బాబు తో నేను.png', 1, 5, 'N'),
(21, 1, 15, 'Madugula-బాబు తో నేను', 10, 10, 0, 'Y', 'Y', '2024-02-22 10:49:25', '2024-02-22 11:37:06', 'https://chat.whatsapp.com/D390vEriRdU0RiAsFtFfYy', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Madugula-బాబు తో నేను.png', 1, 10, 'N'),
(22, 1, 15, 'Anakapalli-బాబు తో నేను', 9, 9, 0, 'Y', 'Y', '2024-02-22 10:49:24', '2024-02-22 11:37:08', 'https://chat.whatsapp.com/C0eJgySkxCWF3CVA6ZPKVj', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Anakapalli-బాబు తో నేను.png', 1, 9, 'N'),
(23, 1, 15, 'Pendurthi-బాబు తో నేను', 22, 22, 0, 'Y', 'Y', '2024-02-22 10:49:24', '2024-02-22 11:37:09', 'https://chat.whatsapp.com/DFNGXCfvzaeH4oPdokBHis', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Pendurthi-బాబు తో నేను.png', 1, 22, 'N'),
(24, 1, 15, 'Nellimarla-బాబు తో నేను', 22, 22, 0, 'Y', 'Y', '2024-02-22 10:49:24', '2024-02-22 11:37:14', 'https://chat.whatsapp.com/FyGeoU9C5Aj4BUct03IC0g', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Nellimarla-బాబు తో నేను.png', 1, 22, 'N'),
(25, 1, 15, 'Srikakulam-బాబు తో నేను', 14, 14, 0, 'Y', 'Y', '2024-02-22 10:49:24', '2024-02-22 11:37:18', 'https://chat.whatsapp.com/CxtPuJWSNaw3gCS53JrkPf', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Srikakulam-బాబు తో నేను.png', 1, 14, 'N'),
(26, 1, 15, 'Ichapuram-బాబు తో నేను', 66, 66, 0, 'Y', 'Y', '2024-02-22 10:49:23', '2024-02-22 11:37:20', 'https://chat.whatsapp.com/Bd9Wejt7xt9AOQ0W2gx1cP', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Ichapuram-బాబు తో నేను.png', 1, 66, 'N'),
(27, 1, 15, 'Bhimili-బాబు తో నేను', 23, 23, 0, 'Y', 'Y', '2024-02-22 10:49:23', '2024-02-22 11:37:30', 'https://chat.whatsapp.com/KCGGGQwcjNOLYh3JbPMSnv', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Bhimili-బాబు తో నేను.png', 1, 23, 'N'),
(28, 1, 15, 'Palasa-బాబు తో నేను', 52, 52, 0, 'Y', 'Y', '2024-02-22 10:49:23', '2024-02-22 11:37:32', 'https://chat.whatsapp.com/GTSPK63TTc1DGjl9ukdBzK', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Palasa-బాబు తో నేను.png', 1, 52, 'N'),
(29, 1, 15, 'Visakhapatnam South-బాబు తో నేను', 3, 3, 0, 'Y', 'Y', '2024-02-22 10:49:23', '2024-02-22 11:37:38', 'https://chat.whatsapp.com/Fod5m3XwbNI49siFWZ5Vbv', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Visakhapatnam South-బాబు తో నేను.png', 1, 3, 'N'),
(30, 1, 15, 'Chodavaram-బాబు తో నేను', 21, 21, 0, 'Y', 'Y', '2024-02-22 10:49:23', '2024-02-22 11:37:39', 'https://chat.whatsapp.com/Dxnwa08TVGGI4FSZ1BMYWT', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Chodavaram-బాబు తో నేను.png', 1, 21, 'N'),
(31, 1, 15, 'Araku Valley-బాబు తో నేను', 3, 3, 0, 'Y', 'Y', '2024-02-22 10:49:21', '2024-02-22 11:37:43', 'https://chat.whatsapp.com/CgbVcgT5ova2HWKnGQW5II', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Araku Valley-బాబు తో నేను.png', 1, 3, 'N'),
(32, 1, 15, 'Parvathipuram-బాబు తో నేను', 4, 4, 0, 'Y', 'Y', '2024-02-22 10:49:21', '2024-02-22 11:37:44', 'https://chat.whatsapp.com/IDZujFqOE909VyqLf4KQcP', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Parvathipuram-బాబు తో నేను.png', 1, 4, 'N'),
(33, 1, 15, 'Kurupam-బాబు తో నేను', 14, 14, 0, 'Y', 'Y', '2024-02-22 10:49:21', '2024-02-22 11:37:45', 'https://chat.whatsapp.com/GzgHWsieTkw7KXmrJJqATW', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Kurupam-బాబు తో నేను.png', 1, 14, 'N'),
(34, 1, 15, 'Payakaraopeta-బాబు తో నేను', 3, 3, 0, 'Y', 'Y', '2024-02-22 10:49:21', '2024-02-22 11:37:47', 'https://chat.whatsapp.com/CPWglMZQdnM5spMAkorRKU', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Payakaraopeta-బాబు తో నేను.png', 1, 3, 'N'),
(35, 1, 15, 'Narsipatnam-బాబు తో నేను', 10, 10, 0, 'Y', 'Y', '2024-02-22 10:49:21', '2024-02-22 11:37:48', 'https://chat.whatsapp.com/IbuFGvHvZHW8f4A0B7keff', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Narsipatnam-బాబు తో నేను.png', 1, 10, 'N'),
(36, 1, 15, 'Rajam-బాబు తో నేను', 4, 4, 0, 'Y', 'Y', '2024-02-22 10:49:19', '2024-02-22 11:37:49', 'https://chat.whatsapp.com/FUy4pyVQH3PICfp2UsV0lz', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Rajam-బాబు తో నేను.png', 1, 4, 'N'),
(37, 1, 15, 'Paderu-బాబు తో నేను', 3, 3, 0, 'Y', 'Y', '2024-02-22 10:49:19', '2024-02-22 11:37:50', 'https://chat.whatsapp.com/GLKp6OiTpQr6sje8RMOJ2q', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Paderu-బాబు తో నేను.png', 1, 3, 'N'),
(38, 1, 15, 'Rampachodavaram-బాబు తో నేను', 4, 4, 0, 'Y', 'Y', '2024-02-22 10:49:19', '2024-02-22 11:37:50', 'https://chat.whatsapp.com/G9sq6LNy0wEGb5FdCb2Kol', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Rampachodavaram-బాబు తో నేను.png', 1, 4, 'N'),
(39, 1, 15, 'Srungavarapukota-బాబు తో నేను', 8, 8, 0, 'Y', 'Y', '2024-02-22 10:49:19', '2024-02-22 11:37:51', 'https://chat.whatsapp.com/H1dnW8qwhqwF9M94w7Ihrj', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Srungavarapukota-బాబు తో నేను.png', 1, 8, 'N'),
(40, 1, 15, 'Elamanchili-బాబు తో నేను', 3, 3, 0, 'Y', 'Y', '2024-02-22 10:49:19', '2024-02-22 11:37:52', 'https://chat.whatsapp.com/DgJnjdZXaAT9wdU8Op19mU', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Elamanchili-బాబు తో నేను.png', 1, 3, 'N'),
(41, 1, 15, 'Palakonda-బాబు తో నేను', 4, 4, 0, 'Y', 'Y', '2024-02-22 10:49:17', '2024-02-22 11:37:53', 'https://chat.whatsapp.com/FhnwXbWg6nI65ZoC1TqiVV', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Palakonda-బాబు తో నేను.png', 1, 4, 'N'),
(42, 1, 15, 'Salur-బాబు తో నేను', 4, 4, 0, 'Y', 'Y', '2024-02-22 10:49:17', '2024-02-22 11:37:53', 'https://chat.whatsapp.com/GUTQhMIT7J4Hseut0SrgH1', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Salur-బాబు తో నేను.png', 1, 4, 'N'),
(43, 1, 15, 'Visakhapatnam West-బాబు తో నేను', 7, 7, 0, 'Y', 'Y', '2024-02-22 10:49:17', '2024-02-22 11:37:54', 'https://chat.whatsapp.com/DSwr4RHIIoD4eB9SUxEIik', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Visakhapatnam West-బాబు తో నేను.png', 1, 7, 'N'),
(44, 1, 15, 'బాబు తో నేను', 5, 5, 0, 'Y', 'Y', '2024-02-22 10:49:17', '2024-02-22 11:37:55', 'https://chat.whatsapp.com/GsWWB0ZKdixDilcIXCvaPG', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/బాబు తో నేను.png', 1, 5, 'N'),
(45, 1, 15, 'Vizianagaram-బాబు తో నేను', 4, 4, 0, 'Y', 'Y', '2024-02-22 10:49:17', '2024-02-22 11:37:56', 'https://chat.whatsapp.com/JJagu1xaMq70Yp24GVaPTC', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Vizianagaram-బాబు తో నేను.png', 1, 4, 'N'),
(46, 1, 15, 'Visakhapatnam East-బాబు తో నేను', 4, 4, 0, 'Y', 'Y', '2024-02-22 10:49:15', '2024-02-22 11:37:57', 'https://chat.whatsapp.com/Kqx24wC0UA7GsDEiBFoFfr', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Visakhapatnam East-బాబు తో నేను.png', 1, 4, 'N'),
(47, 1, 15, 'Visakhapatnam North-బాబు తో నేను', 3, 3, 0, 'Y', 'Y', '2024-02-22 10:49:15', '2024-02-22 11:37:58', 'https://chat.whatsapp.com/LnOCMalXjryFUwyMCI1og8', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Visakhapatnam North-బాబు తో నేను.png', 1, 3, 'N'),
(48, 1, 15, 'Bobbili-బాబు తో నేను', 8, 8, 0, 'Y', 'Y', '2024-02-22 10:49:15', '2024-02-22 11:37:59', 'https://chat.whatsapp.com/FkbRfagOHWWIXkkwkLDk4u', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Bobbili-బాబు తో నేను.png', 1, 8, 'N'),
(49, 1, 15, 'Gajapathinagaram-బాబు తో నేను', 3, 3, 0, 'Y', 'Y', '2024-02-22 10:49:15', '2024-02-22 11:38:00', 'https://chat.whatsapp.com/JHVvhaNSnh0AHYPEm59inA', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Gajapathinagaram-బాబు తో నేను.png', 1, 3, 'N'),
(50, 1, 15, 'Pathapatnam-బాబు తో నేను', 120, 120, 0, 'Y', 'Y', '2024-02-22 10:49:15', '2024-02-22 11:38:00', 'https://chat.whatsapp.com/IKzphDXLJZzG0NwdrUAzhl', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Pathapatnam-బాబు తో నేను.png', 1, 120, 'N'),
(51, 1, 1, 'Whatsapp Group', 6, 7, 0, 'Y', 'Y', '2024-02-15 04:45:23', '2024-02-26 07:00:40', 'https://chat.whatsapp.com/DPGRxXLZnJtHW4rr2Gs99Z', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Whatsapp Group.png', 1, 7, 'N'),
(52, 1, 1, 'New Group1', 1, 2, 0, 'Y', 'Y', '2024-02-14 12:43:37', '2024-02-26 07:00:40', 'https://chat.whatsapp.com/DMU65FEoqToJkEecehHSVA', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/New Group1.png', 1, 2, 'N'),
(53, 1, 1, 'Demo whatsapp', 2, 3, 0, 'Y', 'Y', '2024-02-14 11:16:06', '2024-02-26 07:00:40', 'https://chat.whatsapp.com/EXRw4MkKuksGr9xIsQjhsx', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Demo whatsapp.png', 1, 3, 'N'),
(54, 1, 1, 'Demo Group1', 1, 2, 0, 'Y', 'Y', '2024-02-14 10:52:47', '2024-02-26 07:00:40', 'https://chat.whatsapp.com/JcNNyRlS2DqEZTekXthQQG', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Demo Group1.png', 1, 2, 'N'),
(55, 1, 1, 'Client 1', 1, 2, 0, 'Y', 'Y', '2024-02-14 10:46:00', '2024-02-26 07:00:40', 'https://chat.whatsapp.com/FlQ6epyTj3BBlkQEanU8vP', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Client 1.png', 1, 2, 'N'),
(56, 1, 1, 'Client', 1, 2, 0, 'Y', 'Y', '2024-02-14 10:41:54', '2024-02-26 07:00:40', 'https://chat.whatsapp.com/LCOAUbYe3f03GnveIeHKHW', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Client.png', 1, 2, 'N'),
(57, 1, 1, 'TESTING 1', 2, 2, 0, 'Y', 'Y', '2024-02-14 10:36:11', '2024-02-26 05:26:07', 'https://chat.whatsapp.com/KsdEykCK1iM7xhVJz76wBP', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/TESTING 1.png', 1, 2, 'N'),
(58, 1, 1, 'Contact', 2, 2, 0, 'Y', 'Y', '2024-02-14 10:29:02', '2024-02-26 05:26:08', 'https://chat.whatsapp.com/H9dz5eHIIqiB53NtFwoT2u', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Contact.png', 1, 2, 'N'),
(59, 1, 1, 'YEEJAI', 6, 7, 0, 'Y', 'Y', '2024-02-09 05:57:55', '2024-02-26 07:00:40', 'https://chat.whatsapp.com/Dh7gPIUaCfMHhoAyoRU1lR', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/YEEJAI.png', 1, 7, 'N'),
(60, 1, 1, 'final', 2, 2, 0, 'Y', 'Y', '2024-02-08 13:15:11', '2024-02-26 05:26:09', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2, 'N'),
(61, 1, 1, 'EX', 2, 2, 0, 'Y', 'Y', '2024-02-08 13:08:29', '2024-02-26 05:26:10', 'https://chat.whatsapp.com/Lc69qJjJhIHEnYou9R6l8a', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/EX.png', 1, 2, 'N'),
(62, 1, 1, 'diaplay', 2, 2, 0, 'Y', 'Y', '2024-02-08 13:00:13', '2024-02-26 05:26:10', 'https://chat.whatsapp.com/Gfpl125EUsOIQMggs991Cl', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/diaplay.png', 1, 2, 'N'),
(63, 1, 1, 'Multiple', 2, 2, 0, 'Y', 'Y', '2024-02-08 12:56:50', '2024-02-26 05:26:11', 'https://chat.whatsapp.com/Do1Z5xnaq0pAQvvw6Z33D0', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Multiple.png', 1, 2, 'N'),
(64, 1, 1, 'YJt', 2, 2, 0, 'Y', 'Y', '2024-02-08 12:52:27', '2024-02-26 05:26:12', 'https://chat.whatsapp.com/E1JYHlXhjx4DFurkGy3cPL', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/YJt.png', 1, 2, 'N'),
(65, 1, 1, 'Feb 8', 2, 2, 0, 'Y', 'Y', '2024-02-08 12:47:05', '2024-02-26 05:26:13', 'https://chat.whatsapp.com/F6hC229tEj7I9S12jDEXJA', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Feb 8.png', 1, 2, 'N'),
(66, 1, 1, 'SAGA', 2, 2, 0, 'Y', 'Y', '2024-02-08 12:15:42', '2024-02-26 05:26:13', 'https://chat.whatsapp.com/KAO88A1cHwBCjuIVWIZyBl', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/SAGA.png', 1, 2, 'N'),
(67, 1, 1, 'list', 2, 2, 0, 'Y', 'Y', '2024-02-08 12:02:39', '2024-02-26 05:26:15', 'https://chat.whatsapp.com/HKnhPn2ap63EHPJ6TKMTBu', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/list.png', 1, 2, 'N'),
(68, 1, 1, 'Nano', 2, 2, 0, 'Y', 'Y', '2024-02-08 11:45:05', '2024-02-26 05:26:15', 'https://chat.whatsapp.com/DgXlOKOfb375GuMUEzfGHM', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Nano.png', 1, 2, 'N'),
(69, 1, 1, 'VISIT', 2, 2, 0, 'Y', 'Y', '2024-02-08 11:41:19', '2024-02-26 05:26:16', 'https://chat.whatsapp.com/DiukVsNVp7N19LojRn0L53', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/VISIT.png', 1, 2, 'N'),
(70, 1, 1, 'but', 2, 2, 0, 'Y', 'Y', '2024-02-08 11:28:06', '2024-02-26 05:26:16', 'https://chat.whatsapp.com/KfoHPuh2wYiEHCBXfwlLAi', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/but.png', 1, 2, 'N'),
(71, 1, 1, 'welcome', 2, 2, 0, 'Y', 'Y', '2024-02-08 11:23:20', '2024-02-26 05:26:17', 'https://chat.whatsapp.com/F8qkR0ySE8f9MlWTY01cuv', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/welcome.png', 1, 2, 'N'),
(72, 1, 16, 'Whatsapp Group', 6, 7, 0, 'Y', 'Y', '2024-02-15 04:45:23', '2024-02-26 07:00:40', 'https://chat.whatsapp.com/DPGRxXLZnJtHW4rr2Gs99Z', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Whatsapp Group.png', 1, 7, 'N'),
(73, 1, 16, 'New Group1', 1, 2, 0, 'Y', 'Y', '2024-02-14 12:43:37', '2024-02-26 07:00:40', 'https://chat.whatsapp.com/DMU65FEoqToJkEecehHSVA', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/New Group1.png', 1, 2, 'N'),
(74, 1, 16, 'Demo whatsapp', 2, 3, 0, 'Y', 'Y', '2024-02-14 11:16:06', '2024-02-26 07:00:40', 'https://chat.whatsapp.com/EXRw4MkKuksGr9xIsQjhsx', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Demo whatsapp.png', 1, 3, 'N'),
(75, 1, 16, 'Demo Group1', 1, 2, 0, 'Y', 'Y', '2024-02-14 10:52:47', '2024-02-26 07:00:40', 'https://chat.whatsapp.com/JcNNyRlS2DqEZTekXthQQG', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Demo Group1.png', 1, 2, 'N'),
(76, 1, 16, 'Client 1', 1, 2, 0, 'Y', 'Y', '2024-02-14 10:46:00', '2024-02-26 07:00:40', 'https://chat.whatsapp.com/FlQ6epyTj3BBlkQEanU8vP', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Client 1.png', 1, 2, 'N'),
(77, 1, 16, 'Client', 1, 2, 0, 'Y', 'Y', '2024-02-14 10:41:54', '2024-02-26 07:00:40', 'https://chat.whatsapp.com/LCOAUbYe3f03GnveIeHKHW', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Client.png', 1, 2, 'N'),
(78, 1, 16, 'TESTING 1', 2, 2, 0, 'Y', 'Y', '2024-02-14 10:36:11', '2024-02-26 06:52:03', 'https://chat.whatsapp.com/KsdEykCK1iM7xhVJz76wBP', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/TESTING 1.png', 1, 2, 'N'),
(79, 1, 16, 'Contact', 2, 2, 0, 'Y', 'Y', '2024-02-14 10:29:02', '2024-02-26 06:52:04', 'https://chat.whatsapp.com/H9dz5eHIIqiB53NtFwoT2u', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Contact.png', 1, 2, 'N'),
(80, 1, 16, 'YEEJAI', 6, 6, 0, 'Y', 'Y', '2024-02-09 05:57:55', '2024-02-26 07:00:40', 'https://chat.whatsapp.com/Dh7gPIUaCfMHhoAyoRU1lR', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/YEEJAI.png', 1, 6, 'N'),
(81, 1, 16, 'final', 2, 2, 0, 'Y', 'Y', '2024-02-08 13:15:11', '2024-02-26 06:52:06', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2, 'N'),
(82, 1, 16, 'EX', 2, 2, 0, 'Y', 'Y', '2024-02-08 13:08:29', '2024-02-26 06:52:06', 'https://chat.whatsapp.com/Lc69qJjJhIHEnYou9R6l8a', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/EX.png', 1, 2, 'N'),
(83, 1, 16, 'diaplay', 2, 2, 0, 'Y', 'Y', '2024-02-08 13:00:13', '2024-02-26 06:52:07', 'https://chat.whatsapp.com/Gfpl125EUsOIQMggs991Cl', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/diaplay.png', 1, 2, 'N'),
(84, 1, 16, 'Multiple', 2, 2, 0, 'Y', 'Y', '2024-02-08 12:56:50', '2024-02-26 06:52:07', 'https://chat.whatsapp.com/Do1Z5xnaq0pAQvvw6Z33D0', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Multiple.png', 1, 2, 'N'),
(85, 1, 16, 'YJt', 2, 2, 0, 'Y', 'Y', '2024-02-08 12:52:27', '2024-02-26 06:52:08', 'https://chat.whatsapp.com/E1JYHlXhjx4DFurkGy3cPL', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/YJt.png', 1, 2, 'N'),
(86, 1, 16, 'Feb 8', 2, 2, 0, 'Y', 'Y', '2024-02-08 12:47:05', '2024-02-26 06:52:08', 'https://chat.whatsapp.com/F6hC229tEj7I9S12jDEXJA', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Feb 8.png', 1, 2, 'N'),
(87, 1, 16, 'SAGA', 2, 2, 0, 'Y', 'Y', '2024-02-08 12:15:42', '2024-02-26 06:52:09', 'https://chat.whatsapp.com/KAO88A1cHwBCjuIVWIZyBl', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/SAGA.png', 1, 2, 'N'),
(88, 1, 16, 'list', 2, 2, 0, 'Y', 'Y', '2024-02-08 12:02:39', '2024-02-26 06:52:09', 'https://chat.whatsapp.com/HKnhPn2ap63EHPJ6TKMTBu', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/list.png', 1, 2, 'N'),
(89, 1, 16, 'Nano', 2, 2, 0, 'Y', 'Y', '2024-02-08 11:45:05', '2024-02-26 06:52:10', 'https://chat.whatsapp.com/DgXlOKOfb375GuMUEzfGHM', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Nano.png', 1, 2, 'N'),
(90, 1, 16, 'VISIT', 2, 2, 0, 'Y', 'Y', '2024-02-08 11:41:19', '2024-02-26 06:52:10', 'https://chat.whatsapp.com/DiukVsNVp7N19LojRn0L53', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/VISIT.png', 1, 2, 'N'),
(91, 1, 16, 'but', 2, 2, 0, 'Y', 'Y', '2024-02-08 11:28:06', '2024-02-26 06:52:11', 'https://chat.whatsapp.com/KfoHPuh2wYiEHCBXfwlLAi', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/but.png', 1, 2, 'N'),
(92, 1, 16, 'welcome', 2, 2, 0, 'Y', 'Y', '2024-02-08 11:23:20', '2024-02-26 06:52:11', 'https://chat.whatsapp.com/F8qkR0ySE8f9MlWTY01cuv', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/welcome.png', 1, 2, 'N'),
(93, 1, 16, 'sample group', 2, 2, 0, 'Y', 'Y', '2024-02-26 10:26:49', '2024-02-26 14:35:11', 'https://chat.whatsapp.com/L1QbNI1ITjWEhSrppcnjVq', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/sample group.png', 1, 2, 'N'),
(94, 1, 16, 'TEST Group', 2, 2, 0, 'Y', 'Y', '2024-02-08 10:59:38', '2024-02-26 14:35:15', 'https://chat.whatsapp.com/JTkFBRfDVdJEzzXVDzTmJk', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/TEST Group.png', 1, 2, 'N'),
(95, 1, 16, 'Example', 2, 2, 0, 'Y', 'Y', '2024-02-08 10:55:02', '2024-02-26 14:35:15', 'https://chat.whatsapp.com/DrOu9slTYI9JQ267X7tB1S', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Example.png', 1, 2, 'N'),
(96, 1, 16, 'add', 4, 4, 0, 'Y', 'Y', '2024-02-07 08:06:13', '2024-02-26 14:35:18', 'https://chat.whatsapp.com/JCIbFIZMlp6Dhs7FangS90', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/add.png', 1, 4, 'N'),
(97, 1, 16, 'Groups', 3, 3, 0, 'Y', 'Y', '2024-02-07 06:13:54', '2024-02-26 14:35:19', 'https://chat.whatsapp.com/DvZ9wxqVZPREcFi0oP65pu', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Groups.png', 1, 3, 'N'),
(98, 1, 16, 'Demo Group', 2, 2, 0, 'Y', 'Y', '2024-02-06 11:06:22', '2024-02-26 14:35:19', 'https://chat.whatsapp.com/Fu2lyaN140FAou3oO3U7CD', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Demo Group.png', 1, 2, 'N'),
(99, 1, 16, 'TESTING', 5, 5, 0, 'Y', 'Y', '2024-02-05 06:58:04', '2024-02-26 14:35:21', 'https://chat.whatsapp.com/Dv2ZnRdzMfG5PiEw5raEfn', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/TESTING.png', 1, 5, 'N'),
(100, 1, 16, 'Demo', 4, 3, 0, 'Y', 'Y', '2024-02-04 13:05:39', '2024-02-26 14:35:21', 'https://chat.whatsapp.com/HkNMmI4ssRjGbnX9f8lm7P', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Demo.png', 1, 3, 'N'),
(101, 1, 16, 'Testing Group', 2, 9, 0, 'Y', 'Y', '2024-01-12 05:55:52', '2024-02-26 14:35:23', 'https://chat.whatsapp.com/LmL9g7in6t47MzK7shEzc7', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Testing Group.png', 1, 9, 'N'),
(102, 1, 16, 'Test', 3, 3, 0, 'Y', 'Y', '2023-11-07 14:51:11', '2024-02-26 14:35:27', 'https://chat.whatsapp.com/FVQQSIYDSy2Cnrkzx3DspD', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Test.png', 1, 3, 'N'),
(103, 1, 16, 'Beast♥️', 10, 10, 0, 'Y', 'Y', '2023-10-23 15:54:46', '2024-02-26 14:35:29', 'https://chat.whatsapp.com/LPicslroMV048Lsja9tkMm', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Beast♥️.png', 1, 10, 'N'),
(104, 1, 16, 'BFF ❣️', 7, 7, 0, 'Y', 'Y', '2023-08-06 16:38:44', '2024-02-26 14:35:34', 'https://chat.whatsapp.com/KajgErEgxewD28fRESqnm1', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/BFF ❣️.png', 1, 7, 'N'),
(105, 1, 16, 'yj whatsapp', 5, 5, 0, 'Y', 'Y', '2023-01-27 07:34:53', '2024-02-26 14:35:39', 'https://chat.whatsapp.com/GblpohC3Yc69AY6eRsRDs2', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/yj whatsapp.png', 1, 5, 'N'),
(106, 1, 16, '(Chellapandi sir)pullingo', 5, 5, 0, 'Y', 'Y', '2023-01-01 01:34:36', '2024-02-26 14:35:40', 'https://chat.whatsapp.com/Frv4jUpWbUpFM7YaX0QtTm', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/(Chellapandi sir)pullingo.png', 1, 5, 'N'),
(107, 1, 16, 'Angular Project Team', 3, 3, 0, 'Y', 'Y', '2022-10-27 13:32:41', '2024-02-26 14:35:41', 'https://chat.whatsapp.com/F8ijyiFkZmOEZMz6uSCszH', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Angular Project Team.png', 1, 3, 'N'),
(108, 1, 16, 'Lusungaaa ', 4, 4, 0, 'Y', 'Y', '2022-08-23 17:37:16', '2024-02-26 14:35:43', 'https://chat.whatsapp.com/F9fXw8GfxU096PJxR3uXiv', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Lusungaaa .png', 1, 4, 'N'),
(109, 1, 16, 'Project', 4, 4, 0, 'Y', 'Y', '2022-06-27 03:53:00', '2024-02-26 14:35:45', 'https://chat.whatsapp.com/FAPeMlg9J1Y0AJlWTtwZG1', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Project.png', 1, 4, 'N'),
(110, 1, 16, 'Pictures sharing', 5, 5, 0, 'Y', 'Y', '2022-02-14 14:06:30', '2024-02-26 14:35:47', 'https://chat.whatsapp.com/D312uAeemLNAJOXRdjC81w', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Pictures sharing.png', 1, 5, 'N'),
(111, 1, 16, 'Bla bla', 1, 1, 0, 'Y', 'Y', '2021-11-28 03:37:59', '2024-02-26 14:35:51', 'https://chat.whatsapp.com/Gi24OMLxOEtC53Ba5j2daL', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Bla bla.png', 1, 1, 'N'),
(112, 1, 16, 'Oruthadava meet pannalam.', 5, 5, 0, 'Y', 'Y', '2021-07-25 13:08:56', '2024-02-26 14:35:54', 'https://chat.whatsapp.com/ByLzr2H6pC930LeKhbbo3A', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/Oruthadava meet pannalam..png', 1, 5, 'N'),
(113, 1, 16, '✨Prayer Changes Things✨', 13, 13, 0, 'Y', 'Y', '2021-05-13 14:06:36', '2024-02-26 14:35:55', 'https://chat.whatsapp.com/DoD2FxcCPYv3BMvTFhmzT2', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/✨Prayer Changes Things✨.png', 1, 13, 'N'),
(114, 1, 16, '🥰😍🥳🤩12 C ROCKERS 😍🥰🥳🤩', 19, 19, 0, 'Y', 'Y', '2024-02-24 04:46:28', '2024-02-26 15:23:29', 'https://chat.whatsapp.com/JpF6NWAAjFu7lXswkcrKSR', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/2024226_205214.png', 1, 19, 'N'),
(115, 1, 16, '🧚‍♀️Angels of Friendship🧚🏻‍♀️', 4, 4, 0, 'Y', 'Y', '2024-02-18 07:22:05', '2024-02-26 15:23:30', 'https://chat.whatsapp.com/EuXu7cp20vIJgZJgnzUeea', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/2024226_205214.png', 1, 4, 'N'),
(116, 1, 16, '🫂', 2, 2, 0, 'Y', 'Y', '2023-10-05 17:37:44', '2024-02-26 15:23:38', 'https://chat.whatsapp.com/CKjc5toScZN1gfnrhyv56V', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/2024226_205214.png', 1, 2, 'N'),
(117, 1, 16, '✨🩷5 th Reunion- Girls🩷✨', 22, 22, 0, 'Y', 'Y', '2023-06-29 11:25:08', '2024-02-26 15:23:43', 'https://chat.whatsapp.com/BS66QF1xvoSCGAuhEUEkRM', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/2024226_205214.png', 1, 22, 'N'),
(118, 1, 16, '🖥Cs QuEens👸😘🔥...👑😎', 17, 17, 0, 'Y', 'Y', '2023-05-27 14:23:18', '2024-02-26 15:23:43', 'https://chat.whatsapp.com/JxglJgC0S9cKH1M2baPsI7', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/2024226_205214.png', 1, 17, 'N'),
(119, 1, 16, 'VCE✨☄️ PARITHAPANGAL🥴', 6, 6, 0, 'Y', 'Y', '2023-05-19 11:02:36', '2024-02-26 15:23:44', 'https://chat.whatsapp.com/Fl2dpBDl0Ls4CEujOUQ31L', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/2024226_205214.png', 1, 6, 'N'),
(120, 1, 16, 'MADHAN FAN GROUP 🔥', 11, 11, 0, 'Y', 'Y', '2022-10-24 08:13:44', '2024-02-26 15:23:47', 'https://chat.whatsapp.com/Hp6brviBTXaCjjhIR77o9z', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/2024226_205214.png', 1, 11, 'N'),
(121, 1, 16, 'Planning grp 💞 Swetha mrg', 13, 13, 0, 'Y', 'Y', '2022-09-10 04:36:36', '2024-02-26 15:23:48', 'https://chat.whatsapp.com/IcrxQ34pa6d59trJmYJjrw', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/2024226_205214.png', 1, 13, 'N'),
(122, 1, 16, 'Bell city gangs🥳😎✌', 3, 3, 0, 'Y', 'Y', '2022-08-07 11:10:16', '2024-02-26 15:23:48', 'https://chat.whatsapp.com/BrHP4qLp7uM0SmbKtAUehx', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/2024226_205214.png', 1, 3, 'N'),
(123, 1, 16, 'Pullingo... 🤩😝😂', 6, 6, 0, 'Y', 'Y', '2022-01-19 16:13:36', '2024-02-26 15:23:52', 'https://chat.whatsapp.com/FD1czgfFo8XCKcAfbgtN8R', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/2024226_205214.png', 1, 6, 'N'),
(124, 1, 16, 'Function ku Porom🚶‍♀😂😍♥️', 5, 5, 0, 'Y', 'Y', '2022-01-18 08:40:39', '2024-02-26 15:23:52', 'https://chat.whatsapp.com/DvzcYjiL4wU8FlxxR83vln', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/2024226_205214.png', 1, 5, 'N'),
(125, 1, 16, 'Nanbenda🔥', 2, 2, 0, 'Y', 'Y', '2021-08-09 11:06:47', '2024-02-26 15:23:56', 'https://chat.whatsapp.com/JGR4VYQP5FPIE3J02GRQPp', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/2024226_205214.png', 1, 2, 'N'),
(126, 1, 16, 'Suganya Ku bday..💥♥️🥳🤩', 5, 5, 0, 'Y', 'Y', '2020-10-14 01:25:48', '2024-02-26 15:24:01', 'https://chat.whatsapp.com/JqhC2zbHERmH3RbWUTbjn8', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/2024226_205214.png', 1, 5, 'N'),
(127, 1, 16, 'Paithiyangal .......🤣', 2, 2, 0, 'Y', 'Y', '2020-08-13 10:50:14', '2024-02-26 15:24:01', 'https://chat.whatsapp.com/C1RulkAwkhr0B4ZvSyhqrQ', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/2024226_205214.png', 1, 2, 'N'),
(128, 1, 16, 'Happy🥳b day👼🍼 civil don😎❤️', 7, 7, 0, 'Y', 'Y', '2020-07-22 16:58:50', '2024-02-26 15:24:02', 'https://chat.whatsapp.com/C8pGthy1aLJ7rYq5dOUcGm', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/2024226_205214.png', 1, 7, 'N'),
(129, 1, 16, 'HBD MALU CHLM😍😘', 3, 3, 0, 'Y', 'Y', '2020-06-25 03:15:55', '2024-02-26 15:24:02', 'https://chat.whatsapp.com/Gs0Xhw1nG3O6GWep5UiVq9', '/var/www/html/whatsapp_group_newapi/uploads/group_qr/2024226_205214.png', 1, 3, 'N');

-- --------------------------------------------------------

--
-- Table structure for table `group_master_backup`
--

CREATE TABLE IF NOT EXISTS `group_master_backup` (
  `group_master_id` int NOT NULL,
  `user_id` int NOT NULL,
  `sender_master_id` int NOT NULL,
  `group_name` varchar(250) NOT NULL,
  `total_count` int NOT NULL,
  `success_count` int DEFAULT NULL,
  `failure_count` int DEFAULT NULL,
  `is_created_by_api` char(1) NOT NULL,
  `group_master_status` char(1) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `group_master_entdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT;

--
-- Dumping data for table `group_master_backup`
--

INSERT INTO `group_master_backup` (`group_master_id`, `user_id`, `sender_master_id`, `group_name`, `total_count`, `success_count`, `failure_count`, `is_created_by_api`, `group_master_status`, `group_master_entdate`) VALUES
(1, 1, 4, 'YeeJai Technologies', 3, 2, 1, 'Y', 'N', '2023-07-15 06:31:40'),
(2, 2, 10, 'testing', 1, 1, 0, 'Y', 'Y', '2023-07-08 11:27:06'),
(4, 1, 14, 'hello_test', 1, 1, 0, 'Y', 'Y', '2023-11-05 10:41:47'),
(5, 1, 14, 'test_group', 1, 1, 0, 'Y', 'Y', '2023-11-05 10:51:42'),
(6, 1, 14, 'test10_group', 1, 1, 0, 'Y', 'Y', '2023-11-05 13:33:01'),
(7, 1, 14, 'sample_grp', 2, 2, 0, 'Y', 'Y', '2023-11-05 13:55:27'),
(9, 1, 14, 'hello_group', 8, 5, 3, 'Y', 'Y', '2023-11-07 05:17:43'),
(10, 1, 14, 'testing from web', 6, 4, 2, 'N', 'Y', '2023-11-07 06:05:57'),
(11, 1, 17, 'Test', 4, 4, 0, 'Y', 'Y', '2023-11-08 14:45:33'),
(12, 2, 36, 'testing', 5, 4, 1, 'Y', 'Y', '2023-11-11 06:35:12'),
(13, 2, 32, 'checking', 1, 1, 0, 'Y', 'Y', '2023-11-11 07:53:05'),
(14, 1, 42, 'Demo', 2, 2, 0, 'Y', 'Y', '2024-01-12 05:02:23'),
(15, 1, 44, 'Testing Group', 1, 1, 0, 'Y', 'Y', '2024-01-12 05:49:22'),
(16, 1, 50, 'Demo', 2, 2, 0, 'N', 'Y', '2024-01-13 05:16:10');

-- --------------------------------------------------------

--
-- Table structure for table `master_countries`
--

CREATE TABLE IF NOT EXISTS `master_countries` (
  `id` int NOT NULL,
  `shortname` varchar(3) NOT NULL,
  `name` varchar(150) NOT NULL,
  `phonecode` int NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=249 DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `master_countries`
--

INSERT INTO `master_countries` (`id`, `shortname`, `name`, `phonecode`) VALUES
(1, 'AF', 'Afghanistan', 93),
(2, 'AL', 'Albania', 355),
(3, 'DZ', 'Algeria', 213),
(4, 'AS', 'American Samoa', 1684),
(5, 'AD', 'Andorra', 376),
(6, 'AO', 'Angola', 244),
(7, 'AI', 'Anguilla', 1264),
(8, 'AQ', 'Antarctica', 0),
(9, 'AG', 'Antigua And Barbuda', 1268),
(10, 'AR', 'Argentina', 54),
(11, 'AM', 'Armenia', 374),
(12, 'AW', 'Aruba', 297),
(13, 'AU', 'Australia', 61),
(14, 'AT', 'Austria', 43),
(15, 'AZ', 'Azerbaijan', 994),
(16, 'BS', 'Bahamas The', 1242),
(17, 'BH', 'Bahrain', 973),
(18, 'BD', 'Bangladesh', 880),
(19, 'BB', 'Barbados', 1246),
(20, 'BY', 'Belarus', 375),
(21, 'BE', 'Belgium', 32),
(22, 'BZ', 'Belize', 501),
(23, 'BJ', 'Benin', 229),
(24, 'BM', 'Bermuda', 1441),
(25, 'BT', 'Bhutan', 975),
(26, 'BO', 'Bolivia', 591),
(27, 'BA', 'Bosnia and Herzegovina', 387),
(28, 'BW', 'Botswana', 267),
(29, 'BV', 'Bouvet Island', 0),
(30, 'BR', 'Brazil', 55),
(31, 'IO', 'British Indian Ocean Territory', 246),
(32, 'BN', 'Brunei', 673),
(33, 'BG', 'Bulgaria', 359),
(34, 'BF', 'Burkina Faso', 226),
(35, 'BI', 'Burundi', 257),
(36, 'KH', 'Cambodia', 855),
(37, 'CM', 'Cameroon', 237),
(38, 'CA', 'Canada', 1),
(39, 'CV', 'Cape Verde', 238),
(40, 'KY', 'Cayman Islands', 1345),
(41, 'CF', 'Central African Republic', 236),
(42, 'TD', 'Chad', 235),
(43, 'CL', 'Chile', 56),
(44, 'CN', 'China', 86),
(45, 'CX', 'Christmas Island', 61),
(46, 'CC', 'Cocos (Keeling) Islands', 672),
(47, 'CO', 'Colombia', 57),
(48, 'KM', 'Comoros', 269),
(49, 'CG', 'Republic Of The Congo', 242),
(50, 'CD', 'Democratic Republic Of The Congo', 242),
(51, 'CK', 'Cook Islands', 682),
(52, 'CR', 'Costa Rica', 506),
(53, 'CI', 'Cote D''Ivoire (Ivory Coast)', 225),
(54, 'HR', 'Croatia (Hrvatska)', 385),
(55, 'CU', 'Cuba', 53),
(56, 'CY', 'Cyprus', 357),
(57, 'CZ', 'Czech Republic', 420),
(58, 'DK', 'Denmark', 45),
(59, 'DJ', 'Djibouti', 253),
(60, 'DM', 'Dominica', 1767),
(61, 'DO', 'Dominican Republic', 1809),
(62, 'TP', 'East Timor', 670),
(63, 'EC', 'Ecuador', 593),
(64, 'EG', 'Egypt', 20),
(65, 'SV', 'El Salvador', 503),
(66, 'GQ', 'Equatorial Guinea', 240),
(67, 'ER', 'Eritrea', 291),
(68, 'EE', 'Estonia', 372),
(69, 'ET', 'Ethiopia', 251),
(70, 'XA', 'External Territories of Australia', 61),
(71, 'FK', 'Falkland Islands', 500),
(72, 'FO', 'Faroe Islands', 298),
(73, 'FJ', 'Fiji Islands', 679),
(74, 'FI', 'Finland', 358),
(75, 'FR', 'France', 33),
(76, 'GF', 'French Guiana', 594),
(77, 'PF', 'French Polynesia', 689),
(78, 'TF', 'French Southern Territories', 0),
(79, 'GA', 'Gabon', 241),
(80, 'GM', 'Gambia The', 220),
(81, 'GE', 'Georgia', 995),
(82, 'DE', 'Germany', 49),
(83, 'GH', 'Ghana', 233),
(84, 'GI', 'Gibraltar', 350),
(85, 'GR', 'Greece', 30),
(86, 'GL', 'Greenland', 299),
(87, 'GD', 'Grenada', 1473),
(88, 'GP', 'Guadeloupe', 590),
(89, 'GU', 'Guam', 1671),
(90, 'GT', 'Guatemala', 502),
(91, 'XU', 'Guernsey and Alderney', 44),
(92, 'GN', 'Guinea', 224),
(93, 'GW', 'Guinea-Bissau', 245),
(94, 'GY', 'Guyana', 592),
(95, 'HT', 'Haiti', 509),
(96, 'HM', 'Heard and McDonald Islands', 0),
(97, 'HN', 'Honduras', 504),
(98, 'HK', 'Hong Kong S.A.R.', 852),
(99, 'HU', 'Hungary', 36),
(100, 'IS', 'Iceland', 354),
(101, 'IN', 'India', 91),
(102, 'ID', 'Indonesia', 62),
(103, 'IR', 'Iran', 98),
(104, 'IQ', 'Iraq', 964),
(105, 'IE', 'Ireland', 353),
(106, 'IL', 'Israel', 972),
(107, 'IT', 'Italy', 39),
(108, 'JM', 'Jamaica', 1876),
(109, 'JP', 'Japan', 81),
(110, 'XJ', 'Jersey', 44),
(111, 'JO', 'Jordan', 962),
(112, 'KZ', 'Kazakhstan', 7),
(113, 'KE', 'Kenya', 254),
(114, 'KI', 'Kiribati', 686),
(115, 'KP', 'Korea North', 850),
(116, 'KR', 'Korea South', 82),
(117, 'KW', 'Kuwait', 965),
(118, 'KG', 'Kyrgyzstan', 996),
(119, 'LA', 'Laos', 856),
(120, 'LV', 'Latvia', 371),
(121, 'LB', 'Lebanon', 961),
(122, 'LS', 'Lesotho', 266),
(123, 'LR', 'Liberia', 231),
(124, 'LY', 'Libya', 218),
(125, 'LI', 'Liechtenstein', 423),
(126, 'LT', 'Lithuania', 370),
(127, 'LU', 'Luxembourg', 352),
(128, 'MO', 'Macau S.A.R.', 853),
(129, 'MK', 'Macedonia', 389),
(130, 'MG', 'Madagascar', 261),
(131, 'MW', 'Malawi', 265),
(132, 'MY', 'Malaysia', 60),
(133, 'MV', 'Maldives', 960),
(134, 'ML', 'Mali', 223),
(135, 'MT', 'Malta', 356),
(136, 'XM', 'Man (Isle of)', 44),
(137, 'MH', 'Marshall Islands', 692),
(138, 'MQ', 'Martinique', 596),
(139, 'MR', 'Mauritania', 222),
(140, 'MU', 'Mauritius', 230),
(141, 'YT', 'Mayotte', 269),
(142, 'MX', 'Mexico', 52),
(143, 'FM', 'Micronesia', 691),
(144, 'MD', 'Moldova', 373),
(145, 'MC', 'Monaco', 377),
(146, 'MN', 'Mongolia', 976),
(147, 'MS', 'Montserrat', 1664),
(148, 'MA', 'Morocco', 212),
(149, 'MZ', 'Mozambique', 258),
(150, 'MM', 'Myanmar', 95),
(151, 'NA', 'Namibia', 264),
(152, 'NR', 'Nauru', 674),
(153, 'NP', 'Nepal', 977),
(154, 'AN', 'Netherlands Antilles', 599),
(155, 'NL', 'Netherlands The', 31),
(156, 'NC', 'New Caledonia', 687),
(157, 'NZ', 'New Zealand', 64),
(158, 'NI', 'Nicaragua', 505),
(159, 'NE', 'Niger', 227),
(160, 'NG', 'Nigeria', 234),
(161, 'NU', 'Niue', 683),
(162, 'NF', 'Norfolk Island', 672),
(163, 'MP', 'Northern Mariana Islands', 1670),
(164, 'NO', 'Norway', 47),
(165, 'OM', 'Oman', 968),
(166, 'PK', 'Pakistan', 92),
(167, 'PW', 'Palau', 680),
(168, 'PS', 'Palestinian Territory Occupied', 970),
(169, 'PA', 'Panama', 507),
(170, 'PG', 'Papua new Guinea', 675),
(171, 'PY', 'Paraguay', 595),
(172, 'PE', 'Peru', 51),
(173, 'PH', 'Philippines', 63),
(174, 'PN', 'Pitcairn Island', 0),
(175, 'PL', 'Poland', 48),
(176, 'PT', 'Portugal', 351),
(177, 'PR', 'Puerto Rico', 1787),
(178, 'QA', 'Qatar', 974),
(179, 'RE', 'Reunion', 262),
(180, 'RO', 'Romania', 40),
(181, 'RU', 'Russia', 70),
(182, 'RW', 'Rwanda', 250),
(183, 'SH', 'Saint Helena', 290),
(184, 'KN', 'Saint Kitts And Nevis', 1869),
(185, 'LC', 'Saint Lucia', 1758),
(186, 'PM', 'Saint Pierre and Miquelon', 508),
(187, 'VC', 'Saint Vincent And The Grenadines', 1784),
(188, 'WS', 'Samoa', 684),
(189, 'SM', 'San Marino', 378),
(190, 'ST', 'Sao Tome and Principe', 239),
(191, 'SA', 'Saudi Arabia', 966),
(192, 'SN', 'Senegal', 221),
(193, 'RS', 'Serbia', 381),
(194, 'SC', 'Seychelles', 248),
(195, 'SL', 'Sierra Leone', 232),
(196, 'SG', 'Singapore', 65),
(197, 'SK', 'Slovakia', 421),
(198, 'SI', 'Slovenia', 386),
(199, 'XG', 'Smaller Territories of the UK', 44),
(200, 'SB', 'Solomon Islands', 677),
(201, 'SO', 'Somalia', 252),
(202, 'ZA', 'South Africa', 27),
(203, 'GS', 'South Georgia', 0),
(204, 'SS', 'South Sudan', 211),
(205, 'ES', 'Spain', 34),
(206, 'LK', 'Sri Lanka', 94),
(207, 'SD', 'Sudan', 249),
(208, 'SR', 'Suriname', 597),
(209, 'SJ', 'Svalbard And Jan Mayen Islands', 47),
(210, 'SZ', 'Swaziland', 268),
(211, 'SE', 'Sweden', 46),
(212, 'CH', 'Switzerland', 41),
(213, 'SY', 'Syria', 963),
(214, 'TW', 'Taiwan', 886),
(215, 'TJ', 'Tajikistan', 992),
(216, 'TZ', 'Tanzania', 255),
(217, 'TH', 'Thailand', 66),
(218, 'TG', 'Togo', 228),
(219, 'TK', 'Tokelau', 690),
(220, 'TO', 'Tonga', 676),
(221, 'TT', 'Trinidad And Tobago', 1868),
(222, 'TN', 'Tunisia', 216),
(223, 'TR', 'Turkey', 90),
(224, 'TM', 'Turkmenistan', 7370),
(225, 'TC', 'Turks And Caicos Islands', 1649),
(226, 'TV', 'Tuvalu', 688),
(227, 'UG', 'Uganda', 256),
(228, 'UA', 'Ukraine', 380),
(229, 'AE', 'United Arab Emirates', 971),
(230, 'GB', 'United Kingdom', 44),
(231, 'US', 'United States', 1),
(232, 'UM', 'United States Minor Outlying Islands', 1),
(233, 'UY', 'Uruguay', 598),
(234, 'UZ', 'Uzbekistan', 998),
(235, 'VU', 'Vanuatu', 678),
(236, 'VA', 'Vatican City State (Holy See)', 39),
(237, 'VE', 'Venezuela', 58),
(238, 'VN', 'Vietnam', 84),
(239, 'VG', 'Virgin Islands (British)', 1284),
(240, 'VI', 'Virgin Islands (US)', 1340),
(241, 'WF', 'Wallis And Futuna Islands', 681),
(242, 'EH', 'Western Sahara', 212),
(243, 'YE', 'Yemen', 967),
(244, 'YU', 'Yugoslavia', 38),
(245, 'ZM', 'Zambia', 260),
(246, 'ZW', 'Zimbabwe', 263);

-- --------------------------------------------------------

--
-- Table structure for table `master_language`
--

CREATE TABLE IF NOT EXISTS `master_language` (
  `language_id` int NOT NULL,
  `language_name` varchar(20) NOT NULL,
  `language_code` varchar(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `language_status` char(1) NOT NULL,
  `language_entdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `master_language`
--

INSERT INTO `master_language` (`language_id`, `language_name`, `language_code`, `language_status`, `language_entdate`) VALUES
(1, 'English (US)', 'en_US', 'Y', '2023-03-01 07:54:15'),
(2, 'English (UK)', 'en_GB', 'Y', '2023-03-01 07:54:15'),
(3, 'Hindi', 'hi', 'Y', '2023-03-01 07:54:15'),
(4, 'Kannada', 'kn', 'Y', '2023-03-01 07:54:15'),
(5, 'Malayalam', 'ml', 'Y', '2023-03-01 07:54:15'),
(6, 'Tamil', 'ta', 'Y', '2023-03-01 07:54:15'),
(7, 'Telugu', 'te', 'Y', '2023-03-01 07:54:15'),
(8, 'Urdu', 'ur', 'Y', '2023-03-01 07:54:15'),
(9, 'Indonesian', 'id', 'N', '2023-03-01 22:14:10'),
(10, 'Spanish (ARG)', 'es_AR ', 'N', '2023-03-01 22:14:10'),
(11, 'Spanish', 'es', 'N', '2023-03-01 22:14:10'),
(12, 'Spanish (SPA)', 'es_ES', 'N', '2023-03-01 22:14:10'),
(13, 'Spanish (MEX)', 'es_MX', 'N', '2023-03-01 22:14:10'),
(14, 'Portuguese (BR)', 'pt_BR', 'N', '2023-03-01 22:14:10'),
(15, 'Portuguese (POR)', 'pt_PT', 'N', '2023-03-01 22:14:10');

-- --------------------------------------------------------

--
-- Table structure for table `payment_history_log`
--

CREATE TABLE IF NOT EXISTS `payment_history_log` (
  `payment_history_logid` int NOT NULL,
  `user_id` int NOT NULL,
  `user_plans_id` int NOT NULL,
  `plan_master_id` int NOT NULL,
  `plan_amount` int NOT NULL,
  `payment_status` char(1) NOT NULL,
  `plan_comments` varchar(300) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  `payment_history_logstatus` char(1) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `payment_history_log_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `payment_history_log`
--

INSERT INTO `payment_history_log` (`payment_history_logid`, `user_id`, `user_plans_id`, `plan_master_id`, `plan_amount`, `payment_status`, `plan_comments`, `payment_history_logstatus`, `payment_history_log_date`) VALUES
(1, 1, 1, 2, 300, 'A', 'msg:Payment successfully credited, status:true, productCode:2, paymentID:pay_NNKBH1rGodKSq0, userEmail', 'Y', '2024-01-11 13:31:24');

-- --------------------------------------------------------

--
-- Table structure for table `plans_update`
--

CREATE TABLE IF NOT EXISTS `plans_update` (
  `plans_update_id` int NOT NULL,
  `plan_master_id` int NOT NULL,
  `user_id` int NOT NULL,
  `total_whatsapp_count` int NOT NULL,
  `available_whatsapp_count` int NOT NULL,
  `used_whatsapp_count` int NOT NULL,
  `total_group_count` int NOT NULL,
  `available_group_count` int NOT NULL,
  `used_group_count` int NOT NULL,
  `total_message_limit` int NOT NULL,
  `available_message_limit` int NOT NULL,
  `used_message_limit` int NOT NULL,
  `plan_status` char(1) COLLATE utf8mb4_general_ci NOT NULL,
  `plan_entry_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `plan_expiry_date` datetime DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `plans_update`
--

INSERT INTO `plans_update` (`plans_update_id`, `plan_master_id`, `user_id`, `total_whatsapp_count`, `available_whatsapp_count`, `used_whatsapp_count`, `total_group_count`, `available_group_count`, `used_group_count`, `total_message_limit`, `available_message_limit`, `used_message_limit`, `plan_status`, `plan_entry_date`, `plan_expiry_date`) VALUES
(1, 2, 1, 200, 166, 34, 30, 29, 2, 600, 600, 0, 'Y', '2024-02-26 15:22:45', '2024-02-11 19:01:48');

-- --------------------------------------------------------

--
-- Table structure for table `plan_master`
--

CREATE TABLE IF NOT EXISTS `plan_master` (
  `plan_master_id` int NOT NULL,
  `plan_title` varchar(20) NOT NULL,
  `annual_monthly` char(1) NOT NULL,
  `whatsapp_no_min_count` int NOT NULL,
  `whatsapp_no_max_count` int NOT NULL,
  `group_no_min_count` int NOT NULL,
  `group_no_max_count` int NOT NULL,
  `plan_price` int NOT NULL,
  `message_limit` int DEFAULT NULL,
  `plan_status` char(1) NOT NULL,
  `plan_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `plan_master`
--

INSERT INTO `plan_master` (`plan_master_id`, `plan_title`, `annual_monthly`, `whatsapp_no_min_count`, `whatsapp_no_max_count`, `group_no_min_count`, `group_no_max_count`, `plan_price`, `message_limit`, `plan_status`, `plan_entry_date`) VALUES
(1, 'SILVER', 'M', 0, 100, 0, 20, 100, 500, 'Y', '2023-10-03 00:26:24'),
(2, 'Gold', 'M', 0, 200, 0, 30, 300, 600, 'Y', '2023-10-03 00:26:24'),
(3, 'Platinum', 'M', 0, 300, 0, 50, 500, 800, 'Y', '2023-10-03 00:26:24'),
(4, 'SILVER', 'A', 0, 100, 0, 50, 1100, 1000, 'Y', '2023-10-03 00:26:24'),
(5, 'Gold', 'A', 0, 300, 0, 100, 2100, 3000, 'Y', '2023-10-03 00:26:24');

-- --------------------------------------------------------

--
-- Table structure for table `senderid_master`
--

CREATE TABLE IF NOT EXISTS `senderid_master` (
  `sender_master_id` int NOT NULL,
  `user_id` int NOT NULL,
  `mobile_no` varchar(15) NOT NULL,
  `profile_name` varchar(25) DEFAULT NULL,
  `profile_image` varchar(100) DEFAULT NULL,
  `senderid_master_status` char(1) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `senderid_master_entdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `senderid_master_apprdate` timestamp NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT;

--
-- Dumping data for table `senderid_master`
--

INSERT INTO `senderid_master` (`sender_master_id`, `user_id`, `mobile_no`, `profile_name`, `profile_image`, `senderid_master_status`, `senderid_master_entdate`, `senderid_master_apprdate`) VALUES
(1, 1, '918838964597', 'TEST', 'http://yjtec.in/whatsapp_group_newapi/uploads/whatsapp_images/1_1707114423164.png', 'D', '2024-02-05 06:27:14', '0000-00-00 00:00:00'),
(7, 1, '919025181189', 'YJ', 'http://yjtec.in/whatsapp_group_newapi/uploads/whatsapp_images/1_1708584569187.jpeg', 'X', '2024-02-22 06:49:39', '0000-00-00 00:00:00'),
(12, 1, '916305782559', 'Cmpgn 5', 'http://yjtec.in/whatsapp_group_newapi/uploads/whatsapp_images/1_1708588073228.jpeg', 'X', '2024-02-22 07:48:05', '0000-00-00 00:00:00'),
(13, 1, '917904778285', 'YJ', 'http://yjtec.in/whatsapp_group_newapi/uploads/whatsapp_images/1_1708600210411.jpeg', 'Y', '2024-02-22 11:10:21', '0000-00-00 00:00:00'),
(14, 1, '917842985145', 'Test', 'http://yjtec.in/whatsapp_group_newapi/uploads/whatsapp_images/1_1708601043466.jpeg', 'M', '2024-02-22 11:24:14', '0000-00-00 00:00:00'),
(15, 1, '918121865103', 'Test', 'http://yjtec.in/whatsapp_group_newapi/uploads/whatsapp_images/1_1708601719043.jpeg', 'X', '2024-02-22 11:35:29', '0000-00-00 00:00:00'),
(16, 1, '918838964597', 'test', 'http://yjtec.in/whatsapp_group_newapi/uploads/whatsapp_images/1_1708930175359.png', 'Y', '2024-02-26 06:49:46', '0000-00-00 00:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `summary_report`
--

CREATE TABLE IF NOT EXISTS `summary_report` (
  `summary_report_id` int NOT NULL,
  `user_id` int NOT NULL,
  `campaign_date` date NOT NULL,
  `campaign_count` int NOT NULL,
  `success_count` int DEFAULT NULL,
  `failure_count` int DEFAULT NULL,
  `inprogress_count` int DEFAULT NULL,
  `summary_report_status` char(1) NOT NULL,
  `summary_report_entdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

-- --------------------------------------------------------

--
-- Table structure for table `template_master`
--

CREATE TABLE IF NOT EXISTS `template_master` (
  `template_master_id` int NOT NULL,
  `user_id` int NOT NULL,
  `unique_template_id` varchar(30) NOT NULL,
  `template_name` varchar(50) NOT NULL,
  `language_id` int NOT NULL,
  `template_category` varchar(30) NOT NULL,
  `template_message` longtext NOT NULL,
  `template_status` char(1) NOT NULL,
  `template_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `template_master`
--

INSERT INTO `template_master` (`template_master_id`, `user_id`, `unique_template_id`, `template_name`, `language_id`, `template_category`, `template_message`, `template_status`, `template_entry_date`) VALUES
(1, 1, 'tmplt_Sup_023_001', 'te_Sup_t00000000_24123_001', 2, 'MARKETING', '[{"type":"BODY","text":"TESTING"}]', 'Y', '2024-01-23 07:48:56'),
(2, 1, 'tmplt_Sup_031_002', 'te_Sup_t00000000_24131_002', 1, 'MARKETING', '[{"type":"BODY","text":"JavaScript is the world most popular programming language."}]', 'Y', '2024-01-31 09:42:56'),
(3, 1, 'tmplt_Sup_055_003', 'te_Sup_t00000000_24224_003', 2, 'MARKETING', '[{"type":"BODY","text":"Test *mesasge*"}]', 'Y', '2024-02-24 05:40:05');

-- --------------------------------------------------------

--
-- Table structure for table `user_log`
--

CREATE TABLE IF NOT EXISTS `user_log` (
  `user_log_id` int NOT NULL,
  `user_id` int NOT NULL,
  `ip_address` varchar(50) DEFAULT NULL,
  `login_date` date NOT NULL,
  `login_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `logout_time` timestamp NULL DEFAULT '0000-00-00 00:00:00',
  `user_log_status` char(1) NOT NULL,
  `user_log_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB AUTO_INCREMENT=280 DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `user_log`
--

INSERT INTO `user_log` (`user_log_id`, `user_id`, `ip_address`, `login_date`, `login_time`, `logout_time`, `user_log_status`, `user_log_entry_date`) VALUES
(1, 1, 'undefined', '2023-07-05', '2023-07-05 12:01:14', '2023-07-06 09:06:06', 'O', '2023-07-05 12:01:14'),
(2, 1, 'undefined', '2023-07-06', '2023-07-06 08:57:43', '2023-07-06 09:06:06', 'O', '2023-07-06 08:57:43'),
(3, 1, 'undefined', '2023-07-06', '2023-07-06 09:11:56', '2023-07-06 10:37:24', 'O', '2023-07-06 09:11:56'),
(4, 1, 'undefined', '2023-07-06', '2023-07-06 10:37:24', '2023-07-06 10:45:31', 'O', '2023-07-06 10:37:24'),
(5, 1, 'undefined', '2023-07-06', '2023-07-06 10:45:31', '2023-07-06 10:53:40', 'O', '2023-07-06 10:45:31'),
(6, 1, 'undefined', '2023-07-06', '2023-07-06 10:53:40', '2023-07-06 10:56:28', 'O', '2023-07-06 10:53:40'),
(7, 1, 'undefined', '2023-07-06', '2023-07-06 10:56:28', '2023-07-06 10:57:00', 'O', '2023-07-06 10:56:28'),
(8, 1, 'undefined', '2023-07-06', '2023-07-06 10:57:00', '2023-07-06 10:57:36', 'O', '2023-07-06 10:57:00'),
(9, 1, 'undefined', '2023-07-06', '2023-07-06 10:57:36', '2023-07-06 10:59:22', 'O', '2023-07-06 10:57:36'),
(10, 1, 'undefined', '2023-07-06', '2023-07-06 10:59:22', '2023-07-06 11:00:12', 'O', '2023-07-06 10:59:22'),
(11, 1, 'undefined', '2023-07-06', '2023-07-06 11:00:12', '2023-07-06 11:00:43', 'O', '2023-07-06 11:00:12'),
(12, 1, 'undefined', '2023-07-06', '2023-07-06 11:00:43', '2023-07-06 11:01:21', 'O', '2023-07-06 11:00:43'),
(13, 1, 'undefined', '2023-07-06', '2023-07-06 11:01:21', '2023-07-06 11:01:41', 'O', '2023-07-06 11:01:21'),
(14, 1, 'undefined', '2023-07-06', '2023-07-06 11:01:41', '2023-07-06 11:10:37', 'O', '2023-07-06 11:01:41'),
(15, 1, 'undefined', '2023-07-06', '2023-07-06 11:10:37', '2023-07-06 11:11:01', 'O', '2023-07-06 11:10:37'),
(16, 1, 'undefined', '2023-07-06', '2023-07-06 11:18:11', '2023-07-06 11:19:10', 'O', '2023-07-06 11:18:11'),
(17, 1, 'undefined', '2023-07-06', '2023-07-06 11:19:10', '2023-07-06 11:24:28', 'O', '2023-07-06 11:19:10'),
(18, 1, 'undefined', '2023-07-06', '2023-07-06 11:24:28', '2023-07-06 11:25:48', 'O', '2023-07-06 11:24:28'),
(19, 1, 'undefined', '2023-07-06', '2023-07-06 11:25:48', '2023-07-06 11:33:38', 'O', '2023-07-06 11:25:48'),
(20, 1, 'undefined', '2023-07-06', '2023-07-06 11:33:38', '2023-07-06 11:43:54', 'O', '2023-07-06 11:33:38'),
(21, 1, 'undefined', '2023-07-06', '2023-07-06 11:43:54', '2023-07-06 11:53:46', 'O', '2023-07-06 11:43:54'),
(22, 1, 'undefined', '2023-07-06', '2023-07-06 11:53:46', NULL, 'I', '2023-07-06 11:53:46'),
(23, 1, '59.92.107.49', '2023-07-07', '2023-07-07 04:29:30', NULL, 'I', '2023-07-07 04:29:30'),
(24, 1, '59.92.107.49', '2023-07-08', '2023-07-08 04:15:40', '2023-07-08 04:26:14', 'O', '2023-07-08 04:15:40'),
(25, 1, '59.92.107.49', '2023-07-08', '2023-07-08 04:26:14', '2023-07-08 04:33:00', 'O', '2023-07-08 04:26:14'),
(26, 1, '59.92.107.49', '2023-07-08', '2023-07-08 04:33:00', '2023-07-08 04:33:15', 'O', '2023-07-08 04:33:00'),
(27, 1, '59.92.107.49', '2023-07-08', '2023-07-08 04:33:15', '2023-07-08 10:55:11', 'O', '2023-07-08 04:33:15'),
(28, 2, '59.92.107.49', '2023-07-08', '2023-07-08 04:43:07', '2023-07-08 04:51:34', 'O', '2023-07-08 04:43:07'),
(29, 2, '192.168.1.27', '2023-07-08', '2023-07-08 04:51:34', '2023-07-08 05:03:58', 'O', '2023-07-08 04:51:34'),
(30, 2, '192.168.1.27', '2023-07-08', '2023-07-08 05:03:58', '2023-07-08 07:21:08', 'O', '2023-07-08 05:03:58'),
(31, 2, '192.168.1.27', '2023-07-08', '2023-07-08 07:21:08', '2023-07-08 10:51:28', 'O', '2023-07-08 07:21:08'),
(32, 2, '192.168.1.27', '2023-07-08', '2023-07-08 10:51:28', NULL, 'I', '2023-07-08 10:51:28'),
(33, 1, '192.168.1.27', '2023-07-08', '2023-07-08 10:55:11', '2023-07-08 11:00:10', 'O', '2023-07-08 10:55:11'),
(34, 1, '59.92.107.49', '2023-07-08', '2023-07-08 11:00:10', NULL, 'I', '2023-07-08 11:00:10'),
(35, 1, '59.92.107.49', '2023-07-10', '2023-07-10 04:06:42', NULL, 'I', '2023-07-10 04:06:42'),
(36, 1, 'undefined', '2023-07-14', '2023-07-14 05:04:18', '2023-07-14 06:41:47', 'O', '2023-07-14 05:04:18'),
(37, 1, 'undefined', '2023-07-14', '2023-07-14 06:41:47', '2023-07-14 06:49:46', 'O', '2023-07-14 06:41:47'),
(38, 1, 'undefined', '2023-07-14', '2023-07-14 06:49:46', '2023-07-14 06:51:36', 'O', '2023-07-14 06:49:46'),
(39, 1, 'undefined', '2023-07-14', '2023-07-14 06:51:36', '2023-07-14 06:54:37', 'O', '2023-07-14 06:51:36'),
(40, 1, 'undefined', '2023-07-14', '2023-07-14 06:54:37', '2023-07-14 06:55:47', 'O', '2023-07-14 06:54:37'),
(41, 1, 'undefined', '2023-07-14', '2023-07-14 06:55:47', '2023-07-14 07:00:51', 'O', '2023-07-14 06:55:47'),
(42, 1, 'undefined', '2023-07-14', '2023-07-14 07:00:51', '2023-07-14 07:03:02', 'O', '2023-07-14 07:00:51'),
(43, 1, 'undefined', '2023-07-14', '2023-07-14 07:03:02', NULL, 'I', '2023-07-14 07:03:02'),
(44, 1, '192.168.1.27', '2023-07-15', '2023-07-15 05:15:11', '2023-07-15 05:45:10', 'O', '2023-07-15 05:15:11'),
(45, 1, '59.92.107.49', '2023-07-15', '2023-07-15 05:45:10', '2023-07-15 07:25:35', 'O', '2023-07-15 05:45:10'),
(46, 2, '59.92.107.49', '2023-07-15', '2023-07-15 06:47:18', NULL, 'I', '2023-07-15 06:47:18'),
(47, 1, '192.168.1.27', '2023-07-15', '2023-07-15 07:25:35', NULL, 'I', '2023-07-15 07:25:35'),
(48, 1, '59.92.107.49', '2023-07-21', '2023-07-21 06:07:29', NULL, 'I', '2023-07-21 06:07:29'),
(49, 1, '192.168.1.27', '2023-07-26', '2023-07-26 04:38:36', NULL, 'I', '2023-07-26 04:38:36'),
(50, 2, '192.168.1.27', '2023-07-26', '2023-07-26 04:39:38', '2023-07-26 04:42:26', 'O', '2023-07-26 04:39:38'),
(51, 2, '192.168.1.27', '2023-07-26', '2023-07-26 04:42:26', NULL, 'I', '2023-07-26 04:42:26'),
(52, 1, '49.37.200.249', '2023-08-18', '2023-08-18 09:40:39', NULL, 'I', '2023-08-18 09:40:39'),
(53, 1, '192.168.1.27', '2023-08-21', '2023-08-21 14:01:22', '2023-08-21 14:04:04', 'O', '2023-08-21 14:01:22'),
(54, 1, '192.168.1.27', '2023-08-21', '2023-08-21 14:04:04', NULL, 'I', '2023-08-21 14:04:04'),
(55, 1, '49.37.201.217', '2023-08-24', '2023-08-24 10:09:51', NULL, 'I', '2023-08-24 10:09:51'),
(56, 1, '192.168.1.27', '2023-09-28', '2023-09-28 09:37:05', '2023-09-28 09:39:27', 'O', '2023-09-28 09:37:05'),
(57, 1, '192.168.1.27', '2023-09-28', '2023-09-28 09:39:27', NULL, 'I', '2023-09-28 09:39:27'),
(58, 1, '192.168.1.27', '2023-09-30', '2023-09-30 06:05:12', NULL, 'I', '2023-09-30 06:05:12'),
(59, 1, '192.168.1.27', '2023-10-03', '2023-10-03 07:19:06', '2023-10-03 07:20:53', 'O', '2023-10-03 07:19:06'),
(60, 1, '49.37.200.149', '2023-10-03', '2023-10-03 07:20:53', NULL, 'I', '2023-10-03 07:20:53'),
(61, 1, 'undefined', '2023-10-04', '2023-10-04 13:11:48', '2023-10-04 13:17:14', 'O', '2023-10-04 13:11:48'),
(62, 1, 'undefined', '2023-10-04', '2023-10-04 13:17:14', NULL, 'I', '2023-10-04 13:17:14'),
(63, 1, 'undefined', '2023-10-05', '2023-10-05 04:16:07', '2023-10-05 13:24:27', 'O', '2023-10-05 04:16:07'),
(64, 1, 'undefined', '2023-10-05', '2023-10-05 13:24:27', '2023-10-05 13:28:23', 'O', '2023-10-05 13:24:27'),
(65, 1, 'undefined', '2023-10-05', '2023-10-05 13:28:23', '2023-10-05 13:39:30', 'O', '2023-10-05 13:28:23'),
(66, 1, 'undefined', '2023-10-06', '2023-10-06 04:01:49', '2023-10-06 04:08:00', 'O', '2023-10-06 04:01:49'),
(67, 1, 'undefined', '2023-10-06', '2023-10-06 06:37:34', '2023-10-06 06:37:44', 'O', '2023-10-06 06:37:34'),
(68, 2, 'undefined', '2023-10-06', '2023-10-06 08:50:49', '2023-10-06 09:07:02', 'O', '2023-10-06 08:50:49'),
(69, 2, 'undefined', '2023-10-06', '2023-10-06 09:07:03', '2023-10-06 09:09:55', 'O', '2023-10-06 09:07:03'),
(70, 2, 'undefined', '2023-10-06', '2023-10-06 09:10:07', '2023-10-06 09:30:14', 'O', '2023-10-06 09:10:07'),
(71, 1, 'undefined', '2023-10-06', '2023-10-06 09:19:32', '2023-10-06 15:42:54', 'O', '2023-10-06 09:19:32'),
(72, 2, 'undefined', '2023-10-06', '2023-10-06 09:30:14', '2023-10-06 11:05:05', 'O', '2023-10-06 09:30:14'),
(73, 1, 'undefined', '2023-10-07', '2023-10-07 04:46:33', '2023-10-07 05:33:58', 'O', '2023-10-07 04:46:33'),
(74, 1, 'undefined', '2023-10-07', '2023-10-07 05:33:58', '2023-10-07 05:54:34', 'O', '2023-10-07 05:33:58'),
(75, 1, 'undefined', '2023-10-07', '2023-10-07 05:54:34', '2023-10-07 07:14:37', 'O', '2023-10-07 05:54:34'),
(76, 1, 'undefined', '2023-10-07', '2023-10-07 07:15:40', '2023-10-07 11:11:16', 'O', '2023-10-07 07:15:40'),
(77, 1, 'undefined', '2023-10-07', '2023-10-07 11:11:16', '2023-10-07 11:15:54', 'O', '2023-10-07 11:11:16'),
(78, 1, 'undefined', '2023-10-07', '2023-10-07 11:15:54', '2023-10-07 11:21:31', 'O', '2023-10-07 11:15:54'),
(79, 1, 'undefined', '2023-10-07', '2023-10-07 11:21:32', NULL, 'I', '2023-10-07 11:21:32'),
(80, 1, 'undefined', '2023-10-10', '2023-10-10 10:16:16', '2023-10-10 14:02:23', 'O', '2023-10-10 10:16:16'),
(81, 1, 'undefined', '2023-10-11', '2023-10-11 05:43:28', '2023-10-11 07:54:40', 'O', '2023-10-11 05:43:28'),
(82, 1, 'undefined', '2023-10-11', '2023-10-11 07:55:09', '2023-10-11 14:07:36', 'O', '2023-10-11 07:55:09'),
(83, 1, 'undefined', '2023-10-12', '2023-10-12 04:33:01', '2023-10-12 12:56:33', 'O', '2023-10-12 04:33:01'),
(84, 1, 'undefined', '2023-10-12', '2023-10-12 12:56:33', NULL, 'I', '2023-10-12 12:56:33'),
(85, 1, 'undefined', '2023-10-13', '2023-10-13 11:21:09', '2023-10-13 11:21:45', 'O', '2023-10-13 11:21:09'),
(86, 1, 'undefined', '2023-10-13', '2023-10-13 11:21:45', '2023-10-13 11:22:51', 'O', '2023-10-13 11:21:45'),
(87, 1, 'undefined', '2023-10-13', '2023-10-13 11:22:59', '2023-10-13 11:23:33', 'O', '2023-10-13 11:22:59'),
(88, 1, 'undefined', '2023-10-13', '2023-10-13 11:23:33', '2023-10-13 11:25:02', 'O', '2023-10-13 11:23:33'),
(89, 1, 'undefined', '2023-10-13', '2023-10-13 11:25:02', '2023-10-13 11:29:19', 'O', '2023-10-13 11:25:02'),
(90, 1, 'undefined', '2023-10-13', '2023-10-13 11:29:20', '2023-10-13 11:31:03', 'O', '2023-10-13 11:29:20'),
(91, 1, 'undefined', '2023-10-13', '2023-10-13 11:31:03', '2023-10-13 11:31:50', 'O', '2023-10-13 11:31:03'),
(92, 1, 'undefined', '2023-10-13', '2023-10-13 11:32:12', '2023-10-13 11:54:48', 'O', '2023-10-13 11:32:12'),
(93, 1, 'undefined', '2023-10-13', '2023-10-13 11:55:20', '2023-10-13 14:31:42', 'O', '2023-10-13 11:55:20'),
(94, 1, 'undefined', '2023-11-04', '2023-11-04 14:40:39', '2023-11-04 15:02:42', 'O', '2023-11-04 14:40:39'),
(95, 1, 'undefined', '2023-11-04', '2023-11-04 15:02:42', NULL, 'I', '2023-11-04 15:02:42'),
(96, 1, 'undefined', '2023-11-05', '2023-11-05 09:50:28', '2023-11-05 12:40:32', 'O', '2023-11-05 09:50:28'),
(97, 1, 'undefined', '2023-11-05', '2023-11-05 12:40:32', NULL, 'I', '2023-11-05 12:40:32'),
(98, 1, 'undefined', '2023-11-06', '2023-11-06 03:50:08', '2023-11-06 04:04:32', 'O', '2023-11-06 03:50:08'),
(99, 1, 'undefined', '2023-11-06', '2023-11-06 04:04:32', '2023-11-06 04:04:41', 'O', '2023-11-06 04:04:32'),
(100, 1, 'undefined', '2023-11-06', '2023-11-06 04:04:41', '2023-11-06 04:06:05', 'O', '2023-11-06 04:04:41'),
(101, 1, 'undefined', '2023-11-06', '2023-11-06 04:06:05', '2023-11-06 04:06:59', 'O', '2023-11-06 04:06:05'),
(102, 1, 'undefined', '2023-11-06', '2023-11-06 04:06:59', '2023-11-06 04:08:20', 'O', '2023-11-06 04:06:59'),
(103, 1, 'undefined', '2023-11-06', '2023-11-06 04:08:20', '2023-11-06 07:31:19', 'O', '2023-11-06 04:08:20'),
(104, 2, 'undefined', '2023-11-06', '2023-11-06 04:52:07', '2023-11-06 15:59:47', 'O', '2023-11-06 04:52:07'),
(105, 1, 'undefined', '2023-11-06', '2023-11-06 07:59:17', '2023-11-06 12:00:46', 'O', '2023-11-06 07:59:17'),
(106, 1, 'undefined', '2023-11-06', '2023-11-06 12:00:46', '2023-11-06 16:21:03', 'O', '2023-11-06 12:00:46'),
(107, 2, 'undefined', '2023-11-06', '2023-11-06 15:59:47', '2023-11-06 16:20:47', 'O', '2023-11-06 15:59:47'),
(108, 1, 'undefined', '2023-11-06', '2023-11-06 16:21:03', NULL, 'I', '2023-11-06 16:21:03'),
(109, 1, 'undefined', '2023-11-07', '2023-11-07 03:58:33', '2023-11-07 05:46:51', 'O', '2023-11-07 03:58:33'),
(110, 1, 'undefined', '2023-11-07', '2023-11-07 05:46:51', '2023-11-07 06:12:00', 'O', '2023-11-07 05:46:51'),
(111, 1, 'undefined', '2023-11-07', '2023-11-07 06:12:00', '2023-11-07 06:12:06', 'O', '2023-11-07 06:12:00'),
(112, 1, 'undefined', '2023-11-07', '2023-11-07 06:19:33', '2023-11-07 06:45:47', 'O', '2023-11-07 06:19:33'),
(113, 1, 'undefined', '2023-11-07', '2023-11-07 06:45:47', '2023-11-07 07:02:37', 'O', '2023-11-07 06:45:47'),
(114, 1, 'undefined', '2023-11-07', '2023-11-07 07:02:37', '2023-11-07 07:04:10', 'O', '2023-11-07 07:02:37'),
(115, 2, 'undefined', '2023-11-07', '2023-11-07 07:03:11', '2023-11-07 07:03:37', 'O', '2023-11-07 07:03:11'),
(116, 1, 'undefined', '2023-11-07', '2023-11-07 07:04:10', '2023-11-07 07:04:32', 'O', '2023-11-07 07:04:10'),
(117, 1, 'undefined', '2023-11-07', '2023-11-07 07:04:32', '2023-11-07 07:04:40', 'O', '2023-11-07 07:04:32'),
(118, 1, 'undefined', '2023-11-07', '2023-11-07 07:05:35', '2023-11-07 07:06:11', 'O', '2023-11-07 07:05:35'),
(119, 1, 'undefined', '2023-11-07', '2023-11-07 07:06:11', '2023-11-07 07:20:47', 'O', '2023-11-07 07:06:11'),
(120, 1, 'undefined', '2023-11-07', '2023-11-07 07:21:06', '2023-11-07 07:21:10', 'O', '2023-11-07 07:21:06'),
(121, 1, 'undefined', '2023-11-07', '2023-11-07 07:22:23', '2023-11-07 07:22:32', 'O', '2023-11-07 07:22:23'),
(122, 1, 'undefined', '2023-11-07', '2023-11-07 07:22:51', '2023-11-07 07:22:54', 'O', '2023-11-07 07:22:51'),
(123, 1, 'undefined', '2023-11-07', '2023-11-07 07:23:44', '2023-11-07 07:23:47', 'O', '2023-11-07 07:23:44'),
(124, 1, 'undefined', '2023-11-07', '2023-11-07 07:24:56', '2023-11-07 09:03:04', 'O', '2023-11-07 07:24:56'),
(125, 1, 'undefined', '2023-11-07', '2023-11-07 09:03:04', '2023-11-07 09:03:10', 'O', '2023-11-07 09:03:04'),
(126, 1, 'undefined', '2023-11-07', '2023-11-07 09:04:07', '2023-11-07 09:04:48', 'O', '2023-11-07 09:04:07'),
(127, 1, 'undefined', '2023-11-07', '2023-11-07 09:04:48', '2023-11-07 09:05:39', 'O', '2023-11-07 09:04:48'),
(128, 1, 'undefined', '2023-11-07', '2023-11-07 09:05:39', '2023-11-07 11:09:08', 'O', '2023-11-07 09:05:39'),
(129, 1, 'undefined', '2023-11-07', '2023-11-07 11:09:08', '2023-11-07 12:17:25', 'O', '2023-11-07 11:09:08'),
(130, 2, 'undefined', '2023-11-07', '2023-11-07 12:17:42', '2023-11-07 12:19:47', 'O', '2023-11-07 12:17:42'),
(131, 1, 'undefined', '2023-11-07', '2023-11-07 12:20:03', '2023-11-07 12:57:38', 'O', '2023-11-07 12:20:03'),
(132, 1, 'undefined', '2023-11-07', '2023-11-07 12:57:58', '2023-11-07 13:02:25', 'O', '2023-11-07 12:57:58'),
(133, 1, 'undefined', '2023-11-07', '2023-11-07 13:02:25', '2023-11-07 13:17:03', 'O', '2023-11-07 13:02:25'),
(134, 1, 'undefined', '2023-11-07', '2023-11-07 13:17:03', '2023-11-07 13:19:59', 'O', '2023-11-07 13:17:03'),
(135, 1, 'undefined', '2023-11-07', '2023-11-07 13:29:47', '2023-11-07 13:44:42', 'O', '2023-11-07 13:29:47'),
(136, 1, 'undefined', '2023-11-07', '2023-11-07 13:44:42', '2023-11-07 15:22:52', 'O', '2023-11-07 13:44:42'),
(137, 1, 'undefined', '2023-11-07', '2023-11-07 15:47:04', NULL, 'I', '2023-11-07 15:47:04'),
(138, 1, 'undefined', '2023-11-08', '2023-11-08 04:09:11', '2023-11-08 04:10:59', 'O', '2023-11-08 04:09:11'),
(139, 2, 'undefined', '2023-11-08', '2023-11-08 04:11:10', '2023-11-08 05:28:44', 'O', '2023-11-08 04:11:10'),
(140, 1, 'undefined', '2023-11-08', '2023-11-08 04:13:26', '2023-11-08 05:29:24', 'O', '2023-11-08 04:13:26'),
(141, 1, 'undefined', '2023-11-08', '2023-11-08 05:29:24', '2023-11-08 05:48:06', 'O', '2023-11-08 05:29:24'),
(142, 1, 'undefined', '2023-11-08', '2023-11-08 05:48:23', '2023-11-08 05:48:33', 'O', '2023-11-08 05:48:23'),
(143, 2, 'undefined', '2023-11-08', '2023-11-08 05:48:40', '2023-11-08 06:16:47', 'O', '2023-11-08 05:48:40'),
(144, 1, 'undefined', '2023-11-08', '2023-11-08 06:17:03', '2023-11-08 06:36:36', 'O', '2023-11-08 06:17:03'),
(145, 1, 'undefined', '2023-11-08', '2023-11-08 06:36:36', '2023-11-08 06:37:29', 'O', '2023-11-08 06:36:36'),
(146, 2, 'undefined', '2023-11-08', '2023-11-08 06:37:41', '2023-11-08 06:43:52', 'O', '2023-11-08 06:37:41'),
(147, 1, 'undefined', '2023-11-08', '2023-11-08 06:44:04', '2023-11-08 06:45:45', 'O', '2023-11-08 06:44:04'),
(148, 1, 'undefined', '2023-11-08', '2023-11-08 06:45:45', '2023-11-08 07:05:53', 'O', '2023-11-08 06:45:45'),
(149, 1, 'undefined', '2023-11-08', '2023-11-08 07:05:53', '2023-11-08 07:06:06', 'O', '2023-11-08 07:05:53'),
(150, 2, 'undefined', '2023-11-08', '2023-11-08 07:06:18', '2023-11-08 07:06:24', 'O', '2023-11-08 07:06:18'),
(151, 1, 'undefined', '2023-11-08', '2023-11-08 07:08:33', '2023-11-08 07:16:22', 'O', '2023-11-08 07:08:33'),
(152, 1, 'undefined', '2023-11-08', '2023-11-08 07:16:22', '2023-11-08 09:01:42', 'O', '2023-11-08 07:16:22'),
(153, 1, 'undefined', '2023-11-08', '2023-11-08 09:22:19', '2023-11-08 09:24:28', 'O', '2023-11-08 09:22:19'),
(154, 1, 'undefined', '2023-11-08', '2023-11-08 09:33:14', '2023-11-08 09:54:31', 'O', '2023-11-08 09:33:14'),
(155, 1, 'undefined', '2023-11-08', '2023-11-08 09:54:31', '2023-11-08 13:25:07', 'O', '2023-11-08 09:54:31'),
(156, 1, 'undefined', '2023-11-08', '2023-11-08 13:25:07', '2023-11-08 13:55:08', 'O', '2023-11-08 13:25:07'),
(157, 1, 'undefined', '2023-11-08', '2023-11-08 15:19:56', '2023-11-08 15:25:27', 'O', '2023-11-08 15:19:56'),
(158, 1, 'undefined', '2023-11-09', '2023-11-09 02:37:37', '2023-11-09 03:21:42', 'O', '2023-11-09 02:37:37'),
(159, 1, 'undefined', '2023-11-09', '2023-11-09 04:51:06', '2023-11-09 09:42:26', 'O', '2023-11-09 04:51:06'),
(160, 1, 'undefined', '2023-11-09', '2023-11-09 09:42:26', '2023-11-09 10:02:35', 'O', '2023-11-09 09:42:26'),
(161, 1, 'undefined', '2023-11-09', '2023-11-09 10:02:35', '2023-11-09 10:09:21', 'O', '2023-11-09 10:02:35'),
(162, 1, 'undefined', '2023-11-09', '2023-11-09 10:09:21', '2023-11-09 12:57:16', 'O', '2023-11-09 10:09:21'),
(163, 1, 'undefined', '2023-11-10', '2023-11-10 04:31:41', '2023-11-10 04:44:29', 'O', '2023-11-10 04:31:41'),
(164, 1, 'undefined', '2023-11-10', '2023-11-10 04:44:29', '2023-11-10 04:59:26', 'O', '2023-11-10 04:44:29'),
(165, 1, 'undefined', '2023-11-10', '2023-11-10 05:04:45', '2023-11-10 05:22:57', 'O', '2023-11-10 05:04:45'),
(166, 1, 'undefined', '2023-11-10', '2023-11-10 05:22:58', '2023-11-10 06:17:10', 'O', '2023-11-10 05:22:58'),
(167, 1, 'undefined', '2023-11-10', '2023-11-10 06:17:10', '2023-11-10 09:41:25', 'O', '2023-11-10 06:17:10'),
(168, 2, 'undefined', '2023-11-10', '2023-11-10 09:42:04', '2023-11-10 10:13:41', 'O', '2023-11-10 09:42:04'),
(169, 1, 'undefined', '2023-11-10', '2023-11-10 10:13:50', '2023-11-10 10:26:12', 'O', '2023-11-10 10:13:50'),
(170, 2, 'undefined', '2023-11-10', '2023-11-10 10:27:41', '2023-11-10 10:34:57', 'O', '2023-11-10 10:27:41'),
(171, 1, 'undefined', '2023-11-10', '2023-11-10 10:35:04', '2023-11-10 10:57:33', 'O', '2023-11-10 10:35:04'),
(172, 2, 'undefined', '2023-11-10', '2023-11-10 10:58:39', '2023-11-10 11:00:19', 'O', '2023-11-10 10:58:39'),
(173, 1, 'undefined', '2023-11-10', '2023-11-10 11:02:49', '2023-11-10 11:04:43', 'O', '2023-11-10 11:02:49'),
(174, 1, 'undefined', '2023-11-10', '2023-11-10 11:04:43', '2023-11-10 11:05:00', 'O', '2023-11-10 11:04:43'),
(175, 1, 'undefined', '2023-11-10', '2023-11-10 11:07:45', '2023-11-10 11:33:50', 'O', '2023-11-10 11:07:45'),
(176, 1, 'undefined', '2023-11-10', '2023-11-10 11:33:50', '2023-11-10 11:36:49', 'O', '2023-11-10 11:33:50'),
(177, 1, 'undefined', '2023-11-10', '2023-11-10 11:36:49', '2023-11-10 13:28:57', 'O', '2023-11-10 11:36:49'),
(178, 1, 'undefined', '2023-11-10', '2023-11-10 13:35:11', '2023-11-10 13:45:53', 'O', '2023-11-10 13:35:11'),
(179, 1, 'undefined', '2023-11-10', '2023-11-10 13:45:53', '2023-11-10 13:46:47', 'O', '2023-11-10 13:45:53'),
(180, 1, 'undefined', '2023-11-10', '2023-11-10 13:47:31', '2023-11-10 15:27:01', 'O', '2023-11-10 13:47:31'),
(181, 1, 'undefined', '2023-11-10', '2023-11-10 15:27:01', NULL, 'I', '2023-11-10 15:27:01'),
(182, 1, 'undefined', '2023-11-11', '2023-11-11 04:28:54', '2023-11-11 05:32:37', 'O', '2023-11-11 04:28:54'),
(183, 1, 'undefined', '2023-11-11', '2023-11-11 05:33:00', '2023-11-11 06:11:52', 'O', '2023-11-11 05:33:00'),
(184, 2, 'undefined', '2023-11-11', '2023-11-11 06:12:29', '2023-11-11 07:46:53', 'O', '2023-11-11 06:12:29'),
(185, 1, 'undefined', '2023-11-11', '2023-11-11 07:47:01', '2023-11-11 07:51:26', 'O', '2023-11-11 07:47:01'),
(186, 2, 'undefined', '2023-11-11', '2023-11-11 07:52:06', '2023-11-11 07:54:32', 'O', '2023-11-11 07:52:06'),
(187, 1, 'undefined', '2023-11-11', '2023-11-11 07:54:41', '2023-11-11 08:51:26', 'O', '2023-11-11 07:54:41'),
(188, 2, 'undefined', '2023-11-11', '2023-11-11 08:51:50', '2023-11-11 11:05:16', 'O', '2023-11-11 08:51:50'),
(189, 1, 'undefined', '2023-11-11', '2023-11-11 09:48:18', '2023-11-11 11:02:18', 'O', '2023-11-11 09:48:18'),
(190, 1, 'undefined', '2023-11-11', '2023-11-11 11:02:18', '2023-11-11 11:05:24', 'O', '2023-11-11 11:02:18'),
(191, 1, 'undefined', '2023-11-11', '2023-11-11 11:05:25', '2023-11-11 14:50:10', 'O', '2023-11-11 11:05:25'),
(192, 1, 'undefined', '2023-11-11', '2023-11-11 14:50:10', NULL, 'I', '2023-11-11 14:50:10'),
(193, 1, 'undefined', '2023-11-13', '2023-11-13 04:11:18', '2023-11-13 04:14:55', 'O', '2023-11-13 04:11:18'),
(194, 1, 'undefined', '2023-11-13', '2023-11-13 04:14:55', NULL, 'I', '2023-11-13 04:14:55'),
(195, 1, 'undefined', '2023-11-14', '2023-11-14 11:14:11', NULL, 'I', '2023-11-14 11:14:11'),
(196, 1, 'undefined', '2023-11-25', '2023-11-25 10:36:13', '2023-11-25 10:36:56', 'O', '2023-11-25 10:36:13'),
(197, 1, 'undefined', '2023-11-25', '2023-11-25 10:36:56', '2023-11-25 10:40:00', 'O', '2023-11-25 10:36:56'),
(198, 1, 'undefined', '2023-12-27', '2023-12-27 09:17:53', '2023-12-27 09:20:19', 'O', '2023-12-27 09:17:53'),
(199, 1, 'undefined', '2023-12-28', '2023-12-28 11:02:44', NULL, 'I', '2023-12-28 11:02:44'),
(200, 1, 'undefined', '2023-12-29', '2023-12-29 14:21:13', '2023-12-29 14:23:44', 'O', '2023-12-29 14:21:13'),
(201, 1, 'undefined', '2024-01-02', '2024-01-02 09:54:14', '2024-01-02 09:55:07', 'O', '2024-01-02 09:54:14'),
(202, 1, 'undefined', '2024-01-02', '2024-01-02 10:02:34', NULL, 'I', '2024-01-02 10:02:34'),
(203, 1, 'undefined', '2024-01-03', '2024-01-03 10:48:03', '2024-01-03 10:58:23', 'O', '2024-01-03 10:48:03'),
(204, 1, 'undefined', '2024-01-03', '2024-01-03 10:58:23', '2024-01-03 11:11:11', 'O', '2024-01-03 10:58:23'),
(205, 1, 'undefined', '2024-01-03', '2024-01-03 11:11:11', '2024-01-03 11:15:57', 'O', '2024-01-03 11:11:11'),
(206, 1, 'undefined', '2024-01-03', '2024-01-03 11:15:57', '2024-01-03 11:16:07', 'O', '2024-01-03 11:15:57'),
(207, 1, 'undefined', '2024-01-03', '2024-01-03 12:00:27', NULL, 'I', '2024-01-03 12:00:27'),
(208, 1, 'undefined', '2024-01-05', '2024-01-05 04:40:07', '2024-01-05 05:46:18', 'O', '2024-01-05 04:40:07'),
(209, 1, 'undefined', '2024-01-05', '2024-01-05 05:06:50', '2024-01-05 05:46:18', 'O', '2024-01-05 05:06:50'),
(211, 1, 'undefined', '2024-01-05', '2024-01-05 05:13:33', '2024-01-05 05:46:18', 'O', '2024-01-05 05:13:33'),
(212, 1, 'undefined', '2024-01-05', '2024-01-05 05:29:12', '2024-01-05 05:46:18', 'O', '2024-01-05 05:29:12'),
(213, 1, 'undefined', '2024-01-05', '2024-01-05 05:30:19', '2024-01-05 05:46:18', 'O', '2024-01-05 05:30:19'),
(214, 1, 'undefined', '2024-01-05', '2024-01-05 05:57:59', '2024-01-05 05:58:25', 'O', '2024-01-05 05:57:59'),
(215, 1, 'undefined', '2024-01-05', '2024-01-05 06:04:32', '2024-01-05 06:04:39', 'O', '2024-01-05 06:04:32'),
(216, 1, 'undefined', '2024-01-05', '2024-01-05 06:05:10', '2024-01-05 06:07:17', 'O', '2024-01-05 06:05:10'),
(217, 1, 'undefined', '2024-01-05', '2024-01-05 06:09:36', '2024-01-05 06:10:15', 'O', '2024-01-05 06:09:36'),
(218, 1, 'undefined', '2024-01-05', '2024-01-05 10:54:58', '2024-01-05 10:57:39', 'O', '2024-01-05 10:54:58'),
(219, 1, 'undefined', '2024-01-05', '2024-01-05 10:58:37', '2024-01-05 11:03:17', 'O', '2024-01-05 10:58:37'),
(220, 1, 'undefined', '2024-01-05', '2024-01-05 11:03:33', '2024-01-05 11:03:38', 'O', '2024-01-05 11:03:33'),
(221, 1, 'undefined', '2024-01-05', '2024-01-05 11:09:11', '2024-01-05 11:09:16', 'O', '2024-01-05 11:09:11'),
(222, 1, 'undefined', '2024-01-05', '2024-01-05 11:27:50', '2024-01-05 11:27:55', 'O', '2024-01-05 11:27:50'),
(223, 1, 'undefined', '2024-01-05', '2024-01-05 11:28:15', '2024-01-05 11:28:22', 'O', '2024-01-05 11:28:15'),
(224, 1, 'undefined', '2024-01-05', '2024-01-05 12:11:48', NULL, 'I', '2024-01-05 12:11:48'),
(225, 2, 'undefined', '2024-01-06', '2024-01-06 02:15:05', '2024-01-06 13:12:46', 'O', '2024-01-06 02:15:05'),
(226, 1, 'undefined', '2024-01-07', '2024-01-07 13:21:50', NULL, 'I', '2024-01-07 13:21:50'),
(227, 1, 'undefined', '2024-01-08', '2024-01-08 02:15:54', NULL, 'I', '2024-01-08 02:15:54'),
(228, 1, 'undefined', '2024-01-09', '2024-01-09 04:37:14', NULL, 'I', '2024-01-09 04:37:14'),
(229, 1, 'undefined', '2024-01-09', '2024-01-09 09:31:47', NULL, 'I', '2024-01-09 09:31:47'),
(230, 1, 'undefined', '2024-01-10', '2024-01-10 14:15:48', NULL, 'I', '2024-01-10 14:15:48'),
(231, 1, 'undefined', '2024-01-11', '2024-01-11 13:01:01', '2024-01-11 13:14:19', 'O', '2024-01-11 13:01:01'),
(232, 1, 'undefined', '2024-01-11', '2024-01-11 13:12:23', '2024-01-11 13:14:19', 'O', '2024-01-11 13:12:23'),
(233, 1, 'undefined', '2024-01-11', '2024-01-11 13:15:44', '2024-01-11 13:17:59', 'O', '2024-01-11 13:15:44'),
(234, 1, 'undefined', '2024-01-11', '2024-01-11 13:18:24', '2024-01-11 13:51:11', 'O', '2024-01-11 13:18:24'),
(235, 2, 'undefined', '2024-01-11', '2024-01-11 13:51:28', NULL, 'I', '2024-01-11 13:51:28'),
(236, 1, 'undefined', '2024-01-12', '2024-01-12 04:51:22', '2024-01-12 05:19:46', 'O', '2024-01-12 04:51:22'),
(237, 2, 'undefined', '2024-01-12', '2024-01-12 05:20:07', '2024-01-12 05:42:52', 'O', '2024-01-12 05:20:07'),
(238, 1, 'undefined', '2024-01-12', '2024-01-12 05:48:11', '2024-01-12 06:00:15', 'O', '2024-01-12 05:48:11'),
(239, 2, 'undefined', '2024-01-12', '2024-01-12 06:00:21', '2024-01-12 09:39:43', 'O', '2024-01-12 06:00:21'),
(240, 2, 'undefined', '2024-01-12', '2024-01-12 06:11:25', '2024-01-12 09:39:43', 'O', '2024-01-12 06:11:25'),
(241, 2, 'undefined', '2024-01-12', '2024-01-12 09:40:06', '2024-01-12 09:41:20', 'O', '2024-01-12 09:40:06'),
(242, 1, 'undefined', '2024-01-12', '2024-01-12 09:41:33', '2024-01-12 11:18:00', 'O', '2024-01-12 09:41:33'),
(243, 2, 'undefined', '2024-01-12', '2024-01-12 11:18:19', '2024-01-12 11:23:44', 'O', '2024-01-12 11:18:19'),
(244, 1, 'undefined', '2024-01-12', '2024-01-12 11:23:59', NULL, 'I', '2024-01-12 11:23:59'),
(245, 1, 'undefined', '2024-01-12', '2024-01-12 12:30:26', NULL, 'I', '2024-01-12 12:30:26'),
(246, 1, 'undefined', '2024-01-23', '2024-01-23 04:57:27', NULL, 'I', '2024-01-23 04:57:27'),
(248, 1, 'undefined', '2024-01-23', '2024-01-23 07:17:50', NULL, 'I', '2024-01-23 07:17:50'),
(249, 1, 'undefined', '2024-01-23', '2024-01-23 07:40:55', NULL, 'I', '2024-01-23 07:40:55'),
(250, 1, 'undefined', '2024-01-23', '2024-01-23 09:40:35', NULL, 'I', '2024-01-23 09:40:35'),
(251, 1, 'undefined', '2024-01-24', '2024-01-24 09:04:43', NULL, 'I', '2024-01-24 09:04:43'),
(252, 1, 'undefined', '2024-01-25', '2024-01-25 05:34:45', NULL, 'I', '2024-01-25 05:34:45'),
(253, 1, 'undefined', '2024-01-25', '2024-01-25 05:59:54', NULL, 'I', '2024-01-25 05:59:54'),
(254, 1, 'undefined', '2024-01-25', '2024-01-25 13:07:10', NULL, 'I', '2024-01-25 13:07:10'),
(255, 1, 'undefined', '2024-01-25', '2024-01-25 14:50:36', NULL, 'I', '2024-01-25 14:50:36'),
(256, 1, 'undefined', '2024-01-27', '2024-01-27 05:17:47', NULL, 'I', '2024-01-27 05:17:47'),
(257, 1, 'undefined', '2024-01-30', '2024-01-30 06:43:12', '2024-01-30 06:51:23', 'O', '2024-01-30 06:43:12'),
(258, 1, 'undefined', '2024-01-30', '2024-01-30 06:51:40', NULL, 'I', '2024-01-30 06:51:40'),
(259, 1, 'undefined', '2024-01-30', '2024-01-30 11:18:29', NULL, 'I', '2024-01-30 11:18:29'),
(260, 1, 'undefined', '2024-01-31', '2024-01-31 12:17:38', '2024-01-31 14:12:48', 'O', '2024-01-31 12:17:38'),
(261, 1, 'undefined', '2024-02-01', '2024-02-01 04:05:23', '2024-02-01 06:37:54', 'O', '2024-02-01 04:05:23'),
(262, 1, 'undefined', '2024-02-05', '2024-02-05 06:10:49', '2024-02-05 06:51:19', 'O', '2024-02-05 06:10:49'),
(263, 1, 'undefined', '2024-02-05', '2024-02-05 06:17:23', '2024-02-05 06:51:19', 'O', '2024-02-05 06:17:23'),
(264, 1, 'undefined', '2024-02-05', '2024-02-05 06:18:01', '2024-02-05 06:51:19', 'O', '2024-02-05 06:18:01'),
(265, 1, 'undefined', '2024-02-05', '2024-02-05 06:28:27', '2024-02-05 06:51:19', 'O', '2024-02-05 06:28:27'),
(266, 1, 'undefined', '2024-02-08', '2024-02-08 09:43:07', '2024-02-08 09:43:21', 'O', '2024-02-08 09:43:07'),
(267, 1, 'undefined', '2024-02-08', '2024-02-08 09:46:37', NULL, 'I', '2024-02-08 09:46:37'),
(268, 1, 'undefined', '2024-02-15', '2024-02-15 05:39:55', NULL, 'I', '2024-02-15 05:39:55'),
(269, 1, 'undefined', '2024-02-15', '2024-02-15 07:34:20', NULL, 'I', '2024-02-15 07:34:20'),
(270, 1, 'undefined', '2024-02-22', '2024-02-22 06:23:24', '2024-02-22 11:17:19', 'O', '2024-02-22 06:23:24'),
(271, 1, 'undefined', '2024-02-22', '2024-02-22 09:48:32', '2024-02-22 11:17:19', 'O', '2024-02-22 09:48:32'),
(272, 6, 'undefined', '2024-02-22', '2024-02-22 11:17:47', '2024-02-22 11:17:58', 'O', '2024-02-22 11:17:47'),
(273, 1, 'undefined', '2024-02-22', '2024-02-22 11:18:04', NULL, 'I', '2024-02-22 11:18:04'),
(274, 1, 'undefined', '2024-02-22', '2024-02-22 11:40:23', NULL, 'I', '2024-02-22 11:40:23'),
(275, 1, 'undefined', '2024-02-24', '2024-02-24 05:31:53', '2024-02-24 05:56:57', 'O', '2024-02-24 05:31:53'),
(276, 1, 'undefined', '2024-02-24', '2024-02-24 05:46:24', '2024-02-24 05:56:57', 'O', '2024-02-24 05:46:24'),
(277, 1, 'undefined', '2024-02-24', '2024-02-24 05:51:01', '2024-02-24 05:56:57', 'O', '2024-02-24 05:51:01'),
(278, 1, 'undefined', '2024-02-24', '2024-02-24 06:03:34', '2024-02-24 06:35:45', 'O', '2024-02-24 06:03:34'),
(279, 1, 'undefined', '2024-02-24', '2024-02-24 06:37:27', NULL, 'I', '2024-02-24 06:37:27'),
(280, 1, 'undefined', '2024-02-26', '2024-02-26 04:45:55', '2024-02-26 04:46:06', 'O', '2024-02-26 04:45:55'),
(281, 2, 'undefined', '2024-02-26', '2024-02-26 04:46:17', '2024-02-26 04:46:21', 'O', '2024-02-26 04:46:17'),
(282, 3, 'undefined', '2024-02-26', '2024-02-26 04:46:32', '2024-02-26 04:46:37', 'O', '2024-02-26 04:46:32'),
(283, 1, 'undefined', '2024-02-26', '2024-02-26 05:02:47', '2024-02-26 05:03:04', 'O', '2024-02-26 05:02:47'),
(284, 1, 'undefined', '2024-02-26', '2024-02-26 05:06:40', '2024-02-26 06:20:31', 'O', '2024-02-26 05:06:40'),
(285, 1, 'undefined', '2024-02-26', '2024-02-26 05:22:48', '2024-02-26 06:20:31', 'O', '2024-02-26 05:22:48'),
(286, 1, 'undefined', '2024-02-26', '2024-02-26 06:22:50', '2024-02-26 07:12:57', 'O', '2024-02-26 06:22:50'),
(287, 1, 'undefined', '2024-02-26', '2024-02-26 07:13:12', '2024-02-26 14:33:35', 'O', '2024-02-26 07:13:12'),
(288, 1, 'undefined', '2024-02-26', '2024-02-26 14:33:26', '2024-02-26 14:33:35', 'O', '2024-02-26 14:33:26'),
(289, 1, 'undefined', '2024-02-26', '2024-02-26 14:33:40', '2024-02-26 15:32:51', 'O', '2024-02-26 14:33:40'),
(290, 1, 'undefined', '2024-02-26', '2024-02-26 15:07:31', '2024-02-26 15:32:51', 'O', '2024-02-26 15:07:31');

-- --------------------------------------------------------

--
-- Table structure for table `user_management`
--

CREATE TABLE IF NOT EXISTS `user_management` (
  `user_id` int NOT NULL,
  `user_master_id` int NOT NULL,
  `parent_id` int NOT NULL,
  `user_name` varchar(30) NOT NULL,
  `api_key` varchar(30) DEFAULT NULL,
  `login_password` varchar(50) NOT NULL,
  `user_email` varchar(50) DEFAULT NULL,
  `user_mobile` varchar(10) DEFAULT NULL,
  `usr_mgt_status` char(1) NOT NULL,
  `usr_mgt_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `bearer_token` varchar(500) NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT;

--
-- Dumping data for table `user_management`
--

INSERT INTO `user_management` (`user_id`, `user_master_id`, `parent_id`, `user_name`, `api_key`, `login_password`, `user_email`, `user_mobile`, `usr_mgt_status`, `usr_mgt_entry_date`, `bearer_token`) VALUES
(1, 1, 1, 'Super Admin', 'AA1DE999B6B65D2', 'e58a3754522a05c1ff4d231f8e8cc1bd', 'super_admin@gmail.com', '9000090000', 'Y', '2021-12-30 06:22:20', '-'),
(2, 2, 1, 'User 1', '2134D2287A57625', 'e58a3754522a05c1ff4d231f8e8cc1bd', 'user_1@gmail.com', '9000090001', 'Y', '2023-03-01 02:20:45', '-'),
(3, 2, 1, 'User 2', '2134D2287A57621', 'e58a3754522a05c1ff4d231f8e8cc1bd', 'user_2@gmail.com', '9000090021', 'Y', '2023-03-01 02:20:45', '-'),
(4, 2, 1, 'Shanthini', ' XGYG97KJW0BGSE', 'e233c7da05275ce7e55d2332135b86c7', 'shan@gmail.com', '6380885546', 'Y', '2024-01-02 09:56:44', '-'),
(5, 2, 1, 'test', '8LXN5JXQMM0YFX6', 'e58a3754522a05c1ff4d231f8e8cc1bd', 'test@gmail.com', '8866376735', 'Y', '2024-01-05 09:20:22', '-'),
(6, 2, 1, 'demo', 'S40CH3R9STHQW03', 'e58a3754522a05c1ff4d231f8e8cc1bd', 'demo@gmail.com', '8237489723', 'Y', '2024-01-05 11:10:15', '-'),
(7, 2, 1, 'demo1', '42OV5TC1X6TCXBJ', 'e58a3754522a05c1ff4d231f8e8cc1bd', 'demo1@gmail.com', '8237897957', 'Y', '2024-01-05 11:29:03', '-');

-- --------------------------------------------------------

--
-- Table structure for table `user_master`
--

CREATE TABLE IF NOT EXISTS `user_master` (
  `user_master_id` int NOT NULL,
  `user_type` varchar(20) NOT NULL,
  `user_title` varchar(20) NOT NULL,
  `user_master_status` char(1) NOT NULL,
  `um_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT;

--
-- Dumping data for table `user_master`
--

INSERT INTO `user_master` (`user_master_id`, `user_type`, `user_title`, `user_master_status`, `um_entry_date`) VALUES
(1, 'Super Admin', 'Super Admin', 'Y', '2021-12-14 02:01:00'),
(2, 'User', 'User', 'Y', '2021-12-14 02:01:04');

-- --------------------------------------------------------

--
-- Table structure for table `user_plans`
--

CREATE TABLE IF NOT EXISTS `user_plans` (
  `user_plans_id` int NOT NULL,
  `user_id` int NOT NULL,
  `plan_master_id` int NOT NULL,
  `plan_amount` int NOT NULL,
  `plan_expiry_date` timestamp NULL DEFAULT '0000-00-00 00:00:00',
  `payment_status` char(1) DEFAULT NULL,
  `plan_comments` varchar(300) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  `plan_reference_id` varchar(100) DEFAULT NULL,
  `user_plans_status` char(1) NOT NULL,
  `user_plans_entdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `user_plans`
--

INSERT INTO `user_plans` (`user_plans_id`, `user_id`, `plan_master_id`, `plan_amount`, `plan_expiry_date`, `payment_status`, `plan_comments`, `plan_reference_id`, `user_plans_status`, `user_plans_entdate`) VALUES
(1, 1, 2, 300, '2024-02-11 13:31:48', 'A', 'msg:Payment successfully credited, status:true, productCode:2, paymentID:pay_NNKBH1rGodKSq0, userEmail', '-', 'A', '2024-01-11 13:31:24');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `api_log`
--
ALTER TABLE `api_log`
  ADD PRIMARY KEY (`api_log_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `cron_compose`
--
ALTER TABLE `cron_compose`
  ADD PRIMARY KEY (`cron_com_id`);

--
-- Indexes for table `group_contacts`
--
ALTER TABLE `group_contacts`
  ADD PRIMARY KEY (`group_contacts_id`),
  ADD KEY `contact_mobile_id` (`group_contacts_id`,`group_master_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `group_master_id` (`group_master_id`);

--
-- Indexes for table `group_contacts_backup`
--
ALTER TABLE `group_contacts_backup`
  ADD PRIMARY KEY (`group_contacts_id`),
  ADD KEY `contact_mobile_id` (`group_contacts_id`,`group_master_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `group_master_id` (`group_master_id`);

--
-- Indexes for table `group_master`
--
ALTER TABLE `group_master`
  ADD PRIMARY KEY (`group_master_id`),
  ADD KEY `group_contact_id` (`group_master_id`,`user_id`,`sender_master_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `sender_master_id` (`sender_master_id`);

--
-- Indexes for table `group_master_backup`
--
ALTER TABLE `group_master_backup`
  ADD PRIMARY KEY (`group_master_id`),
  ADD KEY `group_contact_id` (`group_master_id`,`user_id`,`sender_master_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `sender_master_id` (`sender_master_id`);

--
-- Indexes for table `master_countries`
--
ALTER TABLE `master_countries`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `master_language`
--
ALTER TABLE `master_language`
  ADD PRIMARY KEY (`language_id`),
  ADD KEY `language_id` (`language_id`);

--
-- Indexes for table `payment_history_log`
--
ALTER TABLE `payment_history_log`
  ADD PRIMARY KEY (`payment_history_logid`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `user_plans_id` (`user_plans_id`),
  ADD KEY `plan_master_id` (`plan_master_id`);

--
-- Indexes for table `plans_update`
--
ALTER TABLE `plans_update`
  ADD PRIMARY KEY (`plans_update_id`);

--
-- Indexes for table `senderid_master`
--
ALTER TABLE `senderid_master`
  ADD PRIMARY KEY (`sender_master_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `whatspp_config_id` (`sender_master_id`,`user_id`),
  ADD KEY `user_id_2` (`user_id`);

--
-- Indexes for table `summary_report`
--
ALTER TABLE `summary_report`
  ADD PRIMARY KEY (`summary_report_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `template_master`
--
ALTER TABLE `template_master`
  ADD PRIMARY KEY (`template_master_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `language_id` (`language_id`);

--
-- Indexes for table `user_log`
--
ALTER TABLE `user_log`
  ADD PRIMARY KEY (`user_log_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `user_log_id` (`user_log_id`,`user_id`);

--
-- Indexes for table `user_management`
--
ALTER TABLE `user_management`
  ADD PRIMARY KEY (`user_id`),
  ADD KEY `user_master_id` (`user_master_id`,`parent_id`),
  ADD KEY `user_master_id_2` (`user_master_id`),
  ADD KEY `parent_id` (`parent_id`);

--
-- Indexes for table `user_master`
--
ALTER TABLE `user_master`
  ADD PRIMARY KEY (`user_master_id`);

--
-- Indexes for table `user_plans`
--
ALTER TABLE `user_plans`
  ADD PRIMARY KEY (`user_plans_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `plan_master_id` (`plan_master_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `api_log`
--
ALTER TABLE `api_log`
  MODIFY `api_log_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=624;
--
-- AUTO_INCREMENT for table `cron_compose`
--
ALTER TABLE `cron_compose`
  MODIFY `cron_com_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=5;
--
-- AUTO_INCREMENT for table `group_contacts`
--
ALTER TABLE `group_contacts`
  MODIFY `group_contacts_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=1008;
--
-- AUTO_INCREMENT for table `group_contacts_backup`
--
ALTER TABLE `group_contacts_backup`
  MODIFY `group_contacts_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=45;
--
-- AUTO_INCREMENT for table `group_master`
--
ALTER TABLE `group_master`
  MODIFY `group_master_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=130;
--
-- AUTO_INCREMENT for table `group_master_backup`
--
ALTER TABLE `group_master_backup`
  MODIFY `group_master_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=17;
--
-- AUTO_INCREMENT for table `master_countries`
--
ALTER TABLE `master_countries`
  MODIFY `id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=249;
--
-- AUTO_INCREMENT for table `master_language`
--
ALTER TABLE `master_language`
  MODIFY `language_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=16;
--
-- AUTO_INCREMENT for table `payment_history_log`
--
ALTER TABLE `payment_history_log`
  MODIFY `payment_history_logid` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `plans_update`
--
ALTER TABLE `plans_update`
  MODIFY `plans_update_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `senderid_master`
--
ALTER TABLE `senderid_master`
  MODIFY `sender_master_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=17;
--
-- AUTO_INCREMENT for table `summary_report`
--
ALTER TABLE `summary_report`
  MODIFY `summary_report_id` int NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `template_master`
--
ALTER TABLE `template_master`
  MODIFY `template_master_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=4;
--
-- AUTO_INCREMENT for table `user_log`
--
ALTER TABLE `user_log`
  MODIFY `user_log_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=291;
--
-- AUTO_INCREMENT for table `user_management`
--
ALTER TABLE `user_management`
  MODIFY `user_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=8;
--
-- AUTO_INCREMENT for table `user_master`
--
ALTER TABLE `user_master`
  MODIFY `user_master_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `user_plans`
--
ALTER TABLE `user_plans`
  MODIFY `user_plans_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
