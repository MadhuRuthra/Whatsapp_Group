-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Feb 13, 2024 at 03:40 PM
-- Server version: 10.4.27-MariaDB
-- PHP Version: 8.0.25

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
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
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeletePlan` (IN `in_plan_master_id` INT)  NO SQL BEGIN
    DECLARE plan_count INT;
    -- Check if the sender ID exists for the specified user
    SELECT COUNT(*) INTO plan_count
    FROM plan_master plan
    WHERE plan_status != 'D' and plan_master_id  = in_plan_master_id ;

    IF plan_count = 0 THEN
        -- Sender ID not found
        SELECT 0 AS response_code, 201 AS response_status, 'Plan not found.' AS response_msg;
    ELSE
        -- Mark the sender ID as deleted
        UPDATE plan_master
        SET plan_status = 'D'
        WHERE plan_master_id = in_plan_master_id
            AND plan_status != 'D';

        SELECT 1 AS response_code, 200 AS response_status, 'Success' AS response_msg;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteSenderId` (IN `in_user_id` INT, IN `in_sender_id` INT)  NO SQL BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetPlanDetails` (IN `in_user_id` INT)   BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertPaymentPlans` (IN `p_plan_master_id` INT, IN `p_slt_user_id` INT, IN `p_whatsapp_no_max_count` INT, IN `p_group_no_max_count` INT, IN `p_message_limit` INT, IN `p_plan_amount` DECIMAL(10,2), IN `p_plan_comments` VARCHAR(255), IN `in_user_plans_id` INT)   BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `LoginProcedure` (IN `p_txt_username` VARCHAR(255), IN `p_txt_password` VARCHAR(255), IN `p_request_id` VARCHAR(255), IN `p_bearer_token` VARCHAR(255), IN `p_ip_address` VARCHAR(255), IN `p_request_url` VARCHAR(255))   BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `LogoutProcedure` (IN `in_user_id` INT)  NO SQL BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `PaymentHistoryList` (IN `in_user_id` INT)   BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `PricingPlanList` (IN `in_user_id` INT)   BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `Purchase_plans` (IN `p_slt_user_id` INT, IN `p_plan_master_id` INT, IN `p_whatsapp_no_max_count` INT, IN `p_group_no_max_count` INT, IN `p_message_limit` INT, IN `p_plan_amount` DECIMAL(10,2), IN `p_plan_comments` VARCHAR(255), IN `p_plan_reference_id` VARCHAR(255))   BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `SenderIdList` (IN `in_user_id` INT)  NO SQL SELECT sndr.sender_master_id,sndr.user_id,usr.user_name,sndr.profile_name,sndr.profile_image, sndr.mobile_no, CASE
    WHEN sndr.senderid_master_status = 'Y' THEN 'Active'
    WHEN sndr.senderid_master_status = 'X' THEN 'Unlinked'
    WHEN sndr.senderid_master_status = 'L' THEN 'Linked'
    WHEN sndr.senderid_master_status = 'B' THEN 'Blocked'
    WHEN sndr.senderid_master_status = 'D' THEN 'Deleted'
    ELSE 'Inactive' END AS senderid_status, sndr.senderid_master_status,DATE_FORMAT(sndr.senderid_master_entdate,'%d-%m-%Y %H:%i:%s') senderid_master_entdate
     FROM senderid_master sndr left join user_management usr on usr.user_id = sndr.user_id where (sndr.user_id = in_user_id or usr.parent_id = in_user_id) ORDER BY sender_master_id DESC$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SignUpProcedure` (IN `in_user_type` VARCHAR(255), IN `in_user_email` VARCHAR(255), IN `in_user_password` VARCHAR(255), IN `in_user_mobile` VARCHAR(255), IN `in_parent_id` VARCHAR(255), IN `in_user_name` VARCHAR(255))   BEGIN
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
    ' sender_master_id INT NOT NULL, group_master_id INT NOT NULL,',
    ' template_master_id INT NOT NULL, message_type VARCHAR(10) NOT NULL,',
    ' campaign_name VARCHAR(30) NOT NULL, cm_status CHAR(1) NOT NULL,',
    ' cm_entry_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,',
    ' INDEX (compose_message_id), INDEX (user_id), PRIMARY KEY (compose_message_id),',
    ' KEY sender_master_id (sender_master_id), KEY group_master_id (group_master_id),',
    ' KEY template_master_id (template_master_id))',
    ' ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateUserPurchase` (IN `in_user_id` INT, IN `in_user_plans_id` INT, IN `in_payment_status` VARCHAR(1), IN `in_plan_comments` VARCHAR(300), IN `in_user_plan_status` VARCHAR(1), IN `in_plan_master_id` INT)   BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_api_log` (IN `in_originalUrl` VARCHAR(255), IN `ip_address` VARCHAR(255), IN `in_request_id` VARCHAR(255), IN `bearerHeader` VARCHAR(255), IN `in_user_id` INT)  NO SQL BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `UserCreationProcedure` (IN `in_user_type` VARCHAR(255), IN `in_user_email` VARCHAR(255), IN `in_user_password` VARCHAR(255), IN `in_user_mobile` VARCHAR(255), IN `in_parent_id` VARCHAR(255), IN `in_user_name` VARCHAR(255), IN `plan_master_id` INT(7), IN `total_whatsapp_count` INT(7), IN `total_group_count` INT(7), IN `total_message_limit` INT(7), IN `expiry_TIMESTAMP` TIMESTAMP, IN `plan_amount` VARCHAR(10))   BEGIN
    DECLARE apikey VARCHAR(15);
    DECLARE lastid INT;
    DECLARE user_planlastid INT;
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
 -- Insert into user_management table

        INSERT INTO user_management
        VALUES (
            NULL, in_user_type, in_parent_id, in_user_name, apikey, in_user_password, in_user_email, in_user_mobile, 'Y', CURRENT_TIMESTAMP, '-'
        );

          -- Get the last inserted user id
        SET lastid = LAST_INSERT_ID();
 -- Insert into plans_update table
         INSERT INTO plans_update
        VALUES (
            NULL, plan_master_id, lastid, total_whatsapp_count,  total_whatsapp_count, 0 , total_group_count,total_group_count, 0 , total_message_limit,total_message_limit,0, 'Y', CURRENT_TIMESTAMP, expiry_TIMESTAMP
        );

        -- Insert into user_plans table
  INSERT INTO user_plans
    VALUES (
      NULL, lastid,plan_master_id,plan_amount, expiry_TIMESTAMP, 'A', 'Admin Direct Approval','-', 'A',CURRENT_TIMESTAMP
    );

  -- Get the user_plans last inserted user id
        SET user_planlastid = LAST_INSERT_ID();

         -- Insert into payment_history_log table
  INSERT INTO payment_history_log
    VALUES (
      NULL, lastid, user_planlastid, plan_master_id,plan_amount, 'A', 'Admin Direct Approval','Y', CURRENT_TIMESTAMP
    );

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
    ' sender_master_id INT NOT NULL, group_master_id INT NOT NULL,',
    ' template_master_id INT NOT NULL, message_type VARCHAR(10) NOT NULL,',
    ' campaign_name VARCHAR(30) NOT NULL, cm_status CHAR(1) NOT NULL,',
    ' cm_entry_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,',
    ' INDEX (compose_message_id), INDEX (user_id), PRIMARY KEY (compose_message_id),',
    ' KEY sender_master_id (sender_master_id), KEY group_master_id (group_master_id),',
    ' KEY template_master_id (template_master_id))',
    ' ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
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

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `api_log`
--

CREATE TABLE `api_log` (
  `api_log_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `api_url` varchar(50) NOT NULL,
  `ip_address` varchar(50) NOT NULL,
  `request_id` varchar(30) NOT NULL,
  `response_status` char(1) DEFAULT NULL,
  `response_comments` varchar(100) DEFAULT NULL,
  `response_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `api_log_status` char(1) NOT NULL,
  `api_log_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

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
(202, 0, '/logout', 'undefined', '1_202412120935_3628', 'F', 'Invalid token', '2024-01-13 06:39:35', 'Y', '2024-01-13 06:39:35'),
(203, 0, '/login', 'undefined', '20816502_92400558', 'S', 'Success', '2024-01-13 06:39:51', 'Y', '2024-01-13 06:39:51'),
(204, 0, '/login', 'undefined', '55358536_91240268', 'S', 'Success', '2024-01-14 02:30:04', 'Y', '2024-01-14 02:30:04'),
(205, 1, '/logout', 'undefined', '1_202416114305_7813', 'S', 'Success', '2024-01-17 06:13:05', 'Y', '2024-01-17 06:13:05'),
(206, 0, '/login', 'undefined', '31011731_21312338', 'S', 'Success', '2024-01-17 06:14:05', 'Y', '2024-01-17 06:14:04'),
(207, 0, '/logout', 'undefined', '1_202418151722_1099', 'F', 'Invalid token', '2024-01-19 09:47:22', 'Y', '2024-01-19 09:47:22'),
(208, 0, '/login', 'undefined', '43886796_63694553', 'S', 'Success', '2024-01-19 09:49:32', 'Y', '2024-01-19 09:49:32'),
(209, 0, '/logout', 'undefined', '1_202419165537_9470', 'F', 'Invalid token', '2024-01-20 11:25:37', 'Y', '2024-01-20 11:25:37'),
(210, 0, '/login', 'undefined', '95957995_54464640', 'S', 'Success', '2024-01-20 11:25:49', 'Y', '2024-01-20 11:25:49'),
(211, 1, '/template/create_template', 'undefined', '_2024021122038_645', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-21 06:50:38'),
(212, 1, '/template/create_template', 'undefined', '_2024021122239_789', 'F', 'Error occurred', '2024-01-21 06:52:39', 'Y', '2024-01-21 06:52:39'),
(213, 1, '/template/create_template', 'undefined', '_2024021122426_761', 'F', 'Error occurred', '2024-01-21 06:54:26', 'Y', '2024-01-21 06:54:26'),
(214, 1, '/template/create_template', 'undefined', '_2024021122603_615', 'F', 'Error occurred', '2024-01-21 06:56:03', 'Y', '2024-01-21 06:56:03'),
(215, 1, '/template/create_template', 'undefined', '_2024021122757_641', 'F', 'No number available or language not available', '2024-01-21 06:57:57', 'Y', '2024-01-21 06:57:57'),
(216, 1, '/template/create_template', 'undefined', '_2024021123344_640', 'F', 'Error occurred', '2024-01-21 07:03:44', 'Y', '2024-01-21 07:03:44'),
(217, 1, '/template/create_template', 'undefined', '_2024021123524_734', 'F', 'Error occurred', '2024-01-21 07:05:24', 'Y', '2024-01-21 07:05:24'),
(218, 1, '/template/create_template', 'undefined', '_2024021123613_793', 'S', 'Success', '2024-01-21 07:06:13', 'Y', '2024-01-21 07:06:13'),
(219, 1, '/template/create_template', 'undefined', '_2024021124314_453', 'S', 'Success', '2024-01-21 07:13:15', 'Y', '2024-01-21 07:13:15'),
(220, 1, '/template/create_template', 'undefined', '_2024021125643_458', 'S', 'Success', '2024-01-21 07:26:44', 'Y', '2024-01-21 07:26:44'),
(221, 1, '/template/create_template', 'undefined', '_2024021130131_329', 'S', 'Success', '2024-01-21 07:31:31', 'Y', '2024-01-21 07:31:31'),
(222, 1, '/template/create_template', 'undefined', '_2024021130850_992', 'S', 'Success', '2024-01-21 07:38:50', 'Y', '2024-01-21 07:38:50'),
(223, 1, '/template/create_template', 'undefined', '_2024021131003_829', 'S', 'Success', '2024-01-21 07:40:03', 'Y', '2024-01-21 07:40:03'),
(224, 1, '/template/create_template', 'undefined', '_2024021131131_578', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-21 07:41:31'),
(225, 1, '/template/create_template', 'undefined', '_2024021131208_904', 'S', 'Success', '2024-01-21 07:42:08', 'Y', '2024-01-21 07:42:08'),
(226, 1, '/template/create_template', 'undefined', '_2024021131410_437', 'S', 'Success', '2024-01-21 07:44:11', 'Y', '2024-01-21 07:44:10'),
(227, 1, '/template/create_template', 'undefined', '_2024021131515_839', 'S', 'Success', '2024-01-21 07:45:15', 'Y', '2024-01-21 07:45:15'),
(228, 1, '/template/create_template', 'undefined', '_2024021131606_390', 'S', 'Success', '2024-01-21 07:46:06', 'Y', '2024-01-21 07:46:06'),
(229, 1, '/template/create_template', 'undefined', '_2024021131626_530', 'S', 'Success', '2024-01-21 07:46:26', 'Y', '2024-01-21 07:46:26'),
(230, 1, '/template/create_template', 'undefined', '_2024021131736_185', 'S', 'Success', '2024-01-21 07:47:36', 'Y', '2024-01-21 07:47:36'),
(231, 1, '/template/create_template', 'undefined', '_2024021131829_445', 'S', 'Success', '2024-01-21 07:48:30', 'Y', '2024-01-21 07:48:29'),
(232, 1, '/template/create_template', 'undefined', '_2024021131838_763', 'S', 'Success', '2024-01-21 07:48:38', 'Y', '2024-01-21 07:48:38'),
(233, 1, '/template/create_template', 'undefined', '_2024021132103_370', 'S', 'Success', '2024-01-21 07:51:03', 'Y', '2024-01-21 07:51:03'),
(234, 1, '/template/create_template', 'undefined', '_2024021132148_239', 'S', 'Success', '2024-01-21 07:51:48', 'Y', '2024-01-21 07:51:48'),
(235, 1, '/template/create_template', 'undefined', '_2024021132346_169', 'S', 'Success', '2024-01-21 07:53:46', 'Y', '2024-01-21 07:53:46'),
(240, 1, '/template/create_template', 'undefined', '_2024021152231_355', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-21 09:52:31'),
(241, 1, '/template/create_template', 'undefined', '_2024021152446_212', 'S', 'Success', '2024-01-21 09:54:46', 'Y', '2024-01-21 09:54:46'),
(242, 1, '/template/create_template', 'undefined', '_2024022095756_621', 'S', 'Success', '2024-01-22 04:27:56', 'Y', '2024-01-22 04:27:56'),
(243, 1, '/template/create_template', 'undefined', '_2024022095838_295', 'S', 'Success', '2024-01-22 04:28:38', 'Y', '2024-01-22 04:28:38'),
(244, 1, '/template/create_template', 'undefined', '_2024022100933_866', 'S', 'Success', '2024-01-22 04:39:33', 'Y', '2024-01-22 04:39:33'),
(245, 1, '/template/create_template', 'undefined', '_2024022101710_587', 'S', 'Success', '2024-01-22 04:47:10', 'Y', '2024-01-22 04:47:10'),
(246, 1, '/template/create_template', 'undefined', '_2024022101814_783', 'S', 'Success', '2024-01-22 04:48:14', 'Y', '2024-01-22 04:48:14'),
(247, 1, '/template/create_template', 'undefined', '_2024022101938_467', 'S', 'Success', '2024-01-22 04:49:38', 'Y', '2024-01-22 04:49:38'),
(248, 1, '/template/create_template', 'undefined', '_2024022102551_276', 'S', 'Success', '2024-01-22 04:55:51', 'Y', '2024-01-22 04:55:51'),
(249, 1, '/template/create_template', 'undefined', '_2024022102755_296', 'S', 'Success', '2024-01-22 04:57:55', 'Y', '2024-01-22 04:57:55'),
(250, 1, '/template/create_template', 'undefined', '_2024022102900_176', 'S', 'Success', '2024-01-22 04:59:00', 'Y', '2024-01-22 04:59:00'),
(251, 1, '/template/create_template', 'undefined', '_2024022103104_459', 'S', 'Success', '2024-01-22 05:01:04', 'Y', '2024-01-22 05:01:04'),
(252, 1, '/template/create_template', 'undefined', '_2024022103227_864', 'S', 'Success', '2024-01-22 05:02:27', 'Y', '2024-01-22 05:02:27'),
(253, 1, '/template/create_template', 'undefined', '_2024022103437_302', 'S', 'Success', '2024-01-22 05:04:37', 'Y', '2024-01-22 05:04:37'),
(254, 1, '/template/create_template', 'undefined', '_2024022103551_409', 'S', 'Success', '2024-01-22 05:05:51', 'Y', '2024-01-22 05:05:51'),
(255, 1, '/template/create_template', 'undefined', '_2024022103628_710', 'S', 'Success', '2024-01-22 05:06:28', 'Y', '2024-01-22 05:06:28'),
(256, 1, '/template/create_template', 'undefined', '_2024022104215_784', 'S', 'Success', '2024-01-22 05:12:15', 'Y', '2024-01-22 05:12:15'),
(257, 1, '/template/create_template', 'undefined', '_2024022104820_108', 'S', 'Success', '2024-01-22 05:18:20', 'Y', '2024-01-22 05:18:20'),
(258, 1, '/template/create_template', 'undefined', '_2024022104937_528', 'S', 'Success', '2024-01-22 05:19:37', 'Y', '2024-01-22 05:19:37'),
(259, 1, '/template/create_template', 'undefined', '_2024022105006_834', 'S', 'Success', '2024-01-22 05:20:06', 'Y', '2024-01-22 05:20:06'),
(260, 1, '/template/create_template', 'undefined', '_2024022105335_926', 'S', 'Success', '2024-01-22 05:23:36', 'Y', '2024-01-22 05:23:35'),
(261, 1, '/template/create_template', 'undefined', '_2024022105401_980', 'S', 'Success', '2024-01-22 05:24:01', 'Y', '2024-01-22 05:24:01'),
(262, 1, '/template/create_template', 'undefined', '_2024022105529_479', 'S', 'Success', '2024-01-22 05:25:29', 'Y', '2024-01-22 05:25:29'),
(263, 1, '/template/create_template', 'undefined', '_2024022110323_931', 'S', 'Success', '2024-01-22 05:33:23', 'Y', '2024-01-22 05:33:23'),
(264, 1, '/template/create_template', 'undefined', '_2024022110337_474', 'S', 'Success', '2024-01-22 05:33:37', 'Y', '2024-01-22 05:33:37'),
(265, 1, '/template/create_template', 'undefined', '_2024022110548_473', 'S', 'Success', '2024-01-22 05:35:48', 'Y', '2024-01-22 05:35:48'),
(266, 1, '/template/create_template', 'undefined', '_2024022110916_791', 'S', 'Success', '2024-01-22 05:39:16', 'Y', '2024-01-22 05:39:16'),
(267, 1, '/template/create_template', 'undefined', '_2024022111516_946', 'S', 'Success', '2024-01-22 05:45:16', 'Y', '2024-01-22 05:45:16'),
(268, 1, '/template/create_template', 'undefined', '_2024022112045_222', 'S', 'Success', '2024-01-22 05:50:45', 'Y', '2024-01-22 05:50:45'),
(269, 1, '/template/create_template', 'undefined', '_2024022112212_991', 'S', 'Success', '2024-01-22 05:52:12', 'Y', '2024-01-22 05:52:12'),
(270, 1, '/template/create_template', 'undefined', '_2024022112319_192', 'S', 'Success', '2024-01-22 05:53:19', 'Y', '2024-01-22 05:53:19'),
(271, 1, '/template/create_template', 'undefined', '_2024022112614_186', 'S', 'Success', '2024-01-22 05:56:14', 'Y', '2024-01-22 05:56:14'),
(272, 1, '/template/create_template', 'undefined', '_2024022113236_459', 'S', 'Success', '2024-01-22 06:02:36', 'Y', '2024-01-22 06:02:36'),
(273, 1, '/template/create_template', 'undefined', '_2024022113441_748', 'S', 'Success', '2024-01-22 06:04:42', 'Y', '2024-01-22 06:04:41'),
(274, 1, '/template/create_template', 'undefined', '_2024022113520_684', 'S', 'Success', '2024-01-22 06:05:21', 'Y', '2024-01-22 06:05:20'),
(275, 1, '/template/create_template', 'undefined', '_2024022114536_803', 'S', 'Success', '2024-01-22 06:15:36', 'Y', '2024-01-22 06:15:36'),
(276, 1, '/template/create_template', 'undefined', '_2024022114706_433', 'S', 'Success', '2024-01-22 06:17:06', 'Y', '2024-01-22 06:17:06'),
(277, 1, '/template/create_template', 'undefined', '_2024022114800_298', 'S', 'Success', '2024-01-22 06:18:00', 'Y', '2024-01-22 06:18:00'),
(278, 1, '/template/create_template', 'undefined', '_2024022114924_478', 'S', 'Success', '2024-01-22 06:19:24', 'Y', '2024-01-22 06:19:24'),
(279, 1, '/template/create_template', 'undefined', '_2024022115345_499', 'S', 'Success', '2024-01-22 06:23:45', 'Y', '2024-01-22 06:23:45'),
(280, 1, '/template/create_template', 'undefined', '_2024022115504_308', 'S', 'Success', '2024-01-22 06:25:04', 'Y', '2024-01-22 06:25:04'),
(281, 1, '/template/create_template', 'undefined', '_2024022115555_649', 'S', 'Success', '2024-01-22 06:25:55', 'Y', '2024-01-22 06:25:55'),
(282, 1, '/template/create_template', 'undefined', '_2024022115735_170', 'S', 'Success', '2024-01-22 06:27:35', 'Y', '2024-01-22 06:27:35'),
(283, 1, '/template/create_template', 'undefined', '_2024022120203_668', 'S', 'Success', '2024-01-22 06:32:03', 'Y', '2024-01-22 06:32:03'),
(284, 1, '/template/create_template', 'undefined', '_2024022120258_221', 'S', 'Success', '2024-01-22 06:32:58', 'Y', '2024-01-22 06:32:58'),
(285, 1, '/template/create_template', 'undefined', '_2024022120720_907', 'S', 'Success', '2024-01-22 06:37:20', 'Y', '2024-01-22 06:37:20'),
(286, 1, '/template/create_template', 'undefined', '_2024022120745_933', 'S', 'Success', '2024-01-22 06:37:45', 'Y', '2024-01-22 06:37:45'),
(287, 1, '/template/create_template', 'undefined', '_2024022120850_737', 'S', 'Success', '2024-01-22 06:38:50', 'Y', '2024-01-22 06:38:50'),
(288, 1, '/template/create_template', 'undefined', '_2024022122104_380', 'S', 'Success', '2024-01-22 06:51:04', 'Y', '2024-01-22 06:51:04'),
(289, 1, '/template/create_template', 'undefined', '_2024022122108_667', 'S', 'Success', '2024-01-22 06:51:08', 'Y', '2024-01-22 06:51:08'),
(290, 1, '/template/create_template', 'undefined', '_2024022122253_954', 'S', 'Success', '2024-01-22 06:52:53', 'Y', '2024-01-22 06:52:53'),
(291, 1, '/template/create_template', 'undefined', '_2024022122944_944', 'S', 'Success', '2024-01-22 06:59:44', 'Y', '2024-01-22 06:59:44'),
(292, 1, '/template/create_template', 'undefined', '_2024022123503_793', 'S', 'Success', '2024-01-22 07:05:03', 'Y', '2024-01-22 07:05:03'),
(293, 1, '/template/create_template', 'undefined', '_2024022123725_521', 'S', 'Success', '2024-01-22 07:07:25', 'Y', '2024-01-22 07:07:25'),
(294, 1, '/template/create_template', 'undefined', '_2024022123743_100', 'S', 'Success', '2024-01-22 07:07:43', 'Y', '2024-01-22 07:07:43'),
(295, 1, '/template/create_template', 'undefined', '_2024022123813_232', 'S', 'Success', '2024-01-22 07:08:13', 'Y', '2024-01-22 07:08:13'),
(296, 1, '/template/create_template', 'undefined', '_2024022123827_774', 'S', 'Success', '2024-01-22 07:08:27', 'Y', '2024-01-22 07:08:27'),
(297, 1, '/template/create_template', 'undefined', '_2024022124407_780', 'S', 'Success', '2024-01-22 07:14:07', 'Y', '2024-01-22 07:14:07'),
(298, 1, '/template/create_template', 'undefined', '_2024022124845_155', 'S', 'Success', '2024-01-22 07:18:45', 'Y', '2024-01-22 07:18:45'),
(299, 1, '/template/create_template', 'undefined', '_2024022125042_433', 'S', 'Success', '2024-01-22 07:20:42', 'Y', '2024-01-22 07:20:42'),
(300, 1, '/template/create_template', 'undefined', '_2024022125253_293', 'S', 'Success', '2024-01-22 07:22:53', 'Y', '2024-01-22 07:22:53'),
(301, 1, '/template/create_template', 'undefined', '_2024022125523_905', 'S', 'Success', '2024-01-22 07:25:23', 'Y', '2024-01-22 07:25:23'),
(302, 1, '/template/create_template', 'undefined', '_2024022125609_288', 'S', 'Success', '2024-01-22 07:26:09', 'Y', '2024-01-22 07:26:09'),
(303, 1, '/template/create_template', 'undefined', '_2024022125846_169', 'S', 'Success', '2024-01-22 07:28:46', 'Y', '2024-01-22 07:28:46'),
(304, 1, '/template/create_template', 'undefined', '_2024022125931_395', 'S', 'Success', '2024-01-22 07:29:31', 'Y', '2024-01-22 07:29:31'),
(305, 1, '/template/create_template', 'undefined', '_2024022130042_178', 'S', 'Success', '2024-01-22 07:30:42', 'Y', '2024-01-22 07:30:42'),
(306, 1, '/template/create_template', 'undefined', '_2024022130124_936', 'S', 'Success', '2024-01-22 07:31:24', 'Y', '2024-01-22 07:31:24'),
(307, 1, '/template/create_template', 'undefined', '_2024022130504_796', 'S', 'Success', '2024-01-22 07:35:04', 'Y', '2024-01-22 07:35:04'),
(308, 1, '/template/create_template', 'undefined', '_2024022130717_975', 'S', 'Success', '2024-01-22 07:37:17', 'Y', '2024-01-22 07:37:17'),
(309, 1, '/template/create_template', 'undefined', '_2024022130842_207', 'S', 'Success', '2024-01-22 07:38:42', 'Y', '2024-01-22 07:38:42'),
(310, 1, '/template/create_template', 'undefined', '_2024022130947_686', 'S', 'Success', '2024-01-22 07:39:47', 'Y', '2024-01-22 07:39:47'),
(311, 1, '/template/create_template', 'undefined', '_2024022131156_895', 'S', 'Success', '2024-01-22 07:41:56', 'Y', '2024-01-22 07:41:56'),
(312, 1, '/template/create_template', 'undefined', '_2024022131313_717', 'S', 'Success', '2024-01-22 07:43:13', 'Y', '2024-01-22 07:43:13'),
(313, 1, '/template/create_template', 'undefined', '_2024022131636_206', 'S', 'Success', '2024-01-22 07:46:37', 'Y', '2024-01-22 07:46:36'),
(314, 1, '/template/create_template', 'undefined', '_2024022131853_221', 'S', 'Success', '2024-01-22 07:48:53', 'Y', '2024-01-22 07:48:53'),
(315, 1, '/template/create_template', 'undefined', '_2024022132059_717', 'F', 'Mismatch code', '2024-01-22 07:50:59', 'Y', '2024-01-22 07:50:59'),
(316, 1, '/template/create_template', 'undefined', '_2024022132617_331', 'F', 'Mismatch code', '2024-01-22 07:56:17', 'Y', '2024-01-22 07:56:17'),
(317, 1, '/template/create_template', 'undefined', '_2024022132644_400', 'S', 'Success', '2024-01-22 07:56:44', 'Y', '2024-01-22 07:56:44'),
(318, 1, '/template/create_template', 'undefined', '_2024022132907_350', 'S', 'Success', '2024-01-22 07:59:07', 'Y', '2024-01-22 07:59:07'),
(319, 1, '/template/create_template', 'undefined', '_2024022133212_295', 'S', 'Success', '2024-01-22 08:02:12', 'Y', '2024-01-22 08:02:12'),
(320, 1, '/template/create_template', 'undefined', '_2024022133448_967', 'S', 'Success', '2024-01-22 08:04:48', 'Y', '2024-01-22 08:04:48'),
(321, 1, '/template/create_template', 'undefined', '_2024022133527_957', 'S', 'Success', '2024-01-22 08:05:27', 'Y', '2024-01-22 08:05:27'),
(322, 1, '/template/create_template', 'undefined', '_2024022133617_449', 'S', 'Success', '2024-01-22 08:06:17', 'Y', '2024-01-22 08:06:17'),
(323, 1, '/template/create_template', 'undefined', '_2024022142344_383', 'S', 'Success', '2024-01-22 08:53:44', 'Y', '2024-01-22 08:53:44'),
(324, 1, '/template/create_template', 'undefined', '_2024022142453_496', 'S', 'Success', '2024-01-22 08:54:53', 'Y', '2024-01-22 08:54:53'),
(325, 1, '/template/create_template', 'undefined', '_2024022143624_785', 'S', 'Success', '2024-01-22 09:06:24', 'Y', '2024-01-22 09:06:24'),
(326, 1, '/template/create_template', 'undefined', '_2024022144146_547', 'S', 'Success', '2024-01-22 09:11:46', 'Y', '2024-01-22 09:11:46'),
(327, 1, '/template/create_template', 'undefined', '_2024022151318_278', 'S', 'Success', '2024-01-22 09:43:19', 'Y', '2024-01-22 09:43:18'),
(328, 1, '/template/create_template', 'undefined', '_2024022151417_266', 'S', 'Success', '2024-01-22 09:44:17', 'Y', '2024-01-22 09:44:17'),
(329, 1, '/template/create_template', 'undefined', '_2024022152116_510', 'S', 'Success', '2024-01-22 09:51:16', 'Y', '2024-01-22 09:51:16'),
(330, 1, '/template/create_template', 'undefined', '_2024022152322_965', 'S', 'Success', '2024-01-22 09:53:22', 'Y', '2024-01-22 09:53:22'),
(331, 1, '/template/create_template', 'undefined', '_2024022152337_810', 'S', 'Success', '2024-01-22 09:53:37', 'Y', '2024-01-22 09:53:37'),
(332, 1, '/template/create_template', 'undefined', '_2024022152513_227', 'S', 'Success', '2024-01-22 09:55:13', 'Y', '2024-01-22 09:55:13'),
(333, 1, '/template/create_template', 'undefined', '_2024022152541_392', 'S', 'Success', '2024-01-22 09:55:41', 'Y', '2024-01-22 09:55:41'),
(334, 1, '/template/create_template', 'undefined', '_2024022152845_906', 'S', 'Success', '2024-01-22 09:58:45', 'Y', '2024-01-22 09:58:45'),
(335, 1, '/template/create_template', 'undefined', '_2024022153410_355', 'S', 'Success', '2024-01-22 10:04:10', 'Y', '2024-01-22 10:04:10'),
(336, 1, '/template/create_template', 'undefined', '_2024022153513_273', 'S', 'Success', '2024-01-22 10:05:13', 'Y', '2024-01-22 10:05:13'),
(337, 1, '/template/create_template', 'undefined', '_2024022153711_332', 'S', 'Success', '2024-01-22 10:07:11', 'Y', '2024-01-22 10:07:11'),
(338, 1, '/template/create_template', 'undefined', '_2024022153834_833', 'S', 'Success', '2024-01-22 10:08:34', 'Y', '2024-01-22 10:08:34'),
(339, 1, '/template/create_template', 'undefined', '_2024022154016_341', 'S', 'Success', '2024-01-22 10:10:16', 'Y', '2024-01-22 10:10:16'),
(340, 1, '/template/create_template', 'undefined', '_2024022154043_581', 'S', 'Success', '2024-01-22 10:10:43', 'Y', '2024-01-22 10:10:43'),
(341, 1, '/template/create_template', 'undefined', '_2024022154126_130', 'S', 'Success', '2024-01-22 10:11:26', 'Y', '2024-01-22 10:11:26'),
(342, 1, '/template/create_template', 'undefined', '_2024022154301_952', 'S', 'Success', '2024-01-22 10:13:02', 'Y', '2024-01-22 10:13:01'),
(343, 1, '/template/create_template', 'undefined', '_2024022154444_735', 'S', 'Success', '2024-01-22 10:14:44', 'Y', '2024-01-22 10:14:44'),
(344, 1, '/template/create_template', 'undefined', '_2024022154528_336', 'S', 'Success', '2024-01-22 10:15:28', 'Y', '2024-01-22 10:15:28'),
(345, 1, '/template/create_template', 'undefined', '_2024022154615_882', 'S', 'Success', '2024-01-22 10:16:15', 'Y', '2024-01-22 10:16:15'),
(346, 1, '/template/create_template', 'undefined', '_2024022154715_586', 'S', 'Success', '2024-01-22 10:17:15', 'Y', '2024-01-22 10:17:15'),
(347, 1, '/template/create_template', 'undefined', '_2024022154912_302', 'S', 'Success', '2024-01-22 10:19:12', 'Y', '2024-01-22 10:19:12'),
(348, 1, '/template/create_template', 'undefined', '_2024022155421_558', 'S', 'Success', '2024-01-22 10:24:21', 'Y', '2024-01-22 10:24:21'),
(349, 1, '/template/create_template', 'undefined', '_2024022155454_726', 'S', 'Success', '2024-01-22 10:24:54', 'Y', '2024-01-22 10:24:54'),
(350, 1, '/template/create_template', 'undefined', '_2024022160054_471', 'S', 'Success', '2024-01-22 10:30:54', 'Y', '2024-01-22 10:30:54'),
(351, 1, '/template/create_template', 'undefined', '_2024022160110_143', 'S', 'Success', '2024-01-22 10:31:10', 'Y', '2024-01-22 10:31:10'),
(352, 1, '/template/create_template', 'undefined', '_2024022160247_207', 'S', 'Success', '2024-01-22 10:32:47', 'Y', '2024-01-22 10:32:47'),
(353, 1, '/template/create_template', 'undefined', '_2024022160457_685', 'S', 'Success', '2024-01-22 10:34:57', 'Y', '2024-01-22 10:34:57'),
(354, 1, '/template/create_template', 'undefined', '_2024022160528_800', 'S', 'Success', '2024-01-22 10:35:28', 'Y', '2024-01-22 10:35:28'),
(355, 1, '/template/create_template', 'undefined', '_2024022161157_607', 'S', 'Success', '2024-01-22 10:41:57', 'Y', '2024-01-22 10:41:57'),
(356, 1, '/template/create_template', 'undefined', '_2024022161215_347', 'S', 'Success', '2024-01-22 10:42:15', 'Y', '2024-01-22 10:42:15'),
(357, 1, '/template/create_template', 'undefined', '_2024022161502_400', 'S', 'Success', '2024-01-22 10:45:02', 'Y', '2024-01-22 10:45:02'),
(358, 1, '/template/create_template', 'undefined', '_2024022161630_643', 'S', 'Success', '2024-01-22 10:46:30', 'Y', '2024-01-22 10:46:30'),
(359, 1, '/template/create_template', 'undefined', '_2024022161740_976', 'S', 'Success', '2024-01-22 10:47:40', 'Y', '2024-01-22 10:47:40'),
(360, 1, '/template/create_template', 'undefined', '_2024022161809_877', 'S', 'Success', '2024-01-22 10:48:09', 'Y', '2024-01-22 10:48:09'),
(361, 1, '/template/create_template', 'undefined', '_2024022161902_373', 'S', 'Success', '2024-01-22 10:49:02', 'Y', '2024-01-22 10:49:02'),
(362, 1, '/template/create_template', 'undefined', '_2024022162508_534', 'S', 'Success', '2024-01-22 10:55:08', 'Y', '2024-01-22 10:55:08'),
(363, 1, '/template/create_template', 'undefined', '_2024022162750_372', 'S', 'Success', '2024-01-22 10:57:50', 'Y', '2024-01-22 10:57:50'),
(364, 1, '/template/create_template', 'undefined', '_2024022162903_743', 'S', 'Success', '2024-01-22 10:59:03', 'Y', '2024-01-22 10:59:03'),
(365, 1, '/template/create_template', 'undefined', '_2024022163448_546', 'S', 'Success', '2024-01-22 11:04:48', 'Y', '2024-01-22 11:04:48'),
(366, 1, '/template/create_template', 'undefined', '_2024022163654_529', 'S', 'Success', '2024-01-22 11:06:55', 'Y', '2024-01-22 11:06:54'),
(367, 1, '/template/create_template', 'undefined', '_2024022164451_393', 'S', 'Success', '2024-01-22 11:14:51', 'Y', '2024-01-22 11:14:51'),
(368, 1, '/template/create_template', 'undefined', '_2024022165504_436', 'S', 'Success', '2024-01-22 11:25:04', 'Y', '2024-01-22 11:25:04');
INSERT INTO `api_log` (`api_log_id`, `user_id`, `api_url`, `ip_address`, `request_id`, `response_status`, `response_comments`, `response_date`, `api_log_status`, `api_log_entry_date`) VALUES
(369, 1, '/template/create_template', 'undefined', '_2024022170009_436', 'S', 'Success', '2024-01-22 11:30:09', 'Y', '2024-01-22 11:30:09'),
(370, 1, '/template/create_template', 'undefined', '_2024022170132_498', 'S', 'Success', '2024-01-22 11:31:32', 'Y', '2024-01-22 11:31:32'),
(371, 1, '/template/create_template', 'undefined', '_2024022170934_257', 'S', 'Success', '2024-01-22 11:39:34', 'Y', '2024-01-22 11:39:34'),
(372, 1, '/template/create_template', 'undefined', '_2024022171102_736', 'S', 'Success', '2024-01-22 11:41:02', 'Y', '2024-01-22 11:41:02'),
(373, 1, '/template/create_template', 'undefined', '_2024022173431_565', 'S', 'Success', '2024-01-22 12:04:31', 'Y', '2024-01-22 12:04:31'),
(374, 1, '/template/create_template', 'undefined', '_2024022173534_340', 'S', 'Success', '2024-01-22 12:05:34', 'Y', '2024-01-22 12:05:34'),
(375, 1, '/template/create_template', 'undefined', '_2024022173626_524', 'S', 'Success', '2024-01-22 12:06:26', 'Y', '2024-01-22 12:06:26'),
(376, 1, '/template/create_template', 'undefined', '_2024022174034_975', 'S', 'Success', '2024-01-22 12:10:34', 'Y', '2024-01-22 12:10:34'),
(377, 1, '/template/create_template', 'undefined', '_2024022175010_327', 'S', 'Success', '2024-01-22 12:20:10', 'Y', '2024-01-22 12:20:10'),
(378, 1, '/template/create_template', 'undefined', '_2024022175037_985', 'S', 'Success', '2024-01-22 12:20:37', 'Y', '2024-01-22 12:20:37'),
(379, 1, '/template/create_template', 'undefined', '_2024022175231_289', 'S', 'Success', '2024-01-22 12:22:31', 'Y', '2024-01-22 12:22:31'),
(380, 1, '/template/create_template', 'undefined', '_2024022175311_902', 'S', 'Success', '2024-01-22 12:23:11', 'Y', '2024-01-22 12:23:11'),
(381, 1, '/template/create_template', 'undefined', '_2024022175406_458', 'S', 'Success', '2024-01-22 12:24:07', 'Y', '2024-01-22 12:24:06'),
(382, 1, '/template/create_template', 'undefined', '_2024022175507_724', 'S', 'Success', '2024-01-22 12:25:07', 'Y', '2024-01-22 12:25:07'),
(383, 1, '/template/create_template', 'undefined', '_2024022175715_496', 'S', 'Success', '2024-01-22 12:27:15', 'Y', '2024-01-22 12:27:15'),
(384, 1, '/template/create_template', 'undefined', '_2024022180029_402', 'S', 'Success', '2024-01-22 12:30:29', 'Y', '2024-01-22 12:30:29'),
(385, 1, '/template/create_template', 'undefined', '_2024022180042_578', 'S', 'Success', '2024-01-22 12:30:42', 'Y', '2024-01-22 12:30:42'),
(386, 1, '/template/create_template', 'undefined', '_2024022180106_871', 'S', 'Success', '2024-01-22 12:31:06', 'Y', '2024-01-22 12:31:06'),
(387, 1, '/template/create_template', 'undefined', '_2024022180222_174', 'S', 'Success', '2024-01-22 12:32:22', 'Y', '2024-01-22 12:32:22'),
(388, 1, '/template/create_template', 'undefined', '_2024022180315_940', 'S', 'Success', '2024-01-22 12:33:15', 'Y', '2024-01-22 12:33:15'),
(389, 1, '/template/create_template', 'undefined', '_2024022180433_440', 'S', 'Success', '2024-01-22 12:34:33', 'Y', '2024-01-22 12:34:33'),
(390, 1, '/template/create_template', 'undefined', '_2024022180504_877', 'S', 'Success', '2024-01-22 12:35:04', 'Y', '2024-01-22 12:35:04'),
(391, 1, '/template/create_template', 'undefined', '_2024022180603_382', 'S', 'Success', '2024-01-22 12:36:03', 'Y', '2024-01-22 12:36:03'),
(392, 1, '/template/create_template', 'undefined', '_2024022180711_502', 'S', 'Success', '2024-01-22 12:37:11', 'Y', '2024-01-22 12:37:11'),
(393, 1, '/template/create_template', 'undefined', '_2024022181004_574', 'S', 'Success', '2024-01-22 12:40:04', 'Y', '2024-01-22 12:40:04'),
(394, 1, '/template/create_template', 'undefined', '_2024022181034_953', 'S', 'Success', '2024-01-22 12:40:34', 'Y', '2024-01-22 12:40:34'),
(395, 1, '/template/create_template', 'undefined', '_2024022181243_567', 'S', 'Success', '2024-01-22 12:42:43', 'Y', '2024-01-22 12:42:43'),
(396, 1, '/template/create_template', 'undefined', '_2024022182143_998', 'S', 'Success', '2024-01-22 12:51:43', 'Y', '2024-01-22 12:51:43'),
(397, 1, '/template/create_template', 'undefined', '_2024022182220_587', 'S', 'Success', '2024-01-22 12:52:20', 'Y', '2024-01-22 12:52:20'),
(398, 1, '/template/create_template', 'undefined', '_2024022182354_118', 'S', 'Success', '2024-01-22 12:53:54', 'Y', '2024-01-22 12:53:54'),
(399, 1, '/template/create_template', 'undefined', '_2024022182534_206', 'S', 'Success', '2024-01-22 12:55:34', 'Y', '2024-01-22 12:55:34'),
(400, 1, '/template/create_template', 'undefined', '_2024022182547_641', 'S', 'Success', '2024-01-22 12:55:47', 'Y', '2024-01-22 12:55:47'),
(401, 1, '/template/create_template', 'undefined', '_2024022183624_829', 'S', 'Success', '2024-01-22 13:06:24', 'Y', '2024-01-22 13:06:24'),
(402, 1, '/template/create_template', 'undefined', '_2024022183910_374', 'S', 'Success', '2024-01-22 13:09:10', 'Y', '2024-01-22 13:09:10'),
(403, 1, '/template/create_template', 'undefined', '_2024022183931_471', 'S', 'Success', '2024-01-22 13:09:31', 'Y', '2024-01-22 13:09:31'),
(404, 1, '/template/create_template', 'undefined', '_2024022184053_948', 'S', 'Success', '2024-01-22 13:10:53', 'Y', '2024-01-22 13:10:53'),
(405, 1, '/template/create_template', 'undefined', '_2024022184556_580', 'S', 'Success', '2024-01-22 13:15:56', 'Y', '2024-01-22 13:15:56'),
(406, 1, '/template/create_template', 'undefined', '_2024022185244_751', 'S', 'Success', '2024-01-22 13:22:45', 'Y', '2024-01-22 13:22:44'),
(407, 1, '/template/create_template', 'undefined', '_2024022185425_810', 'S', 'Success', '2024-01-22 13:24:25', 'Y', '2024-01-22 13:24:25'),
(408, 1, '/template/create_template', 'undefined', '_2024022185520_171', 'S', 'Success', '2024-01-22 13:25:20', 'Y', '2024-01-22 13:25:20'),
(409, 1, '/template/create_template', 'undefined', '_2024022185808_854', 'S', 'Success', '2024-01-22 13:28:08', 'Y', '2024-01-22 13:28:08'),
(410, 1, '/template/create_template', 'undefined', '_2024022185916_304', 'S', 'Success', '2024-01-22 13:29:16', 'Y', '2024-01-22 13:29:16'),
(411, 1, '/template/create_template', 'undefined', '_2024022190014_862', 'S', 'Success', '2024-01-22 13:30:14', 'Y', '2024-01-22 13:30:14'),
(412, 1, '/template/create_template', 'undefined', '_2024022190143_159', 'S', 'Success', '2024-01-22 13:31:43', 'Y', '2024-01-22 13:31:43'),
(413, 1, '/template/create_template', 'undefined', '_2024022190450_839', 'S', 'Success', '2024-01-22 13:34:50', 'Y', '2024-01-22 13:34:50'),
(414, 1, '/template/create_template', 'undefined', '_2024022190741_901', 'S', 'Success', '2024-01-22 13:37:41', 'Y', '2024-01-22 13:37:41'),
(415, 1, '/template/create_template', 'undefined', '_2024022204724_490', 'S', 'Success', '2024-01-22 15:17:25', 'Y', '2024-01-22 15:17:24'),
(416, 1, '/template/create_template', 'undefined', '_2024022204753_821', 'S', 'Success', '2024-01-22 15:17:53', 'Y', '2024-01-22 15:17:53'),
(417, 1, '/template/create_template', 'undefined', '_2024022210128_757', 'S', 'Success', '2024-01-22 15:31:28', 'Y', '2024-01-22 15:31:28'),
(418, 1, '/template/create_template', 'undefined', '_2024022210818_705', 'S', 'Success', '2024-01-22 15:38:18', 'Y', '2024-01-22 15:38:18'),
(419, 1, '/template/create_template', 'undefined', '_2024022211053_178', 'S', 'Success', '2024-01-22 15:40:53', 'Y', '2024-01-22 15:40:53'),
(420, 1, '/template/create_template', 'undefined', '_2024022211203_168', 'S', 'Success', '2024-01-22 15:42:03', 'Y', '2024-01-22 15:42:03'),
(421, 1, '/template/create_template', 'undefined', '_2024022212133_254', 'S', 'Success', '2024-01-22 15:51:33', 'Y', '2024-01-22 15:51:33'),
(422, 1, '/template/create_template', 'undefined', '_2024022212241_771', 'S', 'Success', '2024-01-22 15:52:41', 'Y', '2024-01-22 15:52:41'),
(423, 1, '/template/create_template', 'undefined', '_2024022212316_759', 'S', 'Success', '2024-01-22 15:53:16', 'Y', '2024-01-22 15:53:16'),
(424, 1, '/template/create_template', 'undefined', '_2024022212440_953', 'S', 'Success', '2024-01-22 15:54:40', 'Y', '2024-01-22 15:54:40'),
(425, 1, '/template/create_template', 'undefined', '_2024022212505_897', 'S', 'Success', '2024-01-22 15:55:05', 'Y', '2024-01-22 15:55:05'),
(426, 1, '/template/create_template', 'undefined', '_2024022220157_303', 'S', 'Success', '2024-01-22 16:31:57', 'Y', '2024-01-22 16:31:57'),
(427, 1, '/template/create_template', 'undefined', '_2024022220706_246', 'S', 'Success', '2024-01-22 16:37:06', 'Y', '2024-01-22 16:37:06'),
(428, 1, '/template/create_template', 'undefined', '_2024022220815_406', 'S', 'Success', '2024-01-22 16:38:15', 'Y', '2024-01-22 16:38:15'),
(429, 1, '/template/create_template', 'undefined', '_2024022220846_429', 'S', 'Success', '2024-01-22 16:38:46', 'Y', '2024-01-22 16:38:46'),
(430, 1, '/template/create_template', 'undefined', '_2024022220921_864', 'S', 'Success', '2024-01-22 16:39:21', 'Y', '2024-01-22 16:39:21'),
(431, 1, '/template/create_template', 'undefined', '_2024022221135_638', 'S', 'Success', '2024-01-22 16:41:35', 'Y', '2024-01-22 16:41:35'),
(432, 1, '/template/create_template', 'undefined', '_2024022221205_980', 'S', 'Success', '2024-01-22 16:42:05', 'Y', '2024-01-22 16:42:05'),
(433, 1, '/template/create_template', 'undefined', '_2024022221614_792', 'S', 'Success', '2024-01-22 16:46:14', 'Y', '2024-01-22 16:46:14'),
(434, 1, '/template/create_template', 'undefined', '_2024022221916_766', 'S', 'Success', '2024-01-22 16:49:17', 'Y', '2024-01-22 16:49:16'),
(435, 1, '/template/create_template', 'undefined', '_2024022222031_863', 'S', 'Success', '2024-01-22 16:50:31', 'Y', '2024-01-22 16:50:31'),
(436, 1, '/template/create_template', 'undefined', '_2024022222145_305', 'S', 'Success', '2024-01-22 16:51:45', 'Y', '2024-01-22 16:51:45'),
(437, 1, '/template/create_template', 'undefined', '_2024022222301_432', 'S', 'Success', '2024-01-22 16:53:02', 'Y', '2024-01-22 16:53:01'),
(438, 1, '/template/create_template', 'undefined', '_2024022222541_864', 'S', 'Success', '2024-01-22 16:55:41', 'Y', '2024-01-22 16:55:41'),
(439, 1, '/template/create_template', 'undefined', '_2024022222659_462', 'S', 'Success', '2024-01-22 16:56:59', 'Y', '2024-01-22 16:56:59'),
(440, 1, '/template/create_template', 'undefined', '_2024022222758_200', 'S', 'Success', '2024-01-22 16:57:58', 'Y', '2024-01-22 16:57:58'),
(441, 1, '/template/create_template', 'undefined', '_2024022222820_680', 'S', 'Success', '2024-01-22 16:58:20', 'Y', '2024-01-22 16:58:20'),
(442, 1, '/template/create_template', 'undefined', '_2024022222922_246', 'S', 'Success', '2024-01-22 16:59:22', 'Y', '2024-01-22 16:59:22'),
(443, 1, '/template/create_template', 'undefined', '_2024022223622_611', 'S', 'Success', '2024-01-22 17:06:22', 'Y', '2024-01-22 17:06:22'),
(444, 1, '/template/create_template', 'undefined', '_2024022223702_686', 'S', 'Success', '2024-01-22 17:07:02', 'Y', '2024-01-22 17:07:02'),
(445, 1, '/template/create_template', 'undefined', '_2024022223729_330', 'S', 'Success', '2024-01-22 17:07:29', 'Y', '2024-01-22 17:07:29'),
(446, 1, '/template/create_template', 'undefined', '_2024022224107_245', 'S', 'Success', '2024-01-22 17:11:07', 'Y', '2024-01-22 17:11:07'),
(447, 1, '/template/create_template', 'undefined', '_2024022224332_552', 'S', 'Success', '2024-01-22 17:13:32', 'Y', '2024-01-22 17:13:32'),
(448, 1, '/template/create_template', 'undefined', '_2024022224503_900', 'S', 'Success', '2024-01-22 17:15:03', 'Y', '2024-01-22 17:15:03'),
(449, 1, '/template/create_template', 'undefined', '_2024022225728_539', 'S', 'Success', '2024-01-22 17:27:28', 'Y', '2024-01-22 17:27:28'),
(450, 1, '/template/create_template', 'undefined', '_2024022230019_271', 'S', 'Success', '2024-01-22 17:30:19', 'Y', '2024-01-22 17:30:19'),
(451, 1, '/template/create_template', 'undefined', '_2024022230104_654', 'S', 'Success', '2024-01-22 17:31:04', 'Y', '2024-01-22 17:31:04'),
(452, 1, '/template/create_template', 'undefined', '_2024022230232_948', 'S', 'Success', '2024-01-22 17:32:32', 'Y', '2024-01-22 17:32:32'),
(453, 1, '/template/create_template', 'undefined', '_2024022230338_172', 'S', 'Success', '2024-01-22 17:33:38', 'Y', '2024-01-22 17:33:38'),
(454, 1, '/template/create_template', 'undefined', '_2024022230534_299', 'S', 'Success', '2024-01-22 17:35:34', 'Y', '2024-01-22 17:35:34'),
(455, 1, '/template/create_template', 'undefined', '_2024022230603_243', 'S', 'Success', '2024-01-22 17:36:03', 'Y', '2024-01-22 17:36:03'),
(456, 1, '/template/create_template', 'undefined', '_2024022230703_122', 'S', 'Success', '2024-01-22 17:37:03', 'Y', '2024-01-22 17:37:03'),
(457, 1, '/template/create_template', 'undefined', '_2024022230915_190', 'S', 'Success', '2024-01-22 17:39:15', 'Y', '2024-01-22 17:39:15'),
(458, 1, '/template/create_template', 'undefined', '_2024023070536_135', 'S', 'Success', '2024-01-23 01:35:36', 'Y', '2024-01-23 01:35:36'),
(459, 1, '/template/create_template', 'undefined', '_2024023070619_755', 'S', 'Success', '2024-01-23 01:36:19', 'Y', '2024-01-23 01:36:19'),
(460, 1, '/template/create_template', 'undefined', '_2024023070654_737', 'S', 'Success', '2024-01-23 01:36:54', 'Y', '2024-01-23 01:36:54'),
(461, 1, '/template/create_template', 'undefined', '_2024023071049_432', 'S', 'Success', '2024-01-23 01:40:49', 'Y', '2024-01-23 01:40:49'),
(462, 1, '/template/create_template', 'undefined', '_2024023071134_918', 'S', 'Success', '2024-01-23 01:41:34', 'Y', '2024-01-23 01:41:34'),
(463, 1, '/template/create_template', 'undefined', '_2024023071249_576', 'S', 'Success', '2024-01-23 01:42:50', 'Y', '2024-01-23 01:42:49'),
(464, 1, '/template/create_template', 'undefined', '_2024023071311_770', 'S', 'Success', '2024-01-23 01:43:11', 'Y', '2024-01-23 01:43:11'),
(465, 1, '/template/create_template', 'undefined', '_2024023071503_307', 'S', 'Success', '2024-01-23 01:45:03', 'Y', '2024-01-23 01:45:03'),
(466, 1, '/template/create_template', 'undefined', '_2024023071530_633', 'S', 'Success', '2024-01-23 01:45:30', 'Y', '2024-01-23 01:45:30'),
(467, 1, '/template/create_template', 'undefined', '_2024023071552_280', 'S', 'Success', '2024-01-23 01:45:52', 'Y', '2024-01-23 01:45:52'),
(468, 1, '/template/create_template', 'undefined', '_2024023071611_734', 'S', 'Success', '2024-01-23 01:46:11', 'Y', '2024-01-23 01:46:11'),
(469, 1, '/template/create_template', 'undefined', '_2024023072149_556', 'S', 'Success', '2024-01-23 01:51:49', 'Y', '2024-01-23 01:51:49'),
(470, 1, '/template/create_template', 'undefined', '_2024023072316_824', 'S', 'Success', '2024-01-23 01:53:16', 'Y', '2024-01-23 01:53:16'),
(471, 1, '/template/create_template', 'undefined', '_2024023072335_533', 'S', 'Success', '2024-01-23 01:53:36', 'Y', '2024-01-23 01:53:35'),
(472, 1, '/template/create_template', 'undefined', '_2024023072855_660', 'S', 'Success', '2024-01-23 01:58:55', 'Y', '2024-01-23 01:58:55'),
(473, 1, '/template/create_template', 'undefined', '_2024023072912_540', 'S', 'Success', '2024-01-23 01:59:12', 'Y', '2024-01-23 01:59:12'),
(474, 1, '/template/create_template', 'undefined', '_2024023073037_594', 'S', 'Success', '2024-01-23 02:00:37', 'Y', '2024-01-23 02:00:37'),
(475, 1, '/template/create_template', 'undefined', '_2024023073059_365', 'S', 'Success', '2024-01-23 02:00:59', 'Y', '2024-01-23 02:00:59'),
(476, 1, '/template/create_template', 'undefined', '_2024023073140_918', 'S', 'Success', '2024-01-23 02:01:41', 'Y', '2024-01-23 02:01:41'),
(477, 1, '/template/create_template', 'undefined', '_2024023073219_202', 'S', 'Success', '2024-01-23 02:02:19', 'Y', '2024-01-23 02:02:19'),
(478, 1, '/template/create_template', 'undefined', '_2024023073419_309', 'S', 'Success', '2024-01-23 02:04:19', 'Y', '2024-01-23 02:04:19'),
(479, 1, '/template/create_template', 'undefined', '_2024023073838_831', 'S', 'Success', '2024-01-23 02:08:38', 'Y', '2024-01-23 02:08:38'),
(480, 1, '/template/create_template', 'undefined', '_2024023073852_783', 'S', 'Success', '2024-01-23 02:08:52', 'Y', '2024-01-23 02:08:52'),
(481, 1, '/template/create_template', 'undefined', '_2024023073917_131', 'S', 'Success', '2024-01-23 02:09:17', 'Y', '2024-01-23 02:09:17'),
(482, 1, '/template/create_template', 'undefined', '_2024023073939_818', 'S', 'Success', '2024-01-23 02:09:39', 'Y', '2024-01-23 02:09:39'),
(483, 1, '/template/create_template', 'undefined', '_2024023074011_350', 'S', 'Success', '2024-01-23 02:10:11', 'Y', '2024-01-23 02:10:11'),
(484, 1, '/template/create_template', 'undefined', '_2024023074101_456', 'S', 'Success', '2024-01-23 02:11:01', 'Y', '2024-01-23 02:11:01'),
(485, 1, '/template/create_template', 'undefined', '_2024023074411_655', 'S', 'Success', '2024-01-23 02:14:12', 'Y', '2024-01-23 02:14:11'),
(486, 1, '/template/create_template', 'undefined', '_2024023074538_521', 'S', 'Success', '2024-01-23 02:15:39', 'Y', '2024-01-23 02:15:38'),
(487, 1, '/template/create_template', 'undefined', '_2024023074808_821', 'S', 'Success', '2024-01-23 02:18:08', 'Y', '2024-01-23 02:18:08'),
(488, 1, '/template/create_template', 'undefined', '_2024023074924_866', 'S', 'Success', '2024-01-23 02:19:25', 'Y', '2024-01-23 02:19:24'),
(489, 1, '/template/create_template', 'undefined', '_2024023074943_425', 'S', 'Success', '2024-01-23 02:19:44', 'Y', '2024-01-23 02:19:43'),
(490, 1, '/template/create_template', 'undefined', '_2024023074956_209', 'S', 'Success', '2024-01-23 02:19:56', 'Y', '2024-01-23 02:19:56'),
(491, 1, '/template/create_template', 'undefined', '_2024023075019_827', 'S', 'Success', '2024-01-23 02:20:19', 'Y', '2024-01-23 02:20:19'),
(492, 1, '/template/create_template', 'undefined', '_2024023075051_113', 'S', 'Success', '2024-01-23 02:20:51', 'Y', '2024-01-23 02:20:51'),
(493, 1, '/template/create_template', 'undefined', '_2024023081304_934', 'S', 'Success', '2024-01-23 02:43:04', 'Y', '2024-01-23 02:43:04'),
(494, 1, '/template/create_template', 'undefined', '_2024023081342_723', 'S', 'Success', '2024-01-23 02:43:42', 'Y', '2024-01-23 02:43:42'),
(495, 1, '/template/create_template', 'undefined', '_2024023081453_192', 'S', 'Success', '2024-01-23 02:44:53', 'Y', '2024-01-23 02:44:53'),
(496, 1, '/template/create_template', 'undefined', '_2024023081528_529', 'S', 'Success', '2024-01-23 02:45:28', 'Y', '2024-01-23 02:45:28'),
(497, 1, '/template/create_template', 'undefined', '_2024023081754_543', 'S', 'Success', '2024-01-23 02:47:54', 'Y', '2024-01-23 02:47:54'),
(498, 1, '/template/create_template', 'undefined', '_2024023082018_525', 'S', 'Success', '2024-01-23 02:50:18', 'Y', '2024-01-23 02:50:18'),
(499, 1, '/template/create_template', 'undefined', '_2024023082648_322', 'S', 'Success', '2024-01-23 02:56:48', 'Y', '2024-01-23 02:56:48'),
(500, 1, '/template/create_template', 'undefined', '_2024023083510_379', 'S', 'Success', '2024-01-23 03:05:10', 'Y', '2024-01-23 03:05:10'),
(501, 1, '/template/create_template', 'undefined', '_2024023083618_478', 'S', 'Success', '2024-01-23 03:06:18', 'Y', '2024-01-23 03:06:18'),
(502, 1, '/template/create_template', 'undefined', '_2024023083733_327', 'S', 'Success', '2024-01-23 03:07:33', 'Y', '2024-01-23 03:07:33'),
(503, 1, '/template/create_template', 'undefined', '_2024023083915_591', 'S', 'Success', '2024-01-23 03:09:16', 'Y', '2024-01-23 03:09:16'),
(504, 1, '/template/create_template', 'undefined', '_2024023084144_367', 'S', 'Success', '2024-01-23 03:11:44', 'Y', '2024-01-23 03:11:44'),
(505, 1, '/template/create_template', 'undefined', '_2024023084311_680', 'S', 'Success', '2024-01-23 03:13:11', 'Y', '2024-01-23 03:13:11'),
(506, 1, '/template/create_template', 'undefined', '_2024023084556_927', 'S', 'Success', '2024-01-23 03:15:56', 'Y', '2024-01-23 03:15:56'),
(507, 1, '/template/create_template', 'undefined', '_2024023084607_332', 'S', 'Success', '2024-01-23 03:16:07', 'Y', '2024-01-23 03:16:07'),
(508, 1, '/template/create_template', 'undefined', '_2024023084628_896', 'S', 'Success', '2024-01-23 03:16:28', 'Y', '2024-01-23 03:16:28'),
(509, 1, '/template/create_template', 'undefined', '_2024023084641_761', 'S', 'Success', '2024-01-23 03:16:41', 'Y', '2024-01-23 03:16:41'),
(510, 1, '/template/create_template', 'undefined', '_2024023084718_111', 'S', 'Success', '2024-01-23 03:17:18', 'Y', '2024-01-23 03:17:18'),
(511, 1, '/template/create_template', 'undefined', '_2024023085031_892', 'S', 'Success', '2024-01-23 03:20:31', 'Y', '2024-01-23 03:20:31'),
(512, 1, '/template/create_template', 'undefined', '_2024023085129_826', 'S', 'Success', '2024-01-23 03:21:29', 'Y', '2024-01-23 03:21:29'),
(513, 1, '/template/create_template', 'undefined', '_2024023085157_699', 'S', 'Success', '2024-01-23 03:21:57', 'Y', '2024-01-23 03:21:57'),
(514, 1, '/template/create_template', 'undefined', '_2024023085216_215', 'S', 'Success', '2024-01-23 03:22:17', 'Y', '2024-01-23 03:22:16'),
(515, 1, '/template/create_template', 'undefined', '_2024023085243_919', 'S', 'Success', '2024-01-23 03:22:43', 'Y', '2024-01-23 03:22:43'),
(516, 1, '/template/create_template', 'undefined', '_2024023085325_933', 'S', 'Success', '2024-01-23 03:23:25', 'Y', '2024-01-23 03:23:25'),
(517, 1, '/template/create_template', 'undefined', '_2024023085345_419', 'S', 'Success', '2024-01-23 03:23:45', 'Y', '2024-01-23 03:23:45'),
(518, 1, '/template/create_template', 'undefined', '_2024023090228_939', 'S', 'Success', '2024-01-23 03:32:28', 'Y', '2024-01-23 03:32:28'),
(519, 1, '/template/create_template', 'undefined', '_2024023090248_723', 'S', 'Success', '2024-01-23 03:32:48', 'Y', '2024-01-23 03:32:48'),
(520, 1, '/template/create_template', 'undefined', '_2024023090319_235', 'S', 'Success', '2024-01-23 03:33:19', 'Y', '2024-01-23 03:33:19'),
(521, 1, '/template/create_template', 'undefined', '_2024023090408_979', 'S', 'Success', '2024-01-23 03:34:08', 'Y', '2024-01-23 03:34:08'),
(522, 1, '/template/create_template', 'undefined', '_2024023090621_222', 'S', 'Success', '2024-01-23 03:36:21', 'Y', '2024-01-23 03:36:21'),
(523, 1, '/template/create_template', 'undefined', '_2024023090647_996', 'S', 'Success', '2024-01-23 03:36:47', 'Y', '2024-01-23 03:36:47'),
(524, 1, '/template/create_template', 'undefined', '_2024023090714_187', 'S', 'Success', '2024-01-23 03:37:14', 'Y', '2024-01-23 03:37:14'),
(525, 1, '/template/create_template', 'undefined', '_2024023090938_881', 'S', 'Success', '2024-01-23 03:39:38', 'Y', '2024-01-23 03:39:38'),
(526, 1, '/template/create_template', 'undefined', '_2024023091055_956', 'S', 'Success', '2024-01-23 03:40:55', 'Y', '2024-01-23 03:40:55'),
(527, 1, '/template/create_template', 'undefined', '_2024023091222_463', 'S', 'Success', '2024-01-23 03:42:23', 'Y', '2024-01-23 03:42:23'),
(528, 1, '/template/create_template', 'undefined', '_2024023091259_755', 'S', 'Success', '2024-01-23 03:42:59', 'Y', '2024-01-23 03:42:59'),
(529, 1, '/template/create_template', 'undefined', '_2024023091553_598', 'S', 'Success', '2024-01-23 03:45:53', 'Y', '2024-01-23 03:45:53'),
(530, 1, '/template/create_template', 'undefined', '_2024023091643_739', 'S', 'Success', '2024-01-23 03:46:43', 'Y', '2024-01-23 03:46:43'),
(531, 1, '/template/create_template', 'undefined', '_2024023110946_350', 'S', 'Success', '2024-01-23 05:39:46', 'Y', '2024-01-23 05:39:46'),
(532, 0, 'jnde', 'dm ', '23897', 'F', 'Token is required', '2024-01-23 07:00:21', 'Y', '2024-01-23 07:00:21'),
(535, 0, '/login', 'undefined', '86408247_76824715', 'S', 'Success', '2024-01-24 10:31:47', 'Y', '2024-01-24 10:31:47'),
(536, 1, '/sender_id/add_sender_id', 'undefined', '1_202423160219_3057', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-24 10:32:19'),
(537, 1, '/sender_id/add_sender_id', 'undefined', '1_202423160311_7895', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-24 10:33:11'),
(538, 1, '/sender_id/add_sender_id', 'undefined', '1_202423160312_8220', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-24 10:33:12'),
(539, 1, '/sender_id/add_sender_id', 'undefined', '1_202423160419_7988', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-24 10:34:19'),
(540, 1, '/sender_id/add_sender_id', 'undefined', '1_202423160448_7404', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-24 10:34:48'),
(541, 1, '/sender_id/add_sender_id', 'undefined', '1_202423160608_5873', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-24 10:36:08'),
(542, 1, '/sender_id/add_sender_id', 'undefined', '1_202423161049_3415', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-24 10:40:49'),
(543, 0, '/login', 'undefined', '86966052_96972819', 'S', 'Success', '2024-01-25 10:54:10', 'Y', '2024-01-25 10:54:10'),
(544, 1, '/sender_id/add_sender_id', 'undefined', '1_202424162451_4295', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 10:54:51'),
(545, 1, '/sender_id/add_sender_id', 'undefined', '1_202424162652_6664', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 10:56:52'),
(546, 1, '/sender_id/add_sender_id', 'undefined', '1_202424162816_9471', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 10:58:16'),
(547, 1, '/sender_id/add_sender_id', 'undefined', '1_202424162947_4341', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 10:59:47'),
(548, 1, '/sender_id/add_sender_id', 'undefined', '1_202424163136_8326', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 11:01:36'),
(549, 1, '/sender_id/add_sender_id', 'undefined', '1_202424163414_6461', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 11:04:14'),
(550, 1, '/sender_id/add_sender_id', 'undefined', '1_202424163725_8228', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 11:07:25'),
(551, 1, '/sender_id/add_sender_id', 'undefined', '1_202424164126_6162', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 11:11:26'),
(552, 1, '/sender_id/add_sender_id', 'undefined', '1_202424164454_5873', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 11:14:54'),
(553, 0, '/login', 'undefined', '91321750_53225278', 'S', 'Success', '2024-01-25 11:35:21', 'Y', '2024-01-25 11:35:21'),
(554, 1, '/sender_id/add_sender_id', 'undefined', '1_202424170606_3189', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 11:36:06'),
(555, 0, '/login', 'undefined', '69521401_98926427', 'S', 'Success', '2024-01-25 11:42:25', 'Y', '2024-01-25 11:42:24'),
(556, 1, '/sender_id/add_sender_id', 'undefined', '1_202424171255_2731', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 11:42:55'),
(557, 1, '/sender_id/add_sender_id', 'undefined', '1_202424171455_1708', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 11:44:56'),
(558, 1, '/sender_id/add_sender_id', 'undefined', '1_202424171605_6792', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 11:46:05'),
(559, 1, '/sender_id/add_sender_id', 'undefined', '1_202424171853_2882', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 11:48:53'),
(560, 0, '/login', 'undefined', '10447611_52810472', 'S', 'Success', '2024-01-25 12:11:55', 'Y', '2024-01-25 12:11:55'),
(561, 1, '/sender_id/add_sender_id', 'undefined', '1_202424174238_2630', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:12:38'),
(562, 1, '/sender_id/add_sender_id', 'undefined', '1_202424175840_4774', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:28:40'),
(563, 1, '/sender_id/add_sender_id', 'undefined', '1_202424175913_4129', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:29:14'),
(564, 1, '/sender_id/add_sender_id', 'undefined', '1_202424175914_5400', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:29:14'),
(565, 1, '/sender_id/add_sender_id', 'undefined', '1_202424175914_2908', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:29:14'),
(566, 1, '/sender_id/add_sender_id', 'undefined', '1_202424175915_6524', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:29:15'),
(567, 1, '/sender_id/add_sender_id', 'undefined', '1_202424175915_5594', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:29:15'),
(568, 1, '/sender_id/add_sender_id', 'undefined', '1_202424175915_5285', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:29:15'),
(569, 1, '/sender_id/add_sender_id', 'undefined', '1_202424175915_6916', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:29:15'),
(570, 1, '/sender_id/add_sender_id', 'undefined', '1_202424175915_1125', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:29:15'),
(571, 1, '/sender_id/add_sender_id', 'undefined', '1_202424175915_1710', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:29:15'),
(572, 1, '/sender_id/add_sender_id', 'undefined', '1_202424175916_9333', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:29:16'),
(573, 1, '/sender_id/add_sender_id', 'undefined', '1_202424175916_4709', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:29:16'),
(574, 1, '/sender_id/add_sender_id', 'undefined', '1_202424175916_1146', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:29:16'),
(575, 1, '/sender_id/add_sender_id', 'undefined', '1_202424175916_5444', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:29:16'),
(576, 1, '/sender_id/add_sender_id', 'undefined', '1_202424180137_4056', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:31:37'),
(577, 1, '/sender_id/add_sender_id', 'undefined', '1_202424180320_6331', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:33:20'),
(578, 1, '/sender_id/add_sender_id', 'undefined', '1_202424180520_4872', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:35:21'),
(579, 1, '/sender_id/add_sender_id', 'undefined', '1_202424180646_8198', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:36:46'),
(580, 1, '/sender_id/add_sender_id', 'undefined', '1_202424181057_6035', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:40:57'),
(581, 1, '/sender_id/add_sender_id', 'undefined', '1_202424182004_9801', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:50:04'),
(582, 1, '/sender_id/add_sender_id', 'undefined', '1_202424182716_3110', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:57:16'),
(583, 1, '/sender_id/add_sender_id', 'undefined', '1_202424182916_4865', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-01-25 12:59:16'),
(584, 0, '/login', 'undefined', '14552931_44760682', 'S', 'Success', '2024-01-25 13:23:59', 'Y', '2024-01-25 13:23:59'),
(585, 1, '/sender_id/add_sender_id', 'undefined', '1_202424190030_9369', 'S', 'Success', '2024-01-25 13:30:53', 'Y', '2024-01-25 13:30:30'),
(586, 1, '/sender_id/add_sender_id', 'undefined', '1_202424191303_6298', 'F', 'QRcode already scanned', '2024-01-25 13:43:03', 'Y', '2024-01-25 13:43:03'),
(587, 1, '/sender_id/add_sender_id', 'undefined', '1_202424191358_6698', 'S', 'Success', '2024-01-25 13:44:27', 'Y', '2024-01-25 13:43:58'),
(588, 1, '/sender_id/add_sender_id', 'undefined', '1_202424194433_8871', 'S', 'Success', '2024-01-25 14:14:46', 'Y', '2024-01-25 14:14:33'),
(589, 1, '/sender_id/add_sender_id', 'undefined', '1_202424194658_6304', 'S', 'Success', '2024-01-25 14:17:10', 'Y', '2024-01-25 14:16:58'),
(590, 1, '/sender_id/add_sender_id', 'undefined', '1_202424230041_6231', 'S', 'Success', '2024-01-25 17:30:59', 'Y', '2024-01-25 17:30:41'),
(591, 1, '/sender_id/add_sender_id', 'undefined', '1_202424230242_2106', 'S', 'Success', '2024-01-25 17:32:52', 'Y', '2024-01-25 17:32:42'),
(592, 1, '/sender_id/add_sender_id', 'undefined', '1_202424230441_7499', 'S', 'Success', '2024-01-25 17:34:55', 'Y', '2024-01-25 17:34:41'),
(593, 1, '/sender_id/add_sender_id', 'undefined', '1_202424230455_4333', 'S', 'Success', '2024-01-25 17:35:09', 'Y', '2024-01-25 17:34:55'),
(594, 1, '/sender_id/add_sender_id', 'undefined', '1_202425070020_2155', 'S', 'Success', '2024-01-26 01:30:32', 'Y', '2024-01-26 01:30:20'),
(595, 1, '/group/create_group', 'undefined', '1_202425070158_4825', 'S', 'Success', '2024-01-26 01:33:57', 'Y', '2024-01-26 01:31:58'),
(596, 1, '/group/add_members', 'undefined', '1_202425070440_9046', 'S', 'Success', '2024-01-26 01:36:01', 'Y', '2024-01-26 01:34:40'),
(597, 1, '/group/add_members', 'undefined', '1_202425070631_5609', 'S', 'Success', '2024-01-26 01:36:59', 'Y', '2024-01-26 01:36:31'),
(598, 1, '/sender_id/add_sender_id', 'undefined', '1_202425075638_7977', 'S', 'Success', '2024-01-26 02:26:48', 'Y', '2024-01-26 02:26:38'),
(599, 1, '/sender_id/add_sender_id', 'undefined', '1_202425080004_7226', 'S', 'Success', '2024-01-26 02:30:15', 'Y', '2024-01-26 02:30:04'),
(600, 1, '/template/create_template', 'undefined', '_2024026085533_545', 'S', 'Success', '2024-01-26 03:25:33', 'Y', '2024-01-26 03:25:33'),
(601, 1, '/template/create_template', 'undefined', '_2024026090340_528', 'S', 'Success', '2024-01-26 03:33:40', 'Y', '2024-01-26 03:33:40'),
(602, 1, '/template/create_template', 'undefined', '_2024026090555_498', 'S', 'Success', '2024-01-26 03:35:55', 'Y', '2024-01-26 03:35:55'),
(603, 1, '/template/create_template', 'undefined', '_2024026090652_737', 'S', 'Success', '2024-01-26 03:36:52', 'Y', '2024-01-26 03:36:52'),
(604, 1, '/template/create_template', 'undefined', '_2024026090835_706', 'S', 'Success', '2024-01-26 03:38:35', 'Y', '2024-01-26 03:38:35'),
(605, 1, '/template/create_template', 'undefined', '_2024026090921_885', 'S', 'Success', '2024-01-26 03:39:21', 'Y', '2024-01-26 03:39:21'),
(606, 1, '/template/create_template', 'undefined', '_2024026091203_663', 'S', 'Success', '2024-01-26 03:42:03', 'Y', '2024-01-26 03:42:03'),
(607, 1, '/template/create_template', 'undefined', '_2024026093505_171', 'S', 'Success', '2024-01-26 04:05:05', 'Y', '2024-01-26 04:05:05'),
(608, 1, '/template/create_template', 'undefined', '_2024026093625_454', 'S', 'Success', '2024-01-26 04:06:26', 'Y', '2024-01-26 04:06:25'),
(609, 1, '/template/create_template', 'undefined', '_2024026093647_229', 'S', 'Success', '2024-01-26 04:06:47', 'Y', '2024-01-26 04:06:47'),
(610, 0, '/login', 'undefined', '40093712_10247539', 'S', 'Success', '2024-01-27 06:08:39', 'Y', '2024-01-27 06:08:39'),
(611, 0, '/login', 'undefined', '28880298_89385454', 'S', 'Success', '2024-01-28 07:29:07', 'Y', '2024-01-28 07:29:07'),
(612, 1, '/logout', 'undefined', '1_202428101517_7894', 'S', 'Success', '2024-01-29 04:45:17', 'Y', '2024-01-29 04:45:17'),
(613, 0, '/login', 'undefined', '26075908_62855674', 'S', 'Success', '2024-01-29 04:45:41', 'Y', '2024-01-29 04:45:41'),
(614, 0, '/login', 'undefined', '36857935_43910156', 'F', 'Invalid Password. Kindly try again with the valid details!', '2024-01-29 09:20:44', 'Y', '2024-01-29 09:20:44'),
(615, 0, '/login', 'undefined', '46720736_77901505', 'S', 'Success', '2024-01-29 09:20:51', 'Y', '2024-01-29 09:20:51'),
(616, 1, '/plan/delete_plan', 'undefined', '1_202428180052_2348', 'F', 'Error Occurred.', '2024-01-29 12:30:52', 'Y', '2024-01-29 12:30:52'),
(617, 1, '/plan/delete_plan', 'undefined', '1_202428180151_1425', 'S', 'Success', '2024-01-29 12:31:51', 'Y', '2024-01-29 12:31:51'),
(618, 1, '/plan/delete_plan', 'undefined', '1_202428180535_5327', 'S', 'Success', '2024-01-29 12:35:35', 'Y', '2024-01-29 12:35:35'),
(619, 1, '/plan/delete_plan', 'undefined', '1_202428180650_1974', 'S', 'Success', '2024-01-29 12:36:50', 'Y', '2024-01-29 12:36:50'),
(620, 1, '/plan/delete_plan', 'undefined', '1_202428180701_7970', 'S', 'Success', '2024-01-29 12:37:01', 'Y', '2024-01-29 12:37:01'),
(621, 1, '/plan/delete_plan', 'undefined', '1_202428180911_6732', 'S', 'Success', '2024-01-29 12:39:11', 'Y', '2024-01-29 12:39:11'),
(622, 1, '/plan/user_plans_purchase', 'undefined', '1_202428181831_9483', 'F', 'Invalid Plan', '2024-01-29 12:48:31', 'Y', '2024-01-29 12:48:31'),
(623, 1, '/plan/delete_plan', 'undefined', '1_202429102436_5404', 'S', 'Success', '2024-01-30 04:54:36', 'Y', '2024-01-30 04:54:36'),
(624, 0, '/login', 'undefined', '91661638_39101806', 'S', 'Success', '2024-01-31 10:51:29', 'Y', '2024-01-31 10:51:29'),
(625, 0, '/login', 'undefined', '12695605_89700936', 'S', 'Success', '2024-02-01 04:59:54', 'Y', '2024-02-01 04:59:54'),
(626, 1, '/template/create_template', 'undefined', '_2024032112715_762', 'S', 'Success', '2024-02-01 05:57:15', 'Y', '2024-02-01 05:57:15'),
(627, 1, '/template/create_template', 'undefined', '_2024032113041_709', 'S', 'Success', '2024-02-01 06:00:41', 'Y', '2024-02-01 06:00:41'),
(628, 1, '/sender_id/add_sender_id', 'undefined', '1_202431122012_9019', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 06:50:13'),
(629, 1, '/sender_id/add_sender_id', 'undefined', '1_202431122254_1779', 'S', 'Success', '2024-02-01 06:53:02', 'Y', '2024-02-01 06:52:54'),
(630, 1, '/sender_id/add_sender_id', 'undefined', '1_202431122454_6998', 'F', 'QRcode already scanned', '2024-02-01 06:54:54', 'Y', '2024-02-01 06:54:54'),
(631, 1, '/group/send_message', 'undefined', '_2024032122651_672', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 06:56:51'),
(632, 1, '/sender_id/add_sender_id', 'undefined', '1_202431123048_5678', 'S', 'Success', '2024-02-01 07:00:57', 'Y', '2024-02-01 07:00:48'),
(633, 1, '/group/send_message', 'undefined', '_2024032123208_843', 'Y', 'Success', '2024-02-01 07:03:38', 'Y', '2024-02-01 07:02:08'),
(634, 1, '/group/send_message', 'undefined', '_2024032123405_185', 'F', 'Sender ID unlinked', '2024-02-01 07:06:06', 'Y', '2024-02-01 07:04:05'),
(635, 1, '/sender_id/add_sender_id', 'undefined', '1_202431123755_4812', 'S', 'Success', '2024-02-01 07:08:04', 'Y', '2024-02-01 07:07:55'),
(636, 1, '/group/send_message', 'undefined', '_2024032123904_492', 'Y', 'Success', '2024-02-01 07:10:25', 'Y', '2024-02-01 07:09:04'),
(637, 1, '/group/send_message', 'undefined', '_2024032124105_799', 'Y', 'Success', '2024-02-01 07:12:36', 'Y', '2024-02-01 07:11:05'),
(638, 1, '/group/send_message', 'undefined', '_2024032124349_780', 'Y', 'Success', '2024-02-01 07:14:45', 'Y', '2024-02-01 07:13:49'),
(639, 1, '/group/schedule_send_message', 'undefined', '_2024032124607_264', 'Y', 'Success', '2024-02-01 07:20:31', 'Y', '2024-02-01 07:16:07'),
(640, 1, '/group/schedule_send_message', 'undefined', '_2024032124648_424', 'Y', 'Success', '2024-02-01 07:18:32', 'Y', '2024-02-01 07:16:48'),
(641, 1, '/group/schedule_send_message', 'undefined', '_2024032130040_465', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 07:30:40'),
(642, 1, '/group/schedule_send_message', 'undefined', '_2024032130125_375', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 07:31:25'),
(643, 1, '/group/schedule_send_message', 'undefined', '_2024032130157_592', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 07:31:57'),
(644, 1, '/group/schedule_send_message', 'undefined', '_2024032130232_914', 'Y', 'Success', '2024-02-01 07:35:40', 'Y', '2024-02-01 07:32:32'),
(645, 1, '/group/schedule_send_message', 'undefined', '_2024032130317_424', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 07:33:17'),
(646, 1, '/group/schedule_send_message', 'undefined', '_2024032130451_649', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 07:34:51'),
(647, 1, '/sender_id/add_sender_id', 'undefined', '1_202431130736_3807', 'S', 'Success', '2024-02-01 07:37:43', 'Y', '2024-02-01 07:37:36'),
(648, 1, '/sender_id/add_sender_id', 'undefined', '1_202431130936_7791', 'F', 'QRcode already scanned', '2024-02-01 07:39:36', 'Y', '2024-02-01 07:39:36'),
(649, 1, '/group/schedule_send_message', 'undefined', '_2024032133025_516', 'Y', 'Success', '2024-02-01 08:03:54', 'Y', '2024-02-01 08:00:25'),
(650, 1, '/group/schedule_send_message', 'undefined', '_2024032133052_112', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 08:00:52'),
(651, 1, '/group/schedule_send_message', 'undefined', '_2024032133122_626', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 08:01:22'),
(652, 1, '/sender_id/add_sender_id', 'undefined', '1_202431133609_6896', 'S', 'Success', '2024-02-01 08:06:17', 'Y', '2024-02-01 08:06:09'),
(653, 1, '/group/schedule_send_message', 'undefined', '_2024032133719_356', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 08:07:19'),
(654, 1, '/group/schedule_send_message', 'undefined', '_2024032133805_173', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 08:08:05'),
(655, 1, '/group/schedule_send_message', 'undefined', '_2024032134200_122', 'Y', 'Success', '2024-02-01 08:16:03', 'Y', '2024-02-01 08:12:00'),
(656, 1, '/sender_id/add_sender_id', 'undefined', '1_202431134231_6495', 'S', 'Success', '2024-02-01 08:12:39', 'Y', '2024-02-01 08:12:31'),
(657, 1, '/group/schedule_send_message', 'undefined', '_2024032134641_951', 'Y', 'Success', '2024-02-01 08:30:29', 'Y', '2024-02-01 08:16:41'),
(658, 1, '/group/schedule_send_message', 'undefined', '_2024032134656_938', 'Y', 'Success', '2024-02-01 08:22:06', 'Y', '2024-02-01 08:16:56'),
(659, 1, '/group/schedule_send_message', 'undefined', '_2024032134722_764', 'Y', 'Success', '2024-02-01 08:25:27', 'Y', '2024-02-01 08:17:22'),
(660, 1, '/group/schedule_send_message', 'undefined', '_2024032142741_200', 'Y', 'Success', '2024-02-01 09:00:31', 'Y', '2024-02-01 08:57:41'),
(661, 1, '/group/schedule_send_message', 'undefined', '_2024032142801_148', 'F', 'Sender ID unlinked', '2024-02-01 09:02:01', 'Y', '2024-02-01 08:58:01'),
(662, 0, '/login', 'undefined', '22272978_53636883', 'S', 'Success', '2024-02-01 10:10:08', 'Y', '2024-02-01 10:10:08'),
(663, 1, '/sender_id/add_sender_id', 'undefined', '1_202431154223_2718', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 10:12:23'),
(664, 1, '/sender_id/add_sender_id', 'undefined', '1_202431154316_5937', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 10:13:16'),
(665, 0, '/login', 'undefined', '45869428_16152386', 'S', 'Success', '2024-02-01 10:15:15', 'Y', '2024-02-01 10:15:15'),
(666, 1, '/sender_id/add_sender_id', 'undefined', '1_202431154526_4199', 'S', 'Success', '2024-02-01 10:15:33', 'Y', '2024-02-01 10:15:26'),
(667, 1, '/sender_id/add_sender_id', 'undefined', '1_202431154727_6961', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 10:17:27'),
(668, 1, '/sender_id/add_sender_id', 'undefined', '1_202431154927_5253', 'S', 'Success', '2024-02-01 10:19:48', 'Y', '2024-02-01 10:19:27'),
(669, 1, '/sender_id/add_sender_id', 'undefined', '1_202431154948_6095', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 10:19:48'),
(670, 1, '/sender_id/add_sender_id', 'undefined', '1_202431155054_6846', 'S', 'Success', '2024-02-01 10:21:07', 'Y', '2024-02-01 10:20:54'),
(671, 1, '/group/send_message', 'undefined', '_2024032155211_217', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 10:22:11'),
(672, 1, '/group/send_message', 'undefined', '_2024032155354_333', 'Y', 'Success', '2024-02-01 10:25:21', 'Y', '2024-02-01 10:23:54'),
(673, 1, '/group/schedule_send_message', 'undefined', '_2024032155543_880', 'Y', 'Success', '2024-02-01 10:30:24', 'Y', '2024-02-01 10:25:43'),
(674, 1, '/group/schedule_send_message', 'undefined', '_2024032155802_176', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 10:28:02'),
(675, 1, '/group/schedule_send_message', 'undefined', '_2024032155841_935', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 10:28:41'),
(676, 1, '/group/schedule_send_message', 'undefined', '_2024032155927_166', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 10:29:27'),
(677, 1, '/group/schedule_send_message', 'undefined', '_2024032160033_326', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 10:30:33'),
(678, 1, '/sender_id/add_sender_id', 'undefined', '1_202431160224_9817', 'S', 'Success', '2024-02-01 10:32:31', 'Y', '2024-02-01 10:32:24'),
(679, 1, '/group/schedule_send_message', 'undefined', '_2024032161703_126', 'Y', 'Success', '2024-02-01 10:49:00', 'Y', '2024-02-01 10:47:03'),
(680, 1, '/group/schedule_send_message', 'undefined', '_2024032162149_113', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 10:51:49'),
(681, 1, '/group/schedule_send_message', 'undefined', '_2024032162233_631', 'Y', 'Success', '2024-02-01 10:55:04', 'Y', '2024-02-01 10:52:33'),
(682, 1, '/group/schedule_send_message', 'undefined', '_2024032162254_802', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-01 10:52:54'),
(683, 1, '/group/schedule_send_message', 'undefined', '_2024032162311_580', 'F', 'Sender ID unlinked', '2024-02-01 10:57:01', 'Y', '2024-02-01 10:53:11'),
(684, 1, '/sender_id/add_sender_id', 'undefined', '1_202431163053_7032', 'S', 'Success', '2024-02-01 11:00:59', 'Y', '2024-02-01 11:00:53'),
(685, 1, '/group/schedule_send_message', 'undefined', '_2024032163239_633', 'Y', 'Success', '2024-02-01 11:05:24', 'Y', '2024-02-01 11:02:39'),
(686, 1, '/group/schedule_send_message', 'undefined', '_2024032170919_766', 'Y', 'Success', '2024-02-01 11:42:30', 'Y', '2024-02-01 11:39:19'),
(687, 1, '/password/change_password', 'undefined', '1_202431174658_9627', 'S', 'Success', '2024-02-01 12:16:58', 'Y', '2024-02-01 12:16:58'),
(688, 0, '/login', 'undefined', '64876267_73525287', 'F', 'Invalid Password. Kindly try again with the valid details!', '2024-02-01 12:18:27', 'Y', '2024-02-01 12:18:27'),
(689, 0, '/login', 'undefined', '82514721_47333933', 'F', 'Invalid Password. Kindly try again with the valid details!', '2024-02-01 12:18:33', 'Y', '2024-02-01 12:18:33'),
(690, 0, '/login', 'undefined', '98618681_49437467', 'S', 'Success', '2024-02-01 12:18:39', 'Y', '2024-02-01 12:18:39'),
(691, 1, '/password/change_password', 'undefined', '1_202431174905_3720', 'S', 'Success', '2024-02-01 12:19:05', 'Y', '2024-02-01 12:19:05'),
(692, 0, '/login', 'undefined', '74836271_70781041', 'S', 'Success', '2024-02-01 12:19:18', 'Y', '2024-02-01 12:19:18'),
(693, 0, '/login', 'undefined', '91628554_58713331', 'S', 'Success', '2024-02-01 12:47:04', 'Y', '2024-02-01 12:47:04'),
(694, 0, '/login', 'undefined', '92076023_10284676', 'S', 'Success', '2024-02-01 12:56:51', 'Y', '2024-02-01 12:56:51'),
(695, 0, '/user/update_details', 'undefined', '1_202431192106_1247', 'F', 'Token is required', '2024-02-01 13:51:07', 'Y', '2024-02-01 13:51:07'),
(696, 0, '/user/update_details', 'undefined', '1_202431192127_5082', 'F', 'Token is required', '2024-02-01 13:51:27', 'Y', '2024-02-01 13:51:27'),
(697, 1, '/user/update_details', 'undefined', '1_202431192154_3966', 'S', 'Success', '2024-02-01 13:51:54', 'Y', '2024-02-01 13:51:54'),
(698, 0, '/login', 'undefined', '59215344_72962665', 'S', 'Success', '2024-02-02 04:39:46', 'Y', '2024-02-02 04:39:46'),
(699, 0, '/group/send_message', 'undefined', '_20240260852ej_119', 'F', 'Token is required', '2024-02-02 06:05:29', 'Y', '2024-02-02 06:05:29'),
(700, 0, '/group/send_message', 'undefined', '_20240260852ej_119', 'F', 'Request already processed', '2024-02-02 06:06:02', 'Y', '2024-02-02 06:06:02'),
(701, 1, '/group/send_message', 'undefined', '_20240260jsn_119', 'F', 'Sender ID unlinked', '2024-02-02 06:10:57', 'Y', '2024-02-02 06:06:12'),
(702, 1, '/group/send_message', 'undefined', '_20240260jsn_119', 'F', 'Sender ID unlinked', '2024-02-02 06:10:57', 'Y', '2024-02-02 06:07:03'),
(703, 1, '/group/send_message', 'undefined', '_20240260jsn_119', 'F', 'Sender ID unlinked', '2024-02-02 06:10:57', 'Y', '2024-02-02 06:08:54'),
(704, 1, '/sender_id/add_sender_id', 'undefined', '1_202432114158_8034', 'S', 'Success', '2024-02-02 06:12:04', 'Y', '2024-02-02 06:11:58'),
(705, 0, '/group/send_message', 'undefined', '_20240260jsn_119', 'F', 'Request already processed', '2024-02-02 06:13:20', 'Y', '2024-02-02 06:13:20'),
(706, 1, '/group/send_message', 'undefined', '_202_119', 'F', 'Error occurred', '2024-02-02 06:14:28', 'Y', '2024-02-02 06:13:29'),
(707, 1, '/group/send_message', 'undefined', '_202_1ww19', 'F', 'Error occurred', '2024-02-02 06:20:55', 'Y', '2024-02-02 06:18:50'),
(708, 0, '/group/send_message', 'undefined', '_202_1ww19', 'F', 'Request already processed', '2024-02-02 06:23:51', 'Y', '2024-02-02 06:23:51'),
(709, 1, '/group/send_message', 'undefined', '_202_1wdkw9', 'F', 'Error occurred', '2024-02-02 06:24:32', 'Y', '2024-02-02 06:23:58'),
(710, 0, '/group/send_message', 'undefined', '_202_1wdkw9', 'F', 'Request already processed', '2024-02-02 06:25:27', 'Y', '2024-02-02 06:25:27'),
(711, 1, '/group/send_message', 'undefined', '_202_1832892w9', 'F', 'Error occurred', '2024-02-02 06:26:02', 'Y', '2024-02-02 06:25:34'),
(712, 1, '/group/send_message', 'undefined', '_202_w32892w9', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-02 06:27:16'),
(713, 1, '/group/send_message', 'undefined', '_202_w3wdww9', 'F', 'Error occurred', '2024-02-02 06:28:22', 'Y', '2024-02-02 06:27:52'),
(714, 0, '/group/send_message', 'undefined', '_202_w3wdww9', 'F', 'Request already processed', '2024-02-02 06:29:04', 'Y', '2024-02-02 06:29:04'),
(715, 1, '/group/send_message', 'undefined', '_202_jndjww9', 'F', 'Error occurred', '2024-02-02 06:29:43', 'Y', '2024-02-02 06:29:11'),
(716, 1, '/group/send_message', 'undefined', '_28348djww9', 'F', 'Error occurred', '2024-02-02 06:32:03', 'Y', '2024-02-02 06:31:31'),
(717, 1, '/group/send_message', 'undefined', '_283jkdnjkweww9', 'F', 'Error occurred', '2024-02-02 06:34:40', 'Y', '2024-02-02 06:34:07'),
(718, 1, '/group/send_message', 'undefined', '_283jkdnsjdw9', 'F', 'Error occurred', '2024-02-02 06:43:46', 'Y', '2024-02-02 06:43:12'),
(719, 1, '/group/send_message', 'undefined', '_283jkddw9', 'Y', 'Success', '2024-02-02 06:44:57', 'Y', '2024-02-02 06:44:16'),
(720, 1, '/group/send_message', 'undefined', '_283jkddwjndww9', 'F', 'Error occurred', '2024-02-02 06:53:43', 'Y', '2024-02-02 06:53:12'),
(721, 0, '/group/send_message', 'undefined', '_283jkddwjndww9', 'F', 'Request already processed', '2024-02-02 07:03:24', 'Y', '2024-02-02 07:03:24'),
(722, 1, '/group/send_message', 'undefined', '_283jdjsfww9', 'F', 'Error occurred', '2024-02-02 07:11:25', 'Y', '2024-02-02 07:10:53'),
(723, 0, '/group/send_message', 'undefined', '_283jdjsfww9', 'F', 'Request already processed', '2024-02-02 07:11:42', 'Y', '2024-02-02 07:11:42'),
(724, 1, '/group/send_message', 'undefined', '_283jdww9', 'F', 'Error occurred', '2024-02-02 07:12:16', 'Y', '2024-02-02 07:11:46'),
(725, 1, '/group/send_message', 'undefined', '_283jkd8932892w9', 'F', 'Error occurred', '2024-02-02 07:13:55', 'Y', '2024-02-02 07:13:24'),
(726, 1, '/group/send_message', 'undefined', '_283jk3289748932w9', 'F', 'Error occurred', '2024-02-02 07:15:56', 'Y', '2024-02-02 07:15:23'),
(727, 0, '/group/send_message', 'undefined', '_283jk3289748932w9', 'F', 'Request already processed', '2024-02-02 07:17:19', 'Y', '2024-02-02 07:17:19'),
(728, 1, '/group/send_message', 'undefined', '_283j2983749932w9', 'Y', 'Success', '2024-02-02 07:17:59', 'Y', '2024-02-02 07:17:27'),
(729, 1, '/group/send_message', 'undefined', '_283j298dnkw932w9', 'Y', 'Success', '2024-02-02 07:39:22', 'Y', '2024-02-02 07:38:19'),
(730, 1, '/group/send_message', 'undefined', '_28332w9', 'Y', 'Success', '2024-02-02 07:42:02', 'Y', '2024-02-02 07:41:23'),
(731, 0, '/login', 'undefined', '86369396_94514224', 'S', 'Success', '2024-02-02 11:16:44', 'Y', '2024-02-02 11:16:44'),
(732, 1, '/logout', 'undefined', '1_202432174748_2820', 'S', 'Success', '2024-02-02 12:17:48', 'Y', '2024-02-02 12:17:48'),
(733, 0, '/login', 'undefined', '37361972_79032628', 'S', 'Success', '2024-02-02 12:18:37', 'Y', '2024-02-02 12:18:37');
INSERT INTO `api_log` (`api_log_id`, `user_id`, `api_url`, `ip_address`, `request_id`, `response_status`, `response_comments`, `response_date`, `api_log_status`, `api_log_entry_date`) VALUES
(734, 1, '/logout', 'undefined', '1_202432174915_3182', 'S', 'Success', '2024-02-02 12:19:15', 'Y', '2024-02-02 12:19:15'),
(735, 0, '/login', 'undefined', '20624440_73681650', 'S', 'Success', '2024-02-02 12:19:35', 'Y', '2024-02-02 12:19:35'),
(736, 1, '/sender_id/add_sender_id', 'undefined', '1_202432175103_2190', 'S', 'Success', '2024-02-02 12:21:16', 'Y', '2024-02-02 12:21:03'),
(737, 1, '/sender_id/add_sender_id', 'undefined', '1_202432175303_4971', 'F', 'QRcode already scanned', '2024-02-02 12:23:03', 'Y', '2024-02-02 12:23:03'),
(738, 1, '/group/send_message', 'undefined', '_2024034104316_180', 'Y', 'Success', '2024-02-03 05:13:59', 'Y', '2024-02-03 05:13:16'),
(739, 1, '/group/send_message', 'undefined', '_2024034104458_358', 'Y', 'Success', '2024-02-03 05:16:59', 'Y', '2024-02-03 05:14:58'),
(740, 1, '/group/send_message', 'undefined', '_2024034105821_672', 'Y', 'Success', '2024-02-03 05:29:21', 'Y', '2024-02-03 05:28:21'),
(741, 1, '/group/send_message', 'undefined', '_2024034110457_479', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-03 05:34:57'),
(742, 1, '/group/send_message', 'undefined', '_2024034110527_792', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-03 05:35:27'),
(743, 1, '/group/send_message', 'undefined', '_2024034110606_514', 'Y', 'Success', '2024-02-03 05:36:36', 'Y', '2024-02-03 05:36:06'),
(744, 1, '/group/send_message', 'undefined', '_2024034111020_731', 'Y', 'Success', '2024-02-03 05:40:50', 'Y', '2024-02-03 05:40:20'),
(745, 1, '/group/send_message', 'undefined', '_2024034111727_283', 'Y', 'Success', '2024-02-03 05:48:15', 'Y', '2024-02-03 05:47:27'),
(746, 1, '/group/send_message', 'undefined', '_2024034112035_710', 'Y', 'Success', '2024-02-03 05:51:06', 'Y', '2024-02-03 05:50:35'),
(747, 1, '/group/send_message', 'undefined', '_2024034112519_958', 'F', 'Error occurred', '2024-02-03 05:55:48', 'Y', '2024-02-03 05:55:19'),
(748, 1, '/group/send_message', 'undefined', '_2024034112651_137', 'Y', 'Success', '2024-02-03 05:57:21', 'Y', '2024-02-03 05:56:51'),
(749, 1, '/group/send_message', 'undefined', '_2024034112814_999', 'Y', 'Success', '2024-02-03 05:58:42', 'Y', '2024-02-03 05:58:14'),
(750, 1, '/group/send_message', 'undefined', '_2024034113351_793', 'Y', 'Success', '2024-02-03 06:04:20', 'Y', '2024-02-03 06:03:51'),
(751, 1, '/group/send_message', 'undefined', '_2024034113554_466', 'Y', 'Success', '2024-02-03 06:06:23', 'Y', '2024-02-03 06:05:54'),
(752, 1, '/group/send_message', 'undefined', '_2024034113702_798', 'Y', 'Success', '2024-02-03 06:07:31', 'Y', '2024-02-03 06:07:02'),
(753, 1, '/group/send_message', 'undefined', '_2024034114015_242', 'F', 'Error occurred', '2024-02-03 06:10:45', 'Y', '2024-02-03 06:10:15'),
(754, 1, '/group/send_message', 'undefined', '_2024034115014_317', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-03 06:20:14'),
(755, 1, '/group/send_message', 'undefined', '_2024034115053_917', 'F', 'Error occurred', '2024-02-03 06:21:21', 'Y', '2024-02-03 06:20:53'),
(756, 1, '/group/send_message', 'undefined', '_2024034115231_791', 'F', 'Error occurred', '2024-02-03 06:22:59', 'Y', '2024-02-03 06:22:31'),
(757, 1, '/group/send_message', 'undefined', '_2024034115828_116', 'F', 'Error occurred', '2024-02-03 06:29:04', 'Y', '2024-02-03 06:28:28'),
(758, 1, '/group/send_message', 'undefined', '_2024034120017_222', 'F', 'Error occurred', '2024-02-03 06:30:50', 'Y', '2024-02-03 06:30:17'),
(759, 1, '/group/send_message', 'undefined', '_2024034120234_972', 'F', 'Error occurred', '2024-02-03 06:33:03', 'Y', '2024-02-03 06:32:34'),
(760, 1, '/group/send_message', 'undefined', '_2024034120444_265', 'Y', 'Success', '2024-02-03 06:35:14', 'Y', '2024-02-03 06:34:44'),
(761, 1, '/group/send_message', 'undefined', '_2024034120551_382', 'F', 'Error occurred', '2024-02-03 06:36:22', 'Y', '2024-02-03 06:35:51'),
(762, 1, '/group/send_message', 'undefined', '_2024034120828_772', 'Y', 'Success', '2024-02-03 06:39:04', 'Y', '2024-02-03 06:38:28'),
(763, 1, '/group/send_message', 'undefined', '_2024034121124_488', 'Y', 'Success', '2024-02-03 06:41:57', 'Y', '2024-02-03 06:41:24'),
(764, 1, '/group/send_message', 'undefined', '_2024034121337_926', 'Y', 'Success', '2024-02-03 06:44:08', 'Y', '2024-02-03 06:43:37'),
(765, 1, '/group/send_message', 'undefined', '_2024034122032_265', 'F', 'Error occurred', '2024-02-03 06:51:00', 'Y', '2024-02-03 06:50:32'),
(766, 1, '/group/send_message', 'undefined', '_2024034122417_124', 'Y', 'Success', '2024-02-03 06:54:47', 'Y', '2024-02-03 06:54:17'),
(767, 1, '/group/schedule_send_message', 'undefined', '_2024034123609_834', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-03 07:06:09'),
(768, 1, '/group/schedule_send_message', 'undefined', '_2024034123731_134', 'Y', 'Success', '2024-02-03 07:09:28', 'Y', '2024-02-03 07:07:31'),
(769, 1, '/group/send_message', 'undefined', '_2024034124113_997', 'Y', 'Success', '2024-02-03 07:11:42', 'Y', '2024-02-03 07:11:13'),
(770, 1, '/group/schedule_send_message', 'undefined', '_2024034124211_518', 'Y', 'Success', '2024-02-03 07:13:29', 'Y', '2024-02-03 07:12:11'),
(771, 1, '/group/schedule_send_message', 'undefined', '_2024034124554_437', 'Y', 'Success', '2024-02-03 07:17:31', 'Y', '2024-02-03 07:15:54'),
(772, 1, '/group/schedule_send_message', 'undefined', '_2024034131053_377', 'Y', 'Success', '2024-02-03 07:42:32', 'Y', '2024-02-03 07:40:53'),
(773, 1, '/group/send_message', 'undefined', '_2024034131615_951', 'Y', 'Success', '2024-02-03 07:46:46', 'Y', '2024-02-03 07:46:15'),
(774, 1, '/group/schedule_send_message', 'undefined', '_2024034131753_689', 'S', 'Success', '2024-02-03 07:49:30', 'Y', '2024-02-03 07:47:53'),
(775, 1, '/group/schedule_send_message', 'undefined', '_2024034132052_888', 'Y', 'Success', '2024-02-03 07:52:31', 'Y', '2024-02-03 07:50:52'),
(776, 1, '/group/schedule_send_message', 'undefined', '_2024034133212_325', 'Y', 'Success', '2024-02-03 08:03:34', 'Y', '2024-02-03 08:02:12'),
(777, 1, '/group/schedule_send_message', 'undefined', '_2024034133235_706', 'Y', 'Success', '2024-02-03 08:04:31', 'Y', '2024-02-03 08:02:35'),
(778, 1, '/group/schedule_send_message', 'undefined', '_2024034142553_283', 'Y', 'Success', '2024-02-03 08:57:30', 'Y', '2024-02-03 08:55:53'),
(779, 1, '/group/schedule_send_message', 'undefined', '_2024034142848_436', 'F', 'Sender ID unlinked', '2024-02-03 09:02:04', 'Y', '2024-02-03 08:58:48'),
(780, 1, '/group/schedule_send_message', 'undefined', '_2024034142953_486', 'Y', 'Success', '2024-02-03 09:00:34', 'Y', '2024-02-03 08:59:53'),
(781, 1, '/sender_id/add_sender_id', 'undefined', '1_202433143347_1166', 'S', 'Success', '2024-02-03 09:03:55', 'Y', '2024-02-03 09:03:47'),
(782, 1, '/sender_id/add_sender_id', 'undefined', '1_202433143759_7133', 'S', 'Success', '2024-02-03 09:08:15', 'Y', '2024-02-03 09:07:59'),
(783, 1, '/sender_id/add_sender_id', 'undefined', '1_202433143959_5560', 'S', 'Success', '2024-02-03 09:10:08', 'Y', '2024-02-03 09:09:59'),
(784, 1, '/sender_id/add_sender_id', 'undefined', '1_202433144159_9356', 'F', 'QRcode already scanned', '2024-02-03 09:11:59', 'Y', '2024-02-03 09:11:59'),
(785, 1, '/sender_id/add_sender_id', 'undefined', '1_202433144632_7399', 'S', 'Success', '2024-02-03 09:16:40', 'Y', '2024-02-03 09:16:32'),
(786, 1, '/sender_id/add_sender_id', 'undefined', '1_202433144832_6948', 'F', 'QRcode already scanned', '2024-02-03 09:18:33', 'Y', '2024-02-03 09:18:32'),
(787, 1, '/sender_id/add_sender_id', 'undefined', '1_202433144902_9894', 'S', 'Success', '2024-02-03 09:19:13', 'Y', '2024-02-03 09:19:02'),
(788, 1, '/sender_id/add_sender_id', 'undefined', '1_202433145102_6402', 'F', 'QRcode already scanned', '2024-02-03 09:21:02', 'Y', '2024-02-03 09:21:02'),
(789, 1, '/sender_id/add_sender_id', 'undefined', '1_202433145701_3292', 'S', 'Success', '2024-02-03 09:27:11', 'Y', '2024-02-03 09:27:01'),
(790, 1, '/sender_id/add_sender_id', 'undefined', '1_202433145901_9444', 'F', 'QRcode already scanned', '2024-02-03 09:29:01', 'Y', '2024-02-03 09:29:01'),
(791, 1, '/sender_id/add_sender_id', 'undefined', '1_202433150010_7629', 'S', 'Success', '2024-02-03 09:30:19', 'Y', '2024-02-03 09:30:10'),
(792, 1, '/sender_id/add_sender_id', 'undefined', '1_202433150210_2240', 'F', 'QRcode already scanned', '2024-02-03 09:32:10', 'Y', '2024-02-03 09:32:10'),
(793, 1, '/sender_id/add_sender_id', 'undefined', '1_202433150334_3538', 'S', 'Success', '2024-02-03 09:33:41', 'Y', '2024-02-03 09:33:34'),
(794, 1, '/sender_id/add_sender_id', 'undefined', '1_202433150534_3429', 'F', 'QRcode already scanned', '2024-02-03 09:35:34', 'Y', '2024-02-03 09:35:34'),
(795, 1, '/sender_id/add_sender_id', 'undefined', '1_202433150550_1535', 'S', 'Success', '2024-02-03 09:35:57', 'Y', '2024-02-03 09:35:50'),
(796, 1, '/sender_id/add_sender_id', 'undefined', '1_202433151022_1808', 'S', 'Success', '2024-02-03 09:40:29', 'Y', '2024-02-03 09:40:22'),
(797, 1, '/sender_id/add_sender_id', 'undefined', '1_202433151222_9192', 'F', 'QRcode already scanned', '2024-02-03 09:42:22', 'Y', '2024-02-03 09:42:22'),
(798, 1, '/sender_id/add_sender_id', 'undefined', '1_202433151824_1524', 'S', 'Success', '2024-02-03 09:48:40', 'Y', '2024-02-03 09:48:24'),
(799, 1, '/sender_id/add_sender_id', 'undefined', '1_202433152024_2385', 'F', 'QRcode already scanned', '2024-02-03 09:50:24', 'Y', '2024-02-03 09:50:24'),
(800, 1, '/sender_id/add_sender_id', 'undefined', '1_202433152257_6083', 'S', 'Success', '2024-02-03 09:53:05', 'Y', '2024-02-03 09:52:57'),
(801, 1, '/sender_id/add_sender_id', 'undefined', '1_202433152457_4145', 'F', 'QRcode already scanned', '2024-02-03 09:54:57', 'Y', '2024-02-03 09:54:57'),
(802, 1, '/sender_id/add_sender_id', 'undefined', '1_202433153259_8397', 'S', 'Success', '2024-02-03 10:03:08', 'Y', '2024-02-03 10:02:59'),
(803, 1, '/sender_id/add_sender_id', 'undefined', '1_202433153459_1606', 'F', 'QRcode already scanned', '2024-02-03 10:04:59', 'Y', '2024-02-03 10:04:59'),
(804, 1, '/sender_id/add_sender_id', 'undefined', '1_202433153627_9832', 'S', 'Success', '2024-02-03 10:06:39', 'Y', '2024-02-03 10:06:28'),
(805, 1, '/sender_id/add_sender_id', 'undefined', '1_202433154535_5315', 'S', 'Success', '2024-02-03 10:15:43', 'Y', '2024-02-03 10:15:35'),
(806, 1, '/sender_id/add_sender_id', 'undefined', '1_202433154735_7935', 'F', 'QRcode already scanned', '2024-02-03 10:17:35', 'Y', '2024-02-03 10:17:35'),
(807, 1, '/sender_id/add_sender_id', 'undefined', '1_202433155150_8958', 'S', 'Success', '2024-02-03 10:21:58', 'Y', '2024-02-03 10:21:50'),
(808, 1, '/sender_id/add_sender_id', 'undefined', '1_202433155339_8448', 'S', 'Success', '2024-02-03 10:23:47', 'Y', '2024-02-03 10:23:39'),
(809, 1, '/sender_id/add_sender_id', 'undefined', '1_202433155434_6528', 'F', 'QRcode already scanned', '2024-02-03 10:24:34', 'Y', '2024-02-03 10:24:34'),
(810, 1, '/sender_id/add_sender_id', 'undefined', '1_202433155451_8634', 'S', 'Success', '2024-02-03 10:24:58', 'Y', '2024-02-03 10:24:51'),
(811, 1, '/sender_id/add_sender_id', 'undefined', '1_202433155651_6881', 'F', 'QRcode already scanned', '2024-02-03 10:26:51', 'Y', '2024-02-03 10:26:51'),
(812, 1, '/sender_id/add_sender_id', 'undefined', '1_202433160302_3361', 'S', 'Success', '2024-02-03 10:33:10', 'Y', '2024-02-03 10:33:02'),
(813, 1, '/sender_id/add_sender_id', 'undefined', '1_202433160502_4590', 'F', 'QRcode already scanned', '2024-02-03 10:35:02', 'Y', '2024-02-03 10:35:02'),
(814, 1, '/sender_id/add_sender_id', 'undefined', '1_202433162019_3961', 'S', 'Success', '2024-02-03 10:50:31', 'Y', '2024-02-03 10:50:19'),
(815, 1, '/sender_id/add_sender_id', 'undefined', '1_202433162219_9416', 'F', 'QRcode already scanned', '2024-02-03 10:52:19', 'Y', '2024-02-03 10:52:19'),
(816, 1, '/sender_id/add_sender_id', 'undefined', '1_202433162907_7513', 'S', 'Success', '2024-02-03 10:59:15', 'Y', '2024-02-03 10:59:07'),
(817, 1, '/sender_id/add_sender_id', 'undefined', '1_202433163107_8717', 'F', 'QRcode already scanned', '2024-02-03 11:01:07', 'Y', '2024-02-03 11:01:07'),
(818, 1, '/sender_id/add_sender_id', 'undefined', '1_202433164337_5590', 'S', 'Success', '2024-02-03 11:13:43', 'Y', '2024-02-03 11:13:37'),
(819, 1, '/sender_id/add_sender_id', 'undefined', '1_202433165416_3544', 'S', 'Success', '2024-02-03 11:24:23', 'Y', '2024-02-03 11:24:16'),
(820, 1, '/sender_id/add_sender_id', 'undefined', '1_202433170602_9206', 'S', 'Success', '2024-02-03 11:36:11', 'Y', '2024-02-03 11:36:02'),
(821, 1, '/sender_id/add_sender_id', 'undefined', '1_202433170802_5899', 'F', 'QRcode already scanned', '2024-02-03 11:38:02', 'Y', '2024-02-03 11:38:02'),
(822, 1, '/sender_id/add_sender_id', 'undefined', '1_202433171624_7456', 'S', 'Success', '2024-02-03 11:46:31', 'Y', '2024-02-03 11:46:24'),
(823, 1, '/sender_id/add_sender_id', 'undefined', '1_202433171824_1721', 'F', 'QRcode already scanned', '2024-02-03 11:48:24', 'Y', '2024-02-03 11:48:24'),
(824, 1, '/sender_id/add_sender_id', 'undefined', '1_202433173202_4581', 'S', 'Success', '2024-02-03 12:02:12', 'Y', '2024-02-03 12:02:02'),
(825, 1, '/sender_id/add_sender_id', 'undefined', '1_202433173402_6402', 'F', 'QRcode already scanned', '2024-02-03 12:04:02', 'Y', '2024-02-03 12:04:02'),
(826, 1, '/sender_id/add_sender_id', 'undefined', '1_202434181913_7965', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-04 12:49:13'),
(827, 1, '/sender_id/add_sender_id', 'undefined', '1_202434181954_3760', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-04 12:49:54'),
(828, 1, '/sender_id/add_sender_id', 'undefined', '1_202434182148_2614', 'S', 'Success', '2024-02-04 12:51:59', 'Y', '2024-02-04 12:51:48'),
(829, 1, '/logout', 'undefined', '1_202434182358_1082', 'S', 'Success', '2024-02-04 12:53:58', 'Y', '2024-02-04 12:53:58'),
(830, 0, '/login', 'undefined', '99345260_41798181', 'S', 'Success', '2024-02-04 12:54:16', 'Y', '2024-02-04 12:54:16'),
(831, 1, '/logout', 'undefined', '1_202434182534_7613', 'S', 'Success', '2024-02-04 12:55:34', 'Y', '2024-02-04 12:55:34'),
(832, 0, '/login', 'undefined', '80505968_37175875', 'S', 'Success', '2024-02-04 12:55:59', 'Y', '2024-02-04 12:55:59'),
(833, 1, '/group/send_message', 'undefined', '_2024035182748_953', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-04 12:57:48'),
(834, 1, '/sender_id/add_sender_id', 'undefined', '1_202434182943_3028', 'S', 'Success', '2024-02-04 12:59:54', 'Y', '2024-02-04 12:59:43'),
(835, 1, '/group/send_message', 'undefined', '_2024035183047_904', 'Y', 'Success', '2024-02-04 13:02:19', 'Y', '2024-02-04 13:00:47'),
(836, 1, '/group/send_message', 'undefined', '_2024035183325_487', 'Y', 'Success', '2024-02-04 13:05:37', 'Y', '2024-02-04 13:03:25'),
(837, 1, '/template/create_template', 'undefined', '_2024036065001_252', 'S', 'Success', '2024-02-05 01:20:01', 'Y', '2024-02-05 01:20:01'),
(838, 1, '/template/create_template', 'undefined', '_2024036071704_412', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-05 01:47:04'),
(839, 0, '/login', 'undefined', '91073756_40514511', 'S', 'Success', '2024-02-05 11:10:54', 'Y', '2024-02-05 11:10:54'),
(840, 1, '/template/create_template', 'undefined', '_2024036164200_913', 'S', 'Success', '2024-02-05 11:12:00', 'Y', '2024-02-05 11:12:00'),
(841, 1, '/template/create_template', 'undefined', '_2024036173802_123', 'S', 'Success', '2024-02-05 12:08:02', 'Y', '2024-02-05 12:08:02'),
(842, 1, '/template/create_template', 'undefined', '_2024036174034_328', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-05 12:10:34'),
(843, 1, '/template/create_template', 'undefined', '_2024036175425_298', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-05 12:24:25'),
(844, 1, '/template/create_template', 'undefined', '_2024036175940_618', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-05 12:29:40'),
(845, 1, '/template/create_template', 'undefined', '_2024036175950_123', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-05 12:29:50'),
(846, 1, '/template/create_template', 'undefined', '_2024036180340_458', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-05 12:33:40'),
(847, 1, '/template/create_template', 'undefined', '_2024036180858_708', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-05 12:38:58'),
(848, 1, '/template/create_template', 'undefined', '_2024036181046_203', 'S', 'Success', '2024-02-05 12:40:47', 'Y', '2024-02-05 12:40:47'),
(849, 1, '/template/create_template', 'undefined', '_2024036181118_697', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-05 12:41:18'),
(850, 1, '/template/create_template', 'undefined', '_2024036181402_296', 'S', 'Success', '2024-02-05 12:44:02', 'Y', '2024-02-05 12:44:02'),
(851, 1, '/template/create_template', 'undefined', '_2024036182504_597', 'S', 'Success', '2024-02-05 12:55:04', 'Y', '2024-02-05 12:55:04'),
(852, 1, '/template/create_template', 'undefined', '_2024036182524_694', 'S', 'Success', '2024-02-05 12:55:24', 'Y', '2024-02-05 12:55:24'),
(853, 1, '/template/create_template', 'undefined', '_2024036182933_289', 'S', 'Success', '2024-02-05 12:59:34', 'Y', '2024-02-05 12:59:33'),
(854, 1, '/template/create_template', 'undefined', '_2024036183058_797', 'S', 'Success', '2024-02-05 13:00:58', 'Y', '2024-02-05 13:00:58'),
(855, 1, '/template/create_template', 'undefined', '_2024036183113_281', 'S', 'Success', '2024-02-05 13:01:13', 'Y', '2024-02-05 13:01:13'),
(856, 1, '/template/create_template', 'undefined', '_2024036183141_357', 'S', 'Success', '2024-02-05 13:01:41', 'Y', '2024-02-05 13:01:41'),
(857, 1, '/template/create_template', 'undefined', '_2024036183211_253', 'S', 'Success', '2024-02-05 13:02:11', 'Y', '2024-02-05 13:02:11'),
(858, 1, '/password/change_password', 'undefined', '1_202436100930_1303', 'F', 'Invalid Existing Password. Kindly try again!', '2024-02-06 04:39:30', 'Y', '2024-02-06 04:39:30'),
(859, 1, '/password/change_password', 'undefined', '1_202436101044_1418', 'S', 'Success', '2024-02-06 04:40:44', 'Y', '2024-02-06 04:40:44'),
(860, 1, '/logout', 'undefined', '1_202436101106_7349', 'S', 'Success', '2024-02-06 04:41:06', 'Y', '2024-02-06 04:41:06'),
(861, 0, '/login', 'undefined', '74530565_83443974', 'F', 'Invalid Password. Kindly try again with the valid details!', '2024-02-06 04:41:34', 'Y', '2024-02-06 04:41:34'),
(862, 0, '/login', 'undefined', '99882919_55641960', 'S', 'Success', '2024-02-06 04:41:38', 'Y', '2024-02-06 04:41:38'),
(863, 1, '/password/change_password', 'undefined', '1_202436101215_1511', 'S', 'Success', '2024-02-06 04:42:15', 'Y', '2024-02-06 04:42:15'),
(864, 0, '/login', 'undefined', '84134710_21988139', 'S', 'Success', '2024-02-06 06:22:21', 'Y', '2024-02-06 06:22:21'),
(865, 0, '/login', 'undefined', '32460545_17337755', 'S', 'Success', '2024-02-06 06:37:55', 'Y', '2024-02-06 06:37:55'),
(866, 1, '/logout', 'undefined', '1_202436143007_8878', 'S', 'Success', '2024-02-06 09:00:07', 'Y', '2024-02-06 09:00:07'),
(867, 0, '/login', 'undefined', '16664452_91778621', 'S', 'Success', '2024-02-06 09:00:25', 'Y', '2024-02-06 09:00:25'),
(868, 1, '/sender_id/add_sender_id', 'undefined', '1_202436143222_7617', 'S', 'Success', '2024-02-06 09:02:36', 'Y', '2024-02-06 09:02:22'),
(869, 1, '/group/add_members', 'undefined', '1_202436143439_8434', 'S', 'Success', '2024-02-06 09:07:06', 'Y', '2024-02-06 09:04:39'),
(870, 1, '/group/add_members', 'undefined', '1_202436151503_4301', 'F', 'Error occurred', '2024-02-06 09:45:27', 'Y', '2024-02-06 09:45:03'),
(871, 1, '/group/add_members', 'undefined', '1_202436151853_1960', 'F', 'Error occurred', '2024-02-06 09:49:42', 'Y', '2024-02-06 09:48:53'),
(872, 1, '/group/add_members', 'undefined', '1_202436155116_9469', 'S', 'Success', '2024-02-06 10:21:42', 'Y', '2024-02-06 10:21:16'),
(873, 1, '/group/create_group', 'undefined', '1_202436163557_6727', 'S', 'Success', '2024-02-06 11:06:22', 'Y', '2024-02-06 11:05:57'),
(874, 1, '/group/add_members', 'undefined', '1_202436164539_8372', 'S', 'Success', '2024-02-06 11:16:06', 'Y', '2024-02-06 11:15:39'),
(875, 1, '/group/add_members', 'undefined', '1_202436164730_2483', 'S', 'Success', '2024-02-06 11:17:59', 'Y', '2024-02-06 11:17:30'),
(876, 1, '/group/remove_members', 'undefined', '1_202436171636_7424', 'S', 'Success', '2024-02-06 11:47:03', 'Y', '2024-02-06 11:46:36'),
(877, 1, '/group/add_members', 'undefined', '1_202436171852_7969', 'F', 'Error occurred', '2024-02-06 11:49:19', 'Y', '2024-02-06 11:48:52'),
(878, 1, '/group/add_members', 'undefined', '1_202436171945_5262', 'F', 'Error occurred', '2024-02-06 11:50:10', 'Y', '2024-02-06 11:49:45'),
(879, 1, '/group/add_members', 'undefined', '1_202436172119_1092', 'S', 'Success', '2024-02-06 11:51:49', 'Y', '2024-02-06 11:51:20'),
(880, 1, '/group/create_admin', 'undefined', '_2024036175810_238', 'F', 'Error occurred', '2024-02-06 12:34:38', 'Y', '2024-02-06 12:34:12'),
(881, 0, '/group/create_admin', 'undefined', '_2024036175810_238', 'F', 'Request already processed', '2024-02-06 12:36:05', 'Y', '2024-02-06 12:36:05'),
(882, 1, '/group/create_admin', 'undefined', '_202403810_238', 'F', 'Error occurred', '2024-02-06 12:39:08', 'Y', '2024-02-06 12:38:40'),
(883, 0, '/group/create_admin', 'undefined', '_202403810_238', 'F', 'Request already processed', '2024-02-06 12:41:03', 'Y', '2024-02-06 12:41:03'),
(884, 1, '/group/create_admin', 'undefined', '_20240wjd0_238', 'F', 'Error occurred', '2024-02-06 12:41:38', 'Y', '2024-02-06 12:41:08'),
(885, 1, '/group/create_admin', 'undefined', '_20240djh0_238', 'F', 'Error occurred', '2024-02-06 12:44:35', 'Y', '2024-02-06 12:44:08'),
(886, 1, '/group/remove_members', 'undefined', '1_202437101057_1211', 'S', 'Success', '2024-02-07 04:41:41', 'Y', '2024-02-07 04:40:57'),
(887, 1, '/group/add_members', 'undefined', '1_202437101235_7378', 'F', 'Error occurred', '2024-02-07 04:43:06', 'Y', '2024-02-07 04:42:35'),
(888, 1, '/group/add_members', 'undefined', '1_202437101714_3021', 'S', 'Success', '2024-02-07 04:47:42', 'Y', '2024-02-07 04:47:14'),
(889, 1, '/group/remove_members', 'undefined', '1_202437103614_1724', 'S', 'Success', '2024-02-07 05:06:42', 'Y', '2024-02-07 05:06:14'),
(890, 1, '/group/add_members', 'undefined', '1_202437103711_6704', 'F', 'Error occurred', '2024-02-07 05:07:38', 'Y', '2024-02-07 05:07:11'),
(891, 1, '/group/add_members', 'undefined', '1_202437103836_5720', 'S', 'Success', '2024-02-07 05:09:06', 'Y', '2024-02-07 05:08:36'),
(892, 1, '/group/add_members', 'undefined', '1_202437104255_1670', 'F', 'No contacts found', '2024-02-07 05:13:21', 'Y', '2024-02-07 05:12:55'),
(893, 1, '/group/add_members', 'undefined', '1_202437104652_5687', 'F', 'No contacts found', '2024-02-07 05:17:19', 'Y', '2024-02-07 05:16:52'),
(894, 1, '/group/add_members', 'undefined', '1_202437105110_2285', 'F', 'No contacts found', '2024-02-07 05:21:36', 'Y', '2024-02-07 05:21:10'),
(895, 1, '/group/create_group', 'undefined', '1_202437113253_7155', 'F', 'Error occurred', '2024-02-07 06:03:16', 'Y', '2024-02-07 06:02:53'),
(896, 1, '/group/create_group', 'undefined', '1_202437113659_7901', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-07 06:06:59'),
(897, 1, '/group/create_group', 'undefined', '1_202437114011_3184', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-07 06:10:11'),
(898, 1, '/group/create_group', 'undefined', '1_202437114253_9705', 'F', 'Group already exists', '2024-02-07 06:12:53', 'Y', '2024-02-07 06:12:53'),
(899, 1, '/group/create_group', 'undefined', '1_202437114329_7850', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-07 06:13:30'),
(900, 1, '/group/create_group', 'undefined', '1_202437114538_1117', 'S', 'Success', '2024-02-07 06:16:03', 'Y', '2024-02-07 06:15:38'),
(901, 1, '/group/create_group', 'undefined', '1_202437114728_2569', 'S', 'Success', '2024-02-07 06:17:54', 'Y', '2024-02-07 06:17:28'),
(902, 1, '/group/create_group', 'undefined', '1_202437115033_7204', 'S', 'Success', '2024-02-07 06:20:58', 'Y', '2024-02-07 06:20:33'),
(903, 1, '/group/create_group', 'undefined', '1_202437115303_2104', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-07 06:23:03'),
(904, 1, '/group/create_group', 'undefined', '1_202437115355_1417', 'F', 'Sender ID unlinked', '2024-02-07 06:26:02', 'Y', '2024-02-07 06:23:55'),
(905, 1, '/sender_id/add_sender_id', 'undefined', '1_202437115647_1612', 'S', 'Success', '2024-02-07 06:26:57', 'Y', '2024-02-07 06:26:47'),
(906, 1, '/sender_id/add_sender_id', 'undefined', '1_202437115847_3755', 'F', 'QRcode already scanned', '2024-02-07 06:28:47', 'Y', '2024-02-07 06:28:47'),
(907, 1, '/group/create_group', 'undefined', '1_202437120139_4838', 'S', 'Success', '2024-02-07 06:34:09', 'Y', '2024-02-07 06:31:39'),
(908, 1, '/group/create_group', 'undefined', '1_202437121210_2535', 'S', 'Success', '2024-02-07 06:42:35', 'Y', '2024-02-07 06:42:10'),
(909, 1, '/group/create_group', 'undefined', '1_202437122107_5028', 'S', 'Success', '2024-02-07 06:51:32', 'Y', '2024-02-07 06:51:07'),
(910, 1, '/group/create_group', 'undefined', '1_202437122448_8820', 'S', 'Success', '2024-02-07 06:55:19', 'Y', '2024-02-07 06:54:48'),
(911, 1, '/group/create_group', 'undefined', '1_202437122653_4673', 'S', 'Success', '2024-02-07 06:57:19', 'Y', '2024-02-07 06:56:53'),
(912, 1, '/group/create_group', 'undefined', '1_202437122939_2685', 'S', 'Success', '2024-02-07 07:00:05', 'Y', '2024-02-07 06:59:39'),
(913, 1, '/group/create_group', 'undefined', '1_202437123531_7073', 'S', 'Success', '2024-02-07 07:05:54', 'Y', '2024-02-07 07:05:31'),
(914, 1, '/group/add_members', 'undefined', '1_202437124252_6781', 'F', 'Error occurred', '2024-02-07 07:13:17', 'Y', '2024-02-07 07:12:52'),
(915, 1, '/group/add_members', 'undefined', '1_202437124450_4110', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-07 07:14:50'),
(916, 1, '/group/add_members', 'undefined', '1_202437124536_1580', 'F', 'Error occurred', '2024-02-07 07:16:06', 'Y', '2024-02-07 07:15:36'),
(917, 1, '/group/create_group', 'undefined', '1_202437125210_3413', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-07 07:22:10'),
(918, 1, '/group/create_group', 'undefined', '1_202437125529_6165', 'S', 'Success', '2024-02-07 07:25:54', 'Y', '2024-02-07 07:25:29'),
(919, 1, '/group/create_group', 'undefined', '1_202437130152_8337', 'S', 'Success', '2024-02-07 07:32:16', 'Y', '2024-02-07 07:31:52'),
(920, 1, '/group/create_group', 'undefined', '1_202437130416_5918', 'S', 'Success', '2024-02-07 07:34:42', 'Y', '2024-02-07 07:34:16'),
(921, 1, '/group/create_group', 'undefined', '1_202437130750_9825', 'S', 'Success', '2024-02-07 07:38:16', 'Y', '2024-02-07 07:37:50'),
(922, 1, '/group/create_group', 'undefined', '1_202437131138_6077', 'S', 'Success', '2024-02-07 07:42:03', 'Y', '2024-02-07 07:41:38'),
(923, 1, '/group/create_group', 'undefined', '1_202437133547_7683', 'S', 'Success', '2024-02-07 08:06:13', 'Y', '2024-02-07 08:05:47'),
(924, 1, '/sender_id/add_sender_id', 'undefined', '1_202437150846_9599', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-07 09:38:46'),
(925, 1, '/sender_id/add_sender_id', 'undefined', '1_202437150955_8968', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-07 09:39:55'),
(926, 1, '/sender_id/add_sender_id', 'undefined', '1_202437151212_6155', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-07 09:42:12'),
(927, 1, '/sender_id/add_sender_id', 'undefined', '1_202437151412_8288', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-07 09:44:12'),
(928, 1, '/sender_id/add_sender_id', 'undefined', '1_202437151448_8083', 'S', 'Success', '2024-02-07 09:45:03', 'Y', '2024-02-07 09:44:48'),
(929, 1, '/sender_id/add_sender_id', 'undefined', '1_202437154934_4689', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-07 10:19:34'),
(930, 1, '/sender_id/add_sender_id', 'undefined', '1_202437155033_1330', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-07 10:20:33'),
(931, 1, '/sender_id/add_sender_id', 'undefined', '1_202437155215_5182', 'S', 'Success', '2024-02-07 10:22:31', 'Y', '2024-02-07 10:22:15'),
(932, 1, '/sender_id/add_sender_id', 'undefined', '1_202437160437_6159', 'S', 'Success', '2024-02-07 10:34:49', 'Y', '2024-02-07 10:34:37'),
(933, 1, '/sender_id/add_sender_id', 'undefined', '1_202437160638_6992', 'F', 'QRcode already scanned', '2024-02-07 10:36:38', 'Y', '2024-02-07 10:36:38'),
(934, 1, '/group/add_members', 'undefined', '1_202438102712_5284', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-08 04:57:12'),
(935, 1, '/sender_id/add_sender_id', 'undefined', '1_202438102923_4298', 'S', 'Success', '2024-02-08 04:59:31', 'Y', '2024-02-08 04:59:23'),
(936, 1, '/group/add_members', 'undefined', '1_202438103115_2348', 'F', 'Sender ID unlinked', '2024-02-08 05:03:18', 'Y', '2024-02-08 05:01:15'),
(937, 1, '/sender_id/add_sender_id', 'undefined', '1_202438103508_5775', 'S', 'Success', '2024-02-08 05:05:17', 'Y', '2024-02-08 05:05:08'),
(938, 1, '/sender_id/add_sender_id', 'undefined', '1_202438103708_5390', 'F', 'QRcode already scanned', '2024-02-08 05:07:08', 'Y', '2024-02-08 05:07:08'),
(939, 1, '/group/add_members', 'undefined', '1_202438103854_8245', 'F', 'Error occurred', '2024-02-08 05:10:10', 'Y', '2024-02-08 05:08:54'),
(940, 1, '/group/add_members', 'undefined', '1_202438104159_2733', 'F', 'Error occurred', '2024-02-08 05:13:48', 'Y', '2024-02-08 05:11:59'),
(941, 1, '/group/add_members', 'undefined', '1_202438104715_8701', 'F', 'No contacts found', '2024-02-08 05:17:39', 'Y', '2024-02-08 05:17:15'),
(942, 1, '/group/add_members', 'undefined', '1_202438104753_2341', 'S', 'Success', '2024-02-08 05:18:23', 'Y', '2024-02-08 05:17:53'),
(943, 1, '/group/add_members', 'undefined', '1_202438105534_3857', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-08 05:25:34'),
(944, 1, '/group/add_members', 'undefined', '1_202438105648_9399', 'S', 'Success', '2024-02-08 05:27:17', 'Y', '2024-02-08 05:26:48'),
(945, 1, '/group/create_group', 'undefined', '1_202438160908_9410', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-08 10:39:08'),
(946, 1, '/sender_id/add_sender_id', 'undefined', '1_202438161112_1081', 'S', 'Success', '2024-02-08 10:41:26', 'Y', '2024-02-08 10:41:12'),
(947, 1, '/group/create_group', 'undefined', '1_202438161239_6616', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-08 10:42:39'),
(948, 1, '/sender_id/add_sender_id', 'undefined', '1_202438161611_5717', 'S', 'Success', '2024-02-08 10:46:26', 'Y', '2024-02-08 10:46:11'),
(949, 1, '/group/create_group', 'undefined', '1_202438161753_4728', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-08 10:47:53'),
(950, 1, '/sender_id/add_sender_id', 'undefined', '1_202438162021_5165', 'S', 'Success', '2024-02-08 10:50:34', 'Y', '2024-02-08 10:50:21'),
(951, 1, '/group/create_group', 'undefined', '1_202438162140_8178', 'S', 'Success', '2024-02-08 10:55:06', 'Y', '2024-02-08 10:51:40'),
(952, 1, '/group/create_group', 'undefined', '1_202438162906_7633', 'S', 'Success', '2024-02-08 10:59:42', 'Y', '2024-02-08 10:59:06'),
(953, 1, '/group/create_group', 'undefined', '1_202438165024_5878', 'F', 'Error occurred', '2024-02-08 11:21:00', 'Y', '2024-02-08 11:20:24'),
(954, 1, '/group/create_group', 'undefined', '1_202438165244_5584', 'F', 'Error occurred', '2024-02-08 11:23:22', 'Y', '2024-02-08 11:22:44'),
(955, 1, '/group/create_group', 'undefined', '1_202438165730_8663', 'F', 'Error occurred', '2024-02-08 11:28:09', 'Y', '2024-02-08 11:27:30'),
(956, 1, '/group/create_group', 'undefined', '1_202438171042_7099', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-08 11:40:42'),
(957, 1, '/group/create_group', 'undefined', '1_202438171412_3330', 'F', 'Group already exists', '2024-02-08 11:44:12', 'Y', '2024-02-08 11:44:12'),
(958, 1, '/group/create_group', 'undefined', '1_202438171432_4628', 'S', 'Success', '2024-02-08 11:45:07', 'Y', '2024-02-08 11:44:32'),
(959, 1, '/group/create_group', 'undefined', '1_202438171908_4259', 'F', 'Sender ID unlinked', '2024-02-08 11:51:18', 'Y', '2024-02-08 11:49:08'),
(960, 1, '/sender_id/add_sender_id', 'undefined', '1_202438172216_5719', 'S', 'Success', '2024-02-08 11:52:34', 'Y', '2024-02-08 11:52:16'),
(961, 1, '/group/create_group', 'undefined', '1_202438172349_3185', 'F', 'Sender ID unlinked', '2024-02-08 11:55:55', 'Y', '2024-02-08 11:53:49'),
(962, 1, '/sender_id/add_sender_id', 'undefined', '1_202438172734_1040', 'S', 'Success', '2024-02-08 11:57:51', 'Y', '2024-02-08 11:57:34'),
(963, 1, '/group/create_group', 'undefined', '1_202438172908_3846', 'S', 'Success', '2024-02-08 12:02:42', 'Y', '2024-02-08 11:59:08'),
(964, 1, '/group/create_group', 'undefined', '1_202438174508_7947', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-08 12:15:08'),
(965, 1, '/group/create_group', 'undefined', '1_202438180959_3630', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-08 12:39:59'),
(966, 1, '/sender_id/add_sender_id', 'undefined', '1_202438181238_6274', 'S', 'Success', '2024-02-08 12:42:50', 'Y', '2024-02-08 12:42:38'),
(967, 1, '/group/create_group', 'undefined', '1_202438181404_4240', 'S', 'Success', '2024-02-08 12:47:07', 'Y', '2024-02-08 12:44:04'),
(968, 1, '/group/create_group', 'undefined', '1_202438182158_3560', 'S', 'Success', '2024-02-08 12:52:29', 'Y', '2024-02-08 12:51:58'),
(969, 1, '/group/create_group', 'undefined', '1_202438182618_5569', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-08 12:56:18'),
(970, 1, '/group/create_group', 'undefined', '1_202438182942_4918', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-08 12:59:42'),
(971, 1, '/group/create_group', 'undefined', '1_202438183752_8756', 'S', 'Success', '2024-02-08 13:08:32', 'Y', '2024-02-08 13:07:52'),
(972, 1, '/group/create_group', 'undefined', '1_202438184432_8504', 'S', 'Success', '2024-02-08 13:15:13', 'Y', '2024-02-08 13:14:32'),
(973, 1, '/group/promote_admin', 'undefined', '1_202438193619_1149', 'F', 'Error occurred', '2024-02-08 14:07:03', 'Y', '2024-02-08 14:06:19'),
(974, 1, '/group/promote_admin', 'undefined', '1_202438193722_8388', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-08 14:07:22'),
(975, 1, '/group/promote_admin', 'undefined', '1_202438193926_7674', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-08 14:09:26'),
(976, 1, '/sender_id/add_sender_id', 'undefined', '1_202438232246_2754', 'S', 'Success', '2024-02-08 17:54:00', 'Y', '2024-02-08 17:52:46'),
(977, 1, '/sender_id/add_sender_id', 'undefined', '1_202438232445_7233', 'S', 'Success', '2024-02-08 17:55:27', 'Y', '2024-02-08 17:54:45'),
(978, 1, '/sender_id/add_sender_id', 'undefined', '1_202438232645_2901', 'F', 'QRcode already scanned', '2024-02-08 17:56:45', 'Y', '2024-02-08 17:56:45'),
(979, 1, '/group/promote_admin', 'undefined', '1_202438233949_9328', 'F', 'Sender ID unlinked', '2024-02-08 18:12:10', 'Y', '2024-02-08 18:09:49'),
(980, 1, '/sender_id/add_sender_id', 'undefined', '1_202439000606_8914', 'S', 'Success', '2024-02-08 18:36:27', 'Y', '2024-02-08 18:36:06'),
(981, 1, '/group/promote_admin', 'undefined', '_202jwn38', 'Y', 'Success', '2024-02-08 18:39:56', 'Y', '2024-02-08 18:37:53'),
(982, 1, '/sender_id/add_sender_id', 'undefined', '1_202439000806_9306', 'F', 'QRcode already scanned', '2024-02-08 18:38:06', 'Y', '2024-02-08 18:38:06'),
(983, 1, '/group/promote_admin', 'undefined', '1_202439001139_7935', 'F', 'Error occurred', '2024-02-08 18:42:47', 'Y', '2024-02-08 18:41:39'),
(984, 1, '/group/promote_admin', 'undefined', '1_202439093326_1552', 'F', 'Error occurred', '2024-02-09 04:03:59', 'Y', '2024-02-09 04:03:26'),
(985, 1, '/group/promote_admin', 'undefined', '1_202439093852_3125', 'Y', 'Success', '2024-02-09 04:09:29', 'Y', '2024-02-09 04:08:52'),
(986, 1, '/group/promote_admin', 'undefined', '1_202439103250_1663', 'Y', 'Success', '2024-02-09 05:03:27', 'Y', '2024-02-09 05:02:50'),
(987, 1, '/logout', 'undefined', '1_202439103939_6853', 'S', 'Success', '2024-02-09 05:09:39', 'Y', '2024-02-09 05:09:39'),
(988, 0, '/login', 'undefined', '44526105_37566732', 'S', 'Success', '2024-02-09 05:10:12', 'Y', '2024-02-09 05:10:12'),
(989, 1, '/group/promote_admin', 'undefined', '1_202439104048_9307', 'Y', 'Success', '2024-02-09 05:11:33', 'Y', '2024-02-09 05:10:48'),
(990, 1, '/group/demote_admin', 'undefined', '1_202439104222_5362', 'Y', 'Success', '2024-02-09 05:13:07', 'Y', '2024-02-09 05:12:22'),
(991, 1, '/logout', 'undefined', '1_202439110254_3461', 'S', 'Success', '2024-02-09 05:32:54', 'Y', '2024-02-09 05:32:54'),
(992, 0, '/login', 'undefined', '25967651_75438566', 'S', 'Success', '2024-02-09 05:33:33', 'Y', '2024-02-09 05:33:33'),
(993, 1, '/group/promote_admin', 'undefined', '1_202439110412_1336', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-09 05:34:12'),
(994, 1, '/logout', 'undefined', '1_202439110642_4009', 'S', 'Success', '2024-02-09 05:36:42', 'Y', '2024-02-09 05:36:42'),
(995, 0, '/login', 'undefined', '42183140_44706691', 'S', 'Success', '2024-02-09 05:37:29', 'Y', '2024-02-09 05:37:29'),
(996, 1, '/sender_id/add_sender_id', 'undefined', '1_202439110742_8167', 'S', 'Success', '2024-02-09 05:37:54', 'Y', '2024-02-09 05:37:42'),
(997, 1, '/sender_id/add_sender_id', 'undefined', '1_202439110942_5089', 'F', 'QRcode already scanned', '2024-02-09 05:39:42', 'Y', '2024-02-09 05:39:42'),
(998, 1, '/group/promote_admin', 'undefined', '1_202439111029_5440', 'F', 'Sender ID unlinked', '2024-02-09 05:42:37', 'Y', '2024-02-09 05:40:29'),
(999, 1, '/logout', 'undefined', '1_202439111255_9845', 'S', 'Success', '2024-02-09 05:42:56', 'Y', '2024-02-09 05:42:55'),
(1000, 0, '/login', 'undefined', '36668959_32756885', 'S', 'Success', '2024-02-09 05:43:17', 'Y', '2024-02-09 05:43:17'),
(1001, 1, '/sender_id/add_sender_id', 'undefined', '1_202439111338_4910', 'S', 'Success', '2024-02-09 05:43:56', 'Y', '2024-02-09 05:43:38'),
(1002, 1, '/sender_id/add_sender_id', 'undefined', '1_202439111538_1497', 'F', 'QRcode already scanned', '2024-02-09 05:45:38', 'Y', '2024-02-09 05:45:38'),
(1003, 1, '/group/promote_admin', 'undefined', '1_202439111633_2633', 'Y', 'Success', '2024-02-09 05:50:53', 'Y', '2024-02-09 05:46:33'),
(1004, 1, '/group/demote_admin', 'undefined', '1_202439112157_3230', 'Y', 'Success', '2024-02-09 05:52:47', 'Y', '2024-02-09 05:51:57'),
(1005, 1, '/group/create_group', 'undefined', '1_202439112717_4959', 'S', 'Success', '2024-02-09 05:57:58', 'Y', '2024-02-09 05:57:17'),
(1006, 1, '/group/demote_admin', 'undefined', '1_202439120236_1645', 'Y', 'Success', '2024-02-09 06:33:23', 'Y', '2024-02-09 06:32:36'),
(1007, 1, '/sender_id/add_sender_id', 'undefined', '1_202439152240_2646', 'S', 'Success', '2024-02-09 09:52:52', 'Y', '2024-02-09 09:52:40'),
(1008, 1, '/sender_id/add_sender_id', 'undefined', '1_202439152441_1247', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-09 09:54:41'),
(1009, 1, '/sender_id/add_sender_id', 'undefined', '1_202439153503_4393', 'S', 'Success', '2024-02-09 10:05:20', 'Y', '2024-02-09 10:05:03'),
(1010, 1, '/sender_id/add_sender_id', 'undefined', '1_202439153520_7377', 'S', 'Success', '2024-02-09 10:05:41', 'Y', '2024-02-09 10:05:20'),
(1011, 1, '/sender_id/add_sender_id', 'undefined', '1_202439153541_2043', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-09 10:05:41'),
(1012, 1, '/sender_id/add_sender_id', 'undefined', '1_202439154207_8191', 'S', 'Success', '2024-02-09 10:12:28', 'Y', '2024-02-09 10:12:07'),
(1013, 1, '/sender_id/add_sender_id', 'undefined', '1_202439154814_4584', 'S', 'Success', '2024-02-09 10:18:41', 'Y', '2024-02-09 10:18:14'),
(1014, 1, '/sender_id/add_sender_id', 'undefined', '1_202439155029_6182', 'S', 'Success', '2024-02-09 10:21:06', 'Y', '2024-02-09 10:20:29'),
(1015, 1, '/sender_id/add_sender_id', 'undefined', '1_202439161739_8049', 'S', 'Success', '2024-02-09 10:47:53', 'Y', '2024-02-09 10:47:39'),
(1016, 0, '/login', 'undefined', '64060809_47957464', 'S', 'Success', '2024-02-09 18:14:26', 'Y', '2024-02-09 18:14:26'),
(1017, 1, '/sender_id/add_sender_id', 'undefined', '1_202442172205_4989', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-12 11:52:05'),
(1018, 1, '/sender_id/add_sender_id', 'undefined', '1_202442172404_8212', 'F', 'Validity period is expired.', '2024-02-12 11:54:04', 'Y', '2024-02-12 11:54:04'),
(1019, 1, '/group/send_message', 'undefined', '_2024043172516_118', 'F', 'Validity period is expired.', '2024-02-12 11:55:16', 'Y', '2024-02-12 11:55:16'),
(1020, 1, '/sender_id/add_sender_id', 'undefined', '1_202442172714_3046', 'S', 'Success', '2024-02-12 11:57:22', 'Y', '2024-02-12 11:57:14'),
(1021, 1, '/sender_id/add_sender_id', 'undefined', '1_202442172914_5740', 'F', 'QRcode already scanned', '2024-02-12 11:59:14', 'Y', '2024-02-12 11:59:14'),
(1022, 1, '/logout', 'undefined', '1_202442181959_4335', 'S', 'Success', '2024-02-12 12:49:59', 'Y', '2024-02-12 12:49:59'),
(1023, 0, '/login', 'undefined', '36666811_89991507', 'S', 'Success', '2024-02-12 12:50:39', 'Y', '2024-02-12 12:50:39'),
(1024, 1, '/group/add_members', 'undefined', '1_202442182649_8947', 'S', 'Success', '2024-02-12 12:59:20', 'Y', '2024-02-12 12:56:49'),
(1025, 1, '/group/add_members', 'undefined', '1_202442183117_6453', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-12 13:01:17'),
(1026, 1, '/group/add_members', 'undefined', '1_202442183339_2393', 'F', 'Sender ID unlinked', '2024-02-12 13:05:44', 'Y', '2024-02-12 13:03:39'),
(1027, 1, '/sender_id/add_sender_id', 'undefined', '1_202442183720_9067', 'S', 'Success', '2024-02-12 13:07:56', 'Y', '2024-02-12 13:07:20'),
(1028, 1, '/sender_id/add_sender_id', 'undefined', '1_202442183920_3671', 'F', 'QRcode already scanned', '2024-02-12 13:09:20', 'Y', '2024-02-12 13:09:20'),
(1029, 1, '/group/add_members', 'undefined', '1_202442183945_3546', 'S', 'Success', '2024-02-12 13:12:22', 'Y', '2024-02-12 13:09:45'),
(1030, 0, '/login', 'undefined', '50290547_99691912', 'S', 'Success', '2024-02-13 04:16:56', 'Y', '2024-02-13 04:16:56'),
(1031, 0, '/group/promote_admin', 'undefined', '1_202443102000_7198', 'F', 'Invalid token or User ID', '2024-02-13 04:51:36', 'Y', '2024-02-13 04:51:36'),
(1032, 0, '/group/promote_admin', 'undefined', '1_202443102000_7198', 'F', 'Request already processed', '2024-02-13 04:52:15', 'Y', '2024-02-13 04:52:15'),
(1033, 1, '/group/promote_admin', 'undefined', '1_20244310200s198', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 04:52:26'),
(1034, 1, '/group/promote_admin', 'undefined', '1_20244310200st198', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 04:53:54'),
(1035, 1, '/group/promote_admin', 'undefined', '1_20244310st198', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 05:03:05'),
(1036, 1, '/group/promote_admin', 'undefined', '1_2024431d0st198', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 05:04:01'),
(1037, 1, '/group/promote_admin', 'undefined', '1_2024431d0st198', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 05:04:28'),
(1038, 1, '/group/promote_admin', 'undefined', '1_2024431d0std198', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 05:05:21'),
(1039, 1, '/group/promote_admin', 'undefined', '1_2024431d0dstd198', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 05:07:27'),
(1040, 1, '/group/promote_admin', 'undefined', '1_2024431d0dstd198', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 05:10:52'),
(1041, 1, '/group/promote_admin', 'undefined', '1_2024431d0sdstd198', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 05:12:26'),
(1042, 1, '/group/promote_admin', 'undefined', '1_2024431d0sdsdtd198', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 05:13:14'),
(1043, 1, '/group/promote_admin', 'undefined', '1_2024431d0dsdsdtd198', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 05:17:27'),
(1044, 1, '/group/promote_admin', 'undefined', '1_2024431d0dsdsdtd1d98', 'F', 'Sender ID unlinked', '2024-02-13 05:22:07', 'Y', '2024-02-13 05:20:02'),
(1045, 1, '/sender_id/add_sender_id', 'undefined', '1_202443105318_9345', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 05:23:18'),
(1046, 1, '/sender_id/add_sender_id', 'undefined', '1_202443105451_3271', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 05:24:51'),
(1047, 1, '/sender_id/add_sender_id', 'undefined', '1_202443105936_8581', 'S', 'Success', '2024-02-13 05:29:51', 'Y', '2024-02-13 05:29:36'),
(1048, 1, '/group/promote_admin', 'undefined', '1_202443110139_9657', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 05:31:39'),
(1049, 1, '/group/promote_admin', 'undefined', '1_2024431d0dsdsddtd1d98', 'F', 'Error occurred', '2024-02-13 05:45:54', 'Y', '2024-02-13 05:37:21'),
(1050, 1, '/group/promote_admin', 'undefined', '1_2024431d0dsdsddtd1d98', 'F', 'Error occurred', '2024-02-13 05:45:54', 'Y', '2024-02-13 05:39:14'),
(1051, 1, '/group/promote_admin', 'undefined', '1_2024431d0dsdsddtd1d98', 'F', 'Error occurred', '2024-02-13 05:45:54', 'Y', '2024-02-13 05:43:03'),
(1052, 0, '/group/promote_admin', 'undefined', '1_2024431d0dsdsddtd1d98', 'F', 'Request already processed', '2024-02-13 05:49:02', 'Y', '2024-02-13 05:49:02'),
(1053, 1, '/group/promote_admin', 'undefined', '1_2024431dsddtd1d98', 'F', 'Error occurred', '2024-02-13 05:49:49', 'Y', '2024-02-13 05:49:13'),
(1054, 0, '/group/promote_admin', 'undefined', '1_2024431dsddtd1d98', 'F', 'Request already processed', '2024-02-13 06:01:18', 'Y', '2024-02-13 06:01:18'),
(1055, 1, '/group/promote_admin', 'undefined', '1_202443sddtd1d98', 'F', 'Error occurred', '2024-02-13 06:02:07', 'Y', '2024-02-13 06:01:23'),
(1056, 1, '/group/promote_admin', 'undefined', '1_202443sdddtd1d98', 'F', 'Error occurred', '2024-02-13 06:10:16', 'Y', '2024-02-13 06:09:36'),
(1057, 1, '/group/promote_admin', 'undefined', '1_202443sdddtdd98', 'Y', 'undefined', '2024-02-13 06:13:19', 'Y', '2024-02-13 06:12:41'),
(1058, 0, '/group/promote_admin', 'undefined', '1_202443sdddtdd98', 'F', 'Request already processed', '2024-02-13 06:19:23', 'Y', '2024-02-13 06:19:23'),
(1059, 1, '/group/promote_admin', 'undefined', '1_202443sdddhdd98', 'Y', 'undefined', '2024-02-13 06:20:30', 'Y', '2024-02-13 06:19:49'),
(1060, 1, '/group/promote_admin', 'undefined', '1_202443115250_5988', 'F', 'Error occurred', '2024-02-13 06:23:29', 'Y', '2024-02-13 06:22:50'),
(1061, 1, '/group/promote_admin', 'undefined', '1_202443115250s_5988', 'F', 'Error occurred', '2024-02-13 06:25:07', 'Y', '2024-02-13 06:24:25'),
(1062, 1, '/group/promote_admin', 'undefined', '1_202443115250s_c5988', 'F', 'Error occurred', '2024-02-13 06:32:15', 'Y', '2024-02-13 06:31:38'),
(1063, 1, '/group/promote_admin', 'undefined', '1_202443115vv250s_c5988', 'F', 'Error occurred', '2024-02-13 06:35:07', 'Y', '2024-02-13 06:34:28'),
(1064, 0, '/group/promote_admin', 'undefined', '1_202443115vv250s_c5988', 'F', 'Request already processed', '2024-02-13 06:36:06', 'Y', '2024-02-13 06:36:06'),
(1065, 1, '/group/promote_admin', 'undefined', '1_20244311w50s_c5988', 'F', 'Error occurred', '2024-02-13 06:36:49', 'Y', '2024-02-13 06:36:14'),
(1066, 1, '/group/promote_admin', 'undefined', '1_202443120933_3129', 'F', 'Error occurred', '2024-02-13 06:40:07', 'Y', '2024-02-13 06:39:33'),
(1067, 0, '/group/promote_admin', 'undefined', '1_20244311w50s_c5988', 'F', 'Request already processed', '2024-02-13 06:42:53', 'Y', '2024-02-13 06:42:53'),
(1068, 1, '/group/promote_admin', 'undefined', '1_202443110s_c5988', 'F', 'Error occurred', '2024-02-13 06:44:09', 'Y', '2024-02-13 06:43:31'),
(1069, 1, '/group/promote_admin', 'undefined', '1_2024431_c5988', 'F', 'Error occurred', '2024-02-13 06:47:29', 'Y', '2024-02-13 06:46:54'),
(1070, 0, '/group/promote_admin', 'undefined', '1_2024431_c5988', 'F', 'Request already processed', '2024-02-13 06:52:11', 'Y', '2024-02-13 06:52:11'),
(1071, 1, '/group/promote_admin', 'undefined', '1_2024edef_c5988', 'F', 'Error occurred', '2024-02-13 06:52:57', 'Y', '2024-02-13 06:52:18'),
(1072, 0, '/group/promote_admin', 'undefined', '1_2024edef_c5988', 'F', 'Request already processed', '2024-02-13 06:53:34', 'Y', '2024-02-13 06:53:34'),
(1073, 1, '/group/promote_admin', 'undefined', '1_2024ede5988', 'F', 'Error occurred', '2024-02-13 06:54:26', 'Y', '2024-02-13 06:53:40'),
(1074, 1, '/group/promote_admin', 'undefined', '1_2024e5988', 'F', 'Sender ID unlinked', '2024-02-13 06:58:42', 'Y', '2024-02-13 06:56:35'),
(1075, 1, '/sender_id/add_sender_id', 'undefined', '1_202443122905_7328', 'S', 'Success', '2024-02-13 06:59:22', 'Y', '2024-02-13 06:59:05'),
(1076, 1, '/sender_id/add_sender_id', 'undefined', '1_202443123121_6159', 'S', 'Success', '2024-02-13 07:01:34', 'Y', '2024-02-13 07:01:21'),
(1077, 1, '/sender_id/add_sender_id', 'undefined', '1_202443123322_4090', 'S', 'Success', '2024-02-13 07:03:31', 'Y', '2024-02-13 07:03:22'),
(1078, 1, '/sender_id/add_sender_id', 'undefined', '1_202443123452_5304', 'S', 'Success', '2024-02-13 07:05:07', 'Y', '2024-02-13 07:04:53'),
(1079, 1, '/sender_id/add_sender_id', 'undefined', '1_202443124452_3342', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 07:14:53'),
(1080, 1, '/sender_id/add_sender_id', 'undefined', '1_202443124523_5962', 'S', 'Success', '2024-02-13 07:15:43', 'Y', '2024-02-13 07:15:23'),
(1081, 1, '/sender_id/add_sender_id', 'undefined', '1_202443124723_8881', 'S', 'Success', '2024-02-13 07:17:36', 'Y', '2024-02-13 07:17:23'),
(1082, 1, '/sender_id/add_sender_id', 'undefined', '1_202443125616_8248', 'S', 'Success', '2024-02-13 07:26:30', 'Y', '2024-02-13 07:26:16'),
(1083, 0, '/group/promote_admin', 'undefined', '1_2024e5988', 'F', 'Request already processed', '2024-02-13 07:27:57', 'Y', '2024-02-13 07:27:57'),
(1084, 0, '/group/promote_admin', 'undefined', '1_2024e5988', 'F', 'Request already processed', '2024-02-13 07:28:15', 'Y', '2024-02-13 07:28:15'),
(1085, 1, '/group/promote_admin', 'undefined', '1_2024abjkd988', 'F', 'Error occurred', '2024-02-13 07:31:45', 'Y', '2024-02-13 07:28:36'),
(1086, 1, '/group/promote_admin', 'undefined', '1_2024abjdsjfsk988', 'F', 'Error occurred', '2024-02-13 07:37:12', 'Y', '2024-02-13 07:36:28'),
(1087, 1, '/group/promote_admin', 'undefined', '1_2024abjdsjfssk988', 'F', 'Sender ID unlinked', '2024-02-13 07:53:54', 'Y', '2024-02-13 07:51:26'),
(1088, 1, '/sender_id/add_sender_id', 'undefined', '1_202443132422_4002', 'S', 'Success', '2024-02-13 07:54:42', 'Y', '2024-02-13 07:54:22'),
(1089, 1, '/sender_id/add_sender_id', 'undefined', '1_202443133513_5029', 'S', 'Success', '2024-02-13 08:05:28', 'Y', '2024-02-13 08:05:13'),
(1090, 1, '/sender_id/add_sender_id', 'undefined', '1_202443133713_1077', 'S', 'Success', '2024-02-13 08:07:27', 'Y', '2024-02-13 08:07:13'),
(1091, 1, '/group/promote_admin', 'undefined', '1_2024abjdsjfskndsssk988', 'F', 'Error occurred', '2024-02-13 08:12:07', 'Y', '2024-02-13 08:08:49'),
(1092, 1, '/group/promote_admin', 'undefined', '1_202443141233_6148', 'S', 'SUCCESS', '2024-02-13 08:43:17', 'Y', '2024-02-13 08:42:33'),
(1093, 1, '/group/promote_admin', 'undefined', '1_202443141505_7543', 'S', 'SUCCESS', '2024-02-13 08:45:54', 'Y', '2024-02-13 08:45:05'),
(1094, 1, '/group/promote_admin', 'undefined', '1_202443141917_9853', 'S', 'SUCCESS', '2024-02-13 08:49:59', 'Y', '2024-02-13 08:49:17');
INSERT INTO `api_log` (`api_log_id`, `user_id`, `api_url`, `ip_address`, `request_id`, `response_status`, `response_comments`, `response_date`, `api_log_status`, `api_log_entry_date`) VALUES
(1095, 1, '/group/promote_admin', 'undefined', '1_202443142104_2026', 'S', 'SUCCESS', '2024-02-13 08:51:54', 'Y', '2024-02-13 08:51:04'),
(1096, 1, '/group/promote_admin', 'undefined', '1_202443142259_1663', 'S', 'SUCCESS', '2024-02-13 08:53:40', 'Y', '2024-02-13 08:52:59'),
(1097, 1, '/group/promote_admin', 'undefined', '1_202443143339_7244', 'S', 'SUCCESS', '2024-02-13 09:04:23', 'Y', '2024-02-13 09:03:39'),
(1098, 1, '/group/promote_admin', 'undefined', '1_202443143752_7844', 'S', 'SUCCESS', '2024-02-13 09:08:42', 'Y', '2024-02-13 09:07:52'),
(1099, 1, '/group/promote_admin', 'undefined', '1_202443150112_2989', 'F', 'Sender ID unlinked', '2024-02-13 09:33:16', 'Y', '2024-02-13 09:31:12'),
(1100, 1, '/sender_id/add_sender_id', 'undefined', '1_202443150524_4395', 'S', 'Success', '2024-02-13 09:35:40', 'Y', '2024-02-13 09:35:24'),
(1101, 1, '/group/promote_admin', 'undefined', '1_202443150724_9497', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 09:37:24'),
(1102, 1, '/group/promote_admin', 'undefined', '1_202443150847_7446', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 09:38:47'),
(1103, 1, '/group/promote_admin', 'undefined', '1_202443151602_2572', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 09:46:02'),
(1104, 1, '/sender_id/add_sender_id', 'undefined', '1_202443152011_2285', 'S', 'Success', '2024-02-13 09:50:27', 'Y', '2024-02-13 09:50:11'),
(1105, 1, '/group/promote_admin', 'undefined', '1_202443152142_9244', 'F', 'Error occurred', '2024-02-13 09:53:14', 'Y', '2024-02-13 09:51:42'),
(1106, 1, '/group/promote_admin', 'undefined', '1_202443152447_2147', 'S', 'SUCCESS', '2024-02-13 09:56:20', 'Y', '2024-02-13 09:54:47'),
(1107, 1, '/group/promote_admin', 'undefined', '1_202443153203_9734', 'S', 'SUCCESS', '2024-02-13 10:04:31', 'Y', '2024-02-13 10:02:03'),
(1108, 1, '/group/promote_admin', 'undefined', '1_202443153715_9221', 'S', 'SUCCESS', '2024-02-13 10:08:01', 'Y', '2024-02-13 10:07:15'),
(1109, 1, '/group/promote_admin', 'undefined', '1_202443153844_3796', 'S', 'SUCCESS', '2024-02-13 10:09:29', 'Y', '2024-02-13 10:08:44'),
(1110, 1, '/group/promote_admin', 'undefined', '1_202443154117_9344', 'S', 'SUCCESS', '2024-02-13 10:12:09', 'Y', '2024-02-13 10:11:17'),
(1111, 1, '/group/promote_admin', 'undefined', '1_202443154312_8533', 'S', 'SUCCESS', '2024-02-13 10:13:59', 'Y', '2024-02-13 10:13:12'),
(1112, 1, '/group/promote_admin', 'undefined', '1_202443154631_5467', 'S', 'SUCCESS', '2024-02-13 10:17:22', 'Y', '2024-02-13 10:16:31'),
(1113, 1, '/group/promote_admin', 'undefined', '1_202443155442_5442', 'F', 'Error occurred', '2024-02-13 10:25:34', 'Y', '2024-02-13 10:24:42'),
(1114, 1, '/group/promote_admin', 'undefined', '1_202443155740_2065', 'S', 'SUCCESS', '2024-02-13 10:28:27', 'Y', '2024-02-13 10:27:40'),
(1115, 1, '/group/promote_admin', 'undefined', '1_202443160015_7738', 'S', 'SUCCESS', '2024-02-13 10:31:03', 'Y', '2024-02-13 10:30:15'),
(1116, 1, '/group/promote_admin', 'undefined', '1_202443160502_9537', 'S', 'SUCCESS', '2024-02-13 10:38:04', 'Y', '2024-02-13 10:35:02'),
(1117, 1, '/group/add_members', 'undefined', '1_202443161002_4596', 'F', 'Sender ID unlinked', '2024-02-13 10:42:08', 'Y', '2024-02-13 10:40:02'),
(1118, 1, '/sender_id/add_sender_id', 'undefined', '1_202443161228_6094', 'S', 'Success', '2024-02-13 10:42:46', 'Y', '2024-02-13 10:42:28'),
(1119, 1, '/group/add_members', 'undefined', '1_202443161408_7342', 'S', 'Success', '2024-02-13 10:48:14', 'Y', '2024-02-13 10:44:08'),
(1120, 1, '/group/promote_admin', 'undefined', '1_202443162711_8432', 'S', 'SUCCESS', '2024-02-13 10:58:06', 'Y', '2024-02-13 10:57:11'),
(1121, 1, '/group/promote_admin', 'undefined', '1_202443164626_8879', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 11:16:26'),
(1122, 1, '/group/promote_admin', 'undefined', '1_202443170027_8211', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 11:30:27'),
(1123, 1, '/sender_id/add_sender_id', 'undefined', '1_202443170307_4206', 'S', 'Success', '2024-02-13 11:33:24', 'Y', '2024-02-13 11:33:07'),
(1124, 1, '/sender_id/add_sender_id', 'undefined', '1_202443170507_5142', 'F', 'QRcode already scanned', '2024-02-13 11:35:07', 'Y', '2024-02-13 11:35:07'),
(1125, 1, '/group/promote_admin', 'undefined', '1_202443170712_2018', 'S', 'SUCCESS', '2024-02-13 11:37:58', 'Y', '2024-02-13 11:37:12'),
(1126, 1, '/group/promote_admin', 'undefined', '1_202443171534_6377', 'F', 'Sender ID unlinked', '2024-02-13 11:47:45', 'Y', '2024-02-13 11:45:34'),
(1127, 1, '/sender_id/add_sender_id', 'undefined', '1_202443171832_2037', 'S', 'Success', '2024-02-13 11:48:52', 'Y', '2024-02-13 11:48:32'),
(1128, 1, '/sender_id/add_sender_id', 'undefined', '1_202443172033_2584', 'F', 'QRcode already scanned', '2024-02-13 11:50:33', 'Y', '2024-02-13 11:50:33'),
(1129, 1, '/group/promote_admin', 'undefined', '1_202443172132_1198', 'S', 'SUCCESS', '2024-02-13 11:55:33', 'Y', '2024-02-13 11:51:32'),
(1130, 1, '/group/demote_admin', 'undefined', '1_202443190847_8211', 'S', 'SUCCESS', '2024-02-13 13:39:33', 'Y', '2024-02-13 13:38:47'),
(1131, 1, '/group/demote_admin', 'undefined', '1_202443191311_5792', 'S', 'SUCCESS', '2024-02-13 13:44:21', 'Y', '2024-02-13 13:43:12'),
(1132, 1, '/group/demote_admin', 'undefined', '1_202443192332_8460', 'S', 'SUCCESS', '2024-02-13 13:54:41', 'Y', '2024-02-13 13:53:32'),
(1133, 1, '/group/promote_admin', 'undefined', '1_202443192646_1581', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 13:56:46'),
(1134, 1, '/group/promote_admin', 'undefined', '1_202443193127_6256', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 14:01:27'),
(1135, 1, '/group/promote_admin', 'undefined', '1_202443193322_8439', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 14:03:22'),
(1136, 0, '/login', 'undefined', '19141946_18088898', 'S', 'Success', '2024-02-13 14:08:50', 'Y', '2024-02-13 14:08:50'),
(1137, 1, '/group/promote_admin', 'undefined', '1_202443193933_6936', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 14:09:33'),
(1138, 1, '/group/promote_admin', 'undefined', '1_202443194449_1742', 'F', 'Sender ID unlinked', '2024-02-13 14:17:09', 'Y', '2024-02-13 14:14:49'),
(1139, 1, '/group/promote_admin', 'undefined', '1_202443194929_9903', 'F', 'Sender ID not found', '2024-02-13 14:19:29', 'Y', '2024-02-13 14:19:29'),
(1140, 1, '/sender_id/add_sender_id', 'undefined', '1_202443195048_6571', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 14:20:48'),
(1141, 1, '/sender_id/add_sender_id', 'undefined', '1_202443195248_9076', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 14:22:49'),
(1142, 1, '/sender_id/add_sender_id', 'undefined', '1_202443195448_4618', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 14:24:49'),
(1143, 1, '/sender_id/add_sender_id', 'undefined', '1_202443195449_6767', 'N', '-', '0000-00-00 00:00:00', 'Y', '2024-02-13 14:24:49');

-- --------------------------------------------------------

--
-- Table structure for table `cron_compose`
--

CREATE TABLE `cron_compose` (
  `cron_com_id` int(11) NOT NULL,
  `com_msg_id` int(11) NOT NULL,
  `com_msg_media_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `group_master_id` int(11) NOT NULL,
  `cron_status` varchar(1) NOT NULL,
  `schedule_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `reschedule_date` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `cron_compose`
--

INSERT INTO `cron_compose` (`cron_com_id`, `com_msg_id`, `com_msg_media_id`, `user_id`, `group_master_id`, `cron_status`, `schedule_date`, `reschedule_date`) VALUES
(1, 105, 103, 1, 0, 'Y', '2024-02-01 10:56:21', NULL),
(2, 106, 104, 1, 0, 'Y', '2024-02-01 10:56:21', NULL),
(3, 107, 105, 1, 0, 'Y', '2024-02-01 10:56:21', NULL),
(4, 108, 106, 1, 0, 'Y', '2024-02-01 10:56:21', NULL),
(5, 109, 107, 1, 0, 'Y', '2024-02-01 10:56:21', NULL),
(6, 110, 108, 1, 0, 'Y', '2024-02-01 10:56:21', NULL),
(7, 111, 109, 1, 0, 'Y', '2024-02-01 10:56:21', NULL),
(8, 112, 110, 1, 0, 'Y', '2024-02-04 12:55:08', NULL),
(9, 113, 111, 1, 0, 'Y', '2024-02-01 11:05:24', NULL),
(10, 114, 112, 1, 0, 'Y', '2024-02-01 11:42:30', NULL),
(11, 183, 178, 1, 2, 'Y', '2024-02-03 07:09:28', NULL),
(12, 185, 180, 1, 2, 'Y', '2024-02-03 07:13:29', NULL),
(13, 186, 181, 1, 2, 'Y', '2024-02-03 11:49:35', NULL),
(14, 186, 182, 1, 2, 'Y', '2024-02-03 07:17:30', NULL),
(15, 187, 183, 1, 2, 'Y', '2024-02-03 07:45:52', NULL),
(16, 187, 184, 1, 2, 'Y', '2024-02-03 07:42:32', NULL),
(17, 189, 187, 1, 2, 'S', '2024-02-03 07:49:30', NULL),
(18, 189, 188, 1, 2, 'S', '2024-02-03 07:49:30', NULL),
(19, 190, 189, 1, 2, 'Y', '2024-02-03 07:52:31', NULL),
(20, 190, 190, 1, 2, 'Y', '2024-02-03 07:52:31', NULL),
(21, 191, 191, 1, 2, 'Y', '2024-02-03 12:06:01', NULL),
(22, 192, 192, 1, 2, 'Y', '2024-02-03 08:04:31', NULL),
(23, 193, 193, 1, 2, 'Y', '2024-02-03 08:57:30', NULL),
(24, 194, 194, 1, 2, 'Y', '2024-02-04 12:55:03', NULL),
(25, 195, 195, 1, 2, 'Y', '2024-02-03 09:00:34', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `group_contacts`
--

CREATE TABLE `group_contacts` (
  `group_contacts_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `group_master_id` int(11) NOT NULL,
  `campaign_name` varchar(30) NOT NULL,
  `mobile_no` varchar(30) NOT NULL,
  `mobile_id` varchar(30) DEFAULT NULL,
  `comments` varchar(50) NOT NULL,
  `group_contacts_status` char(1) NOT NULL,
  `group_contacts_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `remove_comments` varchar(50) DEFAULT NULL,
  `admin_status` varchar(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=COMPACT;

--
-- Dumping data for table `group_contacts`
--

INSERT INTO `group_contacts` (`group_contacts_id`, `user_id`, `group_master_id`, `campaign_name`, `mobile_no`, `mobile_id`, `comments`, `group_contacts_status`, `group_contacts_entry_date`, `remove_comments`, `admin_status`) VALUES
(1, 1, 1, 'ca_TESTING_023_1', '919361419661', '919361419661', 'Success', 'Y', '2024-01-23 08:02:57', NULL, 'Y'),
(2, 1, 1, 'ca_TESTING_023_2', '916380885546', '916380885546', 'Success', 'Y', '2024-01-23 08:05:26', NULL, 'Y'),
(3, 1, 2, 'ca_Demo_026_3', '919965014814', '919965014814', 'Success', 'Y', '2024-01-26 01:33:57', NULL, NULL),
(4, 1, 2, 'ca_Demo_026_4', '916369841530', '916369841530', 'Success', 'Y', '2024-01-26 01:36:01', NULL, NULL),
(5, 1, 2, 'ca_Demo_026_5', '919150794800', '919150794800', 'Success', 'Y', '2024-01-26 01:36:59', NULL, NULL),
(6, 1, 1, 'ca_TESTING_037_6', '919025167792', '919025167792', 'Success', 'Y', '2024-02-06 09:07:06', NULL, 'R'),
(7, 1, 1, 'ca_TESTING_037_7', '919786448157', '919786448157', 'Success', 'Y', '2024-02-06 10:21:42', NULL, 'R'),
(8, 1, 3, 'ca_Demo Group_037_8', '919965014814', '919965014814', 'Success', 'Y', '2024-02-06 11:06:22', NULL, NULL),
(9, 1, 3, 'ca_Demo Group_037_9', '916369841530', '916369841530', 'Success', 'Y', '2024-02-06 11:16:06', NULL, NULL),
(10, 1, 3, 'ca_Demo Group_037_10', '919150794800', '919150794800', 'Success', 'R', '2024-02-06 11:17:59', 'testing', NULL),
(11, 1, 3, 'ca_Demo Group_037_11', '919150794800', '919150794800', 'Success', 'R', '2024-02-06 11:51:49', 'test', NULL),
(12, 1, 3, 'ca_Demo Group_038_12', '919150794800', '919150794800', 'Success', 'R', '2024-02-07 04:47:42', 'test', NULL),
(13, 1, 3, 'ca_Demo Group_038_13', '919150794800', '919150794800', 'Success', 'Y', '2024-02-07 05:09:06', NULL, NULL),
(14, 1, 6, 'ca_God_038_14', '919965014814', '919965014814', 'Success', 'Y', '2024-02-07 06:16:03', NULL, NULL),
(15, 1, 7, 'ca_index_038_15', '919965014814', '919965014814', 'Success', 'Y', '2024-02-07 06:17:54', NULL, 'Y'),
(16, 1, 8, 'ca_test_038_16', '919965014814', '919965014814', 'Success', 'Y', '2024-02-07 06:20:58', NULL, NULL),
(17, 1, 9, 'ca_Block_038_17', '919965014814', '919965014814', 'Success', 'Y', '2024-02-07 06:34:09', NULL, NULL),
(18, 1, 10, 'ca_Name_038_18', '919965014814', '919965014814', 'Success', 'Y', '2024-02-07 06:42:35', NULL, NULL),
(19, 1, 11, 'ca_view_038_19', '919965014814', '919965014814', 'Success', 'Y', '2024-02-07 06:51:32', NULL, NULL),
(20, 1, 12, 'ca_admin_038_20', '919965014814', '919965014814', 'Success', 'Y', '2024-02-07 06:55:19', NULL, NULL),
(21, 1, 13, 'ca_chat_038_21', '919965014814', '919965014814', 'Success', 'Y', '2024-02-07 06:57:19', NULL, NULL),
(22, 1, 14, 'ca_viist_038_22', '919965014814', '919965014814', 'Success', 'Y', '2024-02-07 07:00:05', NULL, NULL),
(23, 1, 15, 'ca_special_038_23', '919965014814', '919965014814', 'Success', 'Y', '2024-02-07 07:05:54', NULL, NULL),
(24, 1, 16, 'ca_testname_038_24', '919965014814', '919965014814', 'Success', 'Y', '2024-02-07 07:25:54', NULL, NULL),
(25, 1, 17, 'ca_hello_038_25', '919965014814', '919965014814', 'Success', 'Y', '2024-02-07 07:32:16', NULL, NULL),
(26, 1, 18, 'ca_balance_038_26', '919965014814', '919965014814', 'Success', 'Y', '2024-02-07 07:34:42', NULL, NULL),
(27, 1, 19, 'ca_ttt_038_27', '919965014814', '919965014814', 'Success', 'Y', '2024-02-07 07:38:16', NULL, NULL),
(28, 1, 20, 'ca_enter_038_28', '919965014814', '919965014814', 'Success', 'Y', '2024-02-07 07:42:03', NULL, NULL),
(29, 1, 21, 'ca_add_038_29', '919965014814', '919965014814', 'Success', 'Y', '2024-02-07 08:06:13', NULL, 'R'),
(30, 1, 5, 'ca_Groups_039_30', '916369841530', '916369841530', 'Success', 'Y', '2024-02-08 05:18:23', NULL, NULL),
(31, 1, 21, 'ca_add_039_31', '919150794800', '919150794800', 'Success', 'Y', '2024-02-08 05:27:17', NULL, 'R'),
(32, 1, 22, 'ca_Example_039_32', '919965014814', '919965014814', 'Success', 'Y', '2024-02-08 10:55:06', NULL, NULL),
(33, 1, 23, 'ca_TEST Group_039_33', '919965014814', '919965014814', 'Success', 'Y', '2024-02-08 10:59:42', NULL, NULL),
(34, 1, 25, 'ca_Nano_039_34', '919965014814', '919965014814', 'Success', 'Y', '2024-02-08 11:45:07', NULL, NULL),
(35, 1, 26, 'ca_list_039_35', '919965014814', '919965014814', 'Success', 'Y', '2024-02-08 12:02:42', NULL, NULL),
(36, 1, 28, 'ca_Feb 8_039_36', '919965014814', '919965014814', 'Success', 'Y', '2024-02-08 12:47:07', NULL, NULL),
(37, 1, 29, 'ca_YJt_039_37', '919965014814', '919965014814', 'Success', 'Y', '2024-02-08 12:52:29', NULL, NULL),
(38, 1, 30, 'ca_EX_039_38', '919965014814', '919965014814', 'Success', 'Y', '2024-02-08 13:08:32', NULL, NULL),
(39, 1, 31, 'ca_final_039_39', '919965014814', '919965014814', 'Success', 'Y', '2024-02-08 13:15:13', NULL, NULL),
(40, 1, 32, 'ca_YEEJAI_040_40', '919361419661', '919361419661', 'Success', 'Y', '2024-02-09 05:57:58', NULL, 'R'),
(42, 1, 32, 'ca_YEEJAI_043_41', '916380885546', '916380885546', 'Success', 'Y', '2024-02-12 12:59:20', NULL, 'R'),
(43, 1, 32, 'ca_YEEJAI_043_42', '919025167792', '919025167792', 'Success', 'Y', '2024-02-12 13:12:22', NULL, 'R'),
(44, 1, 32, 'ca_YEEJAI_044_43', '919786448157', '919786448157', 'already Demoted', 'Y', '2024-02-13 10:48:14', NULL, 'R'),
(45, 1, 32, 'ca_YEEJAI_044_44', '916380747454', '916380747454', 'already Demoted', 'Y', '2024-02-13 11:03:14', NULL, 'R');

-- --------------------------------------------------------

--
-- Table structure for table `group_master`
--

CREATE TABLE `group_master` (
  `group_master_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `sender_master_id` int(11) NOT NULL,
  `group_name` varchar(250) NOT NULL,
  `total_count` int(11) NOT NULL,
  `success_count` int(11) DEFAULT NULL,
  `failure_count` int(11) DEFAULT NULL,
  `is_created_by_api` char(1) NOT NULL,
  `group_master_status` char(1) NOT NULL,
  `group_master_entdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `group_updated_date` timestamp NULL DEFAULT NULL,
  `group_link` varchar(200) DEFAULT NULL,
  `group_qrcode` varchar(500) DEFAULT NULL,
  `admin_count` int(11) DEFAULT NULL,
  `members_count` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=COMPACT;

--
-- Dumping data for table `group_master`
--

INSERT INTO `group_master` (`group_master_id`, `user_id`, `sender_master_id`, `group_name`, `total_count`, `success_count`, `failure_count`, `is_created_by_api`, `group_master_status`, `group_master_entdate`, `group_updated_date`, `group_link`, `group_qrcode`, `admin_count`, `members_count`) VALUES
(1, 1, 1, 'TESTING', 4, 4, 0, 'Y', 'Y', '2024-01-23 08:02:57', '2024-02-09 10:50:15', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 2, 5),
(2, 1, 1, 'Demo', 3, 3, 0, 'Y', 'Y', '2024-01-26 01:33:57', '2024-02-09 10:50:15', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(3, 1, 1, 'Demo Group', 1, 2, 0, 'Y', 'Y', '2024-02-06 11:06:22', '2024-02-09 10:50:15', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(4, 1, 1, 'Group', 1, 1, 0, 'Y', 'Y', '2024-02-07 06:10:36', '2024-02-08 13:18:24', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(5, 1, 1, 'Groups', 2, 2, 0, 'Y', 'Y', '2024-02-07 06:13:54', '2024-02-09 10:50:15', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(6, 1, 1, 'God', 1, 1, 0, 'Y', 'Y', '2024-02-07 06:16:03', '2024-02-08 13:18:24', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(7, 1, 1, 'index', 1, 1, 0, 'Y', 'Y', '2024-02-07 06:17:54', '2024-02-08 13:18:24', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(8, 1, 1, 'test', 1, 1, 0, 'Y', 'Y', '2024-02-07 06:20:58', '2024-02-08 13:18:24', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(9, 1, 1, 'Block', 1, 1, 0, 'Y', 'Y', '2024-02-07 06:34:09', '2024-02-08 13:18:24', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(10, 1, 1, 'Name', 1, 1, 0, 'Y', 'Y', '2024-02-07 06:42:35', '2024-02-08 13:18:24', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(11, 1, 1, 'view', 1, 1, 0, 'Y', 'Y', '2024-02-07 06:51:32', '2024-02-08 13:18:24', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(12, 1, 1, 'admin', 1, 1, 0, 'Y', 'Y', '2024-02-07 06:55:19', '2024-02-08 13:18:24', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(13, 1, 1, 'chat', 1, 1, 0, 'Y', 'Y', '2024-02-07 06:57:19', '2024-02-08 13:18:24', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(14, 1, 1, 'viist', 1, 1, 0, 'Y', 'Y', '2024-02-07 07:00:05', '2024-02-08 13:18:24', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(15, 1, 1, 'special', 2, 2, 0, 'Y', 'Y', '2024-02-07 07:05:54', '2024-02-08 13:18:24', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(16, 1, 1, 'testname', 1, 1, 0, 'Y', 'Y', '2024-02-07 07:25:54', '2024-02-08 13:18:24', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(17, 1, 1, 'hello', 1, 1, 0, 'Y', 'Y', '2024-02-07 07:32:16', '2024-02-08 13:18:24', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(18, 1, 1, 'balance', 1, 1, 0, 'Y', 'Y', '2024-02-07 07:34:42', '2024-02-08 13:18:24', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(19, 1, 1, 'ttt', 1, 1, 0, 'Y', 'Y', '2024-02-07 07:38:16', '2024-02-08 13:18:24', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(20, 1, 1, 'enter', 1, 1, 0, 'Y', 'Y', '2024-02-07 07:42:03', '2024-02-08 13:18:24', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(21, 1, 1, 'add', 3, 3, 0, 'Y', 'Y', '2024-02-07 08:06:13', '2024-02-09 10:50:15', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(22, 1, 1, 'Example', 1, 1, 0, 'Y', 'Y', '2024-02-08 10:55:06', '2024-02-09 10:50:15', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(23, 1, 1, 'TEST Group', 1, 1, 0, 'Y', 'Y', '2024-02-08 10:59:42', '2024-02-09 10:50:15', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(24, 1, 1, 'VISIT', 1, 1, 0, 'Y', 'Y', '2024-02-08 11:41:21', '2024-02-09 10:50:15', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(25, 1, 1, 'Nano', 1, 1, 0, 'Y', 'Y', '2024-02-08 11:45:07', '2024-02-09 10:50:15', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(26, 1, 1, 'list', 1, 1, 0, 'Y', 'Y', '2024-02-08 12:02:42', '2024-02-09 10:50:15', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(27, 1, 1, 'SAGA', 1, 1, 0, 'Y', 'Y', '2024-02-08 12:15:46', '2024-02-09 10:50:15', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(28, 1, 1, 'Feb 8', 1, 1, 0, 'Y', 'Y', '2024-02-08 12:47:07', '2024-02-09 10:50:15', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(29, 1, 1, 'YJt', 1, 1, 0, 'Y', 'Y', '2024-02-08 12:52:29', '2024-02-09 10:50:15', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(30, 1, 1, 'EX', 1, 1, 0, 'Y', 'Y', '2024-02-08 13:08:32', '2024-02-09 10:50:15', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(31, 1, 1, 'final', 1, 1, 0, 'Y', 'Y', '2024-02-08 13:15:13', '2024-02-09 10:50:15', 'https://chat.whatsapp.com/GEyk1haeFqL444kYr3iTbx', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/final.png', 1, 2),
(32, 1, 1, 'YEEJAI', 1, 4, 0, 'Y', 'Y', '2024-02-09 05:57:58', '2024-02-13 10:48:14', 'https://chat.whatsapp.com/Dh7gPIUaCfMHhoAyoRU1lR', '/opt/lampp/htdocs/whatsapp_group_newapi/uploads/group_qr/YEEJAI.png', 1, 3);

-- --------------------------------------------------------

--
-- Table structure for table `master_countries`
--

CREATE TABLE `master_countries` (
  `id` int(11) NOT NULL,
  `shortname` varchar(3) NOT NULL,
  `name` varchar(150) NOT NULL,
  `phonecode` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

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
(53, 'CI', 'Cote D\'Ivoire (Ivory Coast)', 225),
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

CREATE TABLE `master_language` (
  `language_id` int(11) NOT NULL,
  `language_name` varchar(20) NOT NULL,
  `language_code` varchar(10) NOT NULL,
  `language_status` char(1) NOT NULL,
  `language_entdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

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

CREATE TABLE `messenger_response` (
  `message_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `message_to` varchar(20) NOT NULL,
  `message_from` varchar(20) NOT NULL,
  `message_from_profile` varchar(50) NOT NULL,
  `message_resp_id` varchar(100) NOT NULL,
  `message_type` varchar(20) NOT NULL,
  `message_data` longtext NOT NULL,
  `msg_text` varchar(300) DEFAULT NULL,
  `msg_media` varchar(50) DEFAULT NULL,
  `msg_media_type` varchar(30) DEFAULT NULL,
  `msg_media_caption` varchar(50) DEFAULT NULL,
  `msg_reply_button` varchar(30) DEFAULT NULL,
  `msg_reaction` varchar(10) DEFAULT NULL,
  `msg_list` longtext DEFAULT NULL,
  `message_is_read` char(1) DEFAULT 'N',
  `message_status` char(1) NOT NULL,
  `message_rec_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `message_read_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=COMPACT;

-- --------------------------------------------------------

--
-- Table structure for table `payment_history_log`
--

CREATE TABLE `payment_history_log` (
  `payment_history_logid` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `user_plans_id` int(11) NOT NULL,
  `plan_master_id` int(11) NOT NULL,
  `plan_amount` int(11) NOT NULL,
  `payment_status` char(1) NOT NULL,
  `plan_comments` varchar(300) DEFAULT NULL,
  `payment_history_logstatus` char(1) NOT NULL,
  `payment_history_log_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `payment_history_log`
--

INSERT INTO `payment_history_log` (`payment_history_logid`, `user_id`, `user_plans_id`, `plan_master_id`, `plan_amount`, `payment_status`, `plan_comments`, `payment_history_logstatus`, `payment_history_log_date`) VALUES
(1, 1, 1, 2, 300, 'A', 'msg:Payment successfully credited, status:true, productCode:2, paymentID:pay_NNKBH1rGodKSq0, userEmail', 'Y', '2024-01-11 13:31:24'),
(2, 8, 2, 1, 100, 'A', 'Admin Direct Approval', 'Y', '2024-01-29 05:10:18'),
(3, 9, 3, 2, 300, 'A', 'Admin Direct Approval', 'Y', '2024-01-29 05:21:44'),
(4, 10, 4, 5, 2100, 'A', 'Admin Direct Approval', 'Y', '2024-01-29 05:26:05'),
(5, 11, 5, 1, 100, 'A', 'Admin Direct Approval', 'Y', '2024-01-29 06:13:16'),
(6, 12, 6, 1, 100, 'A', 'Admin Direct Approval', 'Y', '2024-01-29 07:04:12');

-- --------------------------------------------------------

--
-- Table structure for table `plans_update`
--

CREATE TABLE `plans_update` (
  `plans_update_id` int(11) NOT NULL,
  `plan_master_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `total_whatsapp_count` int(11) NOT NULL,
  `available_whatsapp_count` int(11) NOT NULL,
  `used_whatsapp_count` int(11) NOT NULL,
  `total_group_count` int(11) NOT NULL,
  `available_group_count` int(11) NOT NULL,
  `used_group_count` int(11) NOT NULL,
  `total_message_limit` int(11) NOT NULL,
  `available_message_limit` int(11) NOT NULL,
  `used_message_limit` int(11) NOT NULL,
  `plan_status` char(1) NOT NULL,
  `plan_entry_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `plan_expiry_date` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `plans_update`
--

INSERT INTO `plans_update` (`plans_update_id`, `plan_master_id`, `user_id`, `total_whatsapp_count`, `available_whatsapp_count`, `used_whatsapp_count`, `total_group_count`, `available_group_count`, `used_group_count`, `total_message_limit`, `available_message_limit`, `used_message_limit`, `plan_status`, `plan_entry_date`, `plan_expiry_date`) VALUES
(1, 2, 1, 200, 126, 74, 30, 2, 28, 600, 600, 0, 'Y', '2024-02-13 11:49:27', '2024-02-11 19:01:48'),
(2, 1, 8, 100, 100, 0, 20, 20, 0, 500, 500, 0, 'Y', '2024-01-29 05:10:18', '1971-01-01 05:30:00'),
(3, 2, 9, 200, 200, 0, 30, 30, 0, 600, 600, 0, 'Y', '2024-01-29 05:21:44', '2024-02-29 10:51:44'),
(4, 5, 10, 300, 300, 0, 100, 100, 0, 3000, 3000, 0, 'Y', '2024-01-29 05:26:05', '2025-01-29 10:56:05'),
(5, 1, 11, 100, 100, 0, 20, 20, 0, 500, 500, 0, 'Y', '2024-01-29 06:13:16', '2024-02-29 11:43:16'),
(6, 1, 12, 100, 100, 0, 20, 20, 0, 500, 500, 0, 'Y', '2024-01-29 07:04:12', '2024-02-29 12:34:12');

-- --------------------------------------------------------

--
-- Table structure for table `plan_master`
--

CREATE TABLE `plan_master` (
  `plan_master_id` int(11) NOT NULL,
  `plan_title` varchar(20) NOT NULL,
  `annual_monthly` char(1) NOT NULL,
  `whatsapp_no_min_count` int(11) NOT NULL,
  `whatsapp_no_max_count` int(11) NOT NULL,
  `group_no_min_count` int(11) NOT NULL,
  `group_no_max_count` int(11) NOT NULL,
  `plan_price` int(11) NOT NULL,
  `message_limit` int(11) DEFAULT NULL,
  `plan_status` char(1) NOT NULL,
  `plan_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `plan_master`
--

INSERT INTO `plan_master` (`plan_master_id`, `plan_title`, `annual_monthly`, `whatsapp_no_min_count`, `whatsapp_no_max_count`, `group_no_min_count`, `group_no_max_count`, `plan_price`, `message_limit`, `plan_status`, `plan_entry_date`) VALUES
(1, 'SILVER', 'M', 0, 100, 0, 20, 100, 500, 'Y', '2023-10-03 00:26:24'),
(2, 'Gold', 'M', 0, 200, 0, 30, 300, 600, 'Y', '2023-10-03 00:26:24'),
(3, 'Platinum', 'M', 0, 300, 0, 50, 500, 800, 'Y', '2023-10-03 00:26:24'),
(4, 'SILVER', 'A', 0, 100, 0, 50, 1100, 1000, 'Y', '2023-10-03 00:26:24'),
(5, 'Gold', 'A', 0, 300, 0, 100, 2100, 3000, 'Y', '2023-10-03 00:26:24'),
(6, 'demo', 'M', 0, 5, 0, 1, 100, 100, 'Y', '2024-01-29 12:57:37'),
(7, 'Gold', 'Y', 0, 300, 0, 100, 2101, 100, 'Y', '2024-01-29 13:13:56'),
(8, 'Gold', 'Y', 0, 300, 0, 100, 2101, 100, 'Y', '2024-01-29 13:14:29'),
(9, 'Gold', 'M', 0, 300, 0, 100, 2107, 100, 'Y', '2024-01-29 13:23:53'),
(10, 'Gold', 'M', 0, 300, 0, 100, 2100, 100, 'Y', '2024-01-29 13:24:15'),
(11, 'Gold', 'M', 0, 30, 0, 10, 2100, 100, 'Y', '2024-01-29 13:26:43'),
(12, 'testing', '', 0, 2, 0, 3, 100, 100, 'Y', '2024-01-29 13:37:50'),
(13, 'demo1', 'M', 0, 5, 0, 3, 100, 100, 'Y', '2024-01-30 04:47:37'),
(14, 'demo1', 'A', 0, 10, 0, 6, 1000, 100, 'D', '2024-01-30 04:47:37');

-- --------------------------------------------------------

--
-- Table structure for table `senderid_master`
--

CREATE TABLE `senderid_master` (
  `sender_master_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `mobile_no` varchar(15) NOT NULL,
  `profile_name` varchar(25) DEFAULT NULL,
  `profile_image` varchar(100) DEFAULT NULL,
  `senderid_master_status` char(1) NOT NULL,
  `senderid_master_entdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `senderid_master_apprdate` timestamp NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=COMPACT;

--
-- Dumping data for table `senderid_master`
--

INSERT INTO `senderid_master` (`sender_master_id`, `user_id`, `mobile_no`, `profile_name`, `profile_image`, `senderid_master_status`, `senderid_master_entdate`, `senderid_master_apprdate`) VALUES
(1, 1, '918838964597', 'test', 'http://localhost/whatsapp_group_newapi/uploads/whatsapp_images/1_1706876463369.png', 'X', '2024-02-02 12:21:16', '0000-00-00 00:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `summary_report`
--

CREATE TABLE `summary_report` (
  `summary_report_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `campaign_date` date NOT NULL,
  `campaign_count` int(11) NOT NULL,
  `success_count` int(11) DEFAULT NULL,
  `failure_count` int(11) DEFAULT NULL,
  `inprogress_count` int(11) DEFAULT NULL,
  `summary_report_status` char(1) NOT NULL,
  `summary_report_entdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `template_master`
--

CREATE TABLE `template_master` (
  `template_master_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `unique_template_id` varchar(30) NOT NULL,
  `template_name` varchar(50) NOT NULL,
  `language_id` int(11) NOT NULL,
  `template_category` varchar(30) NOT NULL,
  `template_message` longtext NOT NULL,
  `template_status` char(1) NOT NULL,
  `template_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `template_master`
--

INSERT INTO `template_master` (`template_master_id`, `user_id`, `unique_template_id`, `template_name`, `language_id`, `template_category`, `template_message`, `template_status`, `template_entry_date`) VALUES
(1, 1, 'tmplt_Sup_023_001', 'te_Sup_t00000000_24123_001', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING\"}]', 'Y', '2024-01-23 02:18:56'),
(2, 1, 'tmplt_Sup_026_002', 'te_Sup_t00000000_24126_002', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<b>TEST Message</b>\"}]', 'Y', '2024-01-26 03:42:03'),
(3, 1, 'tmplt_Sup_026_003', 'te_Sup_t00000u00_24126_003', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TEST message<br><a href=\"http://www.google.com\" target=\"_blank\"></a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', 'Y', '2024-01-26 04:05:05'),
(4, 1, 'tmplt_Sup_026_004', 'te_Sup_t00000u00_24126_004', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TEST message<br><a href=\"http://www.google.com\" target=\"_blank\"></a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', 'Y', '2024-01-26 04:06:25'),
(5, 1, 'tmplt_Sup_026_005', 'te_Sup_t00000u00_24126_005', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TEST message<br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', 'Y', '2024-01-26 04:06:47'),
(6, 1, 'tmplt_Sup_032_006', 'te_Sup_t00000000_2421_006', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sjdnkf\"}]', 'Y', '2024-02-01 05:57:15'),
(7, 1, 'tmplt_Sup_032_007', 'te_Sup_t00000000_2421_007', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"jnsjd\"}]', 'Y', '2024-02-01 06:00:41'),
(8, 1, 'tmplt_Sup_036_008', 'te_Sup_t00000000_2425_008', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat.\"\"}]', 'Y', '2024-02-05 01:20:01'),
(9, 1, 'tmplt_Sup_036_009', 'te_Sup_t00000000_2425_009', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testwelcome\"}]', 'Y', '2024-02-05 11:12:00'),
(10, 1, 'tmplt_Sup_036_010', 'te_Sup_t00000000_2425_010', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\nwelcome\n*yeejai tecnology*\n*test*\nwelocme : \"http://welcome\"*\n*\"}]', 'Y', '2024-02-05 12:08:02'),
(11, 1, 'tmplt_Sup_036_011', 'te_Sup_t00000000_2425_011', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"hello<br>welcoem<br>yeejai.com : http://yeejai.com<br>\"}]', 'Y', '2024-02-05 12:40:47'),
(12, 1, 'tmplt_Sup_036_012', 'te_Sup_t00000000_2425_012', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"hello<br>welcoem<br>yeejai.com : http://yeejai.com<br>\"}]', 'Y', '2024-02-05 12:44:02'),
(13, 1, 'tmplt_Sup_036_013', 'te_Sup_t00000000_2425_013', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"hello\"}]', 'Y', '2024-02-05 12:55:04'),
(14, 1, 'tmplt_Sup_036_014', 'te_Sup_t00000000_2425_014', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*\"}]', 'Y', '2024-02-05 12:55:24'),
(15, 1, 'tmplt_Sup_036_015', 'te_Sup_t00000000_2425_015', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*welcome*<br>yeejai\"}]', 'Y', '2024-02-05 12:59:33'),
(16, 1, 'tmplt_Sup_036_016', 'te_Sup_t00000000_2425_016', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"yeejai technology<br>welcome<br>testing<br><br><br>**\"}]', 'Y', '2024-02-05 13:00:58'),
(17, 1, 'tmplt_Sup_036_017', 'te_Sup_t00000000_2425_017', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcome : http://welcome<br>\"}]', 'Y', '2024-02-05 13:01:13'),
(18, 1, 'tmplt_Sup_036_018', 'te_Sup_l00000000_2425_018', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>jbjds : http://ksdks<br>\"}]', 'Y', '2024-02-05 13:01:41'),
(19, 1, 'tmplt_Sup_036_019', 'te_Sup_t00000000_2425_019', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>jbjds : http://ksdks/<br>*jsdjsbnjd*<br>\"}]', 'Y', '2024-02-05 13:02:11');

-- --------------------------------------------------------

--
-- Table structure for table `user_log`
--

CREATE TABLE `user_log` (
  `user_log_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `ip_address` varchar(50) DEFAULT NULL,
  `login_date` date NOT NULL,
  `login_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `logout_time` timestamp NULL DEFAULT '0000-00-00 00:00:00',
  `user_log_status` char(1) NOT NULL,
  `user_log_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

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
(246, 1, 'undefined', '2024-01-13', '2024-01-13 06:39:51', NULL, 'I', '2024-01-13 06:39:51'),
(247, 1, 'undefined', '2024-01-14', '2024-01-14 02:30:04', NULL, 'I', '2024-01-14 02:30:04'),
(248, 1, 'undefined', '2024-01-17', '2024-01-17 06:14:04', NULL, 'I', '2024-01-17 06:14:04'),
(249, 1, 'undefined', '2024-01-19', '2024-01-19 09:49:32', NULL, 'I', '2024-01-19 09:49:32'),
(250, 1, 'undefined', '2024-01-20', '2024-01-20 11:25:49', NULL, 'I', '2024-01-20 11:25:49'),
(251, 1, 'undefined', '2024-01-24', '2024-01-24 10:31:47', NULL, 'I', '2024-01-24 10:31:47'),
(252, 1, 'undefined', '2024-01-25', '2024-01-25 10:54:10', NULL, 'I', '2024-01-25 10:54:10'),
(253, 1, 'undefined', '2024-01-25', '2024-01-25 11:35:21', NULL, 'I', '2024-01-25 11:35:21'),
(254, 1, 'undefined', '2024-01-25', '2024-01-25 11:42:24', NULL, 'I', '2024-01-25 11:42:24'),
(255, 1, 'undefined', '2024-01-25', '2024-01-25 12:11:55', NULL, 'I', '2024-01-25 12:11:55'),
(256, 1, 'undefined', '2024-01-25', '2024-01-25 13:23:59', NULL, 'I', '2024-01-25 13:23:59'),
(257, 1, 'undefined', '2024-01-27', '2024-01-27 06:08:39', NULL, 'I', '2024-01-27 06:08:39'),
(258, 1, 'undefined', '2024-01-28', '2024-01-28 07:29:07', NULL, 'I', '2024-01-28 07:29:07'),
(259, 1, 'undefined', '2024-01-29', '2024-01-29 04:45:41', NULL, 'I', '2024-01-29 04:45:41'),
(260, 1, 'undefined', '2024-01-29', '2024-01-29 09:20:51', NULL, 'I', '2024-01-29 09:20:51'),
(261, 1, 'undefined', '2024-01-31', '2024-01-31 10:51:29', NULL, 'I', '2024-01-31 10:51:29'),
(262, 1, 'undefined', '2024-02-01', '2024-02-01 04:59:54', NULL, 'I', '2024-02-01 04:59:54'),
(263, 1, 'undefined', '2024-02-01', '2024-02-01 10:10:08', NULL, 'I', '2024-02-01 10:10:08'),
(264, 1, 'undefined', '2024-02-01', '2024-02-01 10:15:15', NULL, 'I', '2024-02-01 10:15:15'),
(265, 1, 'undefined', '2024-02-01', '2024-02-01 12:18:39', NULL, 'I', '2024-02-01 12:18:39'),
(266, 1, 'undefined', '2024-02-01', '2024-02-01 12:19:18', NULL, 'I', '2024-02-01 12:19:18'),
(267, 1, 'undefined', '2024-02-01', '2024-02-01 12:47:04', NULL, 'I', '2024-02-01 12:47:04'),
(268, 1, 'undefined', '2024-02-01', '2024-02-01 12:56:51', NULL, 'I', '2024-02-01 12:56:51'),
(269, 1, 'undefined', '2024-02-02', '2024-02-02 04:39:46', '2024-02-02 12:17:48', 'O', '2024-02-02 04:39:46'),
(270, 1, 'undefined', '2024-02-02', '2024-02-02 11:16:44', '2024-02-02 12:17:48', 'O', '2024-02-02 11:16:44'),
(271, 1, 'undefined', '2024-02-02', '2024-02-02 12:18:37', '2024-02-02 12:19:15', 'O', '2024-02-02 12:18:37'),
(272, 1, 'undefined', '2024-02-02', '2024-02-02 12:19:35', NULL, 'I', '2024-02-02 12:19:35'),
(273, 1, 'undefined', '2024-02-04', '2024-02-04 12:54:16', '2024-02-04 12:55:34', 'O', '2024-02-04 12:54:16'),
(274, 1, 'undefined', '2024-02-04', '2024-02-04 12:55:59', NULL, 'I', '2024-02-04 12:55:59'),
(275, 1, 'undefined', '2024-02-05', '2024-02-05 11:10:54', NULL, 'I', '2024-02-05 11:10:54'),
(276, 1, 'undefined', '2024-02-06', '2024-02-06 04:41:38', '2024-02-06 09:00:07', 'O', '2024-02-06 04:41:38'),
(277, 1, 'undefined', '2024-02-06', '2024-02-06 06:22:21', '2024-02-06 09:00:07', 'O', '2024-02-06 06:22:21'),
(278, 1, 'undefined', '2024-02-06', '2024-02-06 06:37:55', '2024-02-06 09:00:07', 'O', '2024-02-06 06:37:55'),
(279, 1, 'undefined', '2024-02-06', '2024-02-06 09:00:25', NULL, 'I', '2024-02-06 09:00:25'),
(280, 1, 'undefined', '2024-02-09', '2024-02-09 05:10:12', '2024-02-09 05:32:54', 'O', '2024-02-09 05:10:12'),
(281, 1, 'undefined', '2024-02-09', '2024-02-09 05:33:33', '2024-02-09 05:36:42', 'O', '2024-02-09 05:33:33'),
(282, 1, 'undefined', '2024-02-09', '2024-02-09 05:37:29', '2024-02-09 05:42:56', 'O', '2024-02-09 05:37:29'),
(283, 1, 'undefined', '2024-02-09', '2024-02-09 05:43:17', NULL, 'I', '2024-02-09 05:43:17'),
(284, 1, 'undefined', '2024-02-09', '2024-02-09 18:14:26', NULL, 'I', '2024-02-09 18:14:26'),
(285, 1, 'undefined', '2024-02-12', '2024-02-12 12:50:39', NULL, 'I', '2024-02-12 12:50:39'),
(286, 1, 'undefined', '2024-02-13', '2024-02-13 04:16:56', NULL, 'I', '2024-02-13 04:16:56'),
(287, 1, 'undefined', '2024-02-13', '2024-02-13 14:08:50', NULL, 'I', '2024-02-13 14:08:50');

-- --------------------------------------------------------

--
-- Table structure for table `user_management`
--

CREATE TABLE `user_management` (
  `user_id` int(11) NOT NULL,
  `user_master_id` int(11) NOT NULL,
  `parent_id` int(11) NOT NULL,
  `user_name` varchar(30) NOT NULL,
  `api_key` varchar(30) DEFAULT NULL,
  `login_password` varchar(50) NOT NULL,
  `user_email` varchar(50) DEFAULT NULL,
  `user_mobile` varchar(10) DEFAULT NULL,
  `usr_mgt_status` char(1) NOT NULL,
  `usr_mgt_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `bearer_token` varchar(500) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=COMPACT;

--
-- Dumping data for table `user_management`
--

INSERT INTO `user_management` (`user_id`, `user_master_id`, `parent_id`, `user_name`, `api_key`, `login_password`, `user_email`, `user_mobile`, `usr_mgt_status`, `usr_mgt_entry_date`, `bearer_token`) VALUES
(1, 1, 1, 'Super Admin', 'AA1DE999B6B65D2', 'e58a3754522a05c1ff4d231f8e8cc1bd', 'super_admin@gmail.com', '9000090000', 'Y', '2021-12-30 06:22:20', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3MDc4MzMzMzAsImV4cCI6MTcwODQzODEzMH0.QUaP0XbzvJ1za1tL1zCzdF7PNGkgaDb8Ux_bBkIPvt0'),
(2, 2, 1, 'User 1', '2134D2287A57625', 'e58a3754522a05c1ff4d231f8e8cc1bd', 'user_1@gmail.com', '9000090001', 'Y', '2023-03-01 02:20:45', '-'),
(3, 2, 1, 'User 2', '2134D2287A57621', 'e58a3754522a05c1ff4d231f8e8cc1bd', 'user_2@gmail.com', '9000090021', 'Y', '2023-03-01 02:20:45', '-'),
(4, 2, 1, 'Shanthini', ' XGYG97KJW0BGSE', 'e233c7da05275ce7e55d2332135b86c7', 'shan@gmail.com', '6380885546', 'Y', '2024-01-02 09:56:44', '-'),
(5, 2, 1, 'test', '8LXN5JXQMM0YFX6', 'e58a3754522a05c1ff4d231f8e8cc1bd', 'test@gmail.com', '8866376735', 'Y', '2024-01-05 09:20:22', '-'),
(6, 2, 1, 'demo', 'S40CH3R9STHQW03', 'e58a3754522a05c1ff4d231f8e8cc1bd', 'demo@gmail.com', '8237489723', 'Y', '2024-01-05 11:10:15', '-'),
(7, 2, 1, 'demo1', '42OV5TC1X6TCXBJ', 'e58a3754522a05c1ff4d231f8e8cc1bd', 'demo1@gmail.com', '8237897957', 'Y', '2024-01-05 11:29:03', '-'),
(8, 2, 1, 'test', 'FX036BPDI2LG8IM', 'ceb6c970658f31504a901b89dcd3e461', 'test123@gmail.com', '8368632846', 'Y', '2024-01-29 05:10:18', '-'),
(9, 2, 1, 'demo_1', 'ABFVVE59JM96UFB', 'f702c1502be8e55f4208d69419f50d0a', 'demo_1@gmail.com', '8762366666', 'Y', '2024-01-29 05:21:44', '-'),
(10, 2, 1, 'demo_2', '0W3I1DH1GWS1I79', '62cc19bb200e8cea7fb998c4be8a9574', 'demo_2@gmail.com', '7826386482', 'Y', '2024-01-29 05:26:05', '-'),
(11, 2, 1, 'testing', 'CO4BV4Q2WYU1GVO', '06e4dff3c420e66ae6927dc539ba82c6', 'testing123@gmail.com', '9749759837', 'Y', '2024-01-29 06:13:16', '-'),
(12, 2, 1, 'test', 'I9IFFHYZRMHCZLT', '752f6ad36c1777b739026cb63b2cf067', 'test1234@gmail.com', '8485666666', 'Y', '2024-01-29 07:04:12', '-');

-- --------------------------------------------------------

--
-- Table structure for table `user_master`
--

CREATE TABLE `user_master` (
  `user_master_id` int(11) NOT NULL,
  `user_type` varchar(20) NOT NULL,
  `user_title` varchar(20) NOT NULL,
  `user_master_status` char(1) NOT NULL,
  `um_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=COMPACT;

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

CREATE TABLE `user_plans` (
  `user_plans_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `plan_master_id` int(11) NOT NULL,
  `plan_amount` int(11) NOT NULL,
  `plan_expiry_date` timestamp NULL DEFAULT '0000-00-00 00:00:00',
  `payment_status` char(1) DEFAULT NULL,
  `plan_comments` varchar(300) DEFAULT NULL,
  `plan_reference_id` varchar(100) DEFAULT NULL,
  `user_plans_status` char(1) NOT NULL,
  `user_plans_entdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `user_plans`
--

INSERT INTO `user_plans` (`user_plans_id`, `user_id`, `plan_master_id`, `plan_amount`, `plan_expiry_date`, `payment_status`, `plan_comments`, `plan_reference_id`, `user_plans_status`, `user_plans_entdate`) VALUES
(1, 1, 2, 300, '2024-02-11 13:31:48', 'A', 'msg:Payment successfully credited, status:true, productCode:2, paymentID:pay_NNKBH1rGodKSq0, userEmail', '-', 'A', '2024-01-11 13:31:24'),
(2, 8, 1, 100, '1971-01-01 00:00:00', 'A', 'Admin Direct Approval', '-', 'A', '2024-01-29 05:10:18'),
(3, 9, 2, 300, '2024-02-29 05:21:44', 'A', 'Admin Direct Approval', '-', 'A', '2024-01-29 05:21:44'),
(4, 10, 5, 2100, '2025-01-29 05:26:05', 'A', 'Admin Direct Approval', '-', 'A', '2024-01-29 05:26:05'),
(5, 11, 1, 100, '2024-02-29 06:13:16', 'A', 'Admin Direct Approval', '-', 'A', '2024-01-29 06:13:16'),
(6, 12, 1, 100, '2024-02-29 07:04:12', 'A', 'Admin Direct Approval', '-', 'A', '2024-01-29 07:04:12');

-- --------------------------------------------------------

--
-- Table structure for table `user_summary_report`
--

CREATE TABLE `user_summary_report` (
  `com_report_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `com_msg_id` int(11) NOT NULL,
  `campaign_name` int(11) NOT NULL,
  `no_group_count` int(11) NOT NULL,
  `total_message_count` int(11) NOT NULL,
  `no_message_sent` int(11) NOT NULL,
  `no_failed_count` int(11) NOT NULL,
  `no_revenue_earned` int(11) NOT NULL,
  `report_status` varchar(1) NOT NULL,
  `com_entry_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `com_start_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `com_end_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

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
-- Indexes for table `group_master`
--
ALTER TABLE `group_master`
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
-- Indexes for table `plan_master`
--
ALTER TABLE `plan_master`
  ADD PRIMARY KEY (`plan_master_id`);

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
-- Indexes for table `user_summary_report`
--
ALTER TABLE `user_summary_report`
  ADD PRIMARY KEY (`com_report_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `api_log`
--
ALTER TABLE `api_log`
  MODIFY `api_log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1144;

--
-- AUTO_INCREMENT for table `cron_compose`
--
ALTER TABLE `cron_compose`
  MODIFY `cron_com_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `group_contacts`
--
ALTER TABLE `group_contacts`
  MODIFY `group_contacts_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT for table `group_master`
--
ALTER TABLE `group_master`
  MODIFY `group_master_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT for table `master_countries`
--
ALTER TABLE `master_countries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=249;

--
-- AUTO_INCREMENT for table `master_language`
--
ALTER TABLE `master_language`
  MODIFY `language_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `messenger_response`
--
ALTER TABLE `messenger_response`
  MODIFY `message_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payment_history_log`
--
ALTER TABLE `payment_history_log`
  MODIFY `payment_history_logid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `plans_update`
--
ALTER TABLE `plans_update`
  MODIFY `plans_update_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `plan_master`
--
ALTER TABLE `plan_master`
  MODIFY `plan_master_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `senderid_master`
--
ALTER TABLE `senderid_master`
  MODIFY `sender_master_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `summary_report`
--
ALTER TABLE `summary_report`
  MODIFY `summary_report_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `template_master`
--
ALTER TABLE `template_master`
  MODIFY `template_master_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `user_log`
--
ALTER TABLE `user_log`
  MODIFY `user_log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=288;

--
-- AUTO_INCREMENT for table `user_management`
--
ALTER TABLE `user_management`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `user_master`
--
ALTER TABLE `user_master`
  MODIFY `user_master_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `user_plans`
--
ALTER TABLE `user_plans`
  MODIFY `user_plans_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `user_summary_report`
--
ALTER TABLE `user_summary_report`
  MODIFY `com_report_id` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
