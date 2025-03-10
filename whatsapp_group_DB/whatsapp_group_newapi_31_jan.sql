-- phpMyAdmin SQL Dump
-- version 4.4.15.10
-- https://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jan 31, 2024 at 02:05 PM
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
) ENGINE=InnoDB AUTO_INCREMENT=322 DEFAULT CHARSET=utf8mb3;

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
(369, 0, '/login', 'undefined', '97568186_58194611', 'S', 'Success', '2024-01-31 12:17:38', 'Y', '2024-01-31 12:17:38');

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
  `remove_comments` varchar(50) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT;

--
-- Dumping data for table `group_contacts`
--

INSERT INTO `group_contacts` (`group_contacts_id`, `user_id`, `group_master_id`, `campaign_name`, `mobile_no`, `mobile_id`, `comments`, `group_contacts_status`, `group_contacts_entry_date`, `remove_comments`) VALUES
(1, 1, 1, 'ca_TESTING_023_1', '919361419661', '919361419661', 'Success', 'Y', '2024-01-23 08:02:57', NULL),
(2, 1, 1, 'ca_TESTING_023_2', '916380885546', '916380885546', 'Success', 'Y', '2024-01-23 08:05:26', NULL),
(3, 1, 1, 'ca_TESTING_025_3', '916369841530', '916369841530', 'Success', 'Y', '2024-01-25 06:22:51', NULL);

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
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT;

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
  `group_name` varchar(250) NOT NULL,
  `total_count` int NOT NULL,
  `success_count` int DEFAULT NULL,
  `failure_count` int DEFAULT NULL,
  `is_created_by_api` char(1) NOT NULL,
  `group_master_status` char(1) NOT NULL,
  `group_master_entdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT;

--
-- Dumping data for table `group_master`
--

INSERT INTO `group_master` (`group_master_id`, `user_id`, `sender_master_id`, `group_name`, `total_count`, `success_count`, `failure_count`, `is_created_by_api`, `group_master_status`, `group_master_entdate`) VALUES
(1, 1, 1, 'TESTING', 3, 3, 0, 'Y', 'Y', '2024-01-23 08:02:57');

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
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT;

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
-- Table structure for table `messenger_response`
--

CREATE TABLE IF NOT EXISTS `messenger_response` (
  `message_id` int NOT NULL,
  `user_id` int NOT NULL,
  `message_to` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `message_from` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `message_from_profile` varchar(50) NOT NULL,
  `message_resp_id` varchar(100) NOT NULL,
  `message_type` varchar(20) NOT NULL,
  `message_data` longtext NOT NULL,
  `msg_text` varchar(300) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  `msg_media` varchar(50) DEFAULT NULL,
  `msg_media_type` varchar(30) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  `msg_media_caption` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  `msg_reply_button` varchar(30) DEFAULT NULL,
  `msg_reaction` varchar(10) DEFAULT NULL,
  `msg_list` longtext CHARACTER SET utf8 COLLATE utf8_general_ci,
  `message_is_read` char(1) DEFAULT 'N',
  `message_status` char(1) NOT NULL,
  `message_rec_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `message_read_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT;

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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;

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
(1, 2, 1, 200, 199, 1, 30, 29, 2, 600, 600, 0, 'Y', '2024-01-23 08:02:57', '2024-02-11 19:01:48');

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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT;

--
-- Dumping data for table `senderid_master`
--

INSERT INTO `senderid_master` (`sender_master_id`, `user_id`, `mobile_no`, `profile_name`, `profile_image`, `senderid_master_status`, `senderid_master_entdate`, `senderid_master_apprdate`) VALUES
(1, 1, '918838964597', 'test', 'http://yjtec.in/whatsapp_group_newapi/uploads/whatsapp_images/1_1706194299642.png', 'X', '2024-01-25 14:51:50', '0000-00-00 00:00:00');

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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `template_master`
--

INSERT INTO `template_master` (`template_master_id`, `user_id`, `unique_template_id`, `template_name`, `language_id`, `template_category`, `template_message`, `template_status`, `template_entry_date`) VALUES
(1, 1, 'tmplt_Sup_023_001', 'te_Sup_t00000000_24123_001', 2, 'MARKETING', '[{"type":"BODY","text":"TESTING"}]', 'Y', '2024-01-23 07:48:56'),
(2, 1, 'tmplt_Sup_031_002', 'te_Sup_t00000000_24131_002', 1, 'MARKETING', '[{"type":"BODY","text":"JavaScript is the world most popular programming language."}]', 'Y', '2024-01-31 09:42:56');

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
) ENGINE=InnoDB AUTO_INCREMENT=260 DEFAULT CHARSET=utf8mb3;

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
(260, 1, 'undefined', '2024-01-31', '2024-01-31 12:17:38', NULL, 'I', '2024-01-31 12:17:38');

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
(1, 1, 1, 'Super Admin', 'AA1DE999B6B65D2', 'e58a3754522a05c1ff4d231f8e8cc1bd', 'super_admin@gmail.com', '9000090000', 'Y', '2021-12-30 06:22:20', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3MDY3MDM0NTgsImV4cCI6MTcwNzMwODI1OH0.JyBinsTvx22xc_IGw9NvihO6MlD7xbQMgI_NjWlhZSI'),
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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;

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
-- Indexes for table `messenger_response`
--
ALTER TABLE `messenger_response`
  ADD PRIMARY KEY (`message_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `user_id_2` (`user_id`),
  ADD KEY `user_id_3` (`user_id`);

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
  MODIFY `api_log_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=370;
--
-- AUTO_INCREMENT for table `group_contacts`
--
ALTER TABLE `group_contacts`
  MODIFY `group_contacts_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=4;
--
-- AUTO_INCREMENT for table `group_contacts_backup`
--
ALTER TABLE `group_contacts_backup`
  MODIFY `group_contacts_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=45;
--
-- AUTO_INCREMENT for table `group_master`
--
ALTER TABLE `group_master`
  MODIFY `group_master_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2;
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
-- AUTO_INCREMENT for table `messenger_response`
--
ALTER TABLE `messenger_response`
  MODIFY `message_id` int NOT NULL AUTO_INCREMENT;
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
  MODIFY `sender_master_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `summary_report`
--
ALTER TABLE `summary_report`
  MODIFY `summary_report_id` int NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `template_master`
--
ALTER TABLE `template_master`
  MODIFY `template_master_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `user_log`
--
ALTER TABLE `user_log`
  MODIFY `user_log_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=261;
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
