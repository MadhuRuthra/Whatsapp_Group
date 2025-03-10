-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Jan 23, 2024 at 05:09 AM
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
(530, 1, '/template/create_template', 'undefined', '_2024023091643_739', 'S', 'Success', '2024-01-23 03:46:43', 'Y', '2024-01-23 03:46:43');

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
  `remove_comments` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=COMPACT;

--
-- Dumping data for table `group_contacts`
--

INSERT INTO `group_contacts` (`group_contacts_id`, `user_id`, `group_master_id`, `campaign_name`, `mobile_no`, `mobile_id`, `comments`, `group_contacts_status`, `group_contacts_entry_date`, `remove_comments`) VALUES
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
(37, 1, 14, 'ca_Demo_012_20', '919965014814', '919965014814', 'Success', 'R', '2024-01-12 05:02:23', NULL),
(38, 2, 14, 'ca_Demo_012_21', '916369841530', '916369841530', 'Success', 'R', '2024-01-12 05:35:30', NULL),
(39, 1, 15, 'ca_Testing Group_012_22', '919965014814', '919965014814', 'Success', 'Y', '2024-01-12 05:49:22', NULL),
(40, 1, 16, 'ca_Demo_013_23', '916380885546', '916380885546', 'Success', 'Y', '2024-01-13 05:16:10', NULL),
(41, 1, 16, 'ca_Demo_013_24', '919361419661', '919361419661', 'Success', 'Y', '2024-01-13 05:17:30', NULL);

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
  `group_master_entdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=COMPACT;

--
-- Dumping data for table `group_master`
--

INSERT INTO `group_master` (`group_master_id`, `user_id`, `sender_master_id`, `group_name`, `total_count`, `success_count`, `failure_count`, `is_created_by_api`, `group_master_status`, `group_master_entdate`) VALUES
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
(14, 1, 45, 'Demo', 2, 2, 0, 'Y', 'Y', '2024-01-12 05:02:23'),
(15, 1, 44, 'Testing Group', 1, 1, 0, 'Y', 'Y', '2024-01-12 05:49:22'),
(16, 1, 46, 'Demo', 2, 2, 0, 'N', 'Y', '2024-01-13 05:16:10');

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
-- Table structure for table `message_template`
--

CREATE TABLE `message_template` (
  `template_id` int(11) NOT NULL,
  `sender_master_id` int(11) NOT NULL,
  `unique_template_id` varchar(30) NOT NULL,
  `template_name` char(50) NOT NULL,
  `language_id` int(11) NOT NULL,
  `template_category` varchar(30) NOT NULL,
  `template_message` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `template_response_id` varchar(50) NOT NULL,
  `created_user` int(11) NOT NULL,
  `template_status` char(1) NOT NULL,
  `template_entdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `approve_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `body_variable_count` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `message_template`
--

INSERT INTO `message_template` (`template_id`, `sender_master_id`, `unique_template_id`, `template_name`, `language_id`, `template_category`, `template_message`, `template_response_id`, `created_user`, `template_status`, `template_entdate`, `approve_date`, `body_variable_count`) VALUES
(1, 14, 'tmplt_Sup_Sup_021_001', 'te_Sup_Sup_t00000000_24121_001', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing\"}]', '54,98,38,64,12,36,18,84,99,95,87,21,77,60,55', 1, 'Y', '2024-01-21 07:53:46', '0000-00-00 00:00:00', 0),
(2, 17, 'tmplt_Sup_Sup_021_001', 'te_Sup_Sup_t00000000_24121_001', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing\"}]', '54,98,38,64,12,36,18,84,99,95,87,21,77,60,55', 1, 'Y', '2024-01-21 07:53:46', '0000-00-00 00:00:00', 0),
(3, 46, 'tmplt_Sup_Sup_021_001', 'te_Sup_Sup_t00000000_24121_001', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing\"}]', '54,98,38,64,12,36,18,84,99,95,87,21,77,60,55', 1, 'Y', '2024-01-21 07:53:46', '0000-00-00 00:00:00', 0),
(4, 14, 'tmplt_Sup_Sup_021_002', 'te_Sup_Sup_t00000000_24121_002', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sjbdj\"}]', '58333583046632', 1, 'Y', '2024-01-21 09:54:46', '0000-00-00 00:00:00', 0),
(5, 17, 'tmplt_Sup_Sup_021_002', 'te_Sup_Sup_t00000000_24121_002', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sjbdj\"}]', '58333583046632', 1, 'Y', '2024-01-21 09:54:46', '0000-00-00 00:00:00', 0),
(6, 46, 'tmplt_Sup_Sup_021_002', 'te_Sup_Sup_t00000000_24121_002', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sjbdj\"}]', '58333583046632', 1, 'Y', '2024-01-21 09:54:46', '0000-00-00 00:00:00', 0),
(7, 14, 'tmplt_Sup_Sup_022_003', 'te_Sup_Sup_t00000000_24122_003', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"dnfkdn\"}]', '296744185226224', 1, 'Y', '2024-01-22 04:27:56', '0000-00-00 00:00:00', 0),
(8, 17, 'tmplt_Sup_Sup_022_003', 'te_Sup_Sup_t00000000_24122_003', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"dnfkdn\"}]', '296744185226224', 1, 'Y', '2024-01-22 04:27:56', '0000-00-00 00:00:00', 0),
(9, 46, 'tmplt_Sup_Sup_022_003', 'te_Sup_Sup_t00000000_24122_003', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"dnfkdn\"}]', '296744185226224', 1, 'Y', '2024-01-22 04:27:56', '0000-00-00 00:00:00', 0),
(10, 14, 'tmplt_Sup_Sup_022_004', 'te_Sup_Sup_t00000000_24122_004', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"d\"}]', '404274902639777', 1, 'Y', '2024-01-22 04:28:38', '0000-00-00 00:00:00', 0),
(11, 17, 'tmplt_Sup_Sup_022_004', 'te_Sup_Sup_t00000000_24122_004', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"d\"}]', '404274902639777', 1, 'Y', '2024-01-22 04:28:38', '0000-00-00 00:00:00', 0),
(12, 46, 'tmplt_Sup_Sup_022_004', 'te_Sup_Sup_t00000000_24122_004', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"d\"}]', '404274902639777', 1, 'Y', '2024-01-22 04:28:38', '0000-00-00 00:00:00', 0),
(13, 14, 'tmplt_Sup_Sup_022_005', 'te_Sup_Sup_t00000000_24122_005', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing\"}]', '896598917825819', 1, 'Y', '2024-01-22 04:39:33', '0000-00-00 00:00:00', 0),
(14, 17, 'tmplt_Sup_Sup_022_005', 'te_Sup_Sup_t00000000_24122_005', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing\"}]', '896598917825819', 1, 'Y', '2024-01-22 04:39:33', '0000-00-00 00:00:00', 0),
(15, 46, 'tmplt_Sup_Sup_022_005', 'te_Sup_Sup_t00000000_24122_005', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing\"}]', '896598917825819', 1, 'Y', '2024-01-22 04:39:33', '0000-00-00 00:00:00', 0),
(16, 14, 'tmplt_Sup_Sup_022_006', 'te_Sup_Sup_t00000000_24122_006', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '442007356319778', 1, 'Y', '2024-01-22 04:47:10', '0000-00-00 00:00:00', 0),
(17, 17, 'tmplt_Sup_Sup_022_006', 'te_Sup_Sup_t00000000_24122_006', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '442007356319778', 1, 'Y', '2024-01-22 04:47:10', '0000-00-00 00:00:00', 0),
(18, 46, 'tmplt_Sup_Sup_022_006', 'te_Sup_Sup_t00000000_24122_006', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '442007356319778', 1, 'Y', '2024-01-22 04:47:10', '0000-00-00 00:00:00', 0),
(19, 14, 'tmplt_Sup_Sup_022_007', 'te_Sup_Sup_t00000000_24122_007', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing\"}]', '3045331807311', 1, 'Y', '2024-01-22 04:48:14', '0000-00-00 00:00:00', 0),
(20, 17, 'tmplt_Sup_Sup_022_007', 'te_Sup_Sup_t00000000_24122_007', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing\"}]', '3045331807311', 1, 'Y', '2024-01-22 04:48:14', '0000-00-00 00:00:00', 0),
(21, 46, 'tmplt_Sup_Sup_022_007', 'te_Sup_Sup_t00000000_24122_007', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing\"}]', '3045331807311', 1, 'Y', '2024-01-22 04:48:14', '0000-00-00 00:00:00', 0),
(22, 14, 'tmplt_Sup_Sup_022_008', 'te_Sup_Sup_t00000000_24122_008', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"www.google.com\"}]', '506207052189867', 1, 'Y', '2024-01-22 04:49:38', '0000-00-00 00:00:00', 0),
(23, 17, 'tmplt_Sup_Sup_022_008', 'te_Sup_Sup_t00000000_24122_008', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"www.google.com\"}]', '506207052189867', 1, 'Y', '2024-01-22 04:49:38', '0000-00-00 00:00:00', 0),
(24, 46, 'tmplt_Sup_Sup_022_008', 'te_Sup_Sup_t00000000_24122_008', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"www.google.com\"}]', '506207052189867', 1, 'Y', '2024-01-22 04:49:38', '0000-00-00 00:00:00', 0),
(25, 14, 'tmplt_Sup_Sup_022_009', 'te_Sup_Sup_t00000000_24122_009', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '244952054355824', 1, 'Y', '2024-01-22 04:55:51', '0000-00-00 00:00:00', 0),
(26, 17, 'tmplt_Sup_Sup_022_009', 'te_Sup_Sup_t00000000_24122_009', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '244952054355824', 1, 'Y', '2024-01-22 04:55:51', '0000-00-00 00:00:00', 0),
(27, 46, 'tmplt_Sup_Sup_022_009', 'te_Sup_Sup_t00000000_24122_009', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '244952054355824', 1, 'Y', '2024-01-22 04:55:51', '0000-00-00 00:00:00', 0),
(28, 14, 'tmplt_Sup_Sup_022_010', 'te_Sup_Sup_t00000000_24122_010', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"jsbdskjds\"}]', '283187463513665', 1, 'Y', '2024-01-22 04:57:55', '0000-00-00 00:00:00', 0),
(29, 17, 'tmplt_Sup_Sup_022_010', 'te_Sup_Sup_t00000000_24122_010', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"jsbdskjds\"}]', '283187463513665', 1, 'Y', '2024-01-22 04:57:55', '0000-00-00 00:00:00', 0),
(30, 46, 'tmplt_Sup_Sup_022_010', 'te_Sup_Sup_t00000000_24122_010', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"jsbdskjds\"}]', '283187463513665', 1, 'Y', '2024-01-22 04:57:55', '0000-00-00 00:00:00', 0),
(31, 14, 'tmplt_Sup_Sup_022_011', 'te_Sup_Sup_t00000000_24122_011', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"msddjnskndsk\"}]', '475454655313065', 1, 'Y', '2024-01-22 04:59:00', '0000-00-00 00:00:00', 0),
(32, 17, 'tmplt_Sup_Sup_022_011', 'te_Sup_Sup_t00000000_24122_011', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"msddjnskndsk\"}]', '475454655313065', 1, 'Y', '2024-01-22 04:59:00', '0000-00-00 00:00:00', 0),
(33, 46, 'tmplt_Sup_Sup_022_011', 'te_Sup_Sup_t00000000_24122_011', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"msddjnskndsk\"}]', '475454655313065', 1, 'Y', '2024-01-22 04:59:00', '0000-00-00 00:00:00', 0),
(34, 14, 'tmplt_Sup_Sup_022_012', 'te_Sup_Sup_t00000000_24122_012', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>sfdfdfd</b></p>\"}]', '811264267754543', 1, 'Y', '2024-01-22 05:01:04', '0000-00-00 00:00:00', 0),
(35, 17, 'tmplt_Sup_Sup_022_012', 'te_Sup_Sup_t00000000_24122_012', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>sfdfdfd</b></p>\"}]', '811264267754543', 1, 'Y', '2024-01-22 05:01:04', '0000-00-00 00:00:00', 0),
(36, 46, 'tmplt_Sup_Sup_022_012', 'te_Sup_Sup_t00000000_24122_012', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>sfdfdfd</b></p>\"}]', '811264267754543', 1, 'Y', '2024-01-22 05:01:04', '0000-00-00 00:00:00', 0),
(37, 14, 'tmplt_Sup_Sup_022_013', 'te_Sup_Sup_t00000000_24122_013', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '352947537526832', 1, 'Y', '2024-01-22 05:02:27', '0000-00-00 00:00:00', 0),
(38, 17, 'tmplt_Sup_Sup_022_013', 'te_Sup_Sup_t00000000_24122_013', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '352947537526832', 1, 'Y', '2024-01-22 05:02:27', '0000-00-00 00:00:00', 0),
(39, 46, 'tmplt_Sup_Sup_022_013', 'te_Sup_Sup_t00000000_24122_013', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '352947537526832', 1, 'Y', '2024-01-22 05:02:27', '0000-00-00 00:00:00', 0),
(40, 14, 'tmplt_Sup_Sup_022_014', 'te_Sup_Sup_t00000000_24122_014', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"dnekde\"}]', '201003626400330', 1, 'Y', '2024-01-22 05:04:37', '0000-00-00 00:00:00', 0),
(41, 17, 'tmplt_Sup_Sup_022_014', 'te_Sup_Sup_t00000000_24122_014', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"dnekde\"}]', '201003626400330', 1, 'Y', '2024-01-22 05:04:37', '0000-00-00 00:00:00', 0),
(42, 46, 'tmplt_Sup_Sup_022_014', 'te_Sup_Sup_t00000000_24122_014', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"dnekde\"}]', '201003626400330', 1, 'Y', '2024-01-22 05:04:37', '0000-00-00 00:00:00', 0),
(43, 14, 'tmplt_Sup_Sup_022_015', 'te_Sup_Sup_t00000000_24122_015', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"&lt;p&gt;&lt;b&gt;dsf&lt;/b&gt;&lt;/p&gt;\"}]', '431845821815967', 1, 'Y', '2024-01-22 05:05:51', '0000-00-00 00:00:00', 0),
(44, 17, 'tmplt_Sup_Sup_022_015', 'te_Sup_Sup_t00000000_24122_015', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"&lt;p&gt;&lt;b&gt;dsf&lt;/b&gt;&lt;/p&gt;\"}]', '431845821815967', 1, 'Y', '2024-01-22 05:05:51', '0000-00-00 00:00:00', 0),
(45, 46, 'tmplt_Sup_Sup_022_015', 'te_Sup_Sup_t00000000_24122_015', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"&lt;p&gt;&lt;b&gt;dsf&lt;/b&gt;&lt;/p&gt;\"}]', '431845821815967', 1, 'Y', '2024-01-22 05:05:51', '0000-00-00 00:00:00', 0),
(46, 14, 'tmplt_Sup_Sup_022_016', 'te_Sup_Sup_t00000000_24122_016', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"kdneknfk\"}]', '246070304464291', 1, 'Y', '2024-01-22 05:06:28', '0000-00-00 00:00:00', 0),
(47, 17, 'tmplt_Sup_Sup_022_016', 'te_Sup_Sup_t00000000_24122_016', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"kdneknfk\"}]', '246070304464291', 1, 'Y', '2024-01-22 05:06:28', '0000-00-00 00:00:00', 0),
(48, 46, 'tmplt_Sup_Sup_022_016', 'te_Sup_Sup_t00000000_24122_016', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"kdneknfk\"}]', '246070304464291', 1, 'Y', '2024-01-22 05:06:28', '0000-00-00 00:00:00', 0),
(49, 14, 'tmplt_Sup_Sup_022_017', 'te_Sup_Sup_t00000000_24122_017', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"kjddddddddddddd\"}]', '295236659137987', 1, 'Y', '2024-01-22 05:12:15', '0000-00-00 00:00:00', 0),
(50, 17, 'tmplt_Sup_Sup_022_017', 'te_Sup_Sup_t00000000_24122_017', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"kjddddddddddddd\"}]', '295236659137987', 1, 'Y', '2024-01-22 05:12:15', '0000-00-00 00:00:00', 0),
(51, 46, 'tmplt_Sup_Sup_022_017', 'te_Sup_Sup_t00000000_24122_017', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"kjddddddddddddd\"}]', '295236659137987', 1, 'Y', '2024-01-22 05:12:15', '0000-00-00 00:00:00', 0),
(52, 14, 'tmplt_Sup_Sup_022_018', 'te_Sup_Sup_t00000000_24122_018', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing\"}]', '447995082621303', 1, 'Y', '2024-01-22 05:18:20', '0000-00-00 00:00:00', 0),
(53, 17, 'tmplt_Sup_Sup_022_018', 'te_Sup_Sup_t00000000_24122_018', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing\"}]', '447995082621303', 1, 'Y', '2024-01-22 05:18:20', '0000-00-00 00:00:00', 0),
(54, 46, 'tmplt_Sup_Sup_022_018', 'te_Sup_Sup_t00000000_24122_018', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing\"}]', '447995082621303', 1, 'Y', '2024-01-22 05:18:20', '0000-00-00 00:00:00', 0),
(55, 14, 'tmplt_Sup_Sup_022_019', 'te_Sup_Sup_t00000000_24122_019', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><a href=\"http://Testing\" target=\"_blank\">Testing</a><br></p>\"}]', '427228220885621', 1, 'Y', '2024-01-22 05:19:37', '0000-00-00 00:00:00', 0),
(56, 17, 'tmplt_Sup_Sup_022_019', 'te_Sup_Sup_t00000000_24122_019', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><a href=\"http://Testing\" target=\"_blank\">Testing</a><br></p>\"}]', '427228220885621', 1, 'Y', '2024-01-22 05:19:37', '0000-00-00 00:00:00', 0),
(57, 46, 'tmplt_Sup_Sup_022_019', 'te_Sup_Sup_t00000000_24122_019', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><a href=\"http://Testing\" target=\"_blank\">Testing</a><br></p>\"}]', '427228220885621', 1, 'Y', '2024-01-22 05:19:37', '0000-00-00 00:00:00', 0),
(58, 14, 'tmplt_Sup_Sup_022_020', 'te_Sup_Sup_t00000000_24122_020', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>Testing</b><br></p>\"}]', '313628779429476', 1, 'Y', '2024-01-22 05:20:06', '0000-00-00 00:00:00', 0),
(59, 17, 'tmplt_Sup_Sup_022_020', 'te_Sup_Sup_t00000000_24122_020', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>Testing</b><br></p>\"}]', '313628779429476', 1, 'Y', '2024-01-22 05:20:06', '0000-00-00 00:00:00', 0),
(60, 46, 'tmplt_Sup_Sup_022_020', 'te_Sup_Sup_t00000000_24122_020', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>Testing</b><br></p>\"}]', '313628779429476', 1, 'Y', '2024-01-22 05:20:06', '0000-00-00 00:00:00', 0),
(61, 14, 'tmplt_Sup_Sup_022_021', 'te_Sup_Sup_t00000000_24122_021', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>Testing</b><br></p>\"}]', '381963762029251', 1, 'Y', '2024-01-22 05:23:36', '0000-00-00 00:00:00', 0),
(62, 17, 'tmplt_Sup_Sup_022_021', 'te_Sup_Sup_t00000000_24122_021', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>Testing</b><br></p>\"}]', '381963762029251', 1, 'Y', '2024-01-22 05:23:36', '0000-00-00 00:00:00', 0),
(63, 46, 'tmplt_Sup_Sup_022_021', 'te_Sup_Sup_t00000000_24122_021', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>Testing</b><br></p>\"}]', '381963762029251', 1, 'Y', '2024-01-22 05:23:36', '0000-00-00 00:00:00', 0),
(64, 14, 'tmplt_Sup_Sup_022_022', 'te_Sup_Sup_t00000000_24122_022', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>Testing</b><br></p>\"}]', '371277920508391', 1, 'Y', '2024-01-22 05:24:01', '0000-00-00 00:00:00', 0),
(65, 17, 'tmplt_Sup_Sup_022_022', 'te_Sup_Sup_t00000000_24122_022', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>Testing</b><br></p>\"}]', '371277920508391', 1, 'Y', '2024-01-22 05:24:01', '0000-00-00 00:00:00', 0),
(66, 46, 'tmplt_Sup_Sup_022_022', 'te_Sup_Sup_t00000000_24122_022', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>Testing</b><br></p>\"}]', '371277920508391', 1, 'Y', '2024-01-22 05:24:01', '0000-00-00 00:00:00', 0),
(67, 14, 'tmplt_Sup_Sup_022_023', 'te_Sup_Sup_t00000000_24122_023', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b><a href=\"http://Testing\" target=\"_blank\">Testing</a></b><br></p>\"}]', '508986886308292', 1, 'Y', '2024-01-22 05:25:29', '0000-00-00 00:00:00', 0),
(68, 17, 'tmplt_Sup_Sup_022_023', 'te_Sup_Sup_t00000000_24122_023', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b><a href=\"http://Testing\" target=\"_blank\">Testing</a></b><br></p>\"}]', '508986886308292', 1, 'Y', '2024-01-22 05:25:29', '0000-00-00 00:00:00', 0),
(69, 46, 'tmplt_Sup_Sup_022_023', 'te_Sup_Sup_t00000000_24122_023', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b><a href=\"http://Testing\" target=\"_blank\">Testing</a></b><br></p>\"}]', '508986886308292', 1, 'Y', '2024-01-22 05:25:29', '0000-00-00 00:00:00', 0),
(70, 14, 'tmplt_Sup_Sup_022_024', 'te_Sup_Sup_t00000000_24122_024', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>testing</b></p>\"}]', '972723376338365', 1, 'Y', '2024-01-22 05:33:23', '0000-00-00 00:00:00', 0),
(71, 17, 'tmplt_Sup_Sup_022_024', 'te_Sup_Sup_t00000000_24122_024', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>testing</b></p>\"}]', '972723376338365', 1, 'Y', '2024-01-22 05:33:23', '0000-00-00 00:00:00', 0),
(72, 46, 'tmplt_Sup_Sup_022_024', 'te_Sup_Sup_t00000000_24122_024', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>testing</b></p>\"}]', '972723376338365', 1, 'Y', '2024-01-22 05:33:23', '0000-00-00 00:00:00', 0),
(73, 14, 'tmplt_Sup_Sup_022_025', 'te_Sup_Sup_t00000000_24122_025', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b><a href=\"http://testing\" target=\"_blank\">testing</a></b></p>\"}]', '833458204270438', 1, 'Y', '2024-01-22 05:33:37', '0000-00-00 00:00:00', 0),
(74, 17, 'tmplt_Sup_Sup_022_025', 'te_Sup_Sup_t00000000_24122_025', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b><a href=\"http://testing\" target=\"_blank\">testing</a></b></p>\"}]', '833458204270438', 1, 'Y', '2024-01-22 05:33:37', '0000-00-00 00:00:00', 0),
(75, 46, 'tmplt_Sup_Sup_022_025', 'te_Sup_Sup_t00000000_24122_025', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b><a href=\"http://testing\" target=\"_blank\">testing</a></b></p>\"}]', '833458204270438', 1, 'Y', '2024-01-22 05:33:37', '0000-00-00 00:00:00', 0),
(76, 14, 'tmplt_Sup_Sup_022_026', 'te_Sup_Sup_t00000000_24122_026', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b><a href=\"http://testing\" target=\"_blank\">testing</a></b></p>\"}]', '111949487335924', 1, 'Y', '2024-01-22 05:35:48', '0000-00-00 00:00:00', 0),
(77, 17, 'tmplt_Sup_Sup_022_026', 'te_Sup_Sup_t00000000_24122_026', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b><a href=\"http://testing\" target=\"_blank\">testing</a></b></p>\"}]', '111949487335924', 1, 'Y', '2024-01-22 05:35:48', '0000-00-00 00:00:00', 0),
(78, 46, 'tmplt_Sup_Sup_022_026', 'te_Sup_Sup_t00000000_24122_026', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b><a href=\"http://testing\" target=\"_blank\">testing</a></b></p>\"}]', '111949487335924', 1, 'Y', '2024-01-22 05:35:48', '0000-00-00 00:00:00', 0),
(79, 14, 'tmplt_Sup_Sup_022_027', 'te_Sup_Sup_t00000000_24122_027', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b><a href=\"http://testing\" target=\"_blank\">testing</a></b></p>\"}]', '32788368123103', 1, 'Y', '2024-01-22 05:39:16', '0000-00-00 00:00:00', 0),
(80, 17, 'tmplt_Sup_Sup_022_027', 'te_Sup_Sup_t00000000_24122_027', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b><a href=\"http://testing\" target=\"_blank\">testing</a></b></p>\"}]', '32788368123103', 1, 'Y', '2024-01-22 05:39:16', '0000-00-00 00:00:00', 0),
(81, 46, 'tmplt_Sup_Sup_022_027', 'te_Sup_Sup_t00000000_24122_027', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b><a href=\"http://testing\" target=\"_blank\">testing</a></b></p>\"}]', '32788368123103', 1, 'Y', '2024-01-22 05:39:16', '0000-00-00 00:00:00', 0),
(82, 14, 'tmplt_Sup_Sup_022_028', 'te_Sup_Sup_t00000u00_24122_028', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b><a href=\"http://testing\" target=\"_blank\">testing</a></b></p>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"testing\",\"url\":\"http://testing\"}]}]', '9056359375168', 1, 'Y', '2024-01-22 05:45:16', '0000-00-00 00:00:00', 0),
(83, 17, 'tmplt_Sup_Sup_022_028', 'te_Sup_Sup_t00000u00_24122_028', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b><a href=\"http://testing\" target=\"_blank\">testing</a></b></p>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"testing\",\"url\":\"http://testing\"}]}]', '9056359375168', 1, 'Y', '2024-01-22 05:45:16', '0000-00-00 00:00:00', 0),
(84, 46, 'tmplt_Sup_Sup_022_028', 'te_Sup_Sup_t00000u00_24122_028', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b><a href=\"http://testing\" target=\"_blank\">testing</a></b></p>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"testing\",\"url\":\"http://testing\"}]}]', '9056359375168', 1, 'Y', '2024-01-22 05:45:16', '0000-00-00 00:00:00', 0),
(85, 14, 'tmplt_Sup_Sup_022_029', 'te_Sup_Sup_t00000u00_24122_029', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"testing\",\"url\":\"http://testing\"}]}]', '234477141713134', 1, 'Y', '2024-01-22 05:50:45', '0000-00-00 00:00:00', 0),
(86, 17, 'tmplt_Sup_Sup_022_029', 'te_Sup_Sup_t00000u00_24122_029', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"testing\",\"url\":\"http://testing\"}]}]', '234477141713134', 1, 'Y', '2024-01-22 05:50:45', '0000-00-00 00:00:00', 0),
(87, 46, 'tmplt_Sup_Sup_022_029', 'te_Sup_Sup_t00000u00_24122_029', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"testing\",\"url\":\"http://testing\"}]}]', '234477141713134', 1, 'Y', '2024-01-22 05:50:45', '0000-00-00 00:00:00', 0),
(88, 14, 'tmplt_Sup_Sup_022_030', 'te_Sup_Sup_t00000000_24122_030', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '832536474455055', 1, 'Y', '2024-01-22 05:52:12', '0000-00-00 00:00:00', 0),
(89, 17, 'tmplt_Sup_Sup_022_030', 'te_Sup_Sup_t00000000_24122_030', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '832536474455055', 1, 'Y', '2024-01-22 05:52:12', '0000-00-00 00:00:00', 0),
(90, 46, 'tmplt_Sup_Sup_022_030', 'te_Sup_Sup_t00000000_24122_030', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '832536474455055', 1, 'Y', '2024-01-22 05:52:12', '0000-00-00 00:00:00', 0),
(91, 14, 'tmplt_Sup_Sup_022_031', 'te_Sup_Sup_t00000000_24122_031', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>testing</b></p>\"}]', '440227187562085', 1, 'Y', '2024-01-22 05:53:19', '0000-00-00 00:00:00', 0),
(92, 17, 'tmplt_Sup_Sup_022_031', 'te_Sup_Sup_t00000000_24122_031', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>testing</b></p>\"}]', '440227187562085', 1, 'Y', '2024-01-22 05:53:19', '0000-00-00 00:00:00', 0),
(93, 46, 'tmplt_Sup_Sup_022_031', 'te_Sup_Sup_t00000000_24122_031', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><b>testing</b></p>\"}]', '440227187562085', 1, 'Y', '2024-01-22 05:53:19', '0000-00-00 00:00:00', 0),
(94, 14, 'tmplt_Sup_Sup_022_032', 'te_Sup_Sup_t00000000_24122_032', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '206449779654765', 1, 'Y', '2024-01-22 05:56:14', '0000-00-00 00:00:00', 0),
(95, 17, 'tmplt_Sup_Sup_022_032', 'te_Sup_Sup_t00000000_24122_032', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '206449779654765', 1, 'Y', '2024-01-22 05:56:14', '0000-00-00 00:00:00', 0),
(96, 46, 'tmplt_Sup_Sup_022_032', 'te_Sup_Sup_t00000000_24122_032', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '206449779654765', 1, 'Y', '2024-01-22 05:56:14', '0000-00-00 00:00:00', 0),
(97, 14, 'tmplt_Sup_Sup_022_033', 'te_Sup_Sup_t00000000_24122_033', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*\"}]', '334173367997404', 1, 'Y', '2024-01-22 06:02:36', '0000-00-00 00:00:00', 0),
(98, 17, 'tmplt_Sup_Sup_022_033', 'te_Sup_Sup_t00000000_24122_033', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*\"}]', '334173367997404', 1, 'Y', '2024-01-22 06:02:36', '0000-00-00 00:00:00', 0),
(99, 46, 'tmplt_Sup_Sup_022_033', 'te_Sup_Sup_t00000000_24122_033', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*\"}]', '334173367997404', 1, 'Y', '2024-01-22 06:02:36', '0000-00-00 00:00:00', 0),
(100, 14, 'tmplt_Sup_Sup_022_034', 'te_Sup_Sup_t00000000_24122_034', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Completed1.logo change on celeb media&nbsp;2.no media disable the media field3.variable count display on front end&nbsp; &nbsp;&nbsp;In progress4. Test case and issue solving on variable count5.1 lakh mobile numbers validating on timing\"}]', '789017783795767', 1, 'Y', '2024-01-22 06:04:41', '0000-00-00 00:00:00', 0),
(101, 17, 'tmplt_Sup_Sup_022_034', 'te_Sup_Sup_t00000000_24122_034', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Completed1.logo change on celeb media&nbsp;2.no media disable the media field3.variable count display on front end&nbsp; &nbsp;&nbsp;In progress4. Test case and issue solving on variable count5.1 lakh mobile numbers validating on timing\"}]', '789017783795767', 1, 'Y', '2024-01-22 06:04:41', '0000-00-00 00:00:00', 0),
(102, 46, 'tmplt_Sup_Sup_022_034', 'te_Sup_Sup_t00000000_24122_034', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Completed1.logo change on celeb media&nbsp;2.no media disable the media field3.variable count display on front end&nbsp; &nbsp;&nbsp;In progress4. Test case and issue solving on variable count5.1 lakh mobile numbers validating on timing\"}]', '789017783795767', 1, 'Y', '2024-01-22 06:04:41', '0000-00-00 00:00:00', 0),
(103, 14, 'tmplt_Sup_Sup_022_035', 'te_Sup_Sup_t00000000_24122_035', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Completed\n1.logo change on celeb media \n2.no media disable the media field\n3.variable count display on front end    \nIn progress\n4. Test case and issue solving on variable count\n5.1 lakh mobile numbers validating on timing\"}]', '340299165539554', 1, 'Y', '2024-01-22 06:05:20', '0000-00-00 00:00:00', 0),
(104, 17, 'tmplt_Sup_Sup_022_035', 'te_Sup_Sup_t00000000_24122_035', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Completed\n1.logo change on celeb media \n2.no media disable the media field\n3.variable count display on front end    \nIn progress\n4. Test case and issue solving on variable count\n5.1 lakh mobile numbers validating on timing\"}]', '340299165539554', 1, 'Y', '2024-01-22 06:05:21', '0000-00-00 00:00:00', 0),
(105, 46, 'tmplt_Sup_Sup_022_035', 'te_Sup_Sup_t00000000_24122_035', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Completed\n1.logo change on celeb media \n2.no media disable the media field\n3.variable count display on front end    \nIn progress\n4. Test case and issue solving on variable count\n5.1 lakh mobile numbers validating on timing\"}]', '340299165539554', 1, 'Y', '2024-01-22 06:05:21', '0000-00-00 00:00:00', 0),
(106, 14, 'tmplt_Sup_Sup_022_036', 'te_Sup_Sup_t00000000_24122_036', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Testing*\"}]', '368655214440324', 1, 'Y', '2024-01-22 06:15:36', '0000-00-00 00:00:00', 0),
(107, 17, 'tmplt_Sup_Sup_022_036', 'te_Sup_Sup_t00000000_24122_036', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Testing*\"}]', '368655214440324', 1, 'Y', '2024-01-22 06:15:36', '0000-00-00 00:00:00', 0),
(108, 46, 'tmplt_Sup_Sup_022_036', 'te_Sup_Sup_t00000000_24122_036', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Testing*\"}]', '368655214440324', 1, 'Y', '2024-01-22 06:15:36', '0000-00-00 00:00:00', 0),
(109, 14, 'tmplt_Sup_Sup_022_037', 'te_Sup_Sup_t00000000_24122_037', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*5.1 lakh mobile numbers validating on timing*\"}]', '162058993574943', 1, 'Y', '2024-01-22 06:17:06', '0000-00-00 00:00:00', 0),
(110, 17, 'tmplt_Sup_Sup_022_037', 'te_Sup_Sup_t00000000_24122_037', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*5.1 lakh mobile numbers validating on timing*\"}]', '162058993574943', 1, 'Y', '2024-01-22 06:17:06', '0000-00-00 00:00:00', 0),
(111, 46, 'tmplt_Sup_Sup_022_037', 'te_Sup_Sup_t00000000_24122_037', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*5.1 lakh mobile numbers validating on timing*\"}]', '162058993574943', 1, 'Y', '2024-01-22 06:17:06', '0000-00-00 00:00:00', 0),
(112, 14, 'tmplt_Sup_Sup_022_038', 'te_Sup_Sup_t00000000_24122_038', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Completed1.logo change on celeb media&nbsp;2.no media disable the media field3.variable count display on front end&nbsp; &nbsp;&nbsp;In progress4. Test case and issue solving on variable count5.1 lakh mobile numbers validating on timing\"}]', '425309399505167', 1, 'Y', '2024-01-22 06:18:00', '0000-00-00 00:00:00', 0),
(113, 17, 'tmplt_Sup_Sup_022_038', 'te_Sup_Sup_t00000000_24122_038', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Completed1.logo change on celeb media&nbsp;2.no media disable the media field3.variable count display on front end&nbsp; &nbsp;&nbsp;In progress4. Test case and issue solving on variable count5.1 lakh mobile numbers validating on timing\"}]', '425309399505167', 1, 'Y', '2024-01-22 06:18:00', '0000-00-00 00:00:00', 0),
(114, 46, 'tmplt_Sup_Sup_022_038', 'te_Sup_Sup_t00000000_24122_038', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Completed1.logo change on celeb media&nbsp;2.no media disable the media field3.variable count display on front end&nbsp; &nbsp;&nbsp;In progress4. Test case and issue solving on variable count5.1 lakh mobile numbers validating on timing\"}]', '425309399505167', 1, 'Y', '2024-01-22 06:18:00', '0000-00-00 00:00:00', 0),
(115, 14, 'tmplt_Sup_Sup_022_039', 'te_Sup_Sup_t00000000_24122_039', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Completed1.logo change on celeb media&nbsp;2.no media disable the media field3.variable count display on front end&nbsp; &nbsp;&nbsp;In progress4. Test case and issue solving on variable count5.1 lakh mobile numbers validating on timing\"}]', '487601181478290', 1, 'Y', '2024-01-22 06:19:24', '0000-00-00 00:00:00', 0),
(116, 17, 'tmplt_Sup_Sup_022_039', 'te_Sup_Sup_t00000000_24122_039', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Completed1.logo change on celeb media&nbsp;2.no media disable the media field3.variable count display on front end&nbsp; &nbsp;&nbsp;In progress4. Test case and issue solving on variable count5.1 lakh mobile numbers validating on timing\"}]', '487601181478290', 1, 'Y', '2024-01-22 06:19:24', '0000-00-00 00:00:00', 0),
(117, 46, 'tmplt_Sup_Sup_022_039', 'te_Sup_Sup_t00000000_24122_039', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Completed1.logo change on celeb media&nbsp;2.no media disable the media field3.variable count display on front end&nbsp; &nbsp;&nbsp;In progress4. Test case and issue solving on variable count5.1 lakh mobile numbers validating on timing\"}]', '487601181478290', 1, 'Y', '2024-01-22 06:19:24', '0000-00-00 00:00:00', 0),
(118, 14, 'tmplt_Sup_Sup_022_040', 'te_Sup_Sup_t00000000_24122_040', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;welcome Madhu&nbsp;Today date is 22 Jan 2023This is a new project . Today is a last date for whatsapp group . And i am working in very sincerely&nbsp;\"}]', '895046926498970', 1, 'Y', '2024-01-22 06:23:45', '0000-00-00 00:00:00', 0),
(119, 17, 'tmplt_Sup_Sup_022_040', 'te_Sup_Sup_t00000000_24122_040', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;welcome Madhu&nbsp;Today date is 22 Jan 2023This is a new project . Today is a last date for whatsapp group . And i am working in very sincerely&nbsp;\"}]', '895046926498970', 1, 'Y', '2024-01-22 06:23:45', '0000-00-00 00:00:00', 0),
(120, 46, 'tmplt_Sup_Sup_022_040', 'te_Sup_Sup_t00000000_24122_040', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;welcome Madhu&nbsp;Today date is 22 Jan 2023This is a new project . Today is a last date for whatsapp group . And i am working in very sincerely&nbsp;\"}]', '895046926498970', 1, 'Y', '2024-01-22 06:23:45', '0000-00-00 00:00:00', 0),
(121, 14, 'tmplt_Sup_Sup_022_041', 'te_Sup_Sup_t00000000_24122_041', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;welcome MadhuToday date is 22 Jan 2023This is a new project .Today is a last date for whatsapp group .And i am working in very sincerely&nbsp;\"}]', '676720360554960', 1, 'Y', '2024-01-22 06:25:04', '0000-00-00 00:00:00', 0),
(122, 17, 'tmplt_Sup_Sup_022_041', 'te_Sup_Sup_t00000000_24122_041', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;welcome MadhuToday date is 22 Jan 2023This is a new project .Today is a last date for whatsapp group .And i am working in very sincerely&nbsp;\"}]', '676720360554960', 1, 'Y', '2024-01-22 06:25:04', '0000-00-00 00:00:00', 0),
(123, 46, 'tmplt_Sup_Sup_022_041', 'te_Sup_Sup_t00000000_24122_041', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;welcome MadhuToday date is 22 Jan 2023This is a new project .Today is a last date for whatsapp group .And i am working in very sincerely&nbsp;\"}]', '676720360554960', 1, 'Y', '2024-01-22 06:25:04', '0000-00-00 00:00:00', 0),
(124, 14, 'tmplt_Sup_Sup_022_042', 'te_Sup_Sup_t00000000_24122_042', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;welcome MadhuToday date is 22 Jan 2023This is a new project .Today is a last date for whatsapp group .And i am working in very sincerely&nbsp;\"}]', '597736469686693', 1, 'Y', '2024-01-22 06:25:55', '0000-00-00 00:00:00', 0),
(125, 17, 'tmplt_Sup_Sup_022_042', 'te_Sup_Sup_t00000000_24122_042', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;welcome MadhuToday date is 22 Jan 2023This is a new project .Today is a last date for whatsapp group .And i am working in very sincerely&nbsp;\"}]', '597736469686693', 1, 'Y', '2024-01-22 06:25:55', '0000-00-00 00:00:00', 0),
(126, 46, 'tmplt_Sup_Sup_022_042', 'te_Sup_Sup_t00000000_24122_042', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;welcome MadhuToday date is 22 Jan 2023This is a new project .Today is a last date for whatsapp group .And i am working in very sincerely&nbsp;\"}]', '597736469686693', 1, 'Y', '2024-01-22 06:25:55', '0000-00-00 00:00:00', 0),
(127, 14, 'tmplt_Sup_Sup_022_043', 'te_Sup_Sup_t00000000_24122_043', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;welcome Madhu&nbsp;Today date is 22 Jan 2023&nbsp;This is a new project .&nbsp;Today is a last date for whatsapp group .&nbsp;And i am working in very sincerely&nbsp;\"}]', '567728484779496', 1, 'Y', '2024-01-22 06:27:35', '0000-00-00 00:00:00', 0),
(128, 17, 'tmplt_Sup_Sup_022_043', 'te_Sup_Sup_t00000000_24122_043', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;welcome Madhu&nbsp;Today date is 22 Jan 2023&nbsp;This is a new project .&nbsp;Today is a last date for whatsapp group .&nbsp;And i am working in very sincerely&nbsp;\"}]', '567728484779496', 1, 'Y', '2024-01-22 06:27:35', '0000-00-00 00:00:00', 0),
(129, 46, 'tmplt_Sup_Sup_022_043', 'te_Sup_Sup_t00000000_24122_043', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;welcome Madhu&nbsp;Today date is 22 Jan 2023&nbsp;This is a new project .&nbsp;Today is a last date for whatsapp group .&nbsp;And i am working in very sincerely&nbsp;\"}]', '567728484779496', 1, 'Y', '2024-01-22 06:27:35', '0000-00-00 00:00:00', 0),
(130, 14, 'tmplt_Sup_Sup_022_044', 'te_Sup_Sup_t00000000_24122_044', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<div>Completed</div><div><br></div><div><div>1.logo change on celeb media</div><div><br></div><div>2.no media disable the media field</div><div><br></div><div>3.variable count display on front end&nbsp;&nbsp;</div><div><br></div><div>In progress</div><div><br></div><div>4. Test case and issue solving on variable count</div><div><br></div><div>5.1 lakh mobile numbers validating on timing</div></div><div><br></div>\"}]', '925125060674922', 1, 'Y', '2024-01-22 06:32:03', '0000-00-00 00:00:00', 0),
(131, 17, 'tmplt_Sup_Sup_022_044', 'te_Sup_Sup_t00000000_24122_044', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<div>Completed</div><div><br></div><div><div>1.logo change on celeb media</div><div><br></div><div>2.no media disable the media field</div><div><br></div><div>3.variable count display on front end&nbsp;&nbsp;</div><div><br></div><div>In progress</div><div><br></div><div>4. Test case and issue solving on variable count</div><div><br></div><div>5.1 lakh mobile numbers validating on timing</div></div><div><br></div>\"}]', '925125060674922', 1, 'Y', '2024-01-22 06:32:03', '0000-00-00 00:00:00', 0),
(132, 46, 'tmplt_Sup_Sup_022_044', 'te_Sup_Sup_t00000000_24122_044', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<div>Completed</div><div><br></div><div><div>1.logo change on celeb media</div><div><br></div><div>2.no media disable the media field</div><div><br></div><div>3.variable count display on front end&nbsp;&nbsp;</div><div><br></div><div>In progress</div><div><br></div><div>4. Test case and issue solving on variable count</div><div><br></div><div>5.1 lakh mobile numbers validating on timing</div></div><div><br></div>\"}]', '925125060674922', 1, 'Y', '2024-01-22 06:32:03', '0000-00-00 00:00:00', 0),
(133, 14, 'tmplt_Sup_Sup_022_045', 'te_Sup_Sup_t00000000_24122_045', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<div>Testing Mobile numbers&nbsp;</div><div>welcome</div><div>Testing&nbsp;</div><div><br></div>\"}]', '10271337474181', 1, 'Y', '2024-01-22 06:32:58', '0000-00-00 00:00:00', 0),
(134, 17, 'tmplt_Sup_Sup_022_045', 'te_Sup_Sup_t00000000_24122_045', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<div>Testing Mobile numbers&nbsp;</div><div>welcome</div><div>Testing&nbsp;</div><div><br></div>\"}]', '10271337474181', 1, 'Y', '2024-01-22 06:32:58', '0000-00-00 00:00:00', 0),
(135, 46, 'tmplt_Sup_Sup_022_045', 'te_Sup_Sup_t00000000_24122_045', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<div>Testing Mobile numbers&nbsp;</div><div>welcome</div><div>Testing&nbsp;</div><div><br></div>\"}]', '10271337474181', 1, 'Y', '2024-01-22 06:32:58', '0000-00-00 00:00:00', 0),
(136, 14, 'tmplt_Sup_Sup_022_046', 'te_Sup_Sup_t00000000_24122_046', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing Message For Today</p><p> 22 Jan 2023.</p><p> Madhu bala</p><p>I am working From Yeejai Technology .</p>\"}]', '975864842764668', 1, 'Y', '2024-01-22 06:37:20', '0000-00-00 00:00:00', 0),
(137, 17, 'tmplt_Sup_Sup_022_046', 'te_Sup_Sup_t00000000_24122_046', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing Message For Today</p><p> 22 Jan 2023.</p><p> Madhu bala</p><p>I am working From Yeejai Technology .</p>\"}]', '975864842764668', 1, 'Y', '2024-01-22 06:37:20', '0000-00-00 00:00:00', 0),
(138, 46, 'tmplt_Sup_Sup_022_046', 'te_Sup_Sup_t00000000_24122_046', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing Message For Today</p><p> 22 Jan 2023.</p><p> Madhu bala</p><p>I am working From Yeejai Technology .</p>\"}]', '975864842764668', 1, 'Y', '2024-01-22 06:37:20', '0000-00-00 00:00:00', 0),
(139, 14, 'tmplt_Sup_Sup_022_047', 'te_Sup_Sup_t00000000_24122_047', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing Message For Today</p><p>22 Jan 2023.</p><p>Madhu bala</p><p>I am working From Yeejai Technology .</p>\"}]', '38271092157132', 1, 'Y', '2024-01-22 06:37:45', '0000-00-00 00:00:00', 0),
(140, 17, 'tmplt_Sup_Sup_022_047', 'te_Sup_Sup_t00000000_24122_047', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing Message For Today</p><p>22 Jan 2023.</p><p>Madhu bala</p><p>I am working From Yeejai Technology .</p>\"}]', '38271092157132', 1, 'Y', '2024-01-22 06:37:45', '0000-00-00 00:00:00', 0),
(141, 46, 'tmplt_Sup_Sup_022_047', 'te_Sup_Sup_t00000000_24122_047', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing Message For Today</p><p>22 Jan 2023.</p><p>Madhu bala</p><p>I am working From Yeejai Technology .</p>\"}]', '38271092157132', 1, 'Y', '2024-01-22 06:37:45', '0000-00-00 00:00:00', 0),
(142, 14, 'tmplt_Sup_Sup_022_048', 'te_Sup_Sup_t00000000_24122_048', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><span style=\"font-weight: bolder;\">Testing Message For Today</span></p><p><span style=\"font-weight: bolder;\">22 Jan 2023.</span></p><p><span style=\"font-weight: bolder;\">Madhu bala</span></p><p><span style=\"font-weight: bolder;\">I am working From Yeejai Technology .</span></p>\"}]', '275444355853807', 1, 'Y', '2024-01-22 06:38:50', '0000-00-00 00:00:00', 0),
(143, 17, 'tmplt_Sup_Sup_022_048', 'te_Sup_Sup_t00000000_24122_048', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><span style=\"font-weight: bolder;\">Testing Message For Today</span></p><p><span style=\"font-weight: bolder;\">22 Jan 2023.</span></p><p><span style=\"font-weight: bolder;\">Madhu bala</span></p><p><span style=\"font-weight: bolder;\">I am working From Yeejai Technology .</span></p>\"}]', '275444355853807', 1, 'Y', '2024-01-22 06:38:50', '0000-00-00 00:00:00', 0),
(144, 46, 'tmplt_Sup_Sup_022_048', 'te_Sup_Sup_t00000000_24122_048', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p><span style=\"font-weight: bolder;\">Testing Message For Today</span></p><p><span style=\"font-weight: bolder;\">22 Jan 2023.</span></p><p><span style=\"font-weight: bolder;\">Madhu bala</span></p><p><span style=\"font-weight: bolder;\">I am working From Yeejai Technology .</span></p>\"}]', '275444355853807', 1, 'Y', '2024-01-22 06:38:50', '0000-00-00 00:00:00', 0),
(145, 14, 'tmplt_Sup_Sup_022_049', 'te_Sup_Sup_t00000000_24122_049', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing message&nbsp;</p><p>welcome&nbsp;</p><p>yeejai technology&nbsp;</p><p>testing</p>\"}]', '167202944809274', 1, 'Y', '2024-01-22 06:51:04', '0000-00-00 00:00:00', 0),
(146, 17, 'tmplt_Sup_Sup_022_049', 'te_Sup_Sup_t00000000_24122_049', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing message&nbsp;</p><p>welcome&nbsp;</p><p>yeejai technology&nbsp;</p><p>testing</p>\"}]', '167202944809274', 1, 'Y', '2024-01-22 06:51:04', '0000-00-00 00:00:00', 0),
(147, 46, 'tmplt_Sup_Sup_022_049', 'te_Sup_Sup_t00000000_24122_049', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing message&nbsp;</p><p>welcome&nbsp;</p><p>yeejai technology&nbsp;</p><p>testing</p>\"}]', '167202944809274', 1, 'Y', '2024-01-22 06:51:04', '0000-00-00 00:00:00', 0),
(148, 14, 'tmplt_Sup_Sup_022_050', 'te_Sup_Sup_t00000000_24122_050', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing message&nbsp;</p><p>welcome&nbsp;</p><p>yeejai technology&nbsp;</p><p>testing</p>\"}]', '555308072724841', 1, 'Y', '2024-01-22 06:51:08', '0000-00-00 00:00:00', 0),
(149, 17, 'tmplt_Sup_Sup_022_050', 'te_Sup_Sup_t00000000_24122_050', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing message&nbsp;</p><p>welcome&nbsp;</p><p>yeejai technology&nbsp;</p><p>testing</p>\"}]', '555308072724841', 1, 'Y', '2024-01-22 06:51:08', '0000-00-00 00:00:00', 0),
(150, 46, 'tmplt_Sup_Sup_022_050', 'te_Sup_Sup_t00000000_24122_050', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing message&nbsp;</p><p>welcome&nbsp;</p><p>yeejai technology&nbsp;</p><p>testing</p>\"}]', '555308072724841', 1, 'Y', '2024-01-22 06:51:08', '0000-00-00 00:00:00', 0),
(151, 14, 'tmplt_Sup_Sup_022_051', 'te_Sup_Sup_t00000000_24122_051', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing message</p><p>content</p><p>welcome&nbsp;</p><p>madhu</p>\"}]', '184982850533888', 1, 'Y', '2024-01-22 06:52:53', '0000-00-00 00:00:00', 0),
(152, 17, 'tmplt_Sup_Sup_022_051', 'te_Sup_Sup_t00000000_24122_051', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing message</p><p>content</p><p>welcome&nbsp;</p><p>madhu</p>\"}]', '184982850533888', 1, 'Y', '2024-01-22 06:52:53', '0000-00-00 00:00:00', 0),
(153, 46, 'tmplt_Sup_Sup_022_051', 'te_Sup_Sup_t00000000_24122_051', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing message</p><p>content</p><p>welcome&nbsp;</p><p>madhu</p>\"}]', '184982850533888', 1, 'Y', '2024-01-22 06:52:53', '0000-00-00 00:00:00', 0),
(154, 14, 'tmplt_Sup_Sup_022_052', 'te_Sup_Sup_t00000000_24122_052', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing mesasge\"}]', '328869040000368', 1, 'Y', '2024-01-22 06:59:44', '0000-00-00 00:00:00', 0),
(155, 17, 'tmplt_Sup_Sup_022_052', 'te_Sup_Sup_t00000000_24122_052', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing mesasge\"}]', '328869040000368', 1, 'Y', '2024-01-22 06:59:44', '0000-00-00 00:00:00', 0),
(156, 46, 'tmplt_Sup_Sup_022_052', 'te_Sup_Sup_t00000000_24122_052', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing mesasge\"}]', '328869040000368', 1, 'Y', '2024-01-22 06:59:44', '0000-00-00 00:00:00', 0),
(157, 14, 'tmplt_Sup_Sup_022_053', 'te_Sup_Sup_t00000000_24122_053', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing mesasgewelcometesting\"}]', '711266548048286', 1, 'Y', '2024-01-22 07:05:03', '0000-00-00 00:00:00', 0),
(158, 17, 'tmplt_Sup_Sup_022_053', 'te_Sup_Sup_t00000000_24122_053', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing mesasgewelcometesting\"}]', '711266548048286', 1, 'Y', '2024-01-22 07:05:03', '0000-00-00 00:00:00', 0),
(159, 46, 'tmplt_Sup_Sup_022_053', 'te_Sup_Sup_t00000000_24122_053', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing mesasgewelcometesting\"}]', '711266548048286', 1, 'Y', '2024-01-22 07:05:03', '0000-00-00 00:00:00', 0),
(160, 14, 'tmplt_Sup_Sup_022_054', 'te_Sup_Sup_t00000000_24122_054', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing mesasgewelcometesting\"}]', '690417637000353', 1, 'Y', '2024-01-22 07:07:25', '0000-00-00 00:00:00', 0),
(161, 17, 'tmplt_Sup_Sup_022_054', 'te_Sup_Sup_t00000000_24122_054', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing mesasgewelcometesting\"}]', '690417637000353', 1, 'Y', '2024-01-22 07:07:25', '0000-00-00 00:00:00', 0),
(162, 46, 'tmplt_Sup_Sup_022_054', 'te_Sup_Sup_t00000000_24122_054', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing mesasgewelcometesting\"}]', '690417637000353', 1, 'Y', '2024-01-22 07:07:25', '0000-00-00 00:00:00', 0),
(163, 14, 'tmplt_Sup_Sup_022_055', 'te_Sup_Sup_t00000000_24122_055', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '90036142273106', 1, 'Y', '2024-01-22 07:07:43', '0000-00-00 00:00:00', 0),
(164, 17, 'tmplt_Sup_Sup_022_055', 'te_Sup_Sup_t00000000_24122_055', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '90036142273106', 1, 'Y', '2024-01-22 07:07:43', '0000-00-00 00:00:00', 0),
(165, 46, 'tmplt_Sup_Sup_022_055', 'te_Sup_Sup_t00000000_24122_055', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '90036142273106', 1, 'Y', '2024-01-22 07:07:43', '0000-00-00 00:00:00', 0),
(166, 14, 'tmplt_Sup_Sup_022_056', 'te_Sup_Sup_t00000000_24122_056', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing mesasge</p><p>welcome</p><p>testing</p>welcometesting\"}]', '372697685512995', 1, 'Y', '2024-01-22 07:08:13', '0000-00-00 00:00:00', 0),
(167, 17, 'tmplt_Sup_Sup_022_056', 'te_Sup_Sup_t00000000_24122_056', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing mesasge</p><p>welcome</p><p>testing</p>welcometesting\"}]', '372697685512995', 1, 'Y', '2024-01-22 07:08:13', '0000-00-00 00:00:00', 0),
(168, 46, 'tmplt_Sup_Sup_022_056', 'te_Sup_Sup_t00000000_24122_056', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing mesasge</p><p>welcome</p><p>testing</p>welcometesting\"}]', '372697685512995', 1, 'Y', '2024-01-22 07:08:13', '0000-00-00 00:00:00', 0),
(169, 14, 'tmplt_Sup_Sup_022_057', 'te_Sup_Sup_t00000000_24122_057', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing mesasge</p><p>welcome</p><p>testing</p>welcometesting\"}]', '34708535025617', 1, 'Y', '2024-01-22 07:08:27', '0000-00-00 00:00:00', 0),
(170, 17, 'tmplt_Sup_Sup_022_057', 'te_Sup_Sup_t00000000_24122_057', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing mesasge</p><p>welcome</p><p>testing</p>welcometesting\"}]', '34708535025617', 1, 'Y', '2024-01-22 07:08:27', '0000-00-00 00:00:00', 0),
(171, 46, 'tmplt_Sup_Sup_022_057', 'te_Sup_Sup_t00000000_24122_057', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing mesasge</p><p>welcome</p><p>testing</p>welcometesting\"}]', '34708535025617', 1, 'Y', '2024-01-22 07:08:27', '0000-00-00 00:00:00', 0),
(172, 14, 'tmplt_Sup_Sup_022_058', 'te_Sup_Sup_t00000000_24122_058', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing messafg\"}]', '894018959475120', 1, 'Y', '2024-01-22 07:14:07', '0000-00-00 00:00:00', 0),
(173, 17, 'tmplt_Sup_Sup_022_058', 'te_Sup_Sup_t00000000_24122_058', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing messafg\"}]', '894018959475120', 1, 'Y', '2024-01-22 07:14:07', '0000-00-00 00:00:00', 0),
(174, 46, 'tmplt_Sup_Sup_022_058', 'te_Sup_Sup_t00000000_24122_058', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing messafg\"}]', '894018959475120', 1, 'Y', '2024-01-22 07:14:07', '0000-00-00 00:00:00', 0),
(175, 14, 'tmplt_Sup_Sup_022_059', 'te_Sup_Sup_t00000000_24122_059', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing messafg</p><p>welcome</p><p>test</p>testing messafgwelcometest\"}]', '253504801764420', 1, 'Y', '2024-01-22 07:18:45', '0000-00-00 00:00:00', 0),
(176, 17, 'tmplt_Sup_Sup_022_059', 'te_Sup_Sup_t00000000_24122_059', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing messafg</p><p>welcome</p><p>test</p>testing messafgwelcometest\"}]', '253504801764420', 1, 'Y', '2024-01-22 07:18:45', '0000-00-00 00:00:00', 0),
(177, 46, 'tmplt_Sup_Sup_022_059', 'te_Sup_Sup_t00000000_24122_059', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing messafg</p><p>welcome</p><p>test</p>testing messafgwelcometest\"}]', '253504801764420', 1, 'Y', '2024-01-22 07:18:45', '0000-00-00 00:00:00', 0),
(178, 14, 'tmplt_Sup_Sup_022_060', 'te_Sup_Sup_t00000000_24122_060', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing messafg</p><p>welcome</p><p>test</p>\"}]', '409778717035215', 1, 'Y', '2024-01-22 07:20:42', '0000-00-00 00:00:00', 0),
(179, 17, 'tmplt_Sup_Sup_022_060', 'te_Sup_Sup_t00000000_24122_060', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing messafg</p><p>welcome</p><p>test</p>\"}]', '409778717035215', 1, 'Y', '2024-01-22 07:20:42', '0000-00-00 00:00:00', 0),
(180, 46, 'tmplt_Sup_Sup_022_060', 'te_Sup_Sup_t00000000_24122_060', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing messafg</p><p>welcome</p><p>test</p>\"}]', '409778717035215', 1, 'Y', '2024-01-22 07:20:42', '0000-00-00 00:00:00', 0),
(181, 14, 'tmplt_Sup_Sup_022_061', 'te_Sup_Sup_t00000000_24122_061', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing messafg</p><p>welcome</p><p>test</p>\"}]', '338244309010596', 1, 'Y', '2024-01-22 07:22:53', '0000-00-00 00:00:00', 0),
(182, 17, 'tmplt_Sup_Sup_022_061', 'te_Sup_Sup_t00000000_24122_061', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing messafg</p><p>welcome</p><p>test</p>\"}]', '338244309010596', 1, 'Y', '2024-01-22 07:22:53', '0000-00-00 00:00:00', 0),
(183, 46, 'tmplt_Sup_Sup_022_061', 'te_Sup_Sup_t00000000_24122_061', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing messafg</p><p>welcome</p><p>test</p>\"}]', '338244309010596', 1, 'Y', '2024-01-22 07:22:53', '0000-00-00 00:00:00', 0),
(184, 14, 'tmplt_Sup_Sup_022_062', 'te_Sup_Sup_t00000000_24122_062', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing messafg</p><p>welcome</p><p>test</p>\"}]', '146252445098493', 1, 'Y', '2024-01-22 07:25:23', '0000-00-00 00:00:00', 0);
INSERT INTO `message_template` (`template_id`, `sender_master_id`, `unique_template_id`, `template_name`, `language_id`, `template_category`, `template_message`, `template_response_id`, `created_user`, `template_status`, `template_entdate`, `approve_date`, `body_variable_count`) VALUES
(185, 17, 'tmplt_Sup_Sup_022_062', 'te_Sup_Sup_t00000000_24122_062', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing messafg</p><p>welcome</p><p>test</p>\"}]', '146252445098493', 1, 'Y', '2024-01-22 07:25:23', '0000-00-00 00:00:00', 0),
(186, 46, 'tmplt_Sup_Sup_022_062', 'te_Sup_Sup_t00000000_24122_062', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>testing messafg</p><p>welcome</p><p>test</p>\"}]', '146252445098493', 1, 'Y', '2024-01-22 07:25:23', '0000-00-00 00:00:00', 0),
(187, 14, 'tmplt_Sup_Sup_022_063', 'te_Sup_Sup_t00000000_24122_063', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing</p><p>message</p><p>welcome</p><p>test</p>\"}]', '68138336500428', 1, 'Y', '2024-01-22 07:26:09', '0000-00-00 00:00:00', 0),
(188, 17, 'tmplt_Sup_Sup_022_063', 'te_Sup_Sup_t00000000_24122_063', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing</p><p>message</p><p>welcome</p><p>test</p>\"}]', '68138336500428', 1, 'Y', '2024-01-22 07:26:09', '0000-00-00 00:00:00', 0),
(189, 46, 'tmplt_Sup_Sup_022_063', 'te_Sup_Sup_t00000000_24122_063', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>Testing</p><p>message</p><p>welcome</p><p>test</p>\"}]', '68138336500428', 1, 'Y', '2024-01-22 07:26:09', '0000-00-00 00:00:00', 0),
(190, 14, 'tmplt_Sup_Sup_022_064', 'te_Sup_Sup_t00000000_24122_064', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing</br>message</br>welcome</br>test\"}]', '376475485866610', 1, 'Y', '2024-01-22 07:28:46', '0000-00-00 00:00:00', 0),
(191, 17, 'tmplt_Sup_Sup_022_064', 'te_Sup_Sup_t00000000_24122_064', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing</br>message</br>welcome</br>test\"}]', '376475485866610', 1, 'Y', '2024-01-22 07:28:46', '0000-00-00 00:00:00', 0),
(192, 46, 'tmplt_Sup_Sup_022_064', 'te_Sup_Sup_t00000000_24122_064', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing</br>message</br>welcome</br>test\"}]', '376475485866610', 1, 'Y', '2024-01-22 07:28:46', '0000-00-00 00:00:00', 0),
(193, 14, 'tmplt_Sup_Sup_022_065', 'te_Sup_Sup_t00000000_24122_065', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Madhu bala\"}]', '634946261560042', 1, 'Y', '2024-01-22 07:29:31', '0000-00-00 00:00:00', 0),
(194, 17, 'tmplt_Sup_Sup_022_065', 'te_Sup_Sup_t00000000_24122_065', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Madhu bala\"}]', '634946261560042', 1, 'Y', '2024-01-22 07:29:31', '0000-00-00 00:00:00', 0),
(195, 46, 'tmplt_Sup_Sup_022_065', 'te_Sup_Sup_t00000000_24122_065', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Madhu bala\"}]', '634946261560042', 1, 'Y', '2024-01-22 07:29:31', '0000-00-00 00:00:00', 0),
(196, 14, 'tmplt_Sup_Sup_022_066', 'te_Sup_Sup_t00000u00_24122_066', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testtesting\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"testing\",\"url\":\"http://welocme\"}]}]', '228731473877584', 1, 'Y', '2024-01-22 07:30:42', '0000-00-00 00:00:00', 0),
(197, 17, 'tmplt_Sup_Sup_022_066', 'te_Sup_Sup_t00000u00_24122_066', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testtesting\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"testing\",\"url\":\"http://welocme\"}]}]', '228731473877584', 1, 'Y', '2024-01-22 07:30:42', '0000-00-00 00:00:00', 0),
(198, 46, 'tmplt_Sup_Sup_022_066', 'te_Sup_Sup_t00000u00_24122_066', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testtesting\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"testing\",\"url\":\"http://welocme\"}]}]', '228731473877584', 1, 'Y', '2024-01-22 07:30:42', '0000-00-00 00:00:00', 0),
(199, 14, 'tmplt_Sup_Sup_022_067', 'te_Sup_Sup_t00000u00_24122_067', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test</br>testing\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"testing\",\"url\":\"http://welocme/\"}]}]', '675857945951825', 1, 'Y', '2024-01-22 07:31:24', '0000-00-00 00:00:00', 0),
(200, 17, 'tmplt_Sup_Sup_022_067', 'te_Sup_Sup_t00000u00_24122_067', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test</br>testing\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"testing\",\"url\":\"http://welocme/\"}]}]', '675857945951825', 1, 'Y', '2024-01-22 07:31:24', '0000-00-00 00:00:00', 0),
(201, 46, 'tmplt_Sup_Sup_022_067', 'te_Sup_Sup_t00000u00_24122_067', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test</br>testing\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"testing\",\"url\":\"http://welocme/\"}]}]', '675857945951825', 1, 'Y', '2024-01-22 07:31:24', '0000-00-00 00:00:00', 0),
(202, 14, 'tmplt_Sup_Sup_022_068', 'te_Sup_Sup_t00000u00_24122_068', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '762633785737482', 1, 'Y', '2024-01-22 07:35:04', '0000-00-00 00:00:00', 0),
(203, 17, 'tmplt_Sup_Sup_022_068', 'te_Sup_Sup_t00000u00_24122_068', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '762633785737482', 1, 'Y', '2024-01-22 07:35:04', '0000-00-00 00:00:00', 0),
(204, 46, 'tmplt_Sup_Sup_022_068', 'te_Sup_Sup_t00000u00_24122_068', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '762633785737482', 1, 'Y', '2024-01-22 07:35:04', '0000-00-00 00:00:00', 0),
(205, 14, 'tmplt_Sup_Sup_022_069', 'te_Sup_Sup_t00000u00_24122_069', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '982670096774712', 1, 'Y', '2024-01-22 07:37:17', '0000-00-00 00:00:00', 0),
(206, 17, 'tmplt_Sup_Sup_022_069', 'te_Sup_Sup_t00000u00_24122_069', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '982670096774712', 1, 'Y', '2024-01-22 07:37:17', '0000-00-00 00:00:00', 0),
(207, 46, 'tmplt_Sup_Sup_022_069', 'te_Sup_Sup_t00000u00_24122_069', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '982670096774712', 1, 'Y', '2024-01-22 07:37:17', '0000-00-00 00:00:00', 0),
(208, 14, 'tmplt_Sup_Sup_022_070', 'te_Sup_Sup_l00000u00_24122_070', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '589218814331025', 1, 'Y', '2024-01-22 07:38:42', '0000-00-00 00:00:00', 0),
(209, 17, 'tmplt_Sup_Sup_022_070', 'te_Sup_Sup_l00000u00_24122_070', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '589218814331025', 1, 'Y', '2024-01-22 07:38:42', '0000-00-00 00:00:00', 0),
(210, 46, 'tmplt_Sup_Sup_022_070', 'te_Sup_Sup_l00000u00_24122_070', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '589218814331025', 1, 'Y', '2024-01-22 07:38:42', '0000-00-00 00:00:00', 0),
(211, 14, 'tmplt_Sup_Sup_022_071', 'te_Sup_Sup_t00000u00_24122_071', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '777241361760521', 1, 'Y', '2024-01-22 07:39:47', '0000-00-00 00:00:00', 0),
(212, 17, 'tmplt_Sup_Sup_022_071', 'te_Sup_Sup_t00000u00_24122_071', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '777241361760521', 1, 'Y', '2024-01-22 07:39:47', '0000-00-00 00:00:00', 0),
(213, 46, 'tmplt_Sup_Sup_022_071', 'te_Sup_Sup_t00000u00_24122_071', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '777241361760521', 1, 'Y', '2024-01-22 07:39:47', '0000-00-00 00:00:00', 0),
(214, 14, 'tmplt_Sup_Sup_022_072', 'te_Sup_Sup_t00000u00_24122_072', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '634031372581944', 1, 'Y', '2024-01-22 07:41:56', '0000-00-00 00:00:00', 0),
(215, 17, 'tmplt_Sup_Sup_022_072', 'te_Sup_Sup_t00000u00_24122_072', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '634031372581944', 1, 'Y', '2024-01-22 07:41:56', '0000-00-00 00:00:00', 0),
(216, 46, 'tmplt_Sup_Sup_022_072', 'te_Sup_Sup_t00000u00_24122_072', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '634031372581944', 1, 'Y', '2024-01-22 07:41:56', '0000-00-00 00:00:00', 0),
(217, 14, 'tmplt_Sup_Sup_022_073', 'te_Sup_Sup_t00000u00_24122_073', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testingGOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '632407542422610', 1, 'Y', '2024-01-22 07:43:13', '0000-00-00 00:00:00', 0),
(218, 17, 'tmplt_Sup_Sup_022_073', 'te_Sup_Sup_t00000u00_24122_073', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testingGOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '632407542422610', 1, 'Y', '2024-01-22 07:43:13', '0000-00-00 00:00:00', 0),
(219, 46, 'tmplt_Sup_Sup_022_073', 'te_Sup_Sup_t00000u00_24122_073', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testingGOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '632407542422610', 1, 'Y', '2024-01-22 07:43:13', '0000-00-00 00:00:00', 0),
(220, 14, 'tmplt_Sup_Sup_022_074', 'te_Sup_Sup_t00000u00_24122_074', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing GOOGLE \"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '817358504153809', 1, 'Y', '2024-01-22 07:46:37', '0000-00-00 00:00:00', 0),
(221, 17, 'tmplt_Sup_Sup_022_074', 'te_Sup_Sup_t00000u00_24122_074', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing GOOGLE \"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '817358504153809', 1, 'Y', '2024-01-22 07:46:37', '0000-00-00 00:00:00', 0),
(222, 46, 'tmplt_Sup_Sup_022_074', 'te_Sup_Sup_t00000u00_24122_074', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing GOOGLE \"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '817358504153809', 1, 'Y', '2024-01-22 07:46:37', '0000-00-00 00:00:00', 0),
(223, 14, 'tmplt_Sup_Sup_022_075', 'te_Sup_Sup_t00000u00_24122_075', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing GOOGLE \"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '652401621606653', 1, 'Y', '2024-01-22 07:48:53', '0000-00-00 00:00:00', 0),
(224, 17, 'tmplt_Sup_Sup_022_075', 'te_Sup_Sup_t00000u00_24122_075', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing GOOGLE \"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '652401621606653', 1, 'Y', '2024-01-22 07:48:53', '0000-00-00 00:00:00', 0),
(225, 46, 'tmplt_Sup_Sup_022_075', 'te_Sup_Sup_t00000u00_24122_075', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing GOOGLE \"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '652401621606653', 1, 'Y', '2024-01-22 07:48:53', '0000-00-00 00:00:00', 0),
(226, 14, 'tmplt_Sup_Sup_022_076', 'te_Sup_Sup_t00000u00_24122_076', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing  Google \"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '67858429168825', 1, 'Y', '2024-01-22 07:56:44', '0000-00-00 00:00:00', 0),
(227, 17, 'tmplt_Sup_Sup_022_076', 'te_Sup_Sup_t00000u00_24122_076', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing  Google \"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '67858429168825', 1, 'Y', '2024-01-22 07:56:44', '0000-00-00 00:00:00', 0),
(228, 46, 'tmplt_Sup_Sup_022_076', 'te_Sup_Sup_t00000u00_24122_076', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing  Google \"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '67858429168825', 1, 'Y', '2024-01-22 07:56:44', '0000-00-00 00:00:00', 0),
(229, 14, 'tmplt_Sup_Sup_022_077', 'te_Sup_Sup_t00000u00_24122_077', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing Google</br>Testing Google</br>Testing </br>Google</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '843016242780450', 1, 'Y', '2024-01-22 07:59:07', '0000-00-00 00:00:00', 0),
(230, 17, 'tmplt_Sup_Sup_022_077', 'te_Sup_Sup_t00000u00_24122_077', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing Google</br>Testing Google</br>Testing </br>Google</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '843016242780450', 1, 'Y', '2024-01-22 07:59:07', '0000-00-00 00:00:00', 0),
(231, 46, 'tmplt_Sup_Sup_022_077', 'te_Sup_Sup_t00000u00_24122_077', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing Google</br>Testing Google</br>Testing </br>Google</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '843016242780450', 1, 'Y', '2024-01-22 07:59:07', '0000-00-00 00:00:00', 0),
(232, 14, 'tmplt_Sup_Sup_022_078', 'te_Sup_Sup_t00000u00_24122_078', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"</br></br></br></br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '493229615636008', 1, 'Y', '2024-01-22 08:02:12', '0000-00-00 00:00:00', 0),
(233, 17, 'tmplt_Sup_Sup_022_078', 'te_Sup_Sup_t00000u00_24122_078', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"</br></br></br></br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '493229615636008', 1, 'Y', '2024-01-22 08:02:12', '0000-00-00 00:00:00', 0),
(234, 46, 'tmplt_Sup_Sup_022_078', 'te_Sup_Sup_t00000u00_24122_078', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"</br></br></br></br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '493229615636008', 1, 'Y', '2024-01-22 08:02:12', '0000-00-00 00:00:00', 0),
(235, 14, 'tmplt_Sup_Sup_022_079', 'te_Sup_Sup_t00000u00_24122_079', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing Google</br>Testing Google</br>Testing </br>Google</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '405394513923624', 1, 'Y', '2024-01-22 08:04:48', '0000-00-00 00:00:00', 0),
(236, 17, 'tmplt_Sup_Sup_022_079', 'te_Sup_Sup_t00000u00_24122_079', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing Google</br>Testing Google</br>Testing </br>Google</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '405394513923624', 1, 'Y', '2024-01-22 08:04:48', '0000-00-00 00:00:00', 0),
(237, 46, 'tmplt_Sup_Sup_022_079', 'te_Sup_Sup_t00000u00_24122_079', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing Google</br>Testing Google</br>Testing </br>Google</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '405394513923624', 1, 'Y', '2024-01-22 08:04:48', '0000-00-00 00:00:00', 0),
(238, 14, 'tmplt_Sup_Sup_022_080', 'te_Sup_Sup_t00000u00_24122_080', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing Google</br></br></br></br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '395400760300869', 1, 'Y', '2024-01-22 08:05:27', '0000-00-00 00:00:00', 0),
(239, 17, 'tmplt_Sup_Sup_022_080', 'te_Sup_Sup_t00000u00_24122_080', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing Google</br></br></br></br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '395400760300869', 1, 'Y', '2024-01-22 08:05:27', '0000-00-00 00:00:00', 0),
(240, 46, 'tmplt_Sup_Sup_022_080', 'te_Sup_Sup_t00000u00_24122_080', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing Google</br></br></br></br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '395400760300869', 1, 'Y', '2024-01-22 08:05:27', '0000-00-00 00:00:00', 0),
(241, 14, 'tmplt_Sup_Sup_022_081', 'te_Sup_Sup_t00000u00_24122_081', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing GoogleTesting Google</br>Testing </br>Google</br></br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '586956680497474', 1, 'Y', '2024-01-22 08:06:17', '0000-00-00 00:00:00', 0),
(242, 17, 'tmplt_Sup_Sup_022_081', 'te_Sup_Sup_t00000u00_24122_081', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing GoogleTesting Google</br>Testing </br>Google</br></br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '586956680497474', 1, 'Y', '2024-01-22 08:06:17', '0000-00-00 00:00:00', 0),
(243, 46, 'tmplt_Sup_Sup_022_081', 'te_Sup_Sup_t00000u00_24122_081', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing GoogleTesting Google</br>Testing </br>Google</br></br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '586956680497474', 1, 'Y', '2024-01-22 08:06:17', '0000-00-00 00:00:00', 0),
(244, 14, 'tmplt_Sup_Sup_022_082', 'te_Sup_Sup_t00000000_24122_082', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"}]', '658132490468837', 1, 'Y', '2024-01-22 08:53:44', '0000-00-00 00:00:00', 0),
(245, 17, 'tmplt_Sup_Sup_022_082', 'te_Sup_Sup_t00000000_24122_082', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"}]', '658132490468837', 1, 'Y', '2024-01-22 08:53:44', '0000-00-00 00:00:00', 0),
(246, 46, 'tmplt_Sup_Sup_022_082', 'te_Sup_Sup_t00000000_24122_082', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"}]', '658132490468837', 1, 'Y', '2024-01-22 08:53:44', '0000-00-00 00:00:00', 0),
(247, 14, 'tmplt_Sup_Sup_022_083', 'te_Sup_Sup_t00000000_24122_083', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"}]', '925762344401601', 1, 'Y', '2024-01-22 08:54:53', '0000-00-00 00:00:00', 0),
(248, 17, 'tmplt_Sup_Sup_022_083', 'te_Sup_Sup_t00000000_24122_083', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"}]', '925762344401601', 1, 'Y', '2024-01-22 08:54:53', '0000-00-00 00:00:00', 0),
(249, 46, 'tmplt_Sup_Sup_022_083', 'te_Sup_Sup_t00000000_24122_083', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"}]', '925762344401601', 1, 'Y', '2024-01-22 08:54:53', '0000-00-00 00:00:00', 0),
(250, 14, 'tmplt_Sup_Sup_022_084', 'te_Sup_Sup_t00000u00_24122_084', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"hello GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '633860072909530', 1, 'Y', '2024-01-22 09:06:24', '0000-00-00 00:00:00', 0),
(251, 17, 'tmplt_Sup_Sup_022_084', 'te_Sup_Sup_t00000u00_24122_084', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"hello GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '633860072909530', 1, 'Y', '2024-01-22 09:06:24', '0000-00-00 00:00:00', 0),
(252, 46, 'tmplt_Sup_Sup_022_084', 'te_Sup_Sup_t00000u00_24122_084', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"hello GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '633860072909530', 1, 'Y', '2024-01-22 09:06:24', '0000-00-00 00:00:00', 0),
(253, 14, 'tmplt_Sup_Sup_022_085', 'te_Sup_Sup_t00000000_24122_085', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message\"}]', '288362030201608', 1, 'Y', '2024-01-22 09:11:46', '0000-00-00 00:00:00', 0),
(254, 17, 'tmplt_Sup_Sup_022_085', 'te_Sup_Sup_t00000000_24122_085', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message\"}]', '288362030201608', 1, 'Y', '2024-01-22 09:11:46', '0000-00-00 00:00:00', 0),
(255, 46, 'tmplt_Sup_Sup_022_085', 'te_Sup_Sup_t00000000_24122_085', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message\"}]', '288362030201608', 1, 'Y', '2024-01-22 09:11:46', '0000-00-00 00:00:00', 0),
(256, 14, 'tmplt_Sup_Sup_022_086', 'te_Sup_Sup_t00000000_24122_086', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"ksdjkfdk\"}]', '255429203262493', 1, 'Y', '2024-01-22 09:43:19', '0000-00-00 00:00:00', 0),
(257, 17, 'tmplt_Sup_Sup_022_086', 'te_Sup_Sup_t00000000_24122_086', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"ksdjkfdk\"}]', '255429203262493', 1, 'Y', '2024-01-22 09:43:19', '0000-00-00 00:00:00', 0),
(258, 46, 'tmplt_Sup_Sup_022_086', 'te_Sup_Sup_t00000000_24122_086', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"ksdjkfdk\"}]', '255429203262493', 1, 'Y', '2024-01-22 09:43:19', '0000-00-00 00:00:00', 0),
(259, 14, 'tmplt_Sup_Sup_022_087', 'te_Sup_Sup_t00000u00_24122_087', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing</br>GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '118546154763680', 1, 'Y', '2024-01-22 09:44:17', '0000-00-00 00:00:00', 0),
(260, 17, 'tmplt_Sup_Sup_022_087', 'te_Sup_Sup_t00000u00_24122_087', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing</br>GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '118546154763680', 1, 'Y', '2024-01-22 09:44:17', '0000-00-00 00:00:00', 0),
(261, 46, 'tmplt_Sup_Sup_022_087', 'te_Sup_Sup_t00000u00_24122_087', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing</br>GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '118546154763680', 1, 'Y', '2024-01-22 09:44:17', '0000-00-00 00:00:00', 0),
(262, 14, 'tmplt_Sup_Sup_022_088', 'te_Sup_Sup_t00000000_24122_088', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"}]', '665712423052306', 1, 'Y', '2024-01-22 09:51:16', '0000-00-00 00:00:00', 0),
(263, 17, 'tmplt_Sup_Sup_022_088', 'te_Sup_Sup_t00000000_24122_088', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"}]', '665712423052306', 1, 'Y', '2024-01-22 09:51:16', '0000-00-00 00:00:00', 0),
(264, 46, 'tmplt_Sup_Sup_022_088', 'te_Sup_Sup_t00000000_24122_088', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"}]', '665712423052306', 1, 'Y', '2024-01-22 09:51:16', '0000-00-00 00:00:00', 0),
(265, 14, 'tmplt_Sup_Sup_022_089', 'te_Sup_Sup_t00000000_24122_089', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"}]', '554277320019367', 1, 'Y', '2024-01-22 09:53:22', '0000-00-00 00:00:00', 0),
(266, 17, 'tmplt_Sup_Sup_022_089', 'te_Sup_Sup_t00000000_24122_089', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"}]', '554277320019367', 1, 'Y', '2024-01-22 09:53:22', '0000-00-00 00:00:00', 0),
(267, 46, 'tmplt_Sup_Sup_022_089', 'te_Sup_Sup_t00000000_24122_089', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"}]', '554277320019367', 1, 'Y', '2024-01-22 09:53:22', '0000-00-00 00:00:00', 0),
(268, 14, 'tmplt_Sup_Sup_022_090', 'te_Sup_Sup_t00000000_24122_090', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"}]', '992797524641816', 1, 'Y', '2024-01-22 09:53:37', '0000-00-00 00:00:00', 0),
(269, 17, 'tmplt_Sup_Sup_022_090', 'te_Sup_Sup_t00000000_24122_090', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"}]', '992797524641816', 1, 'Y', '2024-01-22 09:53:37', '0000-00-00 00:00:00', 0),
(270, 46, 'tmplt_Sup_Sup_022_090', 'te_Sup_Sup_t00000000_24122_090', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"\"}]', '992797524641816', 1, 'Y', '2024-01-22 09:53:37', '0000-00-00 00:00:00', 0),
(271, 14, 'tmplt_Sup_Sup_022_091', 'te_Sup_Sup_t00000000_24122_091', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Test message\"}]', '555896629160250', 1, 'Y', '2024-01-22 09:55:13', '0000-00-00 00:00:00', 0),
(272, 17, 'tmplt_Sup_Sup_022_091', 'te_Sup_Sup_t00000000_24122_091', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Test message\"}]', '555896629160250', 1, 'Y', '2024-01-22 09:55:13', '0000-00-00 00:00:00', 0),
(273, 46, 'tmplt_Sup_Sup_022_091', 'te_Sup_Sup_t00000000_24122_091', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Test message\"}]', '555896629160250', 1, 'Y', '2024-01-22 09:55:13', '0000-00-00 00:00:00', 0),
(274, 14, 'tmplt_Sup_Sup_022_092', 'te_Sup_Sup_t00000000_24122_092', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"WELCOME\"}]', '652515431642076', 1, 'Y', '2024-01-22 09:55:41', '0000-00-00 00:00:00', 0),
(275, 17, 'tmplt_Sup_Sup_022_092', 'te_Sup_Sup_t00000000_24122_092', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"WELCOME\"}]', '652515431642076', 1, 'Y', '2024-01-22 09:55:41', '0000-00-00 00:00:00', 0),
(276, 46, 'tmplt_Sup_Sup_022_092', 'te_Sup_Sup_t00000000_24122_092', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"WELCOME\"}]', '652515431642076', 1, 'Y', '2024-01-22 09:55:41', '0000-00-00 00:00:00', 0),
(277, 14, 'tmplt_Sup_Sup_022_093', 'te_Sup_Sup_t00000000_24122_093', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*\"}]', '104617722623052', 1, 'Y', '2024-01-22 09:58:45', '0000-00-00 00:00:00', 0),
(278, 17, 'tmplt_Sup_Sup_022_093', 'te_Sup_Sup_t00000000_24122_093', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*\"}]', '104617722623052', 1, 'Y', '2024-01-22 09:58:45', '0000-00-00 00:00:00', 0),
(279, 46, 'tmplt_Sup_Sup_022_093', 'te_Sup_Sup_t00000000_24122_093', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*\"}]', '104617722623052', 1, 'Y', '2024-01-22 09:58:45', '0000-00-00 00:00:00', 0),
(280, 14, 'tmplt_Sup_Sup_022_094', 'te_Sup_Sup_t00000u00_24122_094', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '385672095735236', 1, 'Y', '2024-01-22 10:04:10', '0000-00-00 00:00:00', 0),
(281, 17, 'tmplt_Sup_Sup_022_094', 'te_Sup_Sup_t00000u00_24122_094', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '385672095735236', 1, 'Y', '2024-01-22 10:04:10', '0000-00-00 00:00:00', 0),
(282, 46, 'tmplt_Sup_Sup_022_094', 'te_Sup_Sup_t00000u00_24122_094', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Google\",\"url\":\"http://www.google.com\"}]}]', '385672095735236', 1, 'Y', '2024-01-22 10:04:10', '0000-00-00 00:00:00', 0),
(283, 14, 'tmplt_Sup_Sup_022_095', 'te_Sup_Sup_t00000000_24122_095', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test words\"}]', '141009233480235', 1, 'Y', '2024-01-22 10:05:13', '0000-00-00 00:00:00', 0),
(284, 17, 'tmplt_Sup_Sup_022_095', 'te_Sup_Sup_t00000000_24122_095', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test words\"}]', '141009233480235', 1, 'Y', '2024-01-22 10:05:13', '0000-00-00 00:00:00', 0),
(285, 46, 'tmplt_Sup_Sup_022_095', 'te_Sup_Sup_t00000000_24122_095', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test words\"}]', '141009233480235', 1, 'Y', '2024-01-22 10:05:13', '0000-00-00 00:00:00', 0),
(286, 14, 'tmplt_Sup_Sup_022_096', 'te_Sup_Sup_t00000000_24122_096', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>test&nbsp;</p><p>message</p><p>welcome</p><p>test</p>test messagewelcometest</br>test messagewelcometest</br>test </br>message</br>welcome</br>test</br>\"}]', '379914210469352', 1, 'Y', '2024-01-22 10:07:11', '0000-00-00 00:00:00', 0),
(287, 17, 'tmplt_Sup_Sup_022_096', 'te_Sup_Sup_t00000000_24122_096', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>test&nbsp;</p><p>message</p><p>welcome</p><p>test</p>test messagewelcometest</br>test messagewelcometest</br>test </br>message</br>welcome</br>test</br>\"}]', '379914210469352', 1, 'Y', '2024-01-22 10:07:11', '0000-00-00 00:00:00', 0),
(288, 46, 'tmplt_Sup_Sup_022_096', 'te_Sup_Sup_t00000000_24122_096', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>test&nbsp;</p><p>message</p><p>welcome</p><p>test</p>test messagewelcometest</br>test messagewelcometest</br>test </br>message</br>welcome</br>test</br>\"}]', '379914210469352', 1, 'Y', '2024-01-22 10:07:11', '0000-00-00 00:00:00', 0),
(289, 14, 'tmplt_Sup_Sup_022_097', 'te_Sup_Sup_t00000000_24122_097', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test</br>\"}]', '365472429612849', 1, 'Y', '2024-01-22 10:08:34', '0000-00-00 00:00:00', 0),
(290, 17, 'tmplt_Sup_Sup_022_097', 'te_Sup_Sup_t00000000_24122_097', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test</br>\"}]', '365472429612849', 1, 'Y', '2024-01-22 10:08:34', '0000-00-00 00:00:00', 0),
(291, 46, 'tmplt_Sup_Sup_022_097', 'te_Sup_Sup_t00000000_24122_097', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test</br>\"}]', '365472429612849', 1, 'Y', '2024-01-22 10:08:34', '0000-00-00 00:00:00', 0),
(292, 14, 'tmplt_Sup_Sup_022_098', 'te_Sup_Sup_t00000000_24122_098', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test</br>\"}]', '249130558383220', 1, 'Y', '2024-01-22 10:10:16', '0000-00-00 00:00:00', 0),
(293, 17, 'tmplt_Sup_Sup_022_098', 'te_Sup_Sup_t00000000_24122_098', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test</br>\"}]', '249130558383220', 1, 'Y', '2024-01-22 10:10:16', '0000-00-00 00:00:00', 0),
(294, 46, 'tmplt_Sup_Sup_022_098', 'te_Sup_Sup_t00000000_24122_098', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test</br>\"}]', '249130558383220', 1, 'Y', '2024-01-22 10:10:16', '0000-00-00 00:00:00', 0),
(295, 14, 'tmplt_Sup_Sup_022_099', 'te_Sup_Sup_t00000000_24122_099', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>test&nbsp;</p><p>message</p><p>welcome</p><p>test</p>test </br>message</br>welcome</br>test</br>\"}]', '61840305822892', 1, 'Y', '2024-01-22 10:10:43', '0000-00-00 00:00:00', 0),
(296, 17, 'tmplt_Sup_Sup_022_099', 'te_Sup_Sup_t00000000_24122_099', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>test&nbsp;</p><p>message</p><p>welcome</p><p>test</p>test </br>message</br>welcome</br>test</br>\"}]', '61840305822892', 1, 'Y', '2024-01-22 10:10:43', '0000-00-00 00:00:00', 0),
(297, 46, 'tmplt_Sup_Sup_022_099', 'te_Sup_Sup_t00000000_24122_099', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>test&nbsp;</p><p>message</p><p>welcome</p><p>test</p>test </br>message</br>welcome</br>test</br>\"}]', '61840305822892', 1, 'Y', '2024-01-22 10:10:43', '0000-00-00 00:00:00', 0),
(298, 14, 'tmplt_Sup_Sup_022_100', 'te_Sup_Sup_t00000000_24122_100', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>test&nbsp;</p><p>message</p><p>welcome</p><p>test</p>test </br>message</br>welcome</br>test</br>\"}]', '255258213104041', 1, 'Y', '2024-01-22 10:11:26', '0000-00-00 00:00:00', 0),
(299, 17, 'tmplt_Sup_Sup_022_100', 'te_Sup_Sup_t00000000_24122_100', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>test&nbsp;</p><p>message</p><p>welcome</p><p>test</p>test </br>message</br>welcome</br>test</br>\"}]', '255258213104041', 1, 'Y', '2024-01-22 10:11:26', '0000-00-00 00:00:00', 0),
(300, 46, 'tmplt_Sup_Sup_022_100', 'te_Sup_Sup_t00000000_24122_100', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>test&nbsp;</p><p>message</p><p>welcome</p><p>test</p>test </br>message</br>welcome</br>test</br>\"}]', '255258213104041', 1, 'Y', '2024-01-22 10:11:26', '0000-00-00 00:00:00', 0),
(301, 14, 'tmplt_Sup_Sup_022_101', 'te_Sup_Sup_t00000000_24122_101', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>test&nbsp;</p><p>message</p><p>welcome</p><p>test</p>\"}]', '469554897814767', 1, 'Y', '2024-01-22 10:13:02', '0000-00-00 00:00:00', 0),
(302, 17, 'tmplt_Sup_Sup_022_101', 'te_Sup_Sup_t00000000_24122_101', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>test&nbsp;</p><p>message</p><p>welcome</p><p>test</p>\"}]', '469554897814767', 1, 'Y', '2024-01-22 10:13:02', '0000-00-00 00:00:00', 0),
(303, 46, 'tmplt_Sup_Sup_022_101', 'te_Sup_Sup_t00000000_24122_101', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>test&nbsp;</p><p>message</p><p>welcome</p><p>test</p>\"}]', '469554897814767', 1, 'Y', '2024-01-22 10:13:02', '0000-00-00 00:00:00', 0),
(304, 14, 'tmplt_Sup_Sup_022_102', 'te_Sup_Sup_t00000000_24122_102', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Array\"}]', '724530489066799', 1, 'Y', '2024-01-22 10:14:44', '0000-00-00 00:00:00', 0),
(305, 17, 'tmplt_Sup_Sup_022_102', 'te_Sup_Sup_t00000000_24122_102', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Array\"}]', '724530489066799', 1, 'Y', '2024-01-22 10:14:44', '0000-00-00 00:00:00', 0),
(306, 46, 'tmplt_Sup_Sup_022_102', 'te_Sup_Sup_t00000000_24122_102', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Array\"}]', '724530489066799', 1, 'Y', '2024-01-22 10:14:44', '0000-00-00 00:00:00', 0),
(307, 14, 'tmplt_Sup_Sup_022_103', 'te_Sup_Sup_t00000000_24122_103', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"[Array]\"}]', '901469840425806', 1, 'Y', '2024-01-22 10:15:28', '0000-00-00 00:00:00', 0),
(308, 17, 'tmplt_Sup_Sup_022_103', 'te_Sup_Sup_t00000000_24122_103', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"[Array]\"}]', '901469840425806', 1, 'Y', '2024-01-22 10:15:28', '0000-00-00 00:00:00', 0),
(309, 46, 'tmplt_Sup_Sup_022_103', 'te_Sup_Sup_t00000000_24122_103', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"[Array]\"}]', '901469840425806', 1, 'Y', '2024-01-22 10:15:28', '0000-00-00 00:00:00', 0),
(310, 14, 'tmplt_Sup_Sup_022_104', 'te_Sup_Sup_t00000000_24122_104', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test </br>message</br>welcome</br>test</br>\"}]', '190158692926089', 1, 'Y', '2024-01-22 10:16:15', '0000-00-00 00:00:00', 0),
(311, 17, 'tmplt_Sup_Sup_022_104', 'te_Sup_Sup_t00000000_24122_104', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test </br>message</br>welcome</br>test</br>\"}]', '190158692926089', 1, 'Y', '2024-01-22 10:16:15', '0000-00-00 00:00:00', 0),
(312, 46, 'tmplt_Sup_Sup_022_104', 'te_Sup_Sup_t00000000_24122_104', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test </br>message</br>welcome</br>test</br>\"}]', '190158692926089', 1, 'Y', '2024-01-22 10:16:15', '0000-00-00 00:00:00', 0),
(313, 14, 'tmplt_Sup_Sup_022_105', 'te_Sup_Sup_t00000000_24122_105', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Testing message *\"}]', '731859374513444', 1, 'Y', '2024-01-22 10:17:15', '0000-00-00 00:00:00', 0),
(314, 17, 'tmplt_Sup_Sup_022_105', 'te_Sup_Sup_t00000000_24122_105', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Testing message *\"}]', '731859374513444', 1, 'Y', '2024-01-22 10:17:15', '0000-00-00 00:00:00', 0),
(315, 46, 'tmplt_Sup_Sup_022_105', 'te_Sup_Sup_t00000000_24122_105', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Testing message *\"}]', '731859374513444', 1, 'Y', '2024-01-22 10:17:15', '0000-00-00 00:00:00', 0),
(316, 14, 'tmplt_Sup_Sup_022_106', 'te_Sup_Sup_t00000000_24122_106', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing messafe welcome</br>*Testing messafe welcome*Testing message </br>*Testing message *\"}]', '710966654508256', 1, 'Y', '2024-01-22 10:19:12', '0000-00-00 00:00:00', 0),
(317, 17, 'tmplt_Sup_Sup_022_106', 'te_Sup_Sup_t00000000_24122_106', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing messafe welcome</br>*Testing messafe welcome*Testing message </br>*Testing message *\"}]', '710966654508256', 1, 'Y', '2024-01-22 10:19:12', '0000-00-00 00:00:00', 0),
(318, 46, 'tmplt_Sup_Sup_022_106', 'te_Sup_Sup_t00000000_24122_106', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing messafe welcome</br>*Testing messafe welcome*Testing message </br>*Testing message *\"}]', '710966654508256', 1, 'Y', '2024-01-22 10:19:12', '0000-00-00 00:00:00', 0),
(319, 14, 'tmplt_Sup_Sup_022_107', 'te_Sup_Sup_t00000u00_24122_107', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing messafe welcome</br>*Testing messafe welcome*Testing message welcome</br>*Testing message *\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '954784631192493', 1, 'Y', '2024-01-22 10:24:21', '0000-00-00 00:00:00', 0),
(320, 17, 'tmplt_Sup_Sup_022_107', 'te_Sup_Sup_t00000u00_24122_107', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing messafe welcome</br>*Testing messafe welcome*Testing message welcome</br>*Testing message *\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '954784631192493', 1, 'Y', '2024-01-22 10:24:21', '0000-00-00 00:00:00', 0),
(321, 46, 'tmplt_Sup_Sup_022_107', 'te_Sup_Sup_t00000u00_24122_107', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing messafe welcome</br>*Testing messafe welcome*Testing message welcome</br>*Testing message *\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '954784631192493', 1, 'Y', '2024-01-22 10:24:21', '0000-00-00 00:00:00', 0),
(322, 14, 'tmplt_Sup_Sup_022_108', 'te_Sup_Sup_t00000u00_24122_108', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing messafe welcome</br>Testing message welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '537052290702356', 1, 'Y', '2024-01-22 10:24:54', '0000-00-00 00:00:00', 0),
(323, 17, 'tmplt_Sup_Sup_022_108', 'te_Sup_Sup_t00000u00_24122_108', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing messafe welcome</br>Testing message welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '537052290702356', 1, 'Y', '2024-01-22 10:24:54', '0000-00-00 00:00:00', 0),
(324, 46, 'tmplt_Sup_Sup_022_108', 'te_Sup_Sup_t00000u00_24122_108', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing messafe welcome</br>Testing message welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '537052290702356', 1, 'Y', '2024-01-22 10:24:54', '0000-00-00 00:00:00', 0),
(325, 14, 'tmplt_Sup_Sup_022_109', 'te_Sup_Sup_t00000u00_24122_109', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message welcome</br>welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '591689452980294', 1, 'Y', '2024-01-22 10:30:54', '0000-00-00 00:00:00', 0),
(326, 17, 'tmplt_Sup_Sup_022_109', 'te_Sup_Sup_t00000u00_24122_109', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message welcome</br>welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '591689452980294', 1, 'Y', '2024-01-22 10:30:54', '0000-00-00 00:00:00', 0),
(327, 46, 'tmplt_Sup_Sup_022_109', 'te_Sup_Sup_t00000u00_24122_109', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message welcome</br>welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '591689452980294', 1, 'Y', '2024-01-22 10:30:54', '0000-00-00 00:00:00', 0),
(328, 14, 'tmplt_Sup_Sup_022_110', 'te_Sup_Sup_t00000u00_24122_110', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message welcome</br>welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '237721243599976', 1, 'Y', '2024-01-22 10:31:10', '0000-00-00 00:00:00', 0),
(329, 17, 'tmplt_Sup_Sup_022_110', 'te_Sup_Sup_t00000u00_24122_110', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message welcome</br>welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '237721243599976', 1, 'Y', '2024-01-22 10:31:10', '0000-00-00 00:00:00', 0),
(330, 46, 'tmplt_Sup_Sup_022_110', 'te_Sup_Sup_t00000u00_24122_110', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message welcome</br>welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '237721243599976', 1, 'Y', '2024-01-22 10:31:10', '0000-00-00 00:00:00', 0),
(331, 14, 'tmplt_Sup_Sup_022_111', 'te_Sup_Sup_t00000u00_24122_111', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message welcome</br>welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '777967505693415', 1, 'Y', '2024-01-22 10:32:47', '0000-00-00 00:00:00', 0),
(332, 17, 'tmplt_Sup_Sup_022_111', 'te_Sup_Sup_t00000u00_24122_111', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message welcome</br>welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '777967505693415', 1, 'Y', '2024-01-22 10:32:47', '0000-00-00 00:00:00', 0),
(333, 46, 'tmplt_Sup_Sup_022_111', 'te_Sup_Sup_t00000u00_24122_111', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message welcome</br>welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '777967505693415', 1, 'Y', '2024-01-22 10:32:47', '0000-00-00 00:00:00', 0),
(334, 14, 'tmplt_Sup_Sup_022_112', 'te_Sup_Sup_t00000u00_24122_112', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message welcome</br>welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '589613384434346', 1, 'Y', '2024-01-22 10:34:57', '0000-00-00 00:00:00', 0),
(335, 17, 'tmplt_Sup_Sup_022_112', 'te_Sup_Sup_t00000u00_24122_112', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message welcome</br>welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '589613384434346', 1, 'Y', '2024-01-22 10:34:57', '0000-00-00 00:00:00', 0),
(336, 46, 'tmplt_Sup_Sup_022_112', 'te_Sup_Sup_t00000u00_24122_112', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message welcome</br>welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '589613384434346', 1, 'Y', '2024-01-22 10:34:57', '0000-00-00 00:00:00', 0),
(337, 14, 'tmplt_Sup_Sup_022_113', 'te_Sup_Sup_t00000u00_24122_113', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message welcome</br>welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '236098325458382', 1, 'Y', '2024-01-22 10:35:28', '0000-00-00 00:00:00', 0),
(338, 17, 'tmplt_Sup_Sup_022_113', 'te_Sup_Sup_t00000u00_24122_113', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message welcome</br>welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '236098325458382', 1, 'Y', '2024-01-22 10:35:28', '0000-00-00 00:00:00', 0),
(339, 46, 'tmplt_Sup_Sup_022_113', 'te_Sup_Sup_t00000u00_24122_113', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message welcome</br>welcome</br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '236098325458382', 1, 'Y', '2024-01-22 10:35:28', '0000-00-00 00:00:00', 0),
(340, 14, 'tmplt_Sup_Sup_022_114', 'te_Sup_Sup_t00000u00_24122_114', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;Testing message&nbsp;\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '836127265886233', 1, 'Y', '2024-01-22 10:41:57', '0000-00-00 00:00:00', 0),
(341, 17, 'tmplt_Sup_Sup_022_114', 'te_Sup_Sup_t00000u00_24122_114', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;Testing message&nbsp;\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '836127265886233', 1, 'Y', '2024-01-22 10:41:57', '0000-00-00 00:00:00', 0),
(342, 46, 'tmplt_Sup_Sup_022_114', 'te_Sup_Sup_t00000u00_24122_114', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;Testing message&nbsp;\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '836127265886233', 1, 'Y', '2024-01-22 10:41:57', '0000-00-00 00:00:00', 0),
(343, 14, 'tmplt_Sup_Sup_022_115', 'te_Sup_Sup_t00000u00_24122_115', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;Testing message&nbsp;\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '723763698063747', 1, 'Y', '2024-01-22 10:42:15', '0000-00-00 00:00:00', 0),
(344, 17, 'tmplt_Sup_Sup_022_115', 'te_Sup_Sup_t00000u00_24122_115', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;Testing message&nbsp;\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '723763698063747', 1, 'Y', '2024-01-22 10:42:15', '0000-00-00 00:00:00', 0),
(345, 46, 'tmplt_Sup_Sup_022_115', 'te_Sup_Sup_t00000u00_24122_115', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message&nbsp;Testing message&nbsp;\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '723763698063747', 1, 'Y', '2024-01-22 10:42:15', '0000-00-00 00:00:00', 0),
(346, 14, 'tmplt_Sup_Sup_022_116', 'te_Sup_Sup_t00000u00_24122_116', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcomewelcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com\"}]}]', '155367090182950', 1, 'Y', '2024-01-22 10:45:02', '0000-00-00 00:00:00', 0),
(347, 17, 'tmplt_Sup_Sup_022_116', 'te_Sup_Sup_t00000u00_24122_116', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcomewelcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com\"}]}]', '155367090182950', 1, 'Y', '2024-01-22 10:45:02', '0000-00-00 00:00:00', 0),
(348, 46, 'tmplt_Sup_Sup_022_116', 'te_Sup_Sup_t00000u00_24122_116', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcomewelcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com\"}]}]', '155367090182950', 1, 'Y', '2024-01-22 10:45:02', '0000-00-00 00:00:00', 0),
(349, 14, 'tmplt_Sup_Sup_022_117', 'te_Sup_Sup_l00000u00_24122_117', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcomewelcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com/\"}]}]', '397629363495687', 1, 'Y', '2024-01-22 10:46:30', '0000-00-00 00:00:00', 0),
(350, 17, 'tmplt_Sup_Sup_022_117', 'te_Sup_Sup_l00000u00_24122_117', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcomewelcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com/\"}]}]', '397629363495687', 1, 'Y', '2024-01-22 10:46:30', '0000-00-00 00:00:00', 0),
(351, 46, 'tmplt_Sup_Sup_022_117', 'te_Sup_Sup_l00000u00_24122_117', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcomewelcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com/\"}]}]', '397629363495687', 1, 'Y', '2024-01-22 10:46:30', '0000-00-00 00:00:00', 0),
(352, 14, 'tmplt_Sup_Sup_022_118', 'te_Sup_Sup_l00000u00_24122_118', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com/\"}]}]', '707054949805025', 1, 'Y', '2024-01-22 10:47:40', '0000-00-00 00:00:00', 0),
(353, 17, 'tmplt_Sup_Sup_022_118', 'te_Sup_Sup_l00000u00_24122_118', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com/\"}]}]', '707054949805025', 1, 'Y', '2024-01-22 10:47:40', '0000-00-00 00:00:00', 0),
(354, 46, 'tmplt_Sup_Sup_022_118', 'te_Sup_Sup_l00000u00_24122_118', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com/\"}]}]', '707054949805025', 1, 'Y', '2024-01-22 10:47:40', '0000-00-00 00:00:00', 0),
(355, 14, 'tmplt_Sup_Sup_022_119', 'te_Sup_Sup_l00000u00_24122_119', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcomewelcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com/\"}]}]', '5084040007191', 1, 'Y', '2024-01-22 10:48:09', '0000-00-00 00:00:00', 0),
(356, 17, 'tmplt_Sup_Sup_022_119', 'te_Sup_Sup_l00000u00_24122_119', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcomewelcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com/\"}]}]', '5084040007191', 1, 'Y', '2024-01-22 10:48:09', '0000-00-00 00:00:00', 0);
INSERT INTO `message_template` (`template_id`, `sender_master_id`, `unique_template_id`, `template_name`, `language_id`, `template_category`, `template_message`, `template_response_id`, `created_user`, `template_status`, `template_entdate`, `approve_date`, `body_variable_count`) VALUES
(357, 46, 'tmplt_Sup_Sup_022_119', 'te_Sup_Sup_l00000u00_24122_119', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcomewelcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com/\"}]}]', '5084040007191', 1, 'Y', '2024-01-22 10:48:09', '0000-00-00 00:00:00', 0),
(358, 14, 'tmplt_Sup_Sup_022_120', 'te_Sup_Sup_l00000u00_24122_120', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcomewelcomewelcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com/\"}]}]', '103457584358292', 1, 'Y', '2024-01-22 10:49:02', '0000-00-00 00:00:00', 0),
(359, 17, 'tmplt_Sup_Sup_022_120', 'te_Sup_Sup_l00000u00_24122_120', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcomewelcomewelcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com/\"}]}]', '103457584358292', 1, 'Y', '2024-01-22 10:49:02', '0000-00-00 00:00:00', 0),
(360, 46, 'tmplt_Sup_Sup_022_120', 'te_Sup_Sup_l00000u00_24122_120', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcomewelcomewelcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com/\"}]}]', '103457584358292', 1, 'Y', '2024-01-22 10:49:02', '0000-00-00 00:00:00', 0),
(361, 14, 'tmplt_Sup_Sup_022_121', 'te_Sup_Sup_l00000u00_24122_121', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com/\"}]}]', '164795269576828', 1, 'Y', '2024-01-22 10:55:08', '0000-00-00 00:00:00', 0),
(362, 17, 'tmplt_Sup_Sup_022_121', 'te_Sup_Sup_l00000u00_24122_121', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com/\"}]}]', '164795269576828', 1, 'Y', '2024-01-22 10:55:08', '0000-00-00 00:00:00', 0),
(363, 46, 'tmplt_Sup_Sup_022_121', 'te_Sup_Sup_l00000u00_24122_121', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"Testing\",\"url\":\"http://www.google.com/\"}]}]', '164795269576828', 1, 'Y', '2024-01-22 10:55:08', '0000-00-00 00:00:00', 0),
(364, 14, 'tmplt_Sup_Sup_022_122', 'te_Sup_Sup_t00000000_24122_122', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcome\"}]', '428026231434121', 1, 'Y', '2024-01-22 10:57:50', '0000-00-00 00:00:00', 0),
(365, 17, 'tmplt_Sup_Sup_022_122', 'te_Sup_Sup_t00000000_24122_122', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcome\"}]', '428026231434121', 1, 'Y', '2024-01-22 10:57:50', '0000-00-00 00:00:00', 0),
(366, 46, 'tmplt_Sup_Sup_022_122', 'te_Sup_Sup_t00000000_24122_122', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcome\"}]', '428026231434121', 1, 'Y', '2024-01-22 10:57:50', '0000-00-00 00:00:00', 0),
(367, 14, 'tmplt_Sup_Sup_022_123', 'te_Sup_Sup_t00000000_24122_123', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Test message&nbsp;welcomeyeejai technologytesting\"}]', '977748824566931', 1, 'Y', '2024-01-22 10:59:03', '0000-00-00 00:00:00', 0),
(368, 17, 'tmplt_Sup_Sup_022_123', 'te_Sup_Sup_t00000000_24122_123', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Test message&nbsp;welcomeyeejai technologytesting\"}]', '977748824566931', 1, 'Y', '2024-01-22 10:59:03', '0000-00-00 00:00:00', 0),
(369, 46, 'tmplt_Sup_Sup_022_123', 'te_Sup_Sup_t00000000_24122_123', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Test message&nbsp;welcomeyeejai technologytesting\"}]', '977748824566931', 1, 'Y', '2024-01-22 10:59:03', '0000-00-00 00:00:00', 0),
(370, 14, 'tmplt_Sup_Sup_022_124', 'te_Sup_Sup_t00000000_24122_124', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Test message&nbsp;</br>welcome</br>yeejai technology</br>testing\"}]', '400676512792442', 1, 'Y', '2024-01-22 11:04:48', '0000-00-00 00:00:00', 0),
(371, 17, 'tmplt_Sup_Sup_022_124', 'te_Sup_Sup_t00000000_24122_124', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Test message&nbsp;</br>welcome</br>yeejai technology</br>testing\"}]', '400676512792442', 1, 'Y', '2024-01-22 11:04:48', '0000-00-00 00:00:00', 0),
(372, 46, 'tmplt_Sup_Sup_022_124', 'te_Sup_Sup_t00000000_24122_124', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Test message&nbsp;</br>welcome</br>yeejai technology</br>testing\"}]', '400676512792442', 1, 'Y', '2024-01-22 11:04:48', '0000-00-00 00:00:00', 0),
(373, 14, 'tmplt_Sup_Sup_022_125', 'te_Sup_Sup_t00000000_24122_125', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Test message welcomeyeejai technologytesting\"}]', '842249491518443', 1, 'Y', '2024-01-22 11:06:54', '0000-00-00 00:00:00', 0),
(374, 17, 'tmplt_Sup_Sup_022_125', 'te_Sup_Sup_t00000000_24122_125', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Test message welcomeyeejai technologytesting\"}]', '842249491518443', 1, 'Y', '2024-01-22 11:06:54', '0000-00-00 00:00:00', 0),
(375, 46, 'tmplt_Sup_Sup_022_125', 'te_Sup_Sup_t00000000_24122_125', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Test message welcomeyeejai technologytesting\"}]', '842249491518443', 1, 'Y', '2024-01-22 11:06:54', '0000-00-00 00:00:00', 0),
(376, 14, 'tmplt_Sup_Sup_022_126', 'te_Sup_Sup_t00000000_24122_126', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Test message welcomeyeejai technologytesting\"}]', '274597353862047', 1, 'Y', '2024-01-22 11:14:51', '0000-00-00 00:00:00', 0),
(377, 17, 'tmplt_Sup_Sup_022_126', 'te_Sup_Sup_t00000000_24122_126', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Test message welcomeyeejai technologytesting\"}]', '274597353862047', 1, 'Y', '2024-01-22 11:14:51', '0000-00-00 00:00:00', 0),
(378, 46, 'tmplt_Sup_Sup_022_126', 'te_Sup_Sup_t00000000_24122_126', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Test message welcomeyeejai technologytesting\"}]', '274597353862047', 1, 'Y', '2024-01-22 11:14:51', '0000-00-00 00:00:00', 0),
(379, 14, 'tmplt_Sup_Sup_022_127', 'te_Sup_Sup_t00000000_24122_127', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test \"}]', '67020238808938', 1, 'Y', '2024-01-22 11:25:04', '0000-00-00 00:00:00', 0),
(380, 17, 'tmplt_Sup_Sup_022_127', 'te_Sup_Sup_t00000000_24122_127', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test \"}]', '67020238808938', 1, 'Y', '2024-01-22 11:25:04', '0000-00-00 00:00:00', 0),
(381, 46, 'tmplt_Sup_Sup_022_127', 'te_Sup_Sup_t00000000_24122_127', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"test \"}]', '67020238808938', 1, 'Y', '2024-01-22 11:25:04', '0000-00-00 00:00:00', 0),
(382, 14, 'tmplt_Sup_Sup_022_128', 'te_Sup_Sup_t00000u00_24122_128', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"User Creation TestingEdit plans/delete plans (create plans).\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '322941626314096', 1, 'Y', '2024-01-22 11:30:09', '0000-00-00 00:00:00', 0),
(383, 17, 'tmplt_Sup_Sup_022_128', 'te_Sup_Sup_t00000u00_24122_128', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"User Creation TestingEdit plans/delete plans (create plans).\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '322941626314096', 1, 'Y', '2024-01-22 11:30:09', '0000-00-00 00:00:00', 0),
(384, 46, 'tmplt_Sup_Sup_022_128', 'te_Sup_Sup_t00000u00_24122_128', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"User Creation TestingEdit plans/delete plans (create plans).\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '322941626314096', 1, 'Y', '2024-01-22 11:30:09', '0000-00-00 00:00:00', 0),
(385, 14, 'tmplt_Sup_Sup_022_129', 'te_Sup_Sup_t00000u00_24122_129', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"User Creation Testing</br>Edit plans/delete plans (create plans).</br><a href=\"http://www.google.com/\" target=\"_blank\"></a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '174143424944263', 1, 'Y', '2024-01-22 11:31:32', '0000-00-00 00:00:00', 0),
(386, 17, 'tmplt_Sup_Sup_022_129', 'te_Sup_Sup_t00000u00_24122_129', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"User Creation Testing</br>Edit plans/delete plans (create plans).</br><a href=\"http://www.google.com/\" target=\"_blank\"></a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '174143424944263', 1, 'Y', '2024-01-22 11:31:32', '0000-00-00 00:00:00', 0),
(387, 46, 'tmplt_Sup_Sup_022_129', 'te_Sup_Sup_t00000u00_24122_129', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"User Creation Testing</br>Edit plans/delete plans (create plans).</br><a href=\"http://www.google.com/\" target=\"_blank\"></a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '174143424944263', 1, 'Y', '2024-01-22 11:31:32', '0000-00-00 00:00:00', 0),
(388, 14, 'tmplt_Sup_Sup_022_130', 'te_Sup_Sup_t00000u00_24122_130', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span><a href=\"http://www.google.com/\" target=\"_blank\"></a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '930426754295505', 1, 'Y', '2024-01-22 11:39:34', '0000-00-00 00:00:00', 0),
(389, 17, 'tmplt_Sup_Sup_022_130', 'te_Sup_Sup_t00000u00_24122_130', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span><a href=\"http://www.google.com/\" target=\"_blank\"></a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '930426754295505', 1, 'Y', '2024-01-22 11:39:34', '0000-00-00 00:00:00', 0),
(390, 46, 'tmplt_Sup_Sup_022_130', 'te_Sup_Sup_t00000u00_24122_130', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span><a href=\"http://www.google.com/\" target=\"_blank\"></a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '930426754295505', 1, 'Y', '2024-01-22 11:39:34', '0000-00-00 00:00:00', 0),
(391, 14, 'tmplt_Sup_Sup_022_131', 'te_Sup_Sup_t00000u00_24122_131', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span><a href=\"http://www.google.com/\" target=\"_blank\"></a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '883474262515055', 1, 'Y', '2024-01-22 11:41:02', '0000-00-00 00:00:00', 0),
(392, 17, 'tmplt_Sup_Sup_022_131', 'te_Sup_Sup_t00000u00_24122_131', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span><a href=\"http://www.google.com/\" target=\"_blank\"></a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '883474262515055', 1, 'Y', '2024-01-22 11:41:02', '0000-00-00 00:00:00', 0),
(393, 46, 'tmplt_Sup_Sup_022_131', 'te_Sup_Sup_t00000u00_24122_131', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span><a href=\"http://www.google.com/\" target=\"_blank\"></a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '883474262515055', 1, 'Y', '2024-01-22 11:41:02', '0000-00-00 00:00:00', 0),
(394, 14, 'tmplt_Sup_Sup_022_132', 'te_Sup_Sup_t00000u00_24122_132', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '526980945966783', 1, 'Y', '2024-01-22 12:04:31', '0000-00-00 00:00:00', 0),
(395, 17, 'tmplt_Sup_Sup_022_132', 'te_Sup_Sup_t00000u00_24122_132', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '526980945966783', 1, 'Y', '2024-01-22 12:04:31', '0000-00-00 00:00:00', 0),
(396, 46, 'tmplt_Sup_Sup_022_132', 'te_Sup_Sup_t00000u00_24122_132', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '526980945966783', 1, 'Y', '2024-01-22 12:04:31', '0000-00-00 00:00:00', 0),
(397, 14, 'tmplt_Sup_Sup_022_133', 'te_Sup_Sup_t00000u00_24122_133', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '161490258929600', 1, 'Y', '2024-01-22 12:05:34', '0000-00-00 00:00:00', 0),
(398, 17, 'tmplt_Sup_Sup_022_133', 'te_Sup_Sup_t00000u00_24122_133', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '161490258929600', 1, 'Y', '2024-01-22 12:05:34', '0000-00-00 00:00:00', 0),
(399, 46, 'tmplt_Sup_Sup_022_133', 'te_Sup_Sup_t00000u00_24122_133', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '161490258929600', 1, 'Y', '2024-01-22 12:05:34', '0000-00-00 00:00:00', 0),
(400, 14, 'tmplt_Sup_Sup_022_134', 'te_Sup_Sup_t00000u00_24122_134', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '665364553718153', 1, 'Y', '2024-01-22 12:06:26', '0000-00-00 00:00:00', 0),
(401, 17, 'tmplt_Sup_Sup_022_134', 'te_Sup_Sup_t00000u00_24122_134', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '665364553718153', 1, 'Y', '2024-01-22 12:06:26', '0000-00-00 00:00:00', 0),
(402, 46, 'tmplt_Sup_Sup_022_134', 'te_Sup_Sup_t00000u00_24122_134', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '665364553718153', 1, 'Y', '2024-01-22 12:06:26', '0000-00-00 00:00:00', 0),
(403, 14, 'tmplt_Sup_Sup_022_135', 'te_Sup_Sup_t00000u00_24122_135', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '927451050208496', 1, 'Y', '2024-01-22 12:10:34', '0000-00-00 00:00:00', 0),
(404, 17, 'tmplt_Sup_Sup_022_135', 'te_Sup_Sup_t00000u00_24122_135', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '927451050208496', 1, 'Y', '2024-01-22 12:10:34', '0000-00-00 00:00:00', 0),
(405, 46, 'tmplt_Sup_Sup_022_135', 'te_Sup_Sup_t00000u00_24122_135', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">User Creation Testing</span><span style=\"font-weight: bolder;\">Edit plans/delete plans (create plans).</span>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '927451050208496', 1, 'Y', '2024-01-22 12:10:34', '0000-00-00 00:00:00', 0),
(406, 14, 'tmplt_Sup_Sup_022_136', 'te_Sup_Sup_t00000000_24122_136', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '797668707466740', 1, 'Y', '2024-01-22 12:20:10', '0000-00-00 00:00:00', 0),
(407, 17, 'tmplt_Sup_Sup_022_136', 'te_Sup_Sup_t00000000_24122_136', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '797668707466740', 1, 'Y', '2024-01-22 12:20:10', '0000-00-00 00:00:00', 0),
(408, 46, 'tmplt_Sup_Sup_022_136', 'te_Sup_Sup_t00000000_24122_136', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '797668707466740', 1, 'Y', '2024-01-22 12:20:10', '0000-00-00 00:00:00', 0),
(409, 14, 'tmplt_Sup_Sup_022_137', 'te_Sup_Sup_t00000000_24122_137', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<b>Sample Message 1</b><br>\"}]', '477085381698839', 1, 'Y', '2024-01-22 12:20:37', '0000-00-00 00:00:00', 0),
(410, 17, 'tmplt_Sup_Sup_022_137', 'te_Sup_Sup_t00000000_24122_137', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<b>Sample Message 1</b><br>\"}]', '477085381698839', 1, 'Y', '2024-01-22 12:20:37', '0000-00-00 00:00:00', 0),
(411, 46, 'tmplt_Sup_Sup_022_137', 'te_Sup_Sup_t00000000_24122_137', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<b>Sample Message 1</b><br>\"}]', '477085381698839', 1, 'Y', '2024-01-22 12:20:37', '0000-00-00 00:00:00', 0),
(412, 14, 'tmplt_Sup_Sup_022_138', 'te_Sup_Sup_t00000000_24122_138', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Sample Message 1*\"}]', '291996250246099', 1, 'Y', '2024-01-22 12:22:31', '0000-00-00 00:00:00', 0),
(413, 17, 'tmplt_Sup_Sup_022_138', 'te_Sup_Sup_t00000000_24122_138', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Sample Message 1*\"}]', '291996250246099', 1, 'Y', '2024-01-22 12:22:31', '0000-00-00 00:00:00', 0),
(414, 46, 'tmplt_Sup_Sup_022_138', 'te_Sup_Sup_t00000000_24122_138', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Sample Message 1*\"}]', '291996250246099', 1, 'Y', '2024-01-22 12:22:31', '0000-00-00 00:00:00', 0),
(415, 14, 'tmplt_Sup_Sup_022_139', 'te_Sup_Sup_t00000000_24122_139', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message this is a last testing sample messages\"}]', '19779014809430', 1, 'Y', '2024-01-22 12:23:11', '0000-00-00 00:00:00', 0),
(416, 17, 'tmplt_Sup_Sup_022_139', 'te_Sup_Sup_t00000000_24122_139', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message this is a last testing sample messages\"}]', '19779014809430', 1, 'Y', '2024-01-22 12:23:11', '0000-00-00 00:00:00', 0),
(417, 46, 'tmplt_Sup_Sup_022_139', 'te_Sup_Sup_t00000000_24122_139', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message this is a last testing sample messages\"}]', '19779014809430', 1, 'Y', '2024-01-22 12:23:11', '0000-00-00 00:00:00', 0),
(418, 14, 'tmplt_Sup_Sup_022_140', 'te_Sup_Sup_t00000000_24122_140', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*this is a last testing**sample_messages*\"}]', '127156096771308', 1, 'Y', '2024-01-22 12:24:06', '0000-00-00 00:00:00', 0),
(419, 17, 'tmplt_Sup_Sup_022_140', 'te_Sup_Sup_t00000000_24122_140', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*this is a last testing**sample_messages*\"}]', '127156096771308', 1, 'Y', '2024-01-22 12:24:06', '0000-00-00 00:00:00', 0),
(420, 46, 'tmplt_Sup_Sup_022_140', 'te_Sup_Sup_t00000000_24122_140', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*this is a last testing**sample_messages*\"}]', '127156096771308', 1, 'Y', '2024-01-22 12:24:06', '0000-00-00 00:00:00', 0),
(421, 14, 'tmplt_Sup_Sup_022_141', 'te_Sup_Sup_t00000000_24122_141', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample messagetestingwelcomeyeejai\"}]', '193245932451162', 1, 'Y', '2024-01-22 12:25:07', '0000-00-00 00:00:00', 0),
(422, 17, 'tmplt_Sup_Sup_022_141', 'te_Sup_Sup_t00000000_24122_141', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample messagetestingwelcomeyeejai\"}]', '193245932451162', 1, 'Y', '2024-01-22 12:25:07', '0000-00-00 00:00:00', 0),
(423, 46, 'tmplt_Sup_Sup_022_141', 'te_Sup_Sup_t00000000_24122_141', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample messagetestingwelcomeyeejai\"}]', '193245932451162', 1, 'Y', '2024-01-22 12:25:07', '0000-00-00 00:00:00', 0),
(424, 14, 'tmplt_Sup_Sup_022_142', 'te_Sup_Sup_t00000000_24122_142', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample messagetestingwelcomeyeejai\"}]', '635091215360046', 1, 'Y', '2024-01-22 12:27:15', '0000-00-00 00:00:00', 0),
(425, 17, 'tmplt_Sup_Sup_022_142', 'te_Sup_Sup_t00000000_24122_142', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample messagetestingwelcomeyeejai\"}]', '635091215360046', 1, 'Y', '2024-01-22 12:27:15', '0000-00-00 00:00:00', 0),
(426, 46, 'tmplt_Sup_Sup_022_142', 'te_Sup_Sup_t00000000_24122_142', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample messagetestingwelcomeyeejai\"}]', '635091215360046', 1, 'Y', '2024-01-22 12:27:15', '0000-00-00 00:00:00', 0),
(427, 14, 'tmplt_Sup_Sup_022_143', 'te_Sup_Sup_t00000000_24122_143', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample messagetestingwelcomeyeejai\"}]', '617947583535099', 1, 'Y', '2024-01-22 12:30:29', '0000-00-00 00:00:00', 0),
(428, 17, 'tmplt_Sup_Sup_022_143', 'te_Sup_Sup_t00000000_24122_143', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample messagetestingwelcomeyeejai\"}]', '617947583535099', 1, 'Y', '2024-01-22 12:30:29', '0000-00-00 00:00:00', 0),
(429, 46, 'tmplt_Sup_Sup_022_143', 'te_Sup_Sup_t00000000_24122_143', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample messagetestingwelcomeyeejai\"}]', '617947583535099', 1, 'Y', '2024-01-22 12:30:29', '0000-00-00 00:00:00', 0),
(430, 14, 'tmplt_Sup_Sup_022_144', 'te_Sup_Sup_t00000000_24122_144', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample message</br>testing</br>welcome</br>yeejai\"}]', '591942573253594', 1, 'Y', '2024-01-22 12:30:42', '0000-00-00 00:00:00', 0),
(431, 17, 'tmplt_Sup_Sup_022_144', 'te_Sup_Sup_t00000000_24122_144', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample message</br>testing</br>welcome</br>yeejai\"}]', '591942573253594', 1, 'Y', '2024-01-22 12:30:42', '0000-00-00 00:00:00', 0),
(432, 46, 'tmplt_Sup_Sup_022_144', 'te_Sup_Sup_t00000000_24122_144', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample message</br>testing</br>welcome</br>yeejai\"}]', '591942573253594', 1, 'Y', '2024-01-22 12:30:42', '0000-00-00 00:00:00', 0),
(433, 14, 'tmplt_Sup_Sup_022_145', 'te_Sup_Sup_t00000000_24122_145', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample messagetestingwelcomeyeejai\"}]', '170425630997913', 1, 'Y', '2024-01-22 12:31:06', '0000-00-00 00:00:00', 0),
(434, 17, 'tmplt_Sup_Sup_022_145', 'te_Sup_Sup_t00000000_24122_145', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample messagetestingwelcomeyeejai\"}]', '170425630997913', 1, 'Y', '2024-01-22 12:31:06', '0000-00-00 00:00:00', 0),
(435, 46, 'tmplt_Sup_Sup_022_145', 'te_Sup_Sup_t00000000_24122_145', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample messagetestingwelcomeyeejai\"}]', '170425630997913', 1, 'Y', '2024-01-22 12:31:06', '0000-00-00 00:00:00', 0),
(436, 14, 'tmplt_Sup_Sup_022_146', 'te_Sup_Sup_t00000000_24122_146', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">sample message</span></br><span style=\"font-weight: bolder;\">testing</span></br><span style=\"font-weight: bolder;\">welcome</span></br><span style=\"font-weight: bolder;\">yeejai</span>\"}]', '496888987571616', 1, 'Y', '2024-01-22 12:32:22', '0000-00-00 00:00:00', 0),
(437, 17, 'tmplt_Sup_Sup_022_146', 'te_Sup_Sup_t00000000_24122_146', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">sample message</span></br><span style=\"font-weight: bolder;\">testing</span></br><span style=\"font-weight: bolder;\">welcome</span></br><span style=\"font-weight: bolder;\">yeejai</span>\"}]', '496888987571616', 1, 'Y', '2024-01-22 12:32:22', '0000-00-00 00:00:00', 0),
(438, 46, 'tmplt_Sup_Sup_022_146', 'te_Sup_Sup_t00000000_24122_146', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">sample message</span></br><span style=\"font-weight: bolder;\">testing</span></br><span style=\"font-weight: bolder;\">welcome</span></br><span style=\"font-weight: bolder;\">yeejai</span>\"}]', '496888987571616', 1, 'Y', '2024-01-22 12:32:22', '0000-00-00 00:00:00', 0),
(439, 14, 'tmplt_Sup_Sup_022_147', 'te_Sup_Sup_t00000000_24122_147', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample messagewelcome\"}]', '735842427711733', 1, 'Y', '2024-01-22 12:33:15', '0000-00-00 00:00:00', 0),
(440, 17, 'tmplt_Sup_Sup_022_147', 'te_Sup_Sup_t00000000_24122_147', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample messagewelcome\"}]', '735842427711733', 1, 'Y', '2024-01-22 12:33:15', '0000-00-00 00:00:00', 0),
(441, 46, 'tmplt_Sup_Sup_022_147', 'te_Sup_Sup_t00000000_24122_147', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample messagewelcome\"}]', '735842427711733', 1, 'Y', '2024-01-22 12:33:15', '0000-00-00 00:00:00', 0),
(442, 14, 'tmplt_Sup_Sup_022_148', 'te_Sup_Sup_t00000000_24122_148', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">sample message</span></br><span style=\"font-weight: bolder;\">welcome</span>\"}]', '154136453904832', 1, 'Y', '2024-01-22 12:34:33', '0000-00-00 00:00:00', 0),
(443, 17, 'tmplt_Sup_Sup_022_148', 'te_Sup_Sup_t00000000_24122_148', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">sample message</span></br><span style=\"font-weight: bolder;\">welcome</span>\"}]', '154136453904832', 1, 'Y', '2024-01-22 12:34:33', '0000-00-00 00:00:00', 0),
(444, 46, 'tmplt_Sup_Sup_022_148', 'te_Sup_Sup_t00000000_24122_148', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<span style=\"font-weight: bolder;\">sample message</span></br><span style=\"font-weight: bolder;\">welcome</span>\"}]', '154136453904832', 1, 'Y', '2024-01-22 12:34:33', '0000-00-00 00:00:00', 0),
(445, 14, 'tmplt_Sup_Sup_022_149', 'te_Sup_Sup_t00000000_24122_149', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample message welcome\"}]', '582084568661904', 1, 'Y', '2024-01-22 12:35:04', '0000-00-00 00:00:00', 0),
(446, 17, 'tmplt_Sup_Sup_022_149', 'te_Sup_Sup_t00000000_24122_149', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample message welcome\"}]', '582084568661904', 1, 'Y', '2024-01-22 12:35:04', '0000-00-00 00:00:00', 0),
(447, 46, 'tmplt_Sup_Sup_022_149', 'te_Sup_Sup_t00000000_24122_149', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"sample message welcome\"}]', '582084568661904', 1, 'Y', '2024-01-22 12:35:04', '0000-00-00 00:00:00', 0),
(448, 14, 'tmplt_Sup_Sup_022_150', 'te_Sup_Sup_t00000000_24122_150', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Testing**welcome*\"}]', '410330666221139', 1, 'Y', '2024-01-22 12:36:03', '0000-00-00 00:00:00', 0),
(449, 17, 'tmplt_Sup_Sup_022_150', 'te_Sup_Sup_t00000000_24122_150', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Testing**welcome*\"}]', '410330666221139', 1, 'Y', '2024-01-22 12:36:03', '0000-00-00 00:00:00', 0),
(450, 46, 'tmplt_Sup_Sup_022_150', 'te_Sup_Sup_t00000000_24122_150', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Testing**welcome*\"}]', '410330666221139', 1, 'Y', '2024-01-22 12:36:03', '0000-00-00 00:00:00', 0),
(451, 14, 'tmplt_Sup_Sup_022_151', 'te_Sup_Sup_t00000000_24122_151', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*welocme*\"}]', '633554554230362', 1, 'Y', '2024-01-22 12:37:11', '0000-00-00 00:00:00', 0),
(452, 17, 'tmplt_Sup_Sup_022_151', 'te_Sup_Sup_t00000000_24122_151', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*welocme*\"}]', '633554554230362', 1, 'Y', '2024-01-22 12:37:11', '0000-00-00 00:00:00', 0),
(453, 46, 'tmplt_Sup_Sup_022_151', 'te_Sup_Sup_t00000000_24122_151', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*welocme*\"}]', '633554554230362', 1, 'Y', '2024-01-22 12:37:11', '0000-00-00 00:00:00', 0),
(454, 14, 'tmplt_Sup_Sup_022_152', 'te_Sup_Sup_t00000000_24122_152', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing</br><span style=\"font-weight: bolder;\">welocme</span><p>Testing&nbsp;</p><p><span style=\"font-weight: bolder;\">welocme</span></p>\"}]', '652386443718495', 1, 'Y', '2024-01-22 12:40:04', '0000-00-00 00:00:00', 0),
(455, 17, 'tmplt_Sup_Sup_022_152', 'te_Sup_Sup_t00000000_24122_152', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing</br><span style=\"font-weight: bolder;\">welocme</span><p>Testing&nbsp;</p><p><span style=\"font-weight: bolder;\">welocme</span></p>\"}]', '652386443718495', 1, 'Y', '2024-01-22 12:40:04', '0000-00-00 00:00:00', 0),
(456, 46, 'tmplt_Sup_Sup_022_152', 'te_Sup_Sup_t00000000_24122_152', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing</br><span style=\"font-weight: bolder;\">welocme</span><p>Testing&nbsp;</p><p><span style=\"font-weight: bolder;\">welocme</span></p>\"}]', '652386443718495', 1, 'Y', '2024-01-22 12:40:04', '0000-00-00 00:00:00', 0),
(457, 14, 'tmplt_Sup_Sup_022_153', 'te_Sup_Sup_t00000000_24122_153', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*\"}]', '874219639569772', 1, 'Y', '2024-01-22 12:40:34', '0000-00-00 00:00:00', 0),
(458, 17, 'tmplt_Sup_Sup_022_153', 'te_Sup_Sup_t00000000_24122_153', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*\"}]', '874219639569772', 1, 'Y', '2024-01-22 12:40:34', '0000-00-00 00:00:00', 0),
(459, 46, 'tmplt_Sup_Sup_022_153', 'te_Sup_Sup_t00000000_24122_153', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*\"}]', '874219639569772', 1, 'Y', '2024-01-22 12:40:34', '0000-00-00 00:00:00', 0),
(460, 14, 'tmplt_Sup_Sup_022_154', 'te_Sup_Sup_t00000000_24122_154', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing</br><b>welcome</b><p>testing</p><p><b>welcome</b></p>*welcome*\"}]', '811134749355598', 1, 'Y', '2024-01-22 12:42:43', '0000-00-00 00:00:00', 0),
(461, 17, 'tmplt_Sup_Sup_022_154', 'te_Sup_Sup_t00000000_24122_154', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing</br><b>welcome</b><p>testing</p><p><b>welcome</b></p>*welcome*\"}]', '811134749355598', 1, 'Y', '2024-01-22 12:42:43', '0000-00-00 00:00:00', 0),
(462, 46, 'tmplt_Sup_Sup_022_154', 'te_Sup_Sup_t00000000_24122_154', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing</br><b>welcome</b><p>testing</p><p><b>welcome</b></p>*welcome*\"}]', '811134749355598', 1, 'Y', '2024-01-22 12:42:43', '0000-00-00 00:00:00', 0),
(463, 14, 'tmplt_Sup_Sup_022_155', 'te_Sup_Sup_t00000000_24122_155', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>TESTING MESSAGE</p>\"}]', '253784302494270', 1, 'Y', '2024-01-22 12:51:43', '0000-00-00 00:00:00', 0),
(464, 17, 'tmplt_Sup_Sup_022_155', 'te_Sup_Sup_t00000000_24122_155', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>TESTING MESSAGE</p>\"}]', '253784302494270', 1, 'Y', '2024-01-22 12:51:43', '0000-00-00 00:00:00', 0),
(465, 46, 'tmplt_Sup_Sup_022_155', 'te_Sup_Sup_t00000000_24122_155', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>TESTING MESSAGE</p>\"}]', '253784302494270', 1, 'Y', '2024-01-22 12:51:43', '0000-00-00 00:00:00', 0),
(466, 14, 'tmplt_Sup_Sup_022_156', 'te_Sup_Sup_t00000000_24122_156', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>TESTING MESSAGE</p><p>WELCOME<br>YEEJAI TECHNOLOGY</p>\"}]', '927088083026607', 1, 'Y', '2024-01-22 12:52:20', '0000-00-00 00:00:00', 0),
(467, 17, 'tmplt_Sup_Sup_022_156', 'te_Sup_Sup_t00000000_24122_156', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>TESTING MESSAGE</p><p>WELCOME<br>YEEJAI TECHNOLOGY</p>\"}]', '927088083026607', 1, 'Y', '2024-01-22 12:52:20', '0000-00-00 00:00:00', 0),
(468, 46, 'tmplt_Sup_Sup_022_156', 'te_Sup_Sup_t00000000_24122_156', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>TESTING MESSAGE</p><p>WELCOME<br>YEEJAI TECHNOLOGY</p>\"}]', '927088083026607', 1, 'Y', '2024-01-22 12:52:20', '0000-00-00 00:00:00', 0),
(469, 14, 'tmplt_Sup_Sup_022_157', 'te_Sup_Sup_t00000000_24122_157', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>TESTING MESSAGE</p><p>WELCOME<br>YEEJAI TECHNOLOGY</p>\"}]', '580859738098649', 1, 'Y', '2024-01-22 12:53:54', '0000-00-00 00:00:00', 0),
(470, 17, 'tmplt_Sup_Sup_022_157', 'te_Sup_Sup_t00000000_24122_157', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>TESTING MESSAGE</p><p>WELCOME<br>YEEJAI TECHNOLOGY</p>\"}]', '580859738098649', 1, 'Y', '2024-01-22 12:53:54', '0000-00-00 00:00:00', 0),
(471, 46, 'tmplt_Sup_Sup_022_157', 'te_Sup_Sup_t00000000_24122_157', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<p>TESTING MESSAGE</p><p>WELCOME<br>YEEJAI TECHNOLOGY</p>\"}]', '580859738098649', 1, 'Y', '2024-01-22 12:53:54', '0000-00-00 00:00:00', 0),
(472, 14, 'tmplt_Sup_Sup_022_158', 'te_Sup_Sup_l00000000_24122_158', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message\"}]', '198971952499119', 1, 'Y', '2024-01-22 12:55:34', '0000-00-00 00:00:00', 0),
(473, 17, 'tmplt_Sup_Sup_022_158', 'te_Sup_Sup_l00000000_24122_158', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message\"}]', '198971952499119', 1, 'Y', '2024-01-22 12:55:34', '0000-00-00 00:00:00', 0),
(474, 46, 'tmplt_Sup_Sup_022_158', 'te_Sup_Sup_l00000000_24122_158', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing message\"}]', '198971952499119', 1, 'Y', '2024-01-22 12:55:34', '0000-00-00 00:00:00', 0),
(475, 14, 'tmplt_Sup_Sup_022_159', 'te_Sup_Sup_l00000000_24122_159', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGE</br>WELCOME<br>YEEJAI TECHNOLOGY\"}]', '271623150042400', 1, 'Y', '2024-01-22 12:55:47', '0000-00-00 00:00:00', 0),
(476, 17, 'tmplt_Sup_Sup_022_159', 'te_Sup_Sup_l00000000_24122_159', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGE</br>WELCOME<br>YEEJAI TECHNOLOGY\"}]', '271623150042400', 1, 'Y', '2024-01-22 12:55:47', '0000-00-00 00:00:00', 0),
(477, 46, 'tmplt_Sup_Sup_022_159', 'te_Sup_Sup_l00000000_24122_159', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGE</br>WELCOME<br>YEEJAI TECHNOLOGY\"}]', '271623150042400', 1, 'Y', '2024-01-22 12:55:47', '0000-00-00 00:00:00', 0),
(478, 14, 'tmplt_Sup_Sup_022_160', 'te_Sup_Sup_l00000000_24122_160', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGE</br>WELCOME<br>YEEJAI TECHNOLOGYTESTING MESSAGE</br>WELCOME<br>YEEJAI TECHNOLOGY\"}]', '542678524443512', 1, 'Y', '2024-01-22 13:06:24', '0000-00-00 00:00:00', 0),
(479, 17, 'tmplt_Sup_Sup_022_160', 'te_Sup_Sup_l00000000_24122_160', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGE</br>WELCOME<br>YEEJAI TECHNOLOGYTESTING MESSAGE</br>WELCOME<br>YEEJAI TECHNOLOGY\"}]', '542678524443512', 1, 'Y', '2024-01-22 13:06:24', '0000-00-00 00:00:00', 0),
(480, 46, 'tmplt_Sup_Sup_022_160', 'te_Sup_Sup_l00000000_24122_160', 3, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGE</br>WELCOME<br>YEEJAI TECHNOLOGYTESTING MESSAGE</br>WELCOME<br>YEEJAI TECHNOLOGY\"}]', '542678524443512', 1, 'Y', '2024-01-22 13:06:24', '0000-00-00 00:00:00', 0),
(481, 14, 'tmplt_Sup_Sup_022_161', 'te_Sup_Sup_t00000000_24122_161', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING MESSAGE**WELCOMEYEEJAI TECHNOLOGY*\"}]', '347816435079292', 1, 'Y', '2024-01-22 13:09:10', '0000-00-00 00:00:00', 0),
(482, 17, 'tmplt_Sup_Sup_022_161', 'te_Sup_Sup_t00000000_24122_161', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING MESSAGE**WELCOMEYEEJAI TECHNOLOGY*\"}]', '347816435079292', 1, 'Y', '2024-01-22 13:09:10', '0000-00-00 00:00:00', 0),
(483, 46, 'tmplt_Sup_Sup_022_161', 'te_Sup_Sup_t00000000_24122_161', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING MESSAGE**WELCOMEYEEJAI TECHNOLOGY*\"}]', '347816435079292', 1, 'Y', '2024-01-22 13:09:10', '0000-00-00 00:00:00', 0),
(484, 14, 'tmplt_Sup_Sup_022_162', 'te_Sup_Sup_t00000000_24122_162', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOMEYEEJAI TECHNOLOGY*\"}]', '273463014810284', 1, 'Y', '2024-01-22 13:09:31', '0000-00-00 00:00:00', 0),
(485, 17, 'tmplt_Sup_Sup_022_162', 'te_Sup_Sup_t00000000_24122_162', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOMEYEEJAI TECHNOLOGY*\"}]', '273463014810284', 1, 'Y', '2024-01-22 13:09:31', '0000-00-00 00:00:00', 0),
(486, 46, 'tmplt_Sup_Sup_022_162', 'te_Sup_Sup_t00000000_24122_162', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOMEYEEJAI TECHNOLOGY*\"}]', '273463014810284', 1, 'Y', '2024-01-22 13:09:31', '0000-00-00 00:00:00', 0),
(487, 14, 'tmplt_Sup_Sup_022_163', 'te_Sup_Sup_t00000000_24122_163', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOMEYEEJAI TECHNOLOGY*\"}]', '869208293782864', 1, 'Y', '2024-01-22 13:10:53', '0000-00-00 00:00:00', 0),
(488, 17, 'tmplt_Sup_Sup_022_163', 'te_Sup_Sup_t00000000_24122_163', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOMEYEEJAI TECHNOLOGY*\"}]', '869208293782864', 1, 'Y', '2024-01-22 13:10:53', '0000-00-00 00:00:00', 0),
(489, 46, 'tmplt_Sup_Sup_022_163', 'te_Sup_Sup_t00000000_24122_163', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOMEYEEJAI TECHNOLOGY*\"}]', '869208293782864', 1, 'Y', '2024-01-22 13:10:53', '0000-00-00 00:00:00', 0),
(490, 14, 'tmplt_Sup_Sup_022_164', 'te_Sup_Sup_t00000000_24122_164', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*YEEJAI TECHNOLOGY*\"}]', '725998124496408', 1, 'Y', '2024-01-22 13:15:56', '0000-00-00 00:00:00', 0),
(491, 17, 'tmplt_Sup_Sup_022_164', 'te_Sup_Sup_t00000000_24122_164', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*YEEJAI TECHNOLOGY*\"}]', '725998124496408', 1, 'Y', '2024-01-22 13:15:56', '0000-00-00 00:00:00', 0),
(492, 46, 'tmplt_Sup_Sup_022_164', 'te_Sup_Sup_t00000000_24122_164', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*YEEJAI TECHNOLOGY*\"}]', '725998124496408', 1, 'Y', '2024-01-22 13:15:56', '0000-00-00 00:00:00', 0),
(493, 14, 'tmplt_Sup_Sup_022_165', 'te_Sup_Sup_t00000000_24122_165', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*YEEJAI TECHNOLOGY*\"}]', '997000975513243', 1, 'Y', '2024-01-22 13:22:44', '0000-00-00 00:00:00', 0),
(494, 17, 'tmplt_Sup_Sup_022_165', 'te_Sup_Sup_t00000000_24122_165', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*YEEJAI TECHNOLOGY*\"}]', '997000975513243', 1, 'Y', '2024-01-22 13:22:44', '0000-00-00 00:00:00', 0),
(495, 46, 'tmplt_Sup_Sup_022_165', 'te_Sup_Sup_t00000000_24122_165', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*YEEJAI TECHNOLOGY*\"}]', '997000975513243', 1, 'Y', '2024-01-22 13:22:44', '0000-00-00 00:00:00', 0),
(496, 14, 'tmplt_Sup_Sup_022_166', 'te_Sup_Sup_t00000000_24122_166', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*YEEJAI TECHNOLOGY*TESTING MESSAGEWELCOME\"}]', '450247917618498', 1, 'Y', '2024-01-22 13:24:25', '0000-00-00 00:00:00', 0),
(497, 17, 'tmplt_Sup_Sup_022_166', 'te_Sup_Sup_t00000000_24122_166', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*YEEJAI TECHNOLOGY*TESTING MESSAGEWELCOME\"}]', '450247917618498', 1, 'Y', '2024-01-22 13:24:25', '0000-00-00 00:00:00', 0),
(498, 46, 'tmplt_Sup_Sup_022_166', 'te_Sup_Sup_t00000000_24122_166', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*YEEJAI TECHNOLOGY*TESTING MESSAGEWELCOME\"}]', '450247917618498', 1, 'Y', '2024-01-22 13:24:25', '0000-00-00 00:00:00', 0),
(499, 14, 'tmplt_Sup_Sup_022_167', 'te_Sup_Sup_t00000000_24122_167', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Testing message**welcome**yeejai technology*Testing messagewelcomeyeejai technology\"}]', '724649856541803', 1, 'Y', '2024-01-22 13:25:20', '0000-00-00 00:00:00', 0),
(500, 17, 'tmplt_Sup_Sup_022_167', 'te_Sup_Sup_t00000000_24122_167', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Testing message**welcome**yeejai technology*Testing messagewelcomeyeejai technology\"}]', '724649856541803', 1, 'Y', '2024-01-22 13:25:20', '0000-00-00 00:00:00', 0),
(501, 46, 'tmplt_Sup_Sup_022_167', 'te_Sup_Sup_t00000000_24122_167', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Testing message**welcome**yeejai technology*Testing messagewelcomeyeejai technology\"}]', '724649856541803', 1, 'Y', '2024-01-22 13:25:20', '0000-00-00 00:00:00', 0),
(502, 14, 'tmplt_Sup_Sup_022_168', 'te_Sup_Sup_t00000000_24122_168', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Testing message**welcome**yeejai technology*\"}]', '691296726607401', 1, 'Y', '2024-01-22 13:28:08', '0000-00-00 00:00:00', 0),
(503, 17, 'tmplt_Sup_Sup_022_168', 'te_Sup_Sup_t00000000_24122_168', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Testing message**welcome**yeejai technology*\"}]', '691296726607401', 1, 'Y', '2024-01-22 13:28:08', '0000-00-00 00:00:00', 0),
(504, 46, 'tmplt_Sup_Sup_022_168', 'te_Sup_Sup_t00000000_24122_168', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*Testing message**welcome**yeejai technology*\"}]', '691296726607401', 1, 'Y', '2024-01-22 13:28:08', '0000-00-00 00:00:00', 0),
(505, 14, 'tmplt_Sup_Sup_022_169', 'te_Sup_Sup_t00000u00_24122_169', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing message\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '712106142884939', 1, 'Y', '2024-01-22 13:29:16', '0000-00-00 00:00:00', 0),
(506, 17, 'tmplt_Sup_Sup_022_169', 'te_Sup_Sup_t00000u00_24122_169', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing message\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '712106142884939', 1, 'Y', '2024-01-22 13:29:16', '0000-00-00 00:00:00', 0),
(507, 46, 'tmplt_Sup_Sup_022_169', 'te_Sup_Sup_t00000u00_24122_169', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing message\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '712106142884939', 1, 'Y', '2024-01-22 13:29:16', '0000-00-00 00:00:00', 0),
(508, 14, 'tmplt_Sup_Sup_022_170', 'te_Sup_Sup_t00000u00_24122_170', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING BOLD MESSAGE +**LINK*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"link\",\"url\":\"http://www.google.com\"}]}]', '263562042044663', 1, 'Y', '2024-01-22 13:30:14', '0000-00-00 00:00:00', 0),
(509, 17, 'tmplt_Sup_Sup_022_170', 'te_Sup_Sup_t00000u00_24122_170', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING BOLD MESSAGE +**LINK*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"link\",\"url\":\"http://www.google.com\"}]}]', '263562042044663', 1, 'Y', '2024-01-22 13:30:14', '0000-00-00 00:00:00', 0),
(510, 46, 'tmplt_Sup_Sup_022_170', 'te_Sup_Sup_t00000u00_24122_170', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING BOLD MESSAGE +**LINK*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"link\",\"url\":\"http://www.google.com\"}]}]', '263562042044663', 1, 'Y', '2024-01-22 13:30:14', '0000-00-00 00:00:00', 0),
(511, 14, 'tmplt_Sup_Sup_022_171', 'te_Sup_Sup_t00000u00_24122_171', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Tetsing messagewelcomeyeejai technology\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '458921833838197', 1, 'Y', '2024-01-22 13:31:43', '0000-00-00 00:00:00', 0),
(512, 17, 'tmplt_Sup_Sup_022_171', 'te_Sup_Sup_t00000u00_24122_171', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Tetsing messagewelcomeyeejai technology\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '458921833838197', 1, 'Y', '2024-01-22 13:31:43', '0000-00-00 00:00:00', 0),
(513, 46, 'tmplt_Sup_Sup_022_171', 'te_Sup_Sup_t00000u00_24122_171', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Tetsing messagewelcomeyeejai technology\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '458921833838197', 1, 'Y', '2024-01-22 13:31:43', '0000-00-00 00:00:00', 0),
(514, 14, 'tmplt_Sup_Sup_022_172', 'te_Sup_Sup_t00000u00_24122_172', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Tetsing messagewelcomeyeejai technology\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '716097220929222', 1, 'Y', '2024-01-22 13:34:50', '0000-00-00 00:00:00', 0),
(515, 17, 'tmplt_Sup_Sup_022_172', 'te_Sup_Sup_t00000u00_24122_172', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Tetsing messagewelcomeyeejai technology\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '716097220929222', 1, 'Y', '2024-01-22 13:34:50', '0000-00-00 00:00:00', 0),
(516, 46, 'tmplt_Sup_Sup_022_172', 'te_Sup_Sup_t00000u00_24122_172', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Tetsing messagewelcomeyeejai technology\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '716097220929222', 1, 'Y', '2024-01-22 13:34:50', '0000-00-00 00:00:00', 0),
(517, 14, 'tmplt_Sup_Sup_022_173', 'te_Sup_Sup_t00000u00_24122_173', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Tetsing messagewelcomeyeejai technology\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '576426308421244', 1, 'Y', '2024-01-22 13:37:41', '0000-00-00 00:00:00', 0),
(518, 17, 'tmplt_Sup_Sup_022_173', 'te_Sup_Sup_t00000u00_24122_173', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Tetsing messagewelcomeyeejai technology\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '576426308421244', 1, 'Y', '2024-01-22 13:37:41', '0000-00-00 00:00:00', 0),
(519, 46, 'tmplt_Sup_Sup_022_173', 'te_Sup_Sup_t00000u00_24122_173', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Tetsing messagewelcomeyeejai technology\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com/\"}]}]', '576426308421244', 1, 'Y', '2024-01-22 13:37:41', '0000-00-00 00:00:00', 0),
(520, 14, 'tmplt_Sup_Sup_022_174', 'te_Sup_Sup_t00000u00_24122_174', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '406959376250130', 1, 'Y', '2024-01-22 15:17:24', '0000-00-00 00:00:00', 0),
(521, 17, 'tmplt_Sup_Sup_022_174', 'te_Sup_Sup_t00000u00_24122_174', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '406959376250130', 1, 'Y', '2024-01-22 15:17:24', '0000-00-00 00:00:00', 0),
(522, 46, 'tmplt_Sup_Sup_022_174', 'te_Sup_Sup_t00000u00_24122_174', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '406959376250130', 1, 'Y', '2024-01-22 15:17:24', '0000-00-00 00:00:00', 0),
(523, 14, 'tmplt_Sup_Sup_022_175', 'te_Sup_Sup_t00000u00_24122_175', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*TESTING MESSAGE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '918368972993061', 1, 'Y', '2024-01-22 15:17:53', '0000-00-00 00:00:00', 0),
(524, 17, 'tmplt_Sup_Sup_022_175', 'te_Sup_Sup_t00000u00_24122_175', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*TESTING MESSAGE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '918368972993061', 1, 'Y', '2024-01-22 15:17:53', '0000-00-00 00:00:00', 0),
(525, 46, 'tmplt_Sup_Sup_022_175', 'te_Sup_Sup_t00000u00_24122_175', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*TESTING MESSAGE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '918368972993061', 1, 'Y', '2024-01-22 15:17:53', '0000-00-00 00:00:00', 0),
(526, 14, 'tmplt_Sup_Sup_022_176', 'te_Sup_Sup_t00000u00_24122_176', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*TESTING MESSAGE<br>TESTING<br>GOOGLE<br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '610194189884165', 1, 'Y', '2024-01-22 15:31:28', '0000-00-00 00:00:00', 0),
(527, 17, 'tmplt_Sup_Sup_022_176', 'te_Sup_Sup_t00000u00_24122_176', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*TESTING MESSAGE<br>TESTING<br>GOOGLE<br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '610194189884165', 1, 'Y', '2024-01-22 15:31:28', '0000-00-00 00:00:00', 0);
INSERT INTO `message_template` (`template_id`, `sender_master_id`, `unique_template_id`, `template_name`, `language_id`, `template_category`, `template_message`, `template_response_id`, `created_user`, `template_status`, `template_entdate`, `approve_date`, `body_variable_count`) VALUES
(528, 46, 'tmplt_Sup_Sup_022_176', 'te_Sup_Sup_t00000u00_24122_176', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*TESTING MESSAGE<br>TESTING<br>GOOGLE<br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '610194189884165', 1, 'Y', '2024-01-22 15:31:28', '0000-00-00 00:00:00', 0),
(529, 14, 'tmplt_Sup_Sup_022_177', 'te_Sup_Sup_t00000u00_24122_177', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*TESTING MESSAGE<br><b>TESTING</b><br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE</a><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '747595498274134', 1, 'Y', '2024-01-22 15:38:18', '0000-00-00 00:00:00', 0),
(530, 17, 'tmplt_Sup_Sup_022_177', 'te_Sup_Sup_t00000u00_24122_177', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*TESTING MESSAGE<br><b>TESTING</b><br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE</a><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '747595498274134', 1, 'Y', '2024-01-22 15:38:18', '0000-00-00 00:00:00', 0),
(531, 46, 'tmplt_Sup_Sup_022_177', 'te_Sup_Sup_t00000u00_24122_177', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*TESTING MESSAGE<br><b>TESTING</b><br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE</a><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '747595498274134', 1, 'Y', '2024-01-22 15:38:18', '0000-00-00 00:00:00', 0),
(532, 14, 'tmplt_Sup_Sup_022_178', 'te_Sup_Sup_t00000u00_24122_178', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*TESTING MESSAGE<br><b>TESTING</b><br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE</a><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '408555398609839', 1, 'Y', '2024-01-22 15:40:53', '0000-00-00 00:00:00', 0),
(533, 17, 'tmplt_Sup_Sup_022_178', 'te_Sup_Sup_t00000u00_24122_178', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*TESTING MESSAGE<br><b>TESTING</b><br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE</a><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '408555398609839', 1, 'Y', '2024-01-22 15:40:53', '0000-00-00 00:00:00', 0),
(534, 46, 'tmplt_Sup_Sup_022_178', 'te_Sup_Sup_t00000u00_24122_178', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*TESTING MESSAGE<br><b>TESTING</b><br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE</a><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '408555398609839', 1, 'Y', '2024-01-22 15:40:53', '0000-00-00 00:00:00', 0),
(535, 14, 'tmplt_Sup_Sup_022_179', 'te_Sup_Sup_t00000u00_24122_179', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '60334236432817', 1, 'Y', '2024-01-22 15:42:03', '0000-00-00 00:00:00', 0),
(536, 17, 'tmplt_Sup_Sup_022_179', 'te_Sup_Sup_t00000u00_24122_179', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '60334236432817', 1, 'Y', '2024-01-22 15:42:03', '0000-00-00 00:00:00', 0),
(537, 46, 'tmplt_Sup_Sup_022_179', 'te_Sup_Sup_t00000u00_24122_179', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '60334236432817', 1, 'Y', '2024-01-22 15:42:03', '0000-00-00 00:00:00', 0),
(538, 14, 'tmplt_Sup_Sup_022_180', 'te_Sup_Sup_t00000u00_24122_180', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '219335617993884', 1, 'Y', '2024-01-22 15:51:33', '0000-00-00 00:00:00', 0),
(539, 17, 'tmplt_Sup_Sup_022_180', 'te_Sup_Sup_t00000u00_24122_180', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '219335617993884', 1, 'Y', '2024-01-22 15:51:33', '0000-00-00 00:00:00', 0),
(540, 46, 'tmplt_Sup_Sup_022_180', 'te_Sup_Sup_t00000u00_24122_180', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '219335617993884', 1, 'Y', '2024-01-22 15:51:33', '0000-00-00 00:00:00', 0),
(541, 14, 'tmplt_Sup_Sup_022_181', 'te_Sup_Sup_t00000u00_24122_181', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '528972607181820', 1, 'Y', '2024-01-22 15:52:41', '0000-00-00 00:00:00', 0),
(542, 17, 'tmplt_Sup_Sup_022_181', 'te_Sup_Sup_t00000u00_24122_181', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '528972607181820', 1, 'Y', '2024-01-22 15:52:41', '0000-00-00 00:00:00', 0),
(543, 46, 'tmplt_Sup_Sup_022_181', 'te_Sup_Sup_t00000u00_24122_181', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '528972607181820', 1, 'Y', '2024-01-22 15:52:41', '0000-00-00 00:00:00', 0),
(544, 14, 'tmplt_Sup_Sup_022_182', 'te_Sup_Sup_t00000u00_24122_182', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '389346043895865', 1, 'Y', '2024-01-22 15:53:16', '0000-00-00 00:00:00', 0),
(545, 17, 'tmplt_Sup_Sup_022_182', 'te_Sup_Sup_t00000u00_24122_182', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '389346043895865', 1, 'Y', '2024-01-22 15:53:16', '0000-00-00 00:00:00', 0),
(546, 46, 'tmplt_Sup_Sup_022_182', 'te_Sup_Sup_t00000u00_24122_182', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '389346043895865', 1, 'Y', '2024-01-22 15:53:16', '0000-00-00 00:00:00', 0),
(547, 14, 'tmplt_Sup_Sup_022_183', 'te_Sup_Sup_t00000u00_24122_183', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '542360957644872', 1, 'Y', '2024-01-22 15:54:40', '0000-00-00 00:00:00', 0),
(548, 17, 'tmplt_Sup_Sup_022_183', 'te_Sup_Sup_t00000u00_24122_183', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '542360957644872', 1, 'Y', '2024-01-22 15:54:40', '0000-00-00 00:00:00', 0),
(549, 46, 'tmplt_Sup_Sup_022_183', 'te_Sup_Sup_t00000u00_24122_183', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '542360957644872', 1, 'Y', '2024-01-22 15:54:40', '0000-00-00 00:00:00', 0),
(550, 14, 'tmplt_Sup_Sup_022_184', 'te_Sup_Sup_t00000u00_24122_184', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '740914194465716', 1, 'Y', '2024-01-22 15:55:05', '0000-00-00 00:00:00', 0),
(551, 17, 'tmplt_Sup_Sup_022_184', 'te_Sup_Sup_t00000u00_24122_184', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '740914194465716', 1, 'Y', '2024-01-22 15:55:05', '0000-00-00 00:00:00', 0),
(552, 46, 'tmplt_Sup_Sup_022_184', 'te_Sup_Sup_t00000u00_24122_184', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '740914194465716', 1, 'Y', '2024-01-22 15:55:05', '0000-00-00 00:00:00', 0),
(553, 14, 'tmplt_Sup_Sup_022_185', 'te_Sup_Sup_t00000u00_24122_185', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGETESTING\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '61577618912297', 1, 'Y', '2024-01-22 16:31:57', '0000-00-00 00:00:00', 0),
(554, 17, 'tmplt_Sup_Sup_022_185', 'te_Sup_Sup_t00000u00_24122_185', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGETESTING\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '61577618912297', 1, 'Y', '2024-01-22 16:31:57', '0000-00-00 00:00:00', 0),
(555, 46, 'tmplt_Sup_Sup_022_185', 'te_Sup_Sup_t00000u00_24122_185', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGETESTING\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '61577618912297', 1, 'Y', '2024-01-22 16:31:57', '0000-00-00 00:00:00', 0),
(556, 14, 'tmplt_Sup_Sup_022_186', 'te_Sup_Sup_t00000u00_24122_186', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGETESTING\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '158336646734191', 1, 'Y', '2024-01-22 16:37:06', '0000-00-00 00:00:00', 0),
(557, 17, 'tmplt_Sup_Sup_022_186', 'te_Sup_Sup_t00000u00_24122_186', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGETESTING\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '158336646734191', 1, 'Y', '2024-01-22 16:37:06', '0000-00-00 00:00:00', 0),
(558, 46, 'tmplt_Sup_Sup_022_186', 'te_Sup_Sup_t00000u00_24122_186', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGETESTING\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '158336646734191', 1, 'Y', '2024-01-22 16:37:06', '0000-00-00 00:00:00', 0),
(559, 14, 'tmplt_Sup_Sup_022_187', 'te_Sup_Sup_t00000u00_24122_187', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGETESTING\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '599832038543227', 1, 'Y', '2024-01-22 16:38:15', '0000-00-00 00:00:00', 0),
(560, 17, 'tmplt_Sup_Sup_022_187', 'te_Sup_Sup_t00000u00_24122_187', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGETESTING\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '599832038543227', 1, 'Y', '2024-01-22 16:38:15', '0000-00-00 00:00:00', 0),
(561, 46, 'tmplt_Sup_Sup_022_187', 'te_Sup_Sup_t00000u00_24122_187', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGETESTING\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '599832038543227', 1, 'Y', '2024-01-22 16:38:15', '0000-00-00 00:00:00', 0),
(562, 14, 'tmplt_Sup_Sup_022_188', 'te_Sup_Sup_t00000u00_24122_188', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGETESTING\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '54824918888418', 1, 'Y', '2024-01-22 16:38:46', '0000-00-00 00:00:00', 0),
(563, 17, 'tmplt_Sup_Sup_022_188', 'te_Sup_Sup_t00000u00_24122_188', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGETESTING\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '54824918888418', 1, 'Y', '2024-01-22 16:38:46', '0000-00-00 00:00:00', 0),
(564, 46, 'tmplt_Sup_Sup_022_188', 'te_Sup_Sup_t00000u00_24122_188', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGETESTING\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '54824918888418', 1, 'Y', '2024-01-22 16:38:46', '0000-00-00 00:00:00', 0),
(565, 14, 'tmplt_Sup_Sup_022_189', 'te_Sup_Sup_t00000u00_24122_189', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGETESTING\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '234263161059011', 1, 'Y', '2024-01-22 16:39:21', '0000-00-00 00:00:00', 0),
(566, 17, 'tmplt_Sup_Sup_022_189', 'te_Sup_Sup_t00000u00_24122_189', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGETESTING\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '234263161059011', 1, 'Y', '2024-01-22 16:39:21', '0000-00-00 00:00:00', 0),
(567, 46, 'tmplt_Sup_Sup_022_189', 'te_Sup_Sup_t00000u00_24122_189', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGETESTING\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '234263161059011', 1, 'Y', '2024-01-22 16:39:21', '0000-00-00 00:00:00', 0),
(568, 14, 'tmplt_Sup_Sup_022_190', 'te_Sup_Sup_t00000u00_24122_190', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '302586314657842', 1, 'Y', '2024-01-22 16:41:35', '0000-00-00 00:00:00', 0),
(569, 17, 'tmplt_Sup_Sup_022_190', 'te_Sup_Sup_t00000u00_24122_190', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '302586314657842', 1, 'Y', '2024-01-22 16:41:35', '0000-00-00 00:00:00', 0),
(570, 46, 'tmplt_Sup_Sup_022_190', 'te_Sup_Sup_t00000u00_24122_190', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '302586314657842', 1, 'Y', '2024-01-22 16:41:35', '0000-00-00 00:00:00', 0),
(571, 14, 'tmplt_Sup_Sup_022_191', 'te_Sup_Sup_t00000u00_24122_191', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '451452509825461', 1, 'Y', '2024-01-22 16:42:05', '0000-00-00 00:00:00', 0),
(572, 17, 'tmplt_Sup_Sup_022_191', 'te_Sup_Sup_t00000u00_24122_191', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '451452509825461', 1, 'Y', '2024-01-22 16:42:05', '0000-00-00 00:00:00', 0),
(573, 46, 'tmplt_Sup_Sup_022_191', 'te_Sup_Sup_t00000u00_24122_191', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING MESSAGE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '451452509825461', 1, 'Y', '2024-01-22 16:42:05', '0000-00-00 00:00:00', 0),
(574, 14, 'tmplt_Sup_Sup_022_192', 'te_Sup_Sup_t00000000_24122_192', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TETSING\"}]', '969126852363360', 1, 'Y', '2024-01-22 16:46:14', '0000-00-00 00:00:00', 0),
(575, 17, 'tmplt_Sup_Sup_022_192', 'te_Sup_Sup_t00000000_24122_192', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TETSING\"}]', '969126852363360', 1, 'Y', '2024-01-22 16:46:14', '0000-00-00 00:00:00', 0),
(576, 46, 'tmplt_Sup_Sup_022_192', 'te_Sup_Sup_t00000000_24122_192', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TETSING\"}]', '969126852363360', 1, 'Y', '2024-01-22 16:46:14', '0000-00-00 00:00:00', 0),
(577, 14, 'tmplt_Sup_Sup_022_193', 'te_Sup_Sup_t00000000_24122_193', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TETSING\"}]', '851883602252614', 1, 'Y', '2024-01-22 16:49:17', '0000-00-00 00:00:00', 0),
(578, 17, 'tmplt_Sup_Sup_022_193', 'te_Sup_Sup_t00000000_24122_193', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TETSING\"}]', '851883602252614', 1, 'Y', '2024-01-22 16:49:17', '0000-00-00 00:00:00', 0),
(579, 46, 'tmplt_Sup_Sup_022_193', 'te_Sup_Sup_t00000000_24122_193', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TETSING\"}]', '851883602252614', 1, 'Y', '2024-01-22 16:49:17', '0000-00-00 00:00:00', 0),
(580, 14, 'tmplt_Sup_Sup_022_194', 'te_Sup_Sup_t00000000_24122_194', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TETSINGmessagewelcome\"}]', '290850144555347', 1, 'Y', '2024-01-22 16:50:31', '0000-00-00 00:00:00', 0),
(581, 17, 'tmplt_Sup_Sup_022_194', 'te_Sup_Sup_t00000000_24122_194', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TETSINGmessagewelcome\"}]', '290850144555347', 1, 'Y', '2024-01-22 16:50:31', '0000-00-00 00:00:00', 0),
(582, 46, 'tmplt_Sup_Sup_022_194', 'te_Sup_Sup_t00000000_24122_194', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TETSINGmessagewelcome\"}]', '290850144555347', 1, 'Y', '2024-01-22 16:50:31', '0000-00-00 00:00:00', 0),
(583, 14, 'tmplt_Sup_Sup_022_195', 'te_Sup_Sup_t00000000_24122_195', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TETSINGmessagewelcome\"}]', '622398016027343', 1, 'Y', '2024-01-22 16:51:45', '0000-00-00 00:00:00', 0),
(584, 17, 'tmplt_Sup_Sup_022_195', 'te_Sup_Sup_t00000000_24122_195', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TETSINGmessagewelcome\"}]', '622398016027343', 1, 'Y', '2024-01-22 16:51:45', '0000-00-00 00:00:00', 0),
(585, 46, 'tmplt_Sup_Sup_022_195', 'te_Sup_Sup_t00000000_24122_195', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TETSINGmessagewelcome\"}]', '622398016027343', 1, 'Y', '2024-01-22 16:51:45', '0000-00-00 00:00:00', 0),
(586, 14, 'tmplt_Sup_Sup_022_196', 'te_Sup_Sup_t00000000_24122_196', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TETSINGmessagewelcome\"}]', '620138598283147', 1, 'Y', '2024-01-22 16:53:01', '0000-00-00 00:00:00', 0),
(587, 17, 'tmplt_Sup_Sup_022_196', 'te_Sup_Sup_t00000000_24122_196', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TETSINGmessagewelcome\"}]', '620138598283147', 1, 'Y', '2024-01-22 16:53:02', '0000-00-00 00:00:00', 0),
(588, 46, 'tmplt_Sup_Sup_022_196', 'te_Sup_Sup_t00000000_24122_196', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TETSINGmessagewelcome\"}]', '620138598283147', 1, 'Y', '2024-01-22 16:53:02', '0000-00-00 00:00:00', 0),
(589, 14, 'tmplt_Sup_Sup_022_197', 'te_Sup_Sup_t00000000_24122_197', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testingmessagewelcome\"}]', '469623943543451', 1, 'Y', '2024-01-22 16:55:41', '0000-00-00 00:00:00', 0),
(590, 17, 'tmplt_Sup_Sup_022_197', 'te_Sup_Sup_t00000000_24122_197', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testingmessagewelcome\"}]', '469623943543451', 1, 'Y', '2024-01-22 16:55:41', '0000-00-00 00:00:00', 0),
(591, 46, 'tmplt_Sup_Sup_022_197', 'te_Sup_Sup_t00000000_24122_197', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testingmessagewelcome\"}]', '469623943543451', 1, 'Y', '2024-01-22 16:55:41', '0000-00-00 00:00:00', 0),
(592, 14, 'tmplt_Sup_Sup_022_198', 'te_Sup_Sup_t00000000_24122_198', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testmessagewelcome\"}]', '874746984417379', 1, 'Y', '2024-01-22 16:56:59', '0000-00-00 00:00:00', 0),
(593, 17, 'tmplt_Sup_Sup_022_198', 'te_Sup_Sup_t00000000_24122_198', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testmessagewelcome\"}]', '874746984417379', 1, 'Y', '2024-01-22 16:56:59', '0000-00-00 00:00:00', 0),
(594, 46, 'tmplt_Sup_Sup_022_198', 'te_Sup_Sup_t00000000_24122_198', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testmessagewelcome\"}]', '874746984417379', 1, 'Y', '2024-01-22 16:56:59', '0000-00-00 00:00:00', 0),
(595, 14, 'tmplt_Sup_Sup_022_199', 'te_Sup_Sup_t00000000_24122_199', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TEST\"}]', '652840937055714', 1, 'Y', '2024-01-22 16:57:58', '0000-00-00 00:00:00', 0),
(596, 17, 'tmplt_Sup_Sup_022_199', 'te_Sup_Sup_t00000000_24122_199', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TEST\"}]', '652840937055714', 1, 'Y', '2024-01-22 16:57:58', '0000-00-00 00:00:00', 0),
(597, 46, 'tmplt_Sup_Sup_022_199', 'te_Sup_Sup_t00000000_24122_199', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TEST\"}]', '652840937055714', 1, 'Y', '2024-01-22 16:57:58', '0000-00-00 00:00:00', 0),
(598, 14, 'tmplt_Sup_Sup_022_200', 'te_Sup_Sup_t00000000_24122_200', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTwelcomeyeejai technology\"}]', '805228751502617', 1, 'Y', '2024-01-22 16:58:20', '0000-00-00 00:00:00', 0),
(599, 17, 'tmplt_Sup_Sup_022_200', 'te_Sup_Sup_t00000000_24122_200', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTwelcomeyeejai technology\"}]', '805228751502617', 1, 'Y', '2024-01-22 16:58:20', '0000-00-00 00:00:00', 0),
(600, 46, 'tmplt_Sup_Sup_022_200', 'te_Sup_Sup_t00000000_24122_200', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTwelcomeyeejai technology\"}]', '805228751502617', 1, 'Y', '2024-01-22 16:58:20', '0000-00-00 00:00:00', 0),
(601, 14, 'tmplt_Sup_Sup_022_201', 'te_Sup_Sup_t00000000_24122_201', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTwelcomeyeejai technology\"}]', '674049281769095', 1, 'Y', '2024-01-22 16:59:22', '0000-00-00 00:00:00', 0),
(602, 17, 'tmplt_Sup_Sup_022_201', 'te_Sup_Sup_t00000000_24122_201', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTwelcomeyeejai technology\"}]', '674049281769095', 1, 'Y', '2024-01-22 16:59:22', '0000-00-00 00:00:00', 0),
(603, 46, 'tmplt_Sup_Sup_022_201', 'te_Sup_Sup_t00000000_24122_201', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTwelcomeyeejai technology\"}]', '674049281769095', 1, 'Y', '2024-01-22 16:59:22', '0000-00-00 00:00:00', 0),
(604, 14, 'tmplt_Sup_Sup_022_202', 'te_Sup_Sup_t00000000_24122_202', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TEST\"}]', '281042154383596', 1, 'Y', '2024-01-22 17:06:22', '0000-00-00 00:00:00', 0),
(605, 17, 'tmplt_Sup_Sup_022_202', 'te_Sup_Sup_t00000000_24122_202', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TEST\"}]', '281042154383596', 1, 'Y', '2024-01-22 17:06:22', '0000-00-00 00:00:00', 0),
(606, 46, 'tmplt_Sup_Sup_022_202', 'te_Sup_Sup_t00000000_24122_202', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TEST\"}]', '281042154383596', 1, 'Y', '2024-01-22 17:06:22', '0000-00-00 00:00:00', 0),
(607, 14, 'tmplt_Sup_Sup_022_203', 'te_Sup_Sup_t00000000_24122_203', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing a new message<br>welcome<br>yeejai technology\"}]', '421151784925066', 1, 'Y', '2024-01-22 17:07:02', '0000-00-00 00:00:00', 0),
(608, 17, 'tmplt_Sup_Sup_022_203', 'te_Sup_Sup_t00000000_24122_203', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing a new message<br>welcome<br>yeejai technology\"}]', '421151784925066', 1, 'Y', '2024-01-22 17:07:02', '0000-00-00 00:00:00', 0),
(609, 46, 'tmplt_Sup_Sup_022_203', 'te_Sup_Sup_t00000000_24122_203', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing a new message<br>welcome<br>yeejai technology\"}]', '421151784925066', 1, 'Y', '2024-01-22 17:07:02', '0000-00-00 00:00:00', 0),
(610, 14, 'tmplt_Sup_Sup_022_204', 'te_Sup_Sup_t00000000_24122_204', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing a new message<br>welcome<br>yeejai technology<br>TESTING MESSAGE\"}]', '315241726640847', 1, 'Y', '2024-01-22 17:07:29', '0000-00-00 00:00:00', 0),
(611, 17, 'tmplt_Sup_Sup_022_204', 'te_Sup_Sup_t00000000_24122_204', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing a new message<br>welcome<br>yeejai technology<br>TESTING MESSAGE\"}]', '315241726640847', 1, 'Y', '2024-01-22 17:07:29', '0000-00-00 00:00:00', 0),
(612, 46, 'tmplt_Sup_Sup_022_204', 'te_Sup_Sup_t00000000_24122_204', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing a new message<br>welcome<br>yeejai technology<br>TESTING MESSAGE\"}]', '315241726640847', 1, 'Y', '2024-01-22 17:07:29', '0000-00-00 00:00:00', 0),
(613, 14, 'tmplt_Sup_Sup_022_205', 'te_Sup_Sup_t00000000_24122_205', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing a new message<br>welcome<br>yeejai technology<br>TESTING MESSAGE\"}]', '752877947618461', 1, 'Y', '2024-01-22 17:11:07', '0000-00-00 00:00:00', 0),
(614, 17, 'tmplt_Sup_Sup_022_205', 'te_Sup_Sup_t00000000_24122_205', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing a new message<br>welcome<br>yeejai technology<br>TESTING MESSAGE\"}]', '752877947618461', 1, 'Y', '2024-01-22 17:11:07', '0000-00-00 00:00:00', 0),
(615, 46, 'tmplt_Sup_Sup_022_205', 'te_Sup_Sup_t00000000_24122_205', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing a new message<br>welcome<br>yeejai technology<br>TESTING MESSAGE\"}]', '752877947618461', 1, 'Y', '2024-01-22 17:11:07', '0000-00-00 00:00:00', 0),
(616, 14, 'tmplt_Sup_Sup_022_206', 'te_Sup_Sup_t00000000_24122_206', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing a new message<br>welcome<br>yeejai technology<br>TESTING MESSAGE\"}]', '652929177040490', 1, 'Y', '2024-01-22 17:13:32', '0000-00-00 00:00:00', 0),
(617, 17, 'tmplt_Sup_Sup_022_206', 'te_Sup_Sup_t00000000_24122_206', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing a new message<br>welcome<br>yeejai technology<br>TESTING MESSAGE\"}]', '652929177040490', 1, 'Y', '2024-01-22 17:13:32', '0000-00-00 00:00:00', 0),
(618, 46, 'tmplt_Sup_Sup_022_206', 'te_Sup_Sup_t00000000_24122_206', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing a new message<br>welcome<br>yeejai technology<br>TESTING MESSAGE\"}]', '652929177040490', 1, 'Y', '2024-01-22 17:13:32', '0000-00-00 00:00:00', 0),
(619, 14, 'tmplt_Sup_Sup_022_207', 'te_Sup_Sup_t00000000_24122_207', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing a new message<br>welcome<br>yeejai technology<br>TESTING MESSAGE\"}]', '25875268466519', 1, 'Y', '2024-01-22 17:15:03', '0000-00-00 00:00:00', 0),
(620, 17, 'tmplt_Sup_Sup_022_207', 'te_Sup_Sup_t00000000_24122_207', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing a new message<br>welcome<br>yeejai technology<br>TESTING MESSAGE\"}]', '25875268466519', 1, 'Y', '2024-01-22 17:15:03', '0000-00-00 00:00:00', 0),
(621, 46, 'tmplt_Sup_Sup_022_207', 'te_Sup_Sup_t00000000_24122_207', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing a new message<br>welcome<br>yeejai technology<br>TESTING MESSAGE\"}]', '25875268466519', 1, 'Y', '2024-01-22 17:15:03', '0000-00-00 00:00:00', 0),
(622, 14, 'tmplt_Sup_Sup_022_208', 'te_Sup_Sup_t00000000_24122_208', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOME*YEEJAI TECHNOLOGY*\"}]', '67429885908507', 1, 'Y', '2024-01-22 17:27:28', '0000-00-00 00:00:00', 0),
(623, 17, 'tmplt_Sup_Sup_022_208', 'te_Sup_Sup_t00000000_24122_208', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOME*YEEJAI TECHNOLOGY*\"}]', '67429885908507', 1, 'Y', '2024-01-22 17:27:28', '0000-00-00 00:00:00', 0),
(624, 46, 'tmplt_Sup_Sup_022_208', 'te_Sup_Sup_t00000000_24122_208', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOME*YEEJAI TECHNOLOGY*\"}]', '67429885908507', 1, 'Y', '2024-01-22 17:27:28', '0000-00-00 00:00:00', 0),
(625, 14, 'tmplt_Sup_Sup_023_209', 'te_Sup_Sup_t00000000_24122_209', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOME*YEEJAI TECHNOLOGY*TESTINGWELCOME*YEEJAI TECHNOLOGY*\"}]', '415692259733150', 1, 'Y', '2024-01-22 17:30:19', '0000-00-00 00:00:00', 0),
(626, 17, 'tmplt_Sup_Sup_023_209', 'te_Sup_Sup_t00000000_24122_209', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOME*YEEJAI TECHNOLOGY*TESTINGWELCOME*YEEJAI TECHNOLOGY*\"}]', '415692259733150', 1, 'Y', '2024-01-22 17:30:19', '0000-00-00 00:00:00', 0),
(627, 46, 'tmplt_Sup_Sup_023_209', 'te_Sup_Sup_t00000000_24122_209', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOME*YEEJAI TECHNOLOGY*TESTINGWELCOME*YEEJAI TECHNOLOGY*\"}]', '415692259733150', 1, 'Y', '2024-01-22 17:30:19', '0000-00-00 00:00:00', 0),
(628, 14, 'tmplt_Sup_Sup_023_210', 'te_Sup_Sup_t00000000_24122_210', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOME*YEEJAI TECHNOLOGY*\"}]', '960952829495116', 1, 'Y', '2024-01-22 17:31:04', '0000-00-00 00:00:00', 0),
(629, 17, 'tmplt_Sup_Sup_023_210', 'te_Sup_Sup_t00000000_24122_210', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOME*YEEJAI TECHNOLOGY*\"}]', '960952829495116', 1, 'Y', '2024-01-22 17:31:04', '0000-00-00 00:00:00', 0),
(630, 46, 'tmplt_Sup_Sup_023_210', 'te_Sup_Sup_t00000000_24122_210', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOME*YEEJAI TECHNOLOGY*\"}]', '960952829495116', 1, 'Y', '2024-01-22 17:31:04', '0000-00-00 00:00:00', 0),
(631, 14, 'tmplt_Sup_Sup_023_211', 'te_Sup_Sup_t00000000_24122_211', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOME*YEEJAI TECHNOLOGY*\"}]', '101318797275962', 1, 'Y', '2024-01-22 17:32:32', '0000-00-00 00:00:00', 0),
(632, 17, 'tmplt_Sup_Sup_023_211', 'te_Sup_Sup_t00000000_24122_211', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOME*YEEJAI TECHNOLOGY*\"}]', '101318797275962', 1, 'Y', '2024-01-22 17:32:32', '0000-00-00 00:00:00', 0),
(633, 46, 'tmplt_Sup_Sup_023_211', 'te_Sup_Sup_t00000000_24122_211', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOME*YEEJAI TECHNOLOGY*\"}]', '101318797275962', 1, 'Y', '2024-01-22 17:32:32', '0000-00-00 00:00:00', 0),
(634, 14, 'tmplt_Sup_Sup_023_212', 'te_Sup_Sup_t00000000_24122_212', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOME*YEEJAI TECHNOLOGY*<p>TESTING<br>WELCOME<br>*YEEJAI TECHNOLOGY*</p>\"}]', '598946830062517', 1, 'Y', '2024-01-22 17:33:38', '0000-00-00 00:00:00', 0),
(635, 17, 'tmplt_Sup_Sup_023_212', 'te_Sup_Sup_t00000000_24122_212', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOME*YEEJAI TECHNOLOGY*<p>TESTING<br>WELCOME<br>*YEEJAI TECHNOLOGY*</p>\"}]', '598946830062517', 1, 'Y', '2024-01-22 17:33:38', '0000-00-00 00:00:00', 0),
(636, 46, 'tmplt_Sup_Sup_023_212', 'te_Sup_Sup_t00000000_24122_212', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOME*YEEJAI TECHNOLOGY*<p>TESTING<br>WELCOME<br>*YEEJAI TECHNOLOGY*</p>\"}]', '598946830062517', 1, 'Y', '2024-01-22 17:33:38', '0000-00-00 00:00:00', 0),
(637, 14, 'tmplt_Sup_Sup_023_213', 'te_Sup_Sup_t00000000_24122_213', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>WELCOME<br>*YEEJAI TECHNOLOGY*\"}]', '506897915629865', 1, 'Y', '2024-01-22 17:35:34', '0000-00-00 00:00:00', 0),
(638, 17, 'tmplt_Sup_Sup_023_213', 'te_Sup_Sup_t00000000_24122_213', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>WELCOME<br>*YEEJAI TECHNOLOGY*\"}]', '506897915629865', 1, 'Y', '2024-01-22 17:35:34', '0000-00-00 00:00:00', 0),
(639, 46, 'tmplt_Sup_Sup_023_213', 'te_Sup_Sup_t00000000_24122_213', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>WELCOME<br>*YEEJAI TECHNOLOGY*\"}]', '506897915629865', 1, 'Y', '2024-01-22 17:35:34', '0000-00-00 00:00:00', 0),
(640, 14, 'tmplt_Sup_Sup_023_214', 'te_Sup_Sup_t00000000_24122_214', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>WELCOME<br>*YEEJAI TECHNOLOGY*\"}]', '81403295197311', 1, 'Y', '2024-01-22 17:36:03', '0000-00-00 00:00:00', 0),
(641, 17, 'tmplt_Sup_Sup_023_214', 'te_Sup_Sup_t00000000_24122_214', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>WELCOME<br>*YEEJAI TECHNOLOGY*\"}]', '81403295197311', 1, 'Y', '2024-01-22 17:36:03', '0000-00-00 00:00:00', 0),
(642, 46, 'tmplt_Sup_Sup_023_214', 'te_Sup_Sup_t00000000_24122_214', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>WELCOME<br>*YEEJAI TECHNOLOGY*\"}]', '81403295197311', 1, 'Y', '2024-01-22 17:36:03', '0000-00-00 00:00:00', 0),
(643, 14, 'tmplt_Sup_Sup_023_215', 'te_Sup_Sup_t00000000_24122_215', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>WELCOME<br>YEEJAI TECHNOLOGY\"}]', '922812671859185', 1, 'Y', '2024-01-22 17:37:03', '0000-00-00 00:00:00', 0),
(644, 17, 'tmplt_Sup_Sup_023_215', 'te_Sup_Sup_t00000000_24122_215', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>WELCOME<br>YEEJAI TECHNOLOGY\"}]', '922812671859185', 1, 'Y', '2024-01-22 17:37:03', '0000-00-00 00:00:00', 0),
(645, 46, 'tmplt_Sup_Sup_023_215', 'te_Sup_Sup_t00000000_24122_215', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>WELCOME<br>YEEJAI TECHNOLOGY\"}]', '922812671859185', 1, 'Y', '2024-01-22 17:37:03', '0000-00-00 00:00:00', 0),
(646, 14, 'tmplt_Sup_Sup_023_216', 'te_Sup_Sup_t00000u00_24122_216', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOMETESTING<br>WELCOME<br><a href=\"http://www.google.com\" target=\"_blank\" style=\"\">YEEJAI TECHNOLOGY</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"YEEJAI TECHNOLOGY\",\"url\":\"http://www.google.com\"}]}]', '639669069839995', 1, 'Y', '2024-01-22 17:39:15', '0000-00-00 00:00:00', 0),
(647, 17, 'tmplt_Sup_Sup_023_216', 'te_Sup_Sup_t00000u00_24122_216', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOMETESTING<br>WELCOME<br><a href=\"http://www.google.com\" target=\"_blank\" style=\"\">YEEJAI TECHNOLOGY</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"YEEJAI TECHNOLOGY\",\"url\":\"http://www.google.com\"}]}]', '639669069839995', 1, 'Y', '2024-01-22 17:39:15', '0000-00-00 00:00:00', 0),
(648, 46, 'tmplt_Sup_Sup_023_216', 'te_Sup_Sup_t00000u00_24122_216', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGWELCOMETESTING<br>WELCOME<br><a href=\"http://www.google.com\" target=\"_blank\" style=\"\">YEEJAI TECHNOLOGY</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"YEEJAI TECHNOLOGY\",\"url\":\"http://www.google.com\"}]}]', '639669069839995', 1, 'Y', '2024-01-22 17:39:15', '0000-00-00 00:00:00', 0),
(649, 14, 'tmplt_Sup_Sup_023_217', 'te_Sup_Sup_t00000000_24123_217', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing\"}]', '697681170495537', 1, 'Y', '2024-01-23 01:35:36', '0000-00-00 00:00:00', 0),
(650, 17, 'tmplt_Sup_Sup_023_217', 'te_Sup_Sup_t00000000_24123_217', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing\"}]', '697681170495537', 1, 'Y', '2024-01-23 01:35:36', '0000-00-00 00:00:00', 0),
(651, 46, 'tmplt_Sup_Sup_023_217', 'te_Sup_Sup_t00000000_24123_217', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testing\"}]', '697681170495537', 1, 'Y', '2024-01-23 01:35:36', '0000-00-00 00:00:00', 0),
(652, 14, 'tmplt_Sup_Sup_023_218', 'te_Sup_Sup_t00000000_24123_218', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTing<br>message<br>simple\"}]', '81122879830295', 1, 'Y', '2024-01-23 01:36:19', '0000-00-00 00:00:00', 0),
(653, 17, 'tmplt_Sup_Sup_023_218', 'te_Sup_Sup_t00000000_24123_218', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTing<br>message<br>simple\"}]', '81122879830295', 1, 'Y', '2024-01-23 01:36:19', '0000-00-00 00:00:00', 0),
(654, 46, 'tmplt_Sup_Sup_023_218', 'te_Sup_Sup_t00000000_24123_218', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTing<br>message<br>simple\"}]', '81122879830295', 1, 'Y', '2024-01-23 01:36:19', '0000-00-00 00:00:00', 0),
(655, 14, 'tmplt_Sup_Sup_023_219', 'te_Sup_Sup_t00000000_24123_219', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>*message*\"}]', '779804925886190', 1, 'Y', '2024-01-23 01:36:54', '0000-00-00 00:00:00', 0),
(656, 17, 'tmplt_Sup_Sup_023_219', 'te_Sup_Sup_t00000000_24123_219', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>*message*\"}]', '779804925886190', 1, 'Y', '2024-01-23 01:36:54', '0000-00-00 00:00:00', 0),
(657, 46, 'tmplt_Sup_Sup_023_219', 'te_Sup_Sup_t00000000_24123_219', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>*message*\"}]', '779804925886190', 1, 'Y', '2024-01-23 01:36:54', '0000-00-00 00:00:00', 0),
(658, 14, 'tmplt_Sup_Sup_023_220', 'te_Sup_Sup_t00000000_24123_220', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<html><body>*TESTING*</body></html><body>*TESTING*</body>\"}]', '222374666583585', 1, 'Y', '2024-01-23 01:40:49', '0000-00-00 00:00:00', 0),
(659, 17, 'tmplt_Sup_Sup_023_220', 'te_Sup_Sup_t00000000_24123_220', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<html><body>*TESTING*</body></html><body>*TESTING*</body>\"}]', '222374666583585', 1, 'Y', '2024-01-23 01:40:49', '0000-00-00 00:00:00', 0),
(660, 46, 'tmplt_Sup_Sup_023_220', 'te_Sup_Sup_t00000000_24123_220', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<html><body>*TESTING*</body></html><body>*TESTING*</body>\"}]', '222374666583585', 1, 'Y', '2024-01-23 01:40:49', '0000-00-00 00:00:00', 0),
(661, 14, 'tmplt_Sup_Sup_023_221', 'te_Sup_Sup_t00000000_24123_221', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<body>*TESTING*</body>\"}]', '403096685058773', 1, 'Y', '2024-01-23 01:41:34', '0000-00-00 00:00:00', 0),
(662, 17, 'tmplt_Sup_Sup_023_221', 'te_Sup_Sup_t00000000_24123_221', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<body>*TESTING*</body>\"}]', '403096685058773', 1, 'Y', '2024-01-23 01:41:34', '0000-00-00 00:00:00', 0),
(663, 46, 'tmplt_Sup_Sup_023_221', 'te_Sup_Sup_t00000000_24123_221', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<body>*TESTING*</body>\"}]', '403096685058773', 1, 'Y', '2024-01-23 01:41:34', '0000-00-00 00:00:00', 0),
(664, 14, 'tmplt_Sup_Sup_023_222', 'te_Sup_Sup_t00000000_24123_222', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<html><body>*TESTING*</body></html>*TESTING*</body></html><body>*TESTING*</body><body>*TESTING*</body>\"}]', '435196338712042', 1, 'Y', '2024-01-23 01:42:49', '0000-00-00 00:00:00', 0),
(665, 17, 'tmplt_Sup_Sup_023_222', 'te_Sup_Sup_t00000000_24123_222', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<html><body>*TESTING*</body></html>*TESTING*</body></html><body>*TESTING*</body><body>*TESTING*</body>\"}]', '435196338712042', 1, 'Y', '2024-01-23 01:42:50', '0000-00-00 00:00:00', 0),
(666, 46, 'tmplt_Sup_Sup_023_222', 'te_Sup_Sup_t00000000_24123_222', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<html><body>*TESTING*</body></html>*TESTING*</body></html><body>*TESTING*</body><body>*TESTING*</body>\"}]', '435196338712042', 1, 'Y', '2024-01-23 01:42:50', '0000-00-00 00:00:00', 0),
(667, 14, 'tmplt_Sup_Sup_023_223', 'te_Sup_Sup_t00000000_24123_223', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*</body></html><body>*TESTING*</body>\"}]', '305950852802199', 1, 'Y', '2024-01-23 01:43:11', '0000-00-00 00:00:00', 0),
(668, 17, 'tmplt_Sup_Sup_023_223', 'te_Sup_Sup_t00000000_24123_223', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*</body></html><body>*TESTING*</body>\"}]', '305950852802199', 1, 'Y', '2024-01-23 01:43:11', '0000-00-00 00:00:00', 0),
(669, 46, 'tmplt_Sup_Sup_023_223', 'te_Sup_Sup_t00000000_24123_223', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*</body></html><body>*TESTING*</body>\"}]', '305950852802199', 1, 'Y', '2024-01-23 01:43:11', '0000-00-00 00:00:00', 0),
(670, 14, 'tmplt_Sup_Sup_023_224', 'te_Sup_Sup_t00000000_24123_224', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<body>*TESTING*</body>\"}]', '404983837799133', 1, 'Y', '2024-01-23 01:45:03', '0000-00-00 00:00:00', 0),
(671, 17, 'tmplt_Sup_Sup_023_224', 'te_Sup_Sup_t00000000_24123_224', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<body>*TESTING*</body>\"}]', '404983837799133', 1, 'Y', '2024-01-23 01:45:03', '0000-00-00 00:00:00', 0),
(672, 46, 'tmplt_Sup_Sup_023_224', 'te_Sup_Sup_t00000000_24123_224', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<body>*TESTING*</body>\"}]', '404983837799133', 1, 'Y', '2024-01-23 01:45:03', '0000-00-00 00:00:00', 0),
(673, 14, 'tmplt_Sup_Sup_023_225', 'te_Sup_Sup_t00000000_24123_225', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*</body>\"}]', '739088848930158', 1, 'Y', '2024-01-23 01:45:30', '0000-00-00 00:00:00', 0),
(674, 17, 'tmplt_Sup_Sup_023_225', 'te_Sup_Sup_t00000000_24123_225', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*</body>\"}]', '739088848930158', 1, 'Y', '2024-01-23 01:45:30', '0000-00-00 00:00:00', 0),
(675, 46, 'tmplt_Sup_Sup_023_225', 'te_Sup_Sup_t00000000_24123_225', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*</body>\"}]', '739088848930158', 1, 'Y', '2024-01-23 01:45:30', '0000-00-00 00:00:00', 0),
(676, 14, 'tmplt_Sup_Sup_023_226', 'te_Sup_Sup_t00000000_24123_226', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"}]', '641482380381741', 1, 'Y', '2024-01-23 01:45:52', '0000-00-00 00:00:00', 0),
(677, 17, 'tmplt_Sup_Sup_023_226', 'te_Sup_Sup_t00000000_24123_226', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"}]', '641482380381741', 1, 'Y', '2024-01-23 01:45:52', '0000-00-00 00:00:00', 0),
(678, 46, 'tmplt_Sup_Sup_023_226', 'te_Sup_Sup_t00000000_24123_226', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"}]', '641482380381741', 1, 'Y', '2024-01-23 01:45:52', '0000-00-00 00:00:00', 0),
(679, 14, 'tmplt_Sup_Sup_023_227', 'te_Sup_Sup_t00000000_24123_227', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<p>TESTING</p>\"}]', '38409875067051', 1, 'Y', '2024-01-23 01:46:11', '0000-00-00 00:00:00', 0),
(680, 17, 'tmplt_Sup_Sup_023_227', 'te_Sup_Sup_t00000000_24123_227', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<p>TESTING</p>\"}]', '38409875067051', 1, 'Y', '2024-01-23 01:46:11', '0000-00-00 00:00:00', 0),
(681, 46, 'tmplt_Sup_Sup_023_227', 'te_Sup_Sup_t00000000_24123_227', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<p>TESTING</p>\"}]', '38409875067051', 1, 'Y', '2024-01-23 01:46:11', '0000-00-00 00:00:00', 0),
(682, 14, 'tmplt_Sup_Sup_023_228', 'te_Sup_Sup_t00000000_24123_228', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<p>TESTING</p>\"}]', '65899631408655', 1, 'Y', '2024-01-23 01:51:49', '0000-00-00 00:00:00', 0),
(683, 17, 'tmplt_Sup_Sup_023_228', 'te_Sup_Sup_t00000000_24123_228', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<p>TESTING</p>\"}]', '65899631408655', 1, 'Y', '2024-01-23 01:51:49', '0000-00-00 00:00:00', 0),
(684, 46, 'tmplt_Sup_Sup_023_228', 'te_Sup_Sup_t00000000_24123_228', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<p>TESTING</p>\"}]', '65899631408655', 1, 'Y', '2024-01-23 01:51:49', '0000-00-00 00:00:00', 0),
(685, 14, 'tmplt_Sup_Sup_023_229', 'te_Sup_Sup_t00000000_24123_229', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTing\"}]', '872944120528300', 1, 'Y', '2024-01-23 01:53:16', '0000-00-00 00:00:00', 0),
(686, 17, 'tmplt_Sup_Sup_023_229', 'te_Sup_Sup_t00000000_24123_229', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTing\"}]', '872944120528300', 1, 'Y', '2024-01-23 01:53:16', '0000-00-00 00:00:00', 0),
(687, 46, 'tmplt_Sup_Sup_023_229', 'te_Sup_Sup_t00000000_24123_229', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTing\"}]', '872944120528300', 1, 'Y', '2024-01-23 01:53:16', '0000-00-00 00:00:00', 0),
(688, 14, 'tmplt_Sup_Sup_023_230', 'te_Sup_Sup_t00000000_24123_230', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>message\"}]', '400141569736049', 1, 'Y', '2024-01-23 01:53:36', '0000-00-00 00:00:00', 0),
(689, 17, 'tmplt_Sup_Sup_023_230', 'te_Sup_Sup_t00000000_24123_230', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>message\"}]', '400141569736049', 1, 'Y', '2024-01-23 01:53:36', '0000-00-00 00:00:00', 0),
(690, 46, 'tmplt_Sup_Sup_023_230', 'te_Sup_Sup_t00000000_24123_230', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>message\"}]', '400141569736049', 1, 'Y', '2024-01-23 01:53:36', '0000-00-00 00:00:00', 0),
(691, 14, 'tmplt_Sup_Sup_023_231', 'te_Sup_Sup_t00000000_24123_231', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING\"}]', '877471245298537', 1, 'Y', '2024-01-23 01:58:55', '0000-00-00 00:00:00', 0),
(692, 17, 'tmplt_Sup_Sup_023_231', 'te_Sup_Sup_t00000000_24123_231', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING\"}]', '877471245298537', 1, 'Y', '2024-01-23 01:58:55', '0000-00-00 00:00:00', 0),
(693, 46, 'tmplt_Sup_Sup_023_231', 'te_Sup_Sup_t00000000_24123_231', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING\"}]', '877471245298537', 1, 'Y', '2024-01-23 01:58:55', '0000-00-00 00:00:00', 0),
(694, 14, 'tmplt_Sup_Sup_023_232', 'te_Sup_Sup_t00000000_24123_232', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>messahe<br>welcome\"}]', '828605123222303', 1, 'Y', '2024-01-23 01:59:12', '0000-00-00 00:00:00', 0),
(695, 17, 'tmplt_Sup_Sup_023_232', 'te_Sup_Sup_t00000000_24123_232', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>messahe<br>welcome\"}]', '828605123222303', 1, 'Y', '2024-01-23 01:59:12', '0000-00-00 00:00:00', 0),
(696, 46, 'tmplt_Sup_Sup_023_232', 'te_Sup_Sup_t00000000_24123_232', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>messahe<br>welcome\"}]', '828605123222303', 1, 'Y', '2024-01-23 01:59:12', '0000-00-00 00:00:00', 0),
(697, 14, 'tmplt_Sup_Sup_023_233', 'te_Sup_Sup_t00000000_24123_233', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"}]', '364534214145411', 1, 'Y', '2024-01-23 02:00:37', '0000-00-00 00:00:00', 0),
(698, 17, 'tmplt_Sup_Sup_023_233', 'te_Sup_Sup_t00000000_24123_233', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"}]', '364534214145411', 1, 'Y', '2024-01-23 02:00:37', '0000-00-00 00:00:00', 0),
(699, 46, 'tmplt_Sup_Sup_023_233', 'te_Sup_Sup_t00000000_24123_233', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"}]', '364534214145411', 1, 'Y', '2024-01-23 02:00:37', '0000-00-00 00:00:00', 0),
(700, 14, 'tmplt_Sup_Sup_023_234', 'te_Sup_Sup_t00000000_24123_234', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING*message*TESTING<br>*message*\"}]', '772685215523426', 1, 'Y', '2024-01-23 02:00:59', '0000-00-00 00:00:00', 0),
(701, 17, 'tmplt_Sup_Sup_023_234', 'te_Sup_Sup_t00000000_24123_234', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING*message*TESTING<br>*message*\"}]', '772685215523426', 1, 'Y', '2024-01-23 02:00:59', '0000-00-00 00:00:00', 0),
(702, 46, 'tmplt_Sup_Sup_023_234', 'te_Sup_Sup_t00000000_24123_234', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING*message*TESTING<br>*message*\"}]', '772685215523426', 1, 'Y', '2024-01-23 02:00:59', '0000-00-00 00:00:00', 0),
(703, 14, 'tmplt_Sup_Sup_023_235', 'te_Sup_Sup_t00000000_24123_235', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING*message*TESTING<br>*message*\"}]', '63168474486719', 1, 'Y', '2024-01-23 02:01:41', '0000-00-00 00:00:00', 0),
(704, 17, 'tmplt_Sup_Sup_023_235', 'te_Sup_Sup_t00000000_24123_235', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING*message*TESTING<br>*message*\"}]', '63168474486719', 1, 'Y', '2024-01-23 02:01:41', '0000-00-00 00:00:00', 0),
(705, 46, 'tmplt_Sup_Sup_023_235', 'te_Sup_Sup_t00000000_24123_235', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING*message*TESTING<br>*message*\"}]', '63168474486719', 1, 'Y', '2024-01-23 02:01:41', '0000-00-00 00:00:00', 0),
(706, 14, 'tmplt_Sup_Sup_023_236', 'te_Sup_Sup_t00000000_24123_236', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING*message*TESTING<br>*message*\"}]', '769092500925427', 1, 'Y', '2024-01-23 02:02:19', '0000-00-00 00:00:00', 0),
(707, 17, 'tmplt_Sup_Sup_023_236', 'te_Sup_Sup_t00000000_24123_236', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING*message*TESTING<br>*message*\"}]', '769092500925427', 1, 'Y', '2024-01-23 02:02:19', '0000-00-00 00:00:00', 0),
(708, 46, 'tmplt_Sup_Sup_023_236', 'te_Sup_Sup_t00000000_24123_236', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING*message*TESTING<br>*message*\"}]', '769092500925427', 1, 'Y', '2024-01-23 02:02:19', '0000-00-00 00:00:00', 0),
(709, 14, 'tmplt_Sup_Sup_023_237', 'te_Sup_Sup_t00000000_24123_237', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING*message*TESTING<br>*message*\"}]', '947726079577253', 1, 'Y', '2024-01-23 02:04:19', '0000-00-00 00:00:00', 0),
(710, 17, 'tmplt_Sup_Sup_023_237', 'te_Sup_Sup_t00000000_24123_237', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING*message*TESTING<br>*message*\"}]', '947726079577253', 1, 'Y', '2024-01-23 02:04:19', '0000-00-00 00:00:00', 0),
(711, 46, 'tmplt_Sup_Sup_023_237', 'te_Sup_Sup_t00000000_24123_237', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING*message*TESTING<br>*message*\"}]', '947726079577253', 1, 'Y', '2024-01-23 02:04:19', '0000-00-00 00:00:00', 0),
(712, 14, 'tmplt_Sup_Sup_023_238', 'te_Sup_Sup_t00000000_24123_238', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING\"}]', '116186722343193', 1, 'Y', '2024-01-23 02:08:38', '0000-00-00 00:00:00', 0),
(713, 17, 'tmplt_Sup_Sup_023_238', 'te_Sup_Sup_t00000000_24123_238', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING\"}]', '116186722343193', 1, 'Y', '2024-01-23 02:08:38', '0000-00-00 00:00:00', 0),
(714, 46, 'tmplt_Sup_Sup_023_238', 'te_Sup_Sup_t00000000_24123_238', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING\"}]', '116186722343193', 1, 'Y', '2024-01-23 02:08:38', '0000-00-00 00:00:00', 0),
(715, 14, 'tmplt_Sup_Sup_023_239', 'te_Sup_Sup_t00000000_24123_239', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>message\"}]', '953827034894508', 1, 'Y', '2024-01-23 02:08:52', '0000-00-00 00:00:00', 0),
(716, 17, 'tmplt_Sup_Sup_023_239', 'te_Sup_Sup_t00000000_24123_239', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>message\"}]', '953827034894508', 1, 'Y', '2024-01-23 02:08:52', '0000-00-00 00:00:00', 0),
(717, 46, 'tmplt_Sup_Sup_023_239', 'te_Sup_Sup_t00000000_24123_239', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>message\"}]', '953827034894508', 1, 'Y', '2024-01-23 02:08:52', '0000-00-00 00:00:00', 0),
(718, 14, 'tmplt_Sup_Sup_023_240', 'te_Sup_Sup_t00000000_24123_240', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*\"}]', '860982654101562', 1, 'Y', '2024-01-23 02:09:17', '0000-00-00 00:00:00', 0);
INSERT INTO `message_template` (`template_id`, `sender_master_id`, `unique_template_id`, `template_name`, `language_id`, `template_category`, `template_message`, `template_response_id`, `created_user`, `template_status`, `template_entdate`, `approve_date`, `body_variable_count`) VALUES
(719, 17, 'tmplt_Sup_Sup_023_240', 'te_Sup_Sup_t00000000_24123_240', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*\"}]', '860982654101562', 1, 'Y', '2024-01-23 02:09:17', '0000-00-00 00:00:00', 0),
(720, 46, 'tmplt_Sup_Sup_023_240', 'te_Sup_Sup_t00000000_24123_240', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*\"}]', '860982654101562', 1, 'Y', '2024-01-23 02:09:17', '0000-00-00 00:00:00', 0),
(721, 14, 'tmplt_Sup_Sup_023_241', 'te_Sup_Sup_t00000000_24123_241', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*<br>*WELOCome*<br>*mesasge*\"}]', '473746305017604', 1, 'Y', '2024-01-23 02:09:39', '0000-00-00 00:00:00', 0),
(722, 17, 'tmplt_Sup_Sup_023_241', 'te_Sup_Sup_t00000000_24123_241', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*<br>*WELOCome*<br>*mesasge*\"}]', '473746305017604', 1, 'Y', '2024-01-23 02:09:39', '0000-00-00 00:00:00', 0),
(723, 46, 'tmplt_Sup_Sup_023_241', 'te_Sup_Sup_t00000000_24123_241', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*<br>*WELOCome*<br>*mesasge*\"}]', '473746305017604', 1, 'Y', '2024-01-23 02:09:39', '0000-00-00 00:00:00', 0),
(724, 14, 'tmplt_Sup_Sup_023_242', 'te_Sup_Sup_t00000000_24123_242', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*<br>*WELOCome*<br>mesasge\"}]', '520551208342349', 1, 'Y', '2024-01-23 02:10:11', '0000-00-00 00:00:00', 0),
(725, 17, 'tmplt_Sup_Sup_023_242', 'te_Sup_Sup_t00000000_24123_242', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*<br>*WELOCome*<br>mesasge\"}]', '520551208342349', 1, 'Y', '2024-01-23 02:10:11', '0000-00-00 00:00:00', 0),
(726, 46, 'tmplt_Sup_Sup_023_242', 'te_Sup_Sup_t00000000_24123_242', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*<br>*WELOCome*<br>mesasge\"}]', '520551208342349', 1, 'Y', '2024-01-23 02:10:11', '0000-00-00 00:00:00', 0),
(727, 14, 'tmplt_Sup_Sup_023_243', 'te_Sup_Sup_t00000u00_24123_243', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*<br>*WELOCome*<br>mesasge<br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE</a><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '187193619026961', 1, 'Y', '2024-01-23 02:11:01', '0000-00-00 00:00:00', 0),
(728, 17, 'tmplt_Sup_Sup_023_243', 'te_Sup_Sup_t00000u00_24123_243', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*<br>*WELOCome*<br>mesasge<br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE</a><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '187193619026961', 1, 'Y', '2024-01-23 02:11:01', '0000-00-00 00:00:00', 0),
(729, 46, 'tmplt_Sup_Sup_023_243', 'te_Sup_Sup_t00000u00_24123_243', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*<br>*WELOCome*<br>mesasge<br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE</a><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '187193619026961', 1, 'Y', '2024-01-23 02:11:01', '0000-00-00 00:00:00', 0),
(730, 14, 'tmplt_Sup_Sup_023_244', 'te_Sup_Sup_t00000u00_24123_244', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*<br>*WELOCome*<br>mesasge<br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE</a><br>*WELCOME*<br>*WELOCome*<br>mesasge<br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE<br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '601125350620831', 1, 'Y', '2024-01-23 02:14:12', '0000-00-00 00:00:00', 0),
(731, 17, 'tmplt_Sup_Sup_023_244', 'te_Sup_Sup_t00000u00_24123_244', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*<br>*WELOCome*<br>mesasge<br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE</a><br>*WELCOME*<br>*WELOCome*<br>mesasge<br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE<br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '601125350620831', 1, 'Y', '2024-01-23 02:14:12', '0000-00-00 00:00:00', 0),
(732, 46, 'tmplt_Sup_Sup_023_244', 'te_Sup_Sup_t00000u00_24123_244', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*<br>*WELOCome*<br>mesasge<br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE</a><br>*WELCOME*<br>*WELOCome*<br>mesasge<br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE<br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '601125350620831', 1, 'Y', '2024-01-23 02:14:12', '0000-00-00 00:00:00', 0),
(733, 14, 'tmplt_Sup_Sup_023_245', 'te_Sup_Sup_t00000u00_24123_245', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*<br>*WELOCome*<br>mesasge<br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE<br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '339877864046912', 1, 'Y', '2024-01-23 02:15:39', '0000-00-00 00:00:00', 0),
(734, 17, 'tmplt_Sup_Sup_023_245', 'te_Sup_Sup_t00000u00_24123_245', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*<br>*WELOCome*<br>mesasge<br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE<br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '339877864046912', 1, 'Y', '2024-01-23 02:15:39', '0000-00-00 00:00:00', 0),
(735, 46, 'tmplt_Sup_Sup_023_245', 'te_Sup_Sup_t00000u00_24123_245', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME*<br>*WELOCome*<br>mesasge<br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE<br><a href=\"http://www.google.com\" target=\"_blank\">GOOGLE\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '339877864046912', 1, 'Y', '2024-01-23 02:15:39', '0000-00-00 00:00:00', 0),
(736, 14, 'tmplt_Sup_Sup_023_246', 'te_Sup_Sup_t00000u00_24123_246', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME**WELOCome*mesasge<a href=\"http://www.google.com\" target=\"_blank\">GOOGLE</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '940147121497712', 1, 'Y', '2024-01-23 02:18:08', '0000-00-00 00:00:00', 0),
(737, 17, 'tmplt_Sup_Sup_023_246', 'te_Sup_Sup_t00000u00_24123_246', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME**WELOCome*mesasge<a href=\"http://www.google.com\" target=\"_blank\">GOOGLE</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '940147121497712', 1, 'Y', '2024-01-23 02:18:08', '0000-00-00 00:00:00', 0),
(738, 46, 'tmplt_Sup_Sup_023_246', 'te_Sup_Sup_t00000u00_24123_246', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*WELCOME**WELOCome*mesasge<a href=\"http://www.google.com\" target=\"_blank\">GOOGLE</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"GOOGLE\",\"url\":\"http://www.google.com\"}]}]', '940147121497712', 1, 'Y', '2024-01-23 02:18:08', '0000-00-00 00:00:00', 0),
(739, 14, 'tmplt_Sup_Sup_023_247', 'te_Sup_Sup_t00000000_24123_247', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '370954405121142', 1, 'Y', '2024-01-23 02:19:25', '0000-00-00 00:00:00', 0),
(740, 17, 'tmplt_Sup_Sup_023_247', 'te_Sup_Sup_t00000000_24123_247', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '370954405121142', 1, 'Y', '2024-01-23 02:19:25', '0000-00-00 00:00:00', 0),
(741, 46, 'tmplt_Sup_Sup_023_247', 'te_Sup_Sup_t00000000_24123_247', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '370954405121142', 1, 'Y', '2024-01-23 02:19:25', '0000-00-00 00:00:00', 0),
(742, 14, 'tmplt_Sup_Sup_023_248', 'te_Sup_Sup_t00000000_24123_248', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>message<br>welcome\"}]', '480106791904378', 1, 'Y', '2024-01-23 02:19:43', '0000-00-00 00:00:00', 0),
(743, 17, 'tmplt_Sup_Sup_023_248', 'te_Sup_Sup_t00000000_24123_248', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>message<br>welcome\"}]', '480106791904378', 1, 'Y', '2024-01-23 02:19:44', '0000-00-00 00:00:00', 0),
(744, 46, 'tmplt_Sup_Sup_023_248', 'te_Sup_Sup_t00000000_24123_248', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>message<br>welcome\"}]', '480106791904378', 1, 'Y', '2024-01-23 02:19:44', '0000-00-00 00:00:00', 0),
(745, 14, 'tmplt_Sup_Sup_023_249', 'te_Sup_Sup_t00000000_24123_249', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>message<br>*welcome*\"}]', '178203440843929', 1, 'Y', '2024-01-23 02:19:56', '0000-00-00 00:00:00', 0),
(746, 17, 'tmplt_Sup_Sup_023_249', 'te_Sup_Sup_t00000000_24123_249', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>message<br>*welcome*\"}]', '178203440843929', 1, 'Y', '2024-01-23 02:19:56', '0000-00-00 00:00:00', 0),
(747, 46, 'tmplt_Sup_Sup_023_249', 'te_Sup_Sup_t00000000_24123_249', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>message<br>*welcome*\"}]', '178203440843929', 1, 'Y', '2024-01-23 02:19:56', '0000-00-00 00:00:00', 0),
(748, 14, 'tmplt_Sup_Sup_023_250', 'te_Sup_Sup_t00000000_24123_250', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*\"}]', '600014153268593', 1, 'Y', '2024-01-23 02:20:19', '0000-00-00 00:00:00', 0),
(749, 17, 'tmplt_Sup_Sup_023_250', 'te_Sup_Sup_t00000000_24123_250', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*\"}]', '600014153268593', 1, 'Y', '2024-01-23 02:20:19', '0000-00-00 00:00:00', 0),
(750, 46, 'tmplt_Sup_Sup_023_250', 'te_Sup_Sup_t00000000_24123_250', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*\"}]', '600014153268593', 1, 'Y', '2024-01-23 02:20:19', '0000-00-00 00:00:00', 0),
(751, 14, 'tmplt_Sup_Sup_023_251', 'te_Sup_Sup_t00000000_24123_251', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br>welcome\"}]', '608327044872613', 1, 'Y', '2024-01-23 02:20:51', '0000-00-00 00:00:00', 0),
(752, 17, 'tmplt_Sup_Sup_023_251', 'te_Sup_Sup_t00000000_24123_251', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br>welcome\"}]', '608327044872613', 1, 'Y', '2024-01-23 02:20:51', '0000-00-00 00:00:00', 0),
(753, 46, 'tmplt_Sup_Sup_023_251', 'te_Sup_Sup_t00000000_24123_251', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br>welcome\"}]', '608327044872613', 1, 'Y', '2024-01-23 02:20:51', '0000-00-00 00:00:00', 0),
(754, 14, 'tmplt_Sup_Sup_023_252', 'te_Sup_Sup_t00000000_24123_252', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br>welcome\"}]', '922565690945999', 1, 'Y', '2024-01-23 02:43:04', '0000-00-00 00:00:00', 0),
(755, 17, 'tmplt_Sup_Sup_023_252', 'te_Sup_Sup_t00000000_24123_252', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br>welcome\"}]', '922565690945999', 1, 'Y', '2024-01-23 02:43:04', '0000-00-00 00:00:00', 0),
(756, 46, 'tmplt_Sup_Sup_023_252', 'te_Sup_Sup_t00000000_24123_252', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br>welcome\"}]', '922565690945999', 1, 'Y', '2024-01-23 02:43:04', '0000-00-00 00:00:00', 0),
(757, 14, 'tmplt_Sup_Sup_023_253', 'te_Sup_Sup_t00000u00_24123_253', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<a href=\"http://www.google.com\" target=\"_blank\">welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '677257769377331', 1, 'Y', '2024-01-23 02:43:42', '0000-00-00 00:00:00', 0),
(758, 17, 'tmplt_Sup_Sup_023_253', 'te_Sup_Sup_t00000u00_24123_253', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<a href=\"http://www.google.com\" target=\"_blank\">welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '677257769377331', 1, 'Y', '2024-01-23 02:43:42', '0000-00-00 00:00:00', 0),
(759, 46, 'tmplt_Sup_Sup_023_253', 'te_Sup_Sup_t00000u00_24123_253', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<a href=\"http://www.google.com\" target=\"_blank\">welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '677257769377331', 1, 'Y', '2024-01-23 02:43:42', '0000-00-00 00:00:00', 0),
(760, 14, 'tmplt_Sup_Sup_023_254', 'te_Sup_Sup_t00000u00_24123_254', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<a href=\"http://www.google.com\" target=\"_blank\">welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '680920431776563', 1, 'Y', '2024-01-23 02:44:53', '0000-00-00 00:00:00', 0),
(761, 17, 'tmplt_Sup_Sup_023_254', 'te_Sup_Sup_t00000u00_24123_254', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<a href=\"http://www.google.com\" target=\"_blank\">welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '680920431776563', 1, 'Y', '2024-01-23 02:44:53', '0000-00-00 00:00:00', 0),
(762, 46, 'tmplt_Sup_Sup_023_254', 'te_Sup_Sup_t00000u00_24123_254', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<a href=\"http://www.google.com\" target=\"_blank\">welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '680920431776563', 1, 'Y', '2024-01-23 02:44:53', '0000-00-00 00:00:00', 0),
(763, 14, 'tmplt_Sup_Sup_023_255', 'te_Sup_Sup_t00000u00_24123_255', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<a href=\"http://www.google.com\" target=\"_blank\">welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '446874631224701', 1, 'Y', '2024-01-23 02:45:28', '0000-00-00 00:00:00', 0),
(764, 17, 'tmplt_Sup_Sup_023_255', 'te_Sup_Sup_t00000u00_24123_255', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<a href=\"http://www.google.com\" target=\"_blank\">welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '446874631224701', 1, 'Y', '2024-01-23 02:45:28', '0000-00-00 00:00:00', 0),
(765, 46, 'tmplt_Sup_Sup_023_255', 'te_Sup_Sup_t00000u00_24123_255', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<a href=\"http://www.google.com\" target=\"_blank\">welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '446874631224701', 1, 'Y', '2024-01-23 02:45:28', '0000-00-00 00:00:00', 0),
(766, 14, 'tmplt_Sup_Sup_023_256', 'te_Sup_Sup_t00000u00_24123_256', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<a href=\"http://www.google.com\" target=\"_blank\">welcome</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '742957009239872', 1, 'Y', '2024-01-23 02:47:54', '0000-00-00 00:00:00', 0),
(767, 17, 'tmplt_Sup_Sup_023_256', 'te_Sup_Sup_t00000u00_24123_256', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<a href=\"http://www.google.com\" target=\"_blank\">welcome</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '742957009239872', 1, 'Y', '2024-01-23 02:47:54', '0000-00-00 00:00:00', 0),
(768, 46, 'tmplt_Sup_Sup_023_256', 'te_Sup_Sup_t00000u00_24123_256', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<a href=\"http://www.google.com\" target=\"_blank\">welcome</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '742957009239872', 1, 'Y', '2024-01-23 02:47:54', '0000-00-00 00:00:00', 0),
(769, 14, 'tmplt_Sup_Sup_023_257', 'te_Sup_Sup_t00000u00_24123_257', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<a href=\"http://www.google.com\" target=\"_blank\">welcome</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '279650624844827', 1, 'Y', '2024-01-23 02:50:18', '0000-00-00 00:00:00', 0),
(770, 17, 'tmplt_Sup_Sup_023_257', 'te_Sup_Sup_t00000u00_24123_257', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<a href=\"http://www.google.com\" target=\"_blank\">welcome</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '279650624844827', 1, 'Y', '2024-01-23 02:50:18', '0000-00-00 00:00:00', 0),
(771, 46, 'tmplt_Sup_Sup_023_257', 'te_Sup_Sup_t00000u00_24123_257', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"<a href=\"http://www.google.com\" target=\"_blank\">welcome</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '279650624844827', 1, 'Y', '2024-01-23 02:50:18', '0000-00-00 00:00:00', 0),
(772, 14, 'tmplt_Sup_Sup_023_258', 'te_Sup_Sup_t00000u00_24123_258', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br><a href=\"http://www.google.com\" target=\"_blank\">welcome</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '392566919036026', 1, 'Y', '2024-01-23 02:56:48', '0000-00-00 00:00:00', 0),
(773, 17, 'tmplt_Sup_Sup_023_258', 'te_Sup_Sup_t00000u00_24123_258', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br><a href=\"http://www.google.com\" target=\"_blank\">welcome</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '392566919036026', 1, 'Y', '2024-01-23 02:56:48', '0000-00-00 00:00:00', 0),
(774, 46, 'tmplt_Sup_Sup_023_258', 'te_Sup_Sup_t00000u00_24123_258', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br><a href=\"http://www.google.com\" target=\"_blank\">welcome</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '392566919036026', 1, 'Y', '2024-01-23 02:56:48', '0000-00-00 00:00:00', 0),
(775, 14, 'tmplt_Sup_Sup_023_259', 'te_Sup_Sup_t00000u00_24123_259', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br><a href=\"http://www.google.com\" target=\"_blank\">welcome</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '562342719609910', 1, 'Y', '2024-01-23 03:05:10', '0000-00-00 00:00:00', 0),
(776, 17, 'tmplt_Sup_Sup_023_259', 'te_Sup_Sup_t00000u00_24123_259', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br><a href=\"http://www.google.com\" target=\"_blank\">welcome</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '562342719609910', 1, 'Y', '2024-01-23 03:05:10', '0000-00-00 00:00:00', 0),
(777, 46, 'tmplt_Sup_Sup_023_259', 'te_Sup_Sup_t00000u00_24123_259', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br><a href=\"http://www.google.com\" target=\"_blank\">welcome</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '562342719609910', 1, 'Y', '2024-01-23 03:05:10', '0000-00-00 00:00:00', 0),
(778, 14, 'tmplt_Sup_Sup_023_260', 'te_Sup_Sup_t00000u00_24123_260', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br><a href=\"http://www.google.com\" target=\"_blank\">welcome</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '605466401923677', 1, 'Y', '2024-01-23 03:06:18', '0000-00-00 00:00:00', 0),
(779, 17, 'tmplt_Sup_Sup_023_260', 'te_Sup_Sup_t00000u00_24123_260', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br><a href=\"http://www.google.com\" target=\"_blank\">welcome</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '605466401923677', 1, 'Y', '2024-01-23 03:06:18', '0000-00-00 00:00:00', 0),
(780, 46, 'tmplt_Sup_Sup_023_260', 'te_Sup_Sup_t00000u00_24123_260', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br><a href=\"http://www.google.com\" target=\"_blank\">welcome</a>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '605466401923677', 1, 'Y', '2024-01-23 03:06:18', '0000-00-00 00:00:00', 0),
(781, 14, 'tmplt_Sup_Sup_023_261', 'te_Sup_Sup_t00000u00_24123_261', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br><a href=\"http://www.google.com\" target=\"_blank\">welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '99156038779788', 1, 'Y', '2024-01-23 03:07:33', '0000-00-00 00:00:00', 0),
(782, 17, 'tmplt_Sup_Sup_023_261', 'te_Sup_Sup_t00000u00_24123_261', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br><a href=\"http://www.google.com\" target=\"_blank\">welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '99156038779788', 1, 'Y', '2024-01-23 03:07:33', '0000-00-00 00:00:00', 0),
(783, 46, 'tmplt_Sup_Sup_023_261', 'te_Sup_Sup_t00000u00_24123_261', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br><a href=\"http://www.google.com\" target=\"_blank\">welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '99156038779788', 1, 'Y', '2024-01-23 03:07:33', '0000-00-00 00:00:00', 0),
(784, 14, 'tmplt_Sup_Sup_023_262', 'te_Sup_Sup_t00000u00_24123_262', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br>welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '28684363030253', 1, 'Y', '2024-01-23 03:09:16', '0000-00-00 00:00:00', 0),
(785, 17, 'tmplt_Sup_Sup_023_262', 'te_Sup_Sup_t00000u00_24123_262', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br>welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '28684363030253', 1, 'Y', '2024-01-23 03:09:16', '0000-00-00 00:00:00', 0),
(786, 46, 'tmplt_Sup_Sup_023_262', 'te_Sup_Sup_t00000u00_24123_262', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>*welcomewelcome*<br>welcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '28684363030253', 1, 'Y', '2024-01-23 03:09:16', '0000-00-00 00:00:00', 0),
(787, 14, 'tmplt_Sup_Sup_023_263', 'te_Sup_Sup_t00000u00_24123_263', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>**<br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '130945353839154', 1, 'Y', '2024-01-23 03:11:44', '0000-00-00 00:00:00', 0),
(788, 17, 'tmplt_Sup_Sup_023_263', 'te_Sup_Sup_t00000u00_24123_263', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>**<br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '130945353839154', 1, 'Y', '2024-01-23 03:11:44', '0000-00-00 00:00:00', 0),
(789, 46, 'tmplt_Sup_Sup_023_263', 'te_Sup_Sup_t00000u00_24123_263', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*testing*<br>*message*<br>**<br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '130945353839154', 1, 'Y', '2024-01-23 03:11:44', '0000-00-00 00:00:00', 0),
(790, 14, 'tmplt_Sup_Sup_023_264', 'te_Sup_Sup_t00000u00_24123_264', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>message<br><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '366139006419921', 1, 'Y', '2024-01-23 03:13:11', '0000-00-00 00:00:00', 0),
(791, 17, 'tmplt_Sup_Sup_023_264', 'te_Sup_Sup_t00000u00_24123_264', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>message<br><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '366139006419921', 1, 'Y', '2024-01-23 03:13:11', '0000-00-00 00:00:00', 0),
(792, 46, 'tmplt_Sup_Sup_023_264', 'te_Sup_Sup_t00000u00_24123_264', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>message<br><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com/\"}]}]', '366139006419921', 1, 'Y', '2024-01-23 03:13:11', '0000-00-00 00:00:00', 0),
(793, 14, 'tmplt_Sup_Sup_023_265', 'te_Sup_Sup_t00000000_24123_265', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '315031207308568', 1, 'Y', '2024-01-23 03:15:56', '0000-00-00 00:00:00', 0),
(794, 17, 'tmplt_Sup_Sup_023_265', 'te_Sup_Sup_t00000000_24123_265', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '315031207308568', 1, 'Y', '2024-01-23 03:15:56', '0000-00-00 00:00:00', 0),
(795, 46, 'tmplt_Sup_Sup_023_265', 'te_Sup_Sup_t00000000_24123_265', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '315031207308568', 1, 'Y', '2024-01-23 03:15:56', '0000-00-00 00:00:00', 0),
(796, 14, 'tmplt_Sup_Sup_023_266', 'te_Sup_Sup_t00000000_24123_266', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>welcome\"}]', '644436962224996', 1, 'Y', '2024-01-23 03:16:07', '0000-00-00 00:00:00', 0),
(797, 17, 'tmplt_Sup_Sup_023_266', 'te_Sup_Sup_t00000000_24123_266', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>welcome\"}]', '644436962224996', 1, 'Y', '2024-01-23 03:16:07', '0000-00-00 00:00:00', 0),
(798, 46, 'tmplt_Sup_Sup_023_266', 'te_Sup_Sup_t00000000_24123_266', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>welcome\"}]', '644436962224996', 1, 'Y', '2024-01-23 03:16:07', '0000-00-00 00:00:00', 0),
(799, 14, 'tmplt_Sup_Sup_023_267', 'te_Sup_Sup_t00000000_24123_267', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"}]', '94955288284854', 1, 'Y', '2024-01-23 03:16:28', '0000-00-00 00:00:00', 0),
(800, 17, 'tmplt_Sup_Sup_023_267', 'te_Sup_Sup_t00000000_24123_267', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"}]', '94955288284854', 1, 'Y', '2024-01-23 03:16:28', '0000-00-00 00:00:00', 0),
(801, 46, 'tmplt_Sup_Sup_023_267', 'te_Sup_Sup_t00000000_24123_267', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*\"}]', '94955288284854', 1, 'Y', '2024-01-23 03:16:28', '0000-00-00 00:00:00', 0),
(802, 14, 'tmplt_Sup_Sup_023_268', 'te_Sup_Sup_t00000000_24123_268', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*<br>*mESSAFE*\"}]', '627605976909382', 1, 'Y', '2024-01-23 03:16:41', '0000-00-00 00:00:00', 0),
(803, 17, 'tmplt_Sup_Sup_023_268', 'te_Sup_Sup_t00000000_24123_268', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*<br>*mESSAFE*\"}]', '627605976909382', 1, 'Y', '2024-01-23 03:16:41', '0000-00-00 00:00:00', 0),
(804, 46, 'tmplt_Sup_Sup_023_268', 'te_Sup_Sup_t00000000_24123_268', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*<br>*mESSAFE*\"}]', '627605976909382', 1, 'Y', '2024-01-23 03:16:41', '0000-00-00 00:00:00', 0),
(805, 14, 'tmplt_Sup_Sup_023_269', 'te_Sup_Sup_t00000u00_24123_269', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*<br>*mESSAFE*<br>**\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '225192238317400', 1, 'Y', '2024-01-23 03:17:18', '0000-00-00 00:00:00', 0),
(806, 17, 'tmplt_Sup_Sup_023_269', 'te_Sup_Sup_t00000u00_24123_269', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*<br>*mESSAFE*<br>**\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '225192238317400', 1, 'Y', '2024-01-23 03:17:18', '0000-00-00 00:00:00', 0),
(807, 46, 'tmplt_Sup_Sup_023_269', 'te_Sup_Sup_t00000u00_24123_269', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"*TESTING*<br>*mESSAFE*<br>**\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"welcome\",\"url\":\"http://www.google.com\"}]}]', '225192238317400', 1, 'Y', '2024-01-23 03:17:18', '0000-00-00 00:00:00', 0),
(808, 14, 'tmplt_Sup_Sup_023_270', 'te_Sup_Sup_t00000000_24123_270', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TestingTesting\"}]', '71611684971155', 1, 'Y', '2024-01-23 03:20:31', '0000-00-00 00:00:00', 0),
(809, 17, 'tmplt_Sup_Sup_023_270', 'te_Sup_Sup_t00000000_24123_270', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TestingTesting\"}]', '71611684971155', 1, 'Y', '2024-01-23 03:20:31', '0000-00-00 00:00:00', 0),
(810, 46, 'tmplt_Sup_Sup_023_270', 'te_Sup_Sup_t00000000_24123_270', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TestingTesting\"}]', '71611684971155', 1, 'Y', '2024-01-23 03:20:31', '0000-00-00 00:00:00', 0),
(811, 14, 'tmplt_Sup_Sup_023_271', 'te_Sup_Sup_t00000000_24123_271', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"tetsingtetsing\"}]', '68283455880273', 1, 'Y', '2024-01-23 03:21:29', '0000-00-00 00:00:00', 0),
(812, 17, 'tmplt_Sup_Sup_023_271', 'te_Sup_Sup_t00000000_24123_271', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"tetsingtetsing\"}]', '68283455880273', 1, 'Y', '2024-01-23 03:21:29', '0000-00-00 00:00:00', 0),
(813, 46, 'tmplt_Sup_Sup_023_271', 'te_Sup_Sup_t00000000_24123_271', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"tetsingtetsing\"}]', '68283455880273', 1, 'Y', '2024-01-23 03:21:29', '0000-00-00 00:00:00', 0),
(814, 14, 'tmplt_Sup_Sup_023_272', 'te_Sup_Sup_t00000000_24123_272', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"tetsing\"}]', '82675103713502', 1, 'Y', '2024-01-23 03:21:57', '0000-00-00 00:00:00', 0),
(815, 17, 'tmplt_Sup_Sup_023_272', 'te_Sup_Sup_t00000000_24123_272', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"tetsing\"}]', '82675103713502', 1, 'Y', '2024-01-23 03:21:57', '0000-00-00 00:00:00', 0),
(816, 46, 'tmplt_Sup_Sup_023_272', 'te_Sup_Sup_t00000000_24123_272', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"tetsing\"}]', '82675103713502', 1, 'Y', '2024-01-23 03:21:57', '0000-00-00 00:00:00', 0),
(817, 14, 'tmplt_Sup_Sup_023_273', 'te_Sup_Sup_t00000000_24123_273', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"tetsing\"}]', '951328435010073', 1, 'Y', '2024-01-23 03:22:17', '0000-00-00 00:00:00', 0),
(818, 17, 'tmplt_Sup_Sup_023_273', 'te_Sup_Sup_t00000000_24123_273', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"tetsing\"}]', '951328435010073', 1, 'Y', '2024-01-23 03:22:17', '0000-00-00 00:00:00', 0),
(819, 46, 'tmplt_Sup_Sup_023_273', 'te_Sup_Sup_t00000000_24123_273', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"tetsing\"}]', '951328435010073', 1, 'Y', '2024-01-23 03:22:17', '0000-00-00 00:00:00', 0),
(820, 14, 'tmplt_Sup_Sup_023_274', 'te_Sup_Sup_t00000000_24123_274', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"WElcomehave a nice day\"}]', '351204138699343', 1, 'Y', '2024-01-23 03:22:43', '0000-00-00 00:00:00', 0),
(821, 17, 'tmplt_Sup_Sup_023_274', 'te_Sup_Sup_t00000000_24123_274', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"WElcomehave a nice day\"}]', '351204138699343', 1, 'Y', '2024-01-23 03:22:43', '0000-00-00 00:00:00', 0),
(822, 46, 'tmplt_Sup_Sup_023_274', 'te_Sup_Sup_t00000000_24123_274', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"WElcomehave a nice day\"}]', '351204138699343', 1, 'Y', '2024-01-23 03:22:43', '0000-00-00 00:00:00', 0),
(823, 14, 'tmplt_Sup_Sup_023_275', 'te_Sup_Sup_t00000000_24123_275', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING\"}]', '280529889424671', 1, 'Y', '2024-01-23 03:23:25', '0000-00-00 00:00:00', 0),
(824, 17, 'tmplt_Sup_Sup_023_275', 'te_Sup_Sup_t00000000_24123_275', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING\"}]', '280529889424671', 1, 'Y', '2024-01-23 03:23:25', '0000-00-00 00:00:00', 0),
(825, 46, 'tmplt_Sup_Sup_023_275', 'te_Sup_Sup_t00000000_24123_275', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING\"}]', '280529889424671', 1, 'Y', '2024-01-23 03:23:25', '0000-00-00 00:00:00', 0),
(826, 14, 'tmplt_Sup_Sup_023_276', 'te_Sup_Sup_t00000000_24123_276', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcomeyeejia\"}]', '987077661971341', 1, 'Y', '2024-01-23 03:23:45', '0000-00-00 00:00:00', 0),
(827, 17, 'tmplt_Sup_Sup_023_276', 'te_Sup_Sup_t00000000_24123_276', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcomeyeejia\"}]', '987077661971341', 1, 'Y', '2024-01-23 03:23:45', '0000-00-00 00:00:00', 0),
(828, 46, 'tmplt_Sup_Sup_023_276', 'te_Sup_Sup_t00000000_24123_276', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"welcomeyeejia\"}]', '987077661971341', 1, 'Y', '2024-01-23 03:23:45', '0000-00-00 00:00:00', 0),
(829, 14, 'tmplt_Sup_Sup_023_277', 'te_Sup_Sup_t00000000_24123_277', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '330685141597256', 1, 'Y', '2024-01-23 03:32:28', '0000-00-00 00:00:00', 0),
(830, 17, 'tmplt_Sup_Sup_023_277', 'te_Sup_Sup_t00000000_24123_277', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '330685141597256', 1, 'Y', '2024-01-23 03:32:28', '0000-00-00 00:00:00', 0),
(831, 46, 'tmplt_Sup_Sup_023_277', 'te_Sup_Sup_t00000000_24123_277', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing\"}]', '330685141597256', 1, 'Y', '2024-01-23 03:32:28', '0000-00-00 00:00:00', 0),
(832, 14, 'tmplt_Sup_Sup_023_278', 'te_Sup_Sup_t00000000_24123_278', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"tetsing<br>welcome\"}]', '169727022724760', 1, 'Y', '2024-01-23 03:32:48', '0000-00-00 00:00:00', 0),
(833, 17, 'tmplt_Sup_Sup_023_278', 'te_Sup_Sup_t00000000_24123_278', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"tetsing<br>welcome\"}]', '169727022724760', 1, 'Y', '2024-01-23 03:32:48', '0000-00-00 00:00:00', 0),
(834, 46, 'tmplt_Sup_Sup_023_278', 'te_Sup_Sup_t00000000_24123_278', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"tetsing<br>welcome\"}]', '169727022724760', 1, 'Y', '2024-01-23 03:32:48', '0000-00-00 00:00:00', 0),
(835, 14, 'tmplt_Sup_Sup_023_279', 'te_Sup_Sup_t00000000_24123_279', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>welocme<br>*yeejai*\"}]', '343945587582327', 1, 'Y', '2024-01-23 03:33:19', '0000-00-00 00:00:00', 0),
(836, 17, 'tmplt_Sup_Sup_023_279', 'te_Sup_Sup_t00000000_24123_279', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>welocme<br>*yeejai*\"}]', '343945587582327', 1, 'Y', '2024-01-23 03:33:19', '0000-00-00 00:00:00', 0),
(837, 46, 'tmplt_Sup_Sup_023_279', 'te_Sup_Sup_t00000000_24123_279', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>welocme<br>*yeejai*\"}]', '343945587582327', 1, 'Y', '2024-01-23 03:33:19', '0000-00-00 00:00:00', 0),
(838, 14, 'tmplt_Sup_Sup_023_280', 'te_Sup_Sup_t00000u00_24123_280', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>have a nice day<br><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://Google\"}]}]', '31928139215742', 1, 'Y', '2024-01-23 03:34:08', '0000-00-00 00:00:00', 0),
(839, 17, 'tmplt_Sup_Sup_023_280', 'te_Sup_Sup_t00000u00_24123_280', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>have a nice day<br><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://Google\"}]}]', '31928139215742', 1, 'Y', '2024-01-23 03:34:08', '0000-00-00 00:00:00', 0),
(840, 46, 'tmplt_Sup_Sup_023_280', 'te_Sup_Sup_t00000u00_24123_280', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>have a nice day<br><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://Google\"}]}]', '31928139215742', 1, 'Y', '2024-01-23 03:34:08', '0000-00-00 00:00:00', 0),
(841, 14, 'tmplt_Sup_Sup_023_281', 'te_Sup_Sup_t00000u00_24123_281', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>have a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '216203986187375', 1, 'Y', '2024-01-23 03:36:21', '0000-00-00 00:00:00', 0),
(842, 17, 'tmplt_Sup_Sup_023_281', 'te_Sup_Sup_t00000u00_24123_281', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>have a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '216203986187375', 1, 'Y', '2024-01-23 03:36:21', '0000-00-00 00:00:00', 0),
(843, 46, 'tmplt_Sup_Sup_023_281', 'te_Sup_Sup_t00000u00_24123_281', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>have a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '216203986187375', 1, 'Y', '2024-01-23 03:36:21', '0000-00-00 00:00:00', 0),
(844, 14, 'tmplt_Sup_Sup_023_282', 'te_Sup_Sup_l00000u00_24123_282', 4, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>*have a nice day*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '389858875727326', 1, 'Y', '2024-01-23 03:36:47', '0000-00-00 00:00:00', 0),
(845, 17, 'tmplt_Sup_Sup_023_282', 'te_Sup_Sup_l00000u00_24123_282', 4, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>*have a nice day*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '389858875727326', 1, 'Y', '2024-01-23 03:36:47', '0000-00-00 00:00:00', 0),
(846, 46, 'tmplt_Sup_Sup_023_282', 'te_Sup_Sup_l00000u00_24123_282', 4, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>*have a nice day*\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '389858875727326', 1, 'Y', '2024-01-23 03:36:47', '0000-00-00 00:00:00', 0),
(847, 14, 'tmplt_Sup_Sup_023_283', 'te_Sup_Sup_t00000u00_24123_283', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>have a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '459169912078673', 1, 'Y', '2024-01-23 03:37:14', '0000-00-00 00:00:00', 0),
(848, 17, 'tmplt_Sup_Sup_023_283', 'te_Sup_Sup_t00000u00_24123_283', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>have a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '459169912078673', 1, 'Y', '2024-01-23 03:37:14', '0000-00-00 00:00:00', 0),
(849, 46, 'tmplt_Sup_Sup_023_283', 'te_Sup_Sup_t00000u00_24123_283', 2, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>have a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '459169912078673', 1, 'Y', '2024-01-23 03:37:14', '0000-00-00 00:00:00', 0),
(850, 14, 'tmplt_Sup_Sup_023_284', 'te_Sup_Sup_t00000u00_24123_284', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testinghave a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '351382541669025', 1, 'Y', '2024-01-23 03:39:38', '0000-00-00 00:00:00', 0),
(851, 17, 'tmplt_Sup_Sup_023_284', 'te_Sup_Sup_t00000u00_24123_284', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testinghave a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '351382541669025', 1, 'Y', '2024-01-23 03:39:38', '0000-00-00 00:00:00', 0),
(852, 46, 'tmplt_Sup_Sup_023_284', 'te_Sup_Sup_t00000u00_24123_284', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testinghave a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '351382541669025', 1, 'Y', '2024-01-23 03:39:38', '0000-00-00 00:00:00', 0),
(853, 14, 'tmplt_Sup_Sup_023_285', 'te_Sup_Sup_t00000u00_24123_285', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testinghave a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '781672523243312', 1, 'Y', '2024-01-23 03:40:55', '0000-00-00 00:00:00', 0),
(854, 17, 'tmplt_Sup_Sup_023_285', 'te_Sup_Sup_t00000u00_24123_285', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testinghave a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '781672523243312', 1, 'Y', '2024-01-23 03:40:55', '0000-00-00 00:00:00', 0),
(855, 46, 'tmplt_Sup_Sup_023_285', 'te_Sup_Sup_t00000u00_24123_285', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testinghave a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '781672523243312', 1, 'Y', '2024-01-23 03:40:55', '0000-00-00 00:00:00', 0),
(856, 14, 'tmplt_Sup_Sup_023_286', 'te_Sup_Sup_t00000u00_24123_286', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>have a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '495250572576564', 1, 'Y', '2024-01-23 03:42:23', '0000-00-00 00:00:00', 0),
(857, 17, 'tmplt_Sup_Sup_023_286', 'te_Sup_Sup_t00000u00_24123_286', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>have a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '495250572576564', 1, 'Y', '2024-01-23 03:42:23', '0000-00-00 00:00:00', 0),
(858, 46, 'tmplt_Sup_Sup_023_286', 'te_Sup_Sup_t00000u00_24123_286', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>have a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '495250572576564', 1, 'Y', '2024-01-23 03:42:23', '0000-00-00 00:00:00', 0),
(859, 14, 'tmplt_Sup_Sup_023_287', 'te_Sup_Sup_t00000u00_24123_287', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>have a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '246101901904788', 1, 'Y', '2024-01-23 03:42:59', '0000-00-00 00:00:00', 0),
(860, 17, 'tmplt_Sup_Sup_023_287', 'te_Sup_Sup_t00000u00_24123_287', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>have a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '246101901904788', 1, 'Y', '2024-01-23 03:42:59', '0000-00-00 00:00:00', 0),
(861, 46, 'tmplt_Sup_Sup_023_287', 'te_Sup_Sup_t00000u00_24123_287', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"testing<br>have a nice day\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://google/\"}]}]', '246101901904788', 1, 'Y', '2024-01-23 03:42:59', '0000-00-00 00:00:00', 0),
(862, 14, 'tmplt_Sup_Sup_023_288', 'te_Sup_Sup_t00000u00_24123_288', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGwelcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://www.google.com\"}]}]', '587142370795076', 1, 'Y', '2024-01-23 03:45:53', '0000-00-00 00:00:00', 0),
(863, 17, 'tmplt_Sup_Sup_023_288', 'te_Sup_Sup_t00000u00_24123_288', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGwelcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://www.google.com\"}]}]', '587142370795076', 1, 'Y', '2024-01-23 03:45:53', '0000-00-00 00:00:00', 0),
(864, 46, 'tmplt_Sup_Sup_023_288', 'te_Sup_Sup_t00000u00_24123_288', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTINGwelcome\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://www.google.com\"}]}]', '587142370795076', 1, 'Y', '2024-01-23 03:45:53', '0000-00-00 00:00:00', 0),
(865, 14, 'tmplt_Sup_Sup_023_289', 'te_Sup_Sup_t00000u00_24123_289', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>welcome<br><br><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://www.google.com\"}]}]', '522987541683076', 1, 'Y', '2024-01-23 03:46:43', '0000-00-00 00:00:00', 0),
(866, 17, 'tmplt_Sup_Sup_023_289', 'te_Sup_Sup_t00000u00_24123_289', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>welcome<br><br><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://www.google.com\"}]}]', '522987541683076', 1, 'Y', '2024-01-23 03:46:43', '0000-00-00 00:00:00', 0),
(867, 46, 'tmplt_Sup_Sup_023_289', 'te_Sup_Sup_t00000u00_24123_289', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"TESTING<br>welcome<br><br><br>\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"URL\",\"text\":\"google\",\"url\":\"http://www.google.com\"}]}]', '522987541683076', 1, 'Y', '2024-01-23 03:46:43', '0000-00-00 00:00:00', 0);

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
(1, 1, 1, 2, 300, 'A', 'msg:Payment successfully credited, status:true, productCode:2, paymentID:pay_NNKBH1rGodKSq0, userEmail', 'Y', '2024-01-11 13:31:24');

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
(1, 2, 1, 200, 196, 4, 30, 29, 1, 600, 600, 0, 'Y', '2024-01-17 12:06:19', '2024-02-11 19:01:48');

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
(5, 'Gold', 'A', 0, 300, 0, 100, 2100, 3000, 'Y', '2023-10-03 00:26:24');

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
(1, 1, '918610110464', NULL, NULL, 'D', '2023-03-01 03:07:51', '2023-03-01 08:08:13'),
(2, 1, '919345450984', NULL, NULL, 'D', '2023-03-01 03:08:32', '2023-03-02 11:08:32'),
(4, 1, '919025181180', NULL, NULL, 'D', '2023-07-05 12:13:20', '0000-00-00 00:00:00'),
(5, 1, '919894606748', NULL, NULL, 'D', '2023-07-06 12:07:07', '0000-00-00 00:00:00'),
(6, 1, '919894606748', NULL, NULL, 'D', '2023-07-06 12:47:14', '0000-00-00 00:00:00'),
(7, 1, '919894606748', NULL, NULL, 'D', '2023-07-07 10:25:02', '0000-00-00 00:00:00'),
(10, 2, '916380885545', NULL, NULL, 'D', '2023-07-08 05:07:56', '0000-00-00 00:00:00'),
(11, 2, '916380885544', NULL, NULL, 'X', '2023-07-26 04:40:59', '0000-00-00 00:00:00'),
(12, 2, '916380885547', NULL, NULL, 'X', '2023-07-26 05:36:53', '0000-00-00 00:00:00'),
(14, 1, '916380885546', 'SHan', 'https://yjtec.in/whatsapp_service/uploads/whatsapp_images/2_16111932.jpg', 'Y', '2023-11-05 14:08:13', '0000-00-00 00:00:00'),
(15, 1, '918838964597', 'Social media', '1_1697202369105.png', 'D', '2023-10-13 12:55:36', '0000-00-00 00:00:00'),
(17, 1, '918567964597', 'Testing', '1_1699367453092.jpg', 'Y', '2023-11-07 14:31:01', '0000-00-00 00:00:00'),
(19, 1, '918838964598', 'TEST', '1_1699442956631.jpg', 'D', '2023-11-08 11:29:26', '0000-00-00 00:00:00'),
(20, 1, '918838964597', 'Demo', '1_1699448614458.jpg', 'D', '2023-11-08 13:03:45', '0000-00-00 00:00:00'),
(21, 1, '919344145033', 'testing_id', '1_1699525083027.jpeg', 'D', '2023-11-09 10:18:14', '0000-00-00 00:00:00'),
(22, 1, '919344145033', 'testing_id', '1_1699525359766.jpeg', 'D', '2023-11-09 10:22:49', '0000-00-00 00:00:00'),
(23, 1, '918838964597', 'testing_id', '1_1699525431526.jpeg', 'D', '2023-11-09 10:24:00', '0000-00-00 00:00:00'),
(24, 1, '919344145033', 'testing', '1_1699525942403.jpeg', 'X', '2023-11-09 10:32:32', '0000-00-00 00:00:00'),
(25, 1, '916380747454', 'testing_id_2 ', '1_1699526840067.jpeg', 'D', '2023-11-09 10:47:30', '0000-00-00 00:00:00'),
(26, 1, '919361419661', 'testing', '1_1699595214266.jpeg', 'N', '2023-11-10 05:47:10', '0000-00-00 00:00:00'),
(27, 2, '919000190001', 'testing_id', '2_1699610623905.jpeg', 'N', '2023-11-10 10:03:55', '0000-00-00 00:00:00'),
(28, 2, '919685748596', 'testing_id', '2_1699610860721.jpeg', 'N', '2023-11-10 10:07:53', '0000-00-00 00:00:00'),
(29, 1, '918838964597', 'Testing', '1_1699624281267.jpg', 'D', '2023-11-10 13:51:36', '0000-00-00 00:00:00'),
(30, 1, '916380747454', 'testing_id3', '1_1699678445457.jpeg', 'X', '2023-11-11 04:54:15', '0000-00-00 00:00:00'),
(31, 2, '919344145021', 'testing_id', '2_1699683196857.jpeg', 'D', '2023-11-11 06:13:28', '0000-00-00 00:00:00'),
(32, 2, '919025167792', 'checking', '2_1699684265191.jpeg', 'D', '2023-11-11 06:31:15', '0000-00-00 00:00:00'),
(33, 2, '919344145221', 'testing_id', '2_1699687779017.jpeg', 'D', '2023-11-11 07:29:54', '0000-00-00 00:00:00'),
(34, 2, '916789589565', 'checking', '2_1699692794768.jpeg', 'D', '2023-11-11 08:53:30', '0000-00-00 00:00:00'),
(35, 2, '916369841530', 'test', '2_1704507907897.png', 'M', '2024-01-06 02:25:18', '0000-00-00 00:00:00'),
(36, 2, '918838964597', 'test', '2_1704535484920.png', 'D', '2024-01-06 10:04:58', '0000-00-00 00:00:00'),
(37, 2, '918734875394', 'profile', '2_1704507907897.png', 'N', '2024-01-06 11:30:11', '0000-00-00 00:00:00'),
(38, 2, '918734856348', 'demo', '2_1704542358997.png', 'N', '2024-01-06 11:59:28', '0000-00-00 00:00:00'),
(39, 2, '918437896789', 'test1', '2_1704542591230.png', 'N', '2024-01-06 12:03:21', '0000-00-00 00:00:00'),
(40, 2, '919344145221', 'testing_id', '2_1699687779017.jpeg', 'N', '2024-01-06 12:57:08', '0000-00-00 00:00:00'),
(41, 1, '918838964597', 'test', '1_1705062949991.png', 'D', '2024-01-12 12:36:01', '0000-00-00 00:00:00'),
(42, 1, '918838964597', 'Profile', 'http://yjtec.in/whatsapp_group_newapi/uploads/whatsapp_images/1_1705067139183.png', 'D', '2024-01-12 13:45:51', '0000-00-00 00:00:00'),
(43, 1, '918838964597', 'YJT', 'http://yjtec.in/whatsapp_group_newapi/uploads/whatsapp_images/1_1705111732195.png', 'D', '2024-01-13 02:09:06', '0000-00-00 00:00:00'),
(44, 1, '918838964597', 'TESTING', 'http://yjtec.in/whatsapp_group_newapi/uploads/whatsapp_images/1_1705112455561.png', 'D', '2024-01-13 02:21:06', '0000-00-00 00:00:00'),
(45, 1, '918838964597', 'START', 'http://yjtec.in/whatsapp_group_newapi/uploads/whatsapp_images/1_1705116097563.png', 'D', '2024-01-13 03:21:49', '0000-00-00 00:00:00'),
(46, 1, '918838964597', 'TEST', 'http://yjtec.in/whatsapp_group_newapi/uploads/whatsapp_images/1_1705122567141.png', 'Y', '2024-01-13 05:09:43', '0000-00-00 00:00:00');

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
  `sender_master_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `unique_template_id` varchar(30) NOT NULL,
  `template_name` varchar(50) NOT NULL,
  `language_id` int(11) NOT NULL,
  `template_category` varchar(30) NOT NULL,
  `template_message` longtext NOT NULL,
  `template_status` char(1) NOT NULL,
  `template_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `approved_user` int(11) DEFAULT NULL,
  `approve_date` timestamp NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `template_master`
--

INSERT INTO `template_master` (`template_master_id`, `sender_master_id`, `user_id`, `unique_template_id`, `template_name`, `language_id`, `template_category`, `template_message`, `template_status`, `template_entry_date`, `approved_user`, `approve_date`) VALUES
(1, 8, 1, 'tmplt_ad1_dhd1_270_446', 'te_ad1_dhd1_t0000cu00_23920_446', 1, 'MARKETING', '[{\"type\":\"BODY\",\"text\":\"Testingg template\"},{\"type\":\"BUTTONS\",\"buttons\":[{\"type\":\"PHONE_NUMBER\",\"text\":\"Call me\",\"phone_number\":\"+916380885546\"},{\"type\":\"URL\",\"text\":\"Visit website\",\"url\":\"https://google.com\"}]}]', 'Y', '2023-09-27 09:40:19', NULL, '0000-00-00 00:00:00');

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
(250, 1, 'undefined', '2024-01-20', '2024-01-20 11:25:49', NULL, 'I', '2024-01-20 11:25:49');

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
(1, 1, 1, 'Super Admin', 'AA1DE999B6B65D2', 'e58a3754522a05c1ff4d231f8e8cc1bd', 'super_admin@gmail.com', '9000090000', 'Y', '2021-12-30 06:22:20', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3MDU3NDk5NDksImV4cCI6MTcwNjM1NDc0OX0.dgeN7c1X8MeCae58UI-D0n_l8kzVpF0bX2_OGDofJgk'),
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
-- Indexes for table `message_template`
--
ALTER TABLE `message_template`
  ADD PRIMARY KEY (`template_id`),
  ADD KEY `user_id` (`sender_master_id`),
  ADD KEY `user_id_2` (`sender_master_id`,`language_id`,`template_category`),
  ADD KEY `whatsapp_config_id` (`sender_master_id`,`language_id`,`created_user`);

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
  ADD KEY `sender_master_id` (`sender_master_id`),
  ADD KEY `language_id` (`language_id`),
  ADD KEY `approved_user` (`approved_user`);

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
  MODIFY `api_log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=531;

--
-- AUTO_INCREMENT for table `group_contacts`
--
ALTER TABLE `group_contacts`
  MODIFY `group_contacts_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT for table `group_master`
--
ALTER TABLE `group_master`
  MODIFY `group_master_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

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
-- AUTO_INCREMENT for table `message_template`
--
ALTER TABLE `message_template`
  MODIFY `template_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=868;

--
-- AUTO_INCREMENT for table `messenger_response`
--
ALTER TABLE `messenger_response`
  MODIFY `message_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payment_history_log`
--
ALTER TABLE `payment_history_log`
  MODIFY `payment_history_logid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `plans_update`
--
ALTER TABLE `plans_update`
  MODIFY `plans_update_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `senderid_master`
--
ALTER TABLE `senderid_master`
  MODIFY `sender_master_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=47;

--
-- AUTO_INCREMENT for table `summary_report`
--
ALTER TABLE `summary_report`
  MODIFY `summary_report_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `template_master`
--
ALTER TABLE `template_master`
  MODIFY `template_master_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `user_log`
--
ALTER TABLE `user_log`
  MODIFY `user_log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=251;

--
-- AUTO_INCREMENT for table `user_management`
--
ALTER TABLE `user_management`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `user_master`
--
ALTER TABLE `user_master`
  MODIFY `user_master_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `user_plans`
--
ALTER TABLE `user_plans`
  MODIFY `user_plans_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
