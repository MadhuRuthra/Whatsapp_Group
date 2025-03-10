-- phpMyAdmin SQL Dump
-- version 4.4.15.10
-- https://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jan 05, 2024 at 11:51 AM
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
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb3;

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
(49, 1, '/logout', 'undefined', '1_20244165821_7403', 'S', 'Success', '2024-01-05 11:28:22', 'Y', '2024-01-05 11:28:21');

-- --------------------------------------------------------

--
-- Table structure for table `group_contacts`
--

CREATE TABLE IF NOT EXISTS `group_contacts` (
  `group_contacts_id` int NOT NULL,
  `user_id` int NOT NULL,
  `group_master_id` int NOT NULL,
  `campaign_name` varchar(30) NOT NULL,
  `mobile_no` varchar(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `mobile_id` varchar(30) DEFAULT NULL,
  `comments` varchar(50) NOT NULL,
  `group_contacts_status` char(1) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `group_contacts_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT;

--
-- Dumping data for table `group_contacts`
--

INSERT INTO `group_contacts` (`group_contacts_id`, `user_id`, `group_master_id`, `campaign_name`, `mobile_no`, `mobile_id`, `comments`, `group_contacts_status`, `group_contacts_entry_date`) VALUES
(4, 2, 2, 'ca_testing_189_4', 'Arun Sir', 'Arun Sir', '', 'Y', '2023-07-08 11:28:29'),
(8, 1, 5, 'ca_test_group_309_8', '919363113380', 'yjtec23_919363113380', '', 'F', '2023-11-05 10:51:43'),
(9, 1, 6, 'ca_test10_group_309_9', 'yjtec23_919363113380', 'yjtec23_919363113380', '', 'Y', '2023-11-05 13:34:43'),
(10, 1, 7, 'ca_sample_grp_309_10', 'yjtec23_919363113380', 'yjtec23_919363113380', '', 'Y', '2023-11-05 13:55:27'),
(11, 1, 7, 'ca_sample_grp_309_11', 'yjtec23_919445603329', 'yjtec23_919445603329', '', 'Y', '2023-11-05 14:29:49'),
(12, 1, 7, 'ca_sample_grp_309_11', 'yjtec23_919445603328', 'yjtec23_919445603328', '', 'Y', '2023-11-05 14:29:49'),
(13, 1, 9, 'ca_hello_group_310_13', '919361419661', '919361419661', '', 'Y', '2023-11-07 14:44:11'),
(14, 1, 9, 'ca_hello_group_310_13', '919363113380', '919363113380', '', 'Y', '2023-11-07 14:44:11'),
(15, 1, 9, 'ca_hello_group_311_15', '919445603329', '919445603329', '', 'Y', '2023-11-07 05:17:43'),
(16, 1, 9, 'ca_hello_group_311_15', '919363113388', '919363113388', '', 'F', '2023-11-07 05:17:43'),
(17, 1, 9, 'ca_hello_group_311_51', '919363113389', '919363113389', '', 'F', '2023-11-07 05:27:13'),
(18, 1, 9, 'ca_hello_group_311_51', '919894606748', '919894606748', '', 'Y', '2023-11-07 05:27:13'),
(19, 1, 9, 'ca_hello_group_311_11', '918838964597', '918838964597', '', 'Y', '2023-11-07 05:40:59'),
(20, 1, 9, 'ca_hello_group_311_11', '917092362325', '917092362325', '', 'F', '2023-11-07 05:40:59'),
(21, 1, 10, 'ca_testing from web_311_111', '918838964597', '918838964597', '', 'Y', '2023-11-07 06:05:57'),
(22, 1, 10, 'ca_testing from web_311_111', '917092362325', '917092362325', '', 'F', '2023-11-07 06:05:58'),
(23, 1, 10, 'ca_testing from web_311_1111', '919361419661', '919361419661', '', 'Y', '2023-11-07 10:26:40'),
(24, 1, 10, 'ca_testing from web_311_1111', '918838964597', '918838964597', '', 'Y', '2023-11-07 10:26:40'),
(25, 1, 10, 'ca_testing from web_311_11111', '919363113380', '919363113380', 'Success', 'Y', '2023-11-07 13:06:00'),
(26, 1, 10, 'ca_testing from web_311_11111', '918838964597', '918838964597', 'Mobile number already in the group', 'F', '2023-11-07 13:06:00'),
(27, 1, 11, 'ca_Test_311_12', '918838964597', '918838964597', 'Success', 'Y', '2023-11-07 14:45:33'),
(28, 1, 11, 'ca_Test_311_12', '919344145033', '919344145033', 'Success', 'Y', '2023-11-07 14:45:34'),
(29, 1, 11, 'ca_Test_311_13', '916380885546', '916380885546', 'Success', 'Y', '2023-11-07 14:53:45'),
(30, 1, 11, 'ca_Test_311_14', '919894850704', '919894850704', 'Success', 'Y', '2023-11-08 14:56:54'),
(31, 2, 12, 'ca_testing_315_15', '919344145033', '919344145033', 'Success', 'Y', '2023-11-11 06:35:12'),
(32, 2, 12, 'ca_testing_315_16', '918838964597', '918838964597', 'Success', 'Y', '2023-11-11 06:37:23'),
(33, 2, 12, 'ca_testing_315_17', '916380747454', '916380747454', 'Success', 'Y', '2023-11-11 06:48:15'),
(34, 2, 12, 'ca_testing_315_18', '919361419661', '919361419661', 'Success', 'Y', '2023-11-11 06:56:47'),
(35, 2, 12, 'ca_testing_315_18', '919344145033', '919344145033', 'Mobile number already in the group', 'F', '2023-11-11 06:56:47'),
(36, 2, 13, 'ca_checking_315_19', '919344145033', '919344145033', 'Success', 'Y', '2023-11-11 07:53:06');

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
  `group_master_status` char(1) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `group_master_entdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT;

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
(12, 2, 32, 'testing', 5, 4, 1, 'Y', 'Y', '2023-11-11 06:35:12'),
(13, 2, 32, 'checking', 1, 1, 0, 'Y', 'Y', '2023-11-11 07:53:05');

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
) ENGINE=InnoDB AUTO_INCREMENT=52 DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `payment_history_log`
--

INSERT INTO `payment_history_log` (`payment_history_logid`, `user_id`, `user_plans_id`, `plan_master_id`, `plan_amount`, `payment_status`, `plan_comments`, `payment_history_logstatus`, `payment_history_log_date`) VALUES
(1, 1, 15, 1, 100, 'W', 'NULL', 'Y', '2023-10-11 06:55:48'),
(2, 1, 16, 1, 100, 'W', 'NULL', 'Y', '2023-10-11 07:00:15'),
(3, 1, 17, 2, 1100, 'W', 'NULL', 'Y', '2023-10-11 07:04:46'),
(4, 1, 18, 1, 100, 'W', 'NULL', 'Y', '2023-10-11 07:07:07'),
(5, 1, 19, 2, 1100, 'W', 'NULL', 'Y', '2023-10-11 07:09:32'),
(6, 1, 20, 1, 100, 'W', 'NULL', 'Y', '2023-10-11 07:18:48'),
(7, 1, 21, 1, 100, 'W', 'NULL', 'Y', '2023-10-11 07:20:28'),
(8, 1, 22, 1, 100, 'W', 'NULL', 'Y', '2023-10-11 07:24:04'),
(9, 1, 23, 1, 100, 'W', 'NULL', 'Y', '2023-10-11 07:26:21'),
(10, 1, 24, 2, 1100, 'W', 'NULL', 'Y', '2023-10-11 07:27:40'),
(11, 1, 25, 2, 1100, 'W', 'NULL', 'Y', '2023-10-11 07:34:25'),
(12, 1, 26, 2, 1100, 'W', 'NULL', 'Y', '2023-10-11 07:36:57'),
(13, 1, 27, 1, 100, 'W', 'NULL', 'Y', '2023-10-11 07:40:10'),
(14, 1, 28, 2, 1100, 'W', 'NULL', 'Y', '2023-10-11 07:41:54'),
(15, 1, 29, 2, 1100, 'W', 'NULL', 'Y', '2023-10-11 07:48:16'),
(16, 1, 30, 1, 100, 'W', 'NULL', 'Y', '2023-10-11 07:48:59'),
(17, 1, 31, 1, 100, 'W', 'NULL', 'Y', '2023-10-11 07:49:54'),
(18, 1, 32, 1, 100, 'W', 'NULL', 'Y', '2023-10-11 07:55:40'),
(19, 1, 33, 1, 100, 'W', 'NULL', 'Y', '2023-10-11 08:01:57'),
(20, 1, 34, 1, 100, 'W', 'NULL', 'Y', '2023-10-11 08:03:24'),
(21, 1, 35, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MmqD4Cd8EPSh4t, userEmailsuper_admin@gmail.com', 'Y', '2023-10-11 08:48:57'),
(22, 1, 36, 2, 1100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MmrUNy9voEnVyT, userEmailsuper_admin@gmail.com', 'Y', '2023-10-11 08:50:08'),
(23, 1, 37, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MnAU8zjLOKhxU5, userEmailsuper_admin@gmail.com', 'Y', '2023-10-12 04:35:49'),
(24, 1, 38, 1, 100, 'W', 'NULL', 'Y', '2023-10-12 05:27:23'),
(25, 1, 39, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MnBK9GHY8t9mwp, userEmailsuper_admin@gmail.com', 'Y', '2023-10-12 05:28:02'),
(26, 1, 40, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MnBOEPs9gHj7y8, userEmailsuper_admin@gmail.com', 'Y', '2023-10-12 05:31:56'),
(27, 1, 42, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_My01qMnS9lv01j, userEmailsuper_admin@gmail.com', 'Y', '2023-11-08 13:34:03'),
(28, 1, 43, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MyM2qF7WBfDlpT, userEmailsuper_admin@gmail.com', 'Y', '2023-11-09 11:03:55'),
(29, 1, 44, 1, 100, 'W', 'NULL', 'Y', '2023-11-09 11:10:19'),
(30, 1, 45, 2, 1100, 'A', 'msg:Payment successfully credited, status:true, productCode:2, paymentID:pay_MyMDw4GMv5opM6, userEmailsuper_admin@gmail.com', 'Y', '2023-11-09 11:17:07'),
(31, 1, 46, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_Mye8iTr4kxrVuV, userEmailsuper_admin@gmail.com', 'Y', '2023-11-10 04:48:04'),
(32, 1, 47, 1, 100, 'W', 'NULL', 'Y', '2023-11-10 06:52:29'),
(33, 1, 48, 1, 100, 'W', 'NULL', 'Y', '2023-11-10 06:53:12'),
(34, 1, 49, 1, 100, 'W', 'NULL', 'Y', '2023-11-10 06:56:26'),
(35, 1, 50, 1, 100, 'W', 'NULL', 'Y', '2023-11-10 06:56:37'),
(36, 1, 51, 1, 100, 'W', 'NULL', 'Y', '2023-11-10 06:56:42'),
(37, 1, 52, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MygTUuyacJvsiw, userEmailsuper_admin@gmail.com', 'Y', '2023-11-10 06:57:33'),
(38, 2, 53, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MyjYJsy5SYbSPq, userEmailuser_1@gmail.com', 'Y', '2023-11-10 10:05:55'),
(39, 2, 54, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MyjddBnTsi51OZ, userEmailuser_1@gmail.com', 'Y', '2023-11-10 10:10:42'),
(40, 2, 55, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MyjeMjvCatGjrW, userEmailuser_1@gmail.com', 'Y', '2023-11-10 10:11:40'),
(41, 2, 56, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MyjfU9P7zALPJQ, userEmailuser_1@gmail.com', 'Y', '2023-11-10 10:12:39'),
(42, 1, 57, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_Myjh1slQzc95Cl, userEmailsuper_admin@gmail.com', 'Y', '2023-11-10 10:14:14'),
(43, 1, 58, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MyjivPguozP843, userEmailsuper_admin@gmail.com', 'Y', '2023-11-10 10:15:05'),
(44, 1, 59, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MyjqKmBTuTgvJU, userEmailsuper_admin@gmail.com', 'Y', '2023-11-10 10:22:49'),
(45, 1, 60, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_Myjr40FhNmJf9q, userEmailsuper_admin@gmail.com', 'Y', '2023-11-10 10:23:52'),
(46, 2, 61, 2, 1100, 'A', 'msg:Payment successfully credited, status:true, productCode:2, paymentID:pay_MyjxssQ6XqrosY, userEmailuser_1@gmail.com', 'Y', '2023-11-10 10:30:12'),
(47, 2, 62, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MyjzHRMzoWbVqs, userEmailuser_1@gmail.com', 'Y', '2023-11-10 10:30:59'),
(48, 1, 63, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_Mz371JwvBnFWYO, userEmailsuper_admin@gmail.com', 'Y', '2023-11-11 05:14:08'),
(49, 2, 64, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_Mz4DbatSnnpvh0, userEmailuser_1@gmail.com', 'Y', '2023-11-11 06:18:16'),
(50, 2, 65, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_Mz6y5ivNhNAaQm, userEmailuser_1@gmail.com', 'Y', '2023-11-11 08:59:43'),
(51, 2, 66, 1, 100, 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_Mz6ym82g51xaNp, userEmailuser_1@gmail.com', 'Y', '2023-11-11 09:01:10');

-- --------------------------------------------------------

--
-- Table structure for table `plan_master`
--

CREATE TABLE IF NOT EXISTS `plan_master` (
  `plan_master_id` int NOT NULL,
  `user_id` int NOT NULL,
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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `plan_master`
--

INSERT INTO `plan_master` (`plan_master_id`, `user_id`, `plan_title`, `annual_monthly`, `whatsapp_no_min_count`, `whatsapp_no_max_count`, `group_no_min_count`, `group_no_max_count`, `plan_price`, `message_limit`, `plan_status`, `plan_entry_date`) VALUES
(1, 1, 'SILVER', 'M', 0, 100, 0, 70, 100, 500, 'Y', '2023-10-03 05:56:24'),
(2, 1, 'SILVER', 'A', 0, 100, 0, 50, 1100, 6000, 'Y', '2023-10-03 05:56:24');

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
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT;

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
(10, 2, '916380885545', NULL, NULL, 'X', '2023-07-08 05:07:56', '0000-00-00 00:00:00'),
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
(29, 1, '918838964597', 'Testing', '1_1699624281267.jpg', 'X', '2023-11-10 13:51:36', '0000-00-00 00:00:00'),
(30, 1, '916380747454', 'testing_id3', '1_1699678445457.jpeg', 'X', '2023-11-11 04:54:15', '0000-00-00 00:00:00'),
(31, 2, '919344145021', 'testing_id', '2_1699683196857.jpeg', 'D', '2023-11-11 06:13:28', '0000-00-00 00:00:00'),
(32, 2, '919025167792', 'checking', '2_1699684265191.jpeg', 'X', '2023-11-11 06:31:15', '0000-00-00 00:00:00'),
(33, 2, '919344145221', 'testing_id', '2_1699687779017.jpeg', 'D', '2023-11-11 07:29:54', '0000-00-00 00:00:00'),
(34, 2, '916789589565', 'checking', '2_1699692794768.jpeg', 'D', '2023-11-11 08:53:30', '0000-00-00 00:00:00');

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
  `sender_master_id` int NOT NULL,
  `user_id` int NOT NULL,
  `unique_template_id` varchar(30) NOT NULL,
  `template_name` varchar(50) NOT NULL,
  `language_id` int NOT NULL,
  `template_category` varchar(30) NOT NULL,
  `template_message` longtext NOT NULL,
  `template_status` char(1) NOT NULL,
  `template_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `approved_user` int DEFAULT NULL,
  `approve_date` timestamp NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `template_master`
--

INSERT INTO `template_master` (`template_master_id`, `sender_master_id`, `user_id`, `unique_template_id`, `template_name`, `language_id`, `template_category`, `template_message`, `template_status`, `template_entry_date`, `approved_user`, `approve_date`) VALUES
(1, 8, 1, 'tmplt_ad1_dhd1_270_446', 'te_ad1_dhd1_t0000cu00_23920_446', 1, 'MARKETING', '[{"type":"BODY","text":"Testingg template"},{"type":"BUTTONS","buttons":[{"type":"PHONE_NUMBER","text":"Call me","phone_number":"+916380885546"},{"type":"URL","text":"Visit website","url":"https://google.com"}]}]', 'Y', '2023-09-27 09:40:19', NULL, '0000-00-00 00:00:00');

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
) ENGINE=InnoDB AUTO_INCREMENT=208 DEFAULT CHARSET=utf8mb3;

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
(223, 1, 'undefined', '2024-01-05', '2024-01-05 11:28:15', '2024-01-05 11:28:22', 'O', '2024-01-05 11:28:15');

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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT;

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
) ENGINE=InnoDB AUTO_INCREMENT=67 DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `user_plans`
--

INSERT INTO `user_plans` (`user_plans_id`, `user_id`, `plan_master_id`, `plan_amount`, `plan_expiry_date`, `payment_status`, `plan_comments`, `plan_reference_id`, `user_plans_status`, `user_plans_entdate`) VALUES
(1, 1, 2, 1100, '2023-11-01 05:58:35', 'Y', 'STATUS : PAYMENT RECEIVED', 'ASJKYA76ASGJKAHSJY7823TIUYNDUAK', 'Y', '2023-10-03 08:56:45'),
(2, 1, 1, 100, '2023-11-10 10:14:03', 'Y', 'NULL', '-', 'Y', '2023-10-10 10:14:03'),
(3, 1, 1, 100, '2023-11-10 10:16:32', 'Y', 'NULL', '-', 'Y', '2023-10-10 10:16:32'),
(4, 1, 1, 100, '2023-11-10 10:17:21', 'Y', 'NULL', '-', 'Y', '2023-10-10 10:17:22'),
(5, 1, 1, 100, '2023-11-10 10:18:10', 'Y', 'NULL', '-', 'Y', '2023-10-10 10:18:10'),
(6, 1, 1, 100, '2023-11-10 10:25:40', 'Y', 'NULL', '-', 'Y', '2023-10-10 10:25:40'),
(7, 1, 2, 1100, '2023-11-10 10:27:12', 'Y', 'NULL', '-', 'Y', '2023-10-10 10:27:12'),
(8, 1, 1, 100, '2024-10-09 18:30:00', 'Y', 'NULL', '-', 'Y', '2023-10-10 13:00:10'),
(9, 1, 1, 100, '2023-11-10 13:12:21', 'Y', 'NULL', '-', 'Y', '2023-10-10 13:01:33'),
(10, 1, 1, 100, '2023-11-10 13:12:58', 'Y', 'NULL', '-', 'Y', '2023-10-10 13:02:09'),
(11, 1, 1, 100, '2023-11-11 05:54:42', 'Y', 'NULL', '-', 'Y', '2023-10-11 05:43:52'),
(12, 1, 1, 100, '2023-11-11 05:56:40', 'Y', 'NULL', '-', 'Y', '2023-10-11 05:45:50'),
(13, 1, 1, 100, '2023-11-11 07:02:45', 'Y', 'NULL', '-', 'Y', '2023-10-11 06:51:55'),
(14, 1, 1, 100, '2023-11-11 07:04:29', 'W', 'NULL', '-', 'W', '2023-10-11 06:53:44'),
(15, 1, 1, 100, '2023-11-11 07:06:38', 'W', 'NULL', '-', 'W', '2023-10-11 06:55:48'),
(16, 1, 1, 100, '2023-11-11 07:11:05', 'W', 'NULL', '-', 'W', '2023-10-11 07:00:15'),
(17, 1, 2, 1100, '2024-10-11 07:15:36', 'W', 'NULL', '-', 'W', '2023-10-11 07:04:46'),
(18, 1, 1, 100, '2023-11-11 07:17:57', 'W', 'NULL', '-', 'W', '2023-10-11 07:07:07'),
(19, 1, 2, 1100, '2024-10-11 07:20:22', 'W', 'NULL', '-', 'W', '2023-10-11 07:09:32'),
(20, 1, 1, 100, '2023-11-11 07:29:38', 'W', 'NULL', '-', 'W', '2023-10-11 07:18:47'),
(21, 1, 1, 100, '2023-11-11 07:31:18', 'W', 'NULL', '-', 'W', '2023-10-11 07:20:28'),
(22, 1, 1, 100, '2023-11-11 07:34:54', 'W', 'NULL', '-', 'W', '2023-10-11 07:24:04'),
(23, 1, 1, 100, '2023-11-11 07:37:12', 'W', 'NULL', '-', 'W', '2023-10-11 07:26:21'),
(24, 1, 2, 1100, '2024-10-11 07:38:30', 'W', 'NULL', '-', 'W', '2023-10-11 07:27:40'),
(25, 1, 2, 1100, '2024-10-11 07:45:15', 'W', 'NULL', '-', 'W', '2023-10-11 07:34:25'),
(26, 1, 2, 1100, '2024-10-11 07:47:47', 'W', 'NULL', '-', 'W', '2023-10-11 07:36:56'),
(27, 1, 1, 100, '2023-11-11 07:51:00', 'W', 'NULL', '-', 'W', '2023-10-11 07:40:10'),
(28, 1, 2, 1100, '2024-10-11 07:52:44', 'W', 'NULL', '-', 'W', '2023-10-11 07:41:54'),
(29, 1, 2, 1100, '2024-10-11 07:59:07', 'W', 'NULL', '-', 'W', '2023-10-11 07:48:16'),
(30, 1, 1, 100, '2023-11-11 07:59:50', 'W', 'NULL', '-', 'W', '2023-10-11 07:48:59'),
(31, 1, 1, 100, '2023-11-11 08:00:44', 'W', 'NULL', '-', 'W', '2023-10-11 07:49:54'),
(32, 1, 1, 100, '2023-11-11 08:06:30', 'W', 'NULL', '-', 'W', '2023-10-11 07:55:40'),
(33, 1, 1, 100, '2023-11-11 08:12:42', 'W', 'NULL', '-', 'W', '2023-10-11 08:01:57'),
(34, 1, 1, 100, '2023-11-11 08:14:14', 'W', 'NULL', '-', 'W', '2023-10-11 08:03:24'),
(35, 1, 1, 100, '2023-11-11 08:59:48', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MmqD4Cd8EPSh4t, adminEmailsuper_admin@gmail.com', '-', 'A', '2023-10-11 08:48:57'),
(36, 1, 2, 1100, '2024-10-11 09:00:53', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MmrUNy9voEnVyT, userEmailsuper_admin@gmail.com', '-', 'A', '2023-10-11 08:50:08'),
(37, 1, 1, 100, '2023-11-12 04:46:42', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MnAU8zjLOKhxU5, userEmailsuper_admin@gmail.com', '-', 'A', '2023-10-12 04:35:49'),
(38, 1, 1, 100, '2023-11-12 05:38:16', 'W', 'NULL', '-', 'W', '2023-10-12 05:27:23'),
(39, 1, 1, 100, '2023-11-12 05:38:55', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MnBK9GHY8t9mwp, userEmailsuper_admin@gmail.com', '-', 'A', '2023-10-12 05:28:02'),
(40, 1, 1, 100, '2023-11-12 05:42:49', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MnBOEPs9gHj7y8, userEmailsuper_admin@gmail.com', '-', 'A', '2023-10-12 05:31:56'),
(41, 2, 1, 100, '2023-11-12 05:42:49', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MnBOEPs9gHj7y8, userEmailsuper_admin@gmail.com', '-', 'A', '2023-10-12 05:31:56'),
(42, 1, 1, 100, '2023-12-08 13:34:03', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_My01qMnS9lv01j, userEmailsuper_admin@gmail.com', '-', 'A', '2023-11-08 13:34:03'),
(43, 1, 1, 100, '2023-12-09 11:03:55', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MyM2qF7WBfDlpT, userEmailsuper_admin@gmail.com', '-', 'A', '2023-11-09 11:03:55'),
(44, 1, 1, 100, '2023-12-09 11:10:19', 'W', 'NULL', '-', 'W', '2023-11-09 11:10:19'),
(45, 1, 2, 1100, '2024-11-09 11:17:07', 'A', 'msg:Payment successfully credited, status:true, productCode:2, paymentID:pay_MyMDw4GMv5opM6, userEmailsuper_admin@gmail.com', '-', 'A', '2023-11-09 11:17:07'),
(46, 1, 1, 100, '2023-12-10 04:48:04', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_Mye8iTr4kxrVuV, userEmailsuper_admin@gmail.com', '-', 'A', '2023-11-10 04:48:04'),
(47, 1, 1, 100, '2023-12-10 06:52:29', 'W', 'NULL', '-', 'W', '2023-11-10 06:52:29'),
(48, 1, 1, 100, '2023-12-10 06:53:12', 'W', 'NULL', '-', 'W', '2023-11-10 06:53:12'),
(49, 1, 1, 100, '2023-12-10 06:56:25', 'W', 'NULL', '-', 'W', '2023-11-10 06:56:26'),
(50, 1, 1, 100, '2023-12-10 06:56:36', 'W', 'NULL', '-', 'W', '2023-11-10 06:56:36'),
(51, 1, 1, 100, '2023-12-10 06:56:42', 'W', 'NULL', '-', 'W', '2023-11-10 06:56:42'),
(52, 1, 1, 100, '2023-12-10 06:57:33', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MygTUuyacJvsiw, userEmailsuper_admin@gmail.com', '-', 'A', '2023-11-10 06:57:33'),
(53, 2, 1, 100, '2023-12-10 10:05:54', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MyjYJsy5SYbSPq, userEmailuser_1@gmail.com', '-', 'A', '2023-11-10 10:05:55'),
(54, 2, 1, 100, '2023-12-10 10:10:42', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MyjddBnTsi51OZ, userEmailuser_1@gmail.com', '-', 'A', '2023-11-10 10:10:42'),
(55, 2, 1, 100, '2023-12-10 10:11:39', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MyjeMjvCatGjrW, userEmailuser_1@gmail.com', '-', 'A', '2023-11-10 10:11:39'),
(56, 2, 1, 100, '2023-12-10 10:12:39', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MyjfU9P7zALPJQ, userEmailuser_1@gmail.com', '-', 'A', '2023-11-10 10:12:39'),
(57, 1, 1, 100, '2023-12-10 10:14:14', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_Myjh1slQzc95Cl, userEmailsuper_admin@gmail.com', '-', 'A', '2023-11-10 10:14:14'),
(58, 1, 1, 100, '2023-12-10 10:15:05', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MyjivPguozP843, userEmailsuper_admin@gmail.com', '-', 'A', '2023-11-10 10:15:05'),
(59, 1, 1, 100, '2023-12-10 10:22:49', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MyjqKmBTuTgvJU, userEmailsuper_admin@gmail.com', '-', 'A', '2023-11-10 10:22:49'),
(60, 1, 1, 100, '2023-12-10 10:23:52', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_Myjr40FhNmJf9q, userEmailsuper_admin@gmail.com', '-', 'A', '2023-11-10 10:23:52'),
(61, 2, 2, 1100, '2024-11-10 10:30:11', 'A', 'msg:Payment successfully credited, status:true, productCode:2, paymentID:pay_MyjxssQ6XqrosY, userEmailuser_1@gmail.com', '-', 'A', '2023-11-10 10:30:12'),
(62, 2, 1, 100, '2023-12-10 10:30:58', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_MyjzHRMzoWbVqs, userEmailuser_1@gmail.com', '-', 'A', '2023-11-10 10:30:59'),
(63, 1, 1, 100, '2023-12-11 05:14:08', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_Mz371JwvBnFWYO, userEmailsuper_admin@gmail.com', '-', 'A', '2023-12-11 05:14:08'),
(64, 2, 1, 100, '2023-12-11 06:18:16', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_Mz4DbatSnnpvh0, userEmailuser_1@gmail.com', '-', 'A', '2023-11-11 06:18:16'),
(65, 2, 1, 100, '2023-12-11 08:59:43', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_Mz6y5ivNhNAaQm, userEmailuser_1@gmail.com', '-', 'A', '2023-11-11 08:59:43'),
(66, 2, 1, 100, '2023-12-11 09:01:10', 'A', 'msg:Payment successfully credited, status:true, productCode:1, paymentID:pay_Mz6ym82g51xaNp, userEmailuser_1@gmail.com', '-', 'A', '2023-11-11 09:01:10');

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
-- Indexes for table `plan_master`
--
ALTER TABLE `plan_master`
  ADD PRIMARY KEY (`plan_master_id`),
  ADD KEY `user_id` (`user_id`);

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
  MODIFY `api_log_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=50;
--
-- AUTO_INCREMENT for table `group_contacts`
--
ALTER TABLE `group_contacts`
  MODIFY `group_contacts_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=37;
--
-- AUTO_INCREMENT for table `group_master`
--
ALTER TABLE `group_master`
  MODIFY `group_master_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=14;
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
  MODIFY `payment_history_logid` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=52;
--
-- AUTO_INCREMENT for table `plan_master`
--
ALTER TABLE `plan_master`
  MODIFY `plan_master_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `senderid_master`
--
ALTER TABLE `senderid_master`
  MODIFY `sender_master_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=35;
--
-- AUTO_INCREMENT for table `summary_report`
--
ALTER TABLE `summary_report`
  MODIFY `summary_report_id` int NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `template_master`
--
ALTER TABLE `template_master`
  MODIFY `template_master_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `user_log`
--
ALTER TABLE `user_log`
  MODIFY `user_log_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=224;
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
  MODIFY `user_plans_id` int NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=67;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
