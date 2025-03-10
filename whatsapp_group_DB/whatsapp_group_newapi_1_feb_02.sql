-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Feb 02, 2024 at 01:31 PM
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
-- Database: `whatsapp_group_newapi_1`
--

-- --------------------------------------------------------

--
-- Table structure for table `compose_message_1`
--

CREATE TABLE `compose_message_1` (
  `compose_message_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `sender_master_id` int(11) NOT NULL,
  `group_master_id` int(11) NOT NULL,
  `template_master_id` varchar(11) NOT NULL,
  `message_type` varchar(10) NOT NULL,
  `campaign_name` varchar(30) NOT NULL,
  `schedule_status` varchar(1) NOT NULL,
  `schedule_date` timestamp NULL DEFAULT NULL,
  `cm_status` char(1) NOT NULL,
  `cm_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=COMPACT;

--
-- Dumping data for table `compose_message_1`
--

INSERT INTO `compose_message_1` (`compose_message_id`, `user_id`, `sender_master_id`, `group_master_id`, `template_master_id`, `message_type`, `campaign_name`, `schedule_status`, `schedule_date`, `cm_status`, `cm_entry_date`) VALUES
(1, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_023_1', '', NULL, 'N', '2024-01-23 12:53:12'),
(2, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_023_2', '', NULL, 'N', '2024-01-23 13:24:25'),
(3, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_023_3', '', NULL, 'N', '2024-01-23 13:35:39'),
(4, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_024_4', '', NULL, 'N', '2024-01-24 09:09:49'),
(5, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_024_5', '', NULL, 'N', '2024-01-24 09:22:35'),
(6, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_024_6', '', NULL, 'N', '2024-01-24 09:44:07'),
(7, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_024_7', '', NULL, 'N', '2024-01-24 09:58:54'),
(8, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_024_8', '', NULL, 'N', '2024-01-24 10:02:32'),
(9, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_024_9', '', NULL, 'N', '2024-01-24 11:03:35'),
(10, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_024_10', '', NULL, 'N', '2024-01-24 11:40:34'),
(11, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_024_11', '', NULL, 'N', '2024-01-24 11:48:37'),
(12, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_024_12', '', NULL, 'N', '2024-01-24 11:53:47'),
(13, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_024_13', '', NULL, 'N', '2024-01-24 11:58:35'),
(14, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_024_14', '', NULL, 'N', '2024-01-24 12:51:40'),
(15, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_024_15', '', NULL, 'N', '2024-01-24 13:20:01'),
(16, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_16', '', NULL, 'N', '2024-01-25 07:10:56'),
(17, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_17', '', NULL, 'N', '2024-01-25 07:40:29'),
(18, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_18', '', NULL, 'N', '2024-01-25 07:42:17'),
(19, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_19', '', NULL, 'N', '2024-01-25 07:47:32'),
(20, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_20', '', NULL, 'N', '2024-01-25 07:49:49'),
(21, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_21', '', NULL, 'N', '2024-01-25 07:55:30'),
(22, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_22', '', NULL, 'N', '2024-01-25 08:56:26'),
(23, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_23', '', NULL, 'N', '2024-01-25 09:00:10'),
(24, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_24', '', NULL, 'N', '2024-01-25 09:03:29'),
(25, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_25', '', NULL, 'N', '2024-01-25 09:10:10'),
(26, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_26', '', NULL, 'N', '2024-01-25 09:15:04'),
(27, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_27', '', NULL, 'N', '2024-01-25 09:16:31'),
(28, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_28', '', NULL, 'N', '2024-01-25 09:28:55'),
(29, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_29', '', NULL, 'N', '2024-01-25 09:52:31'),
(30, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_30', '', NULL, 'N', '2024-01-25 10:34:52'),
(31, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_31', '', NULL, 'N', '2024-01-25 13:20:53'),
(32, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_32', '', NULL, 'Y', '2024-01-25 14:55:29'),
(33, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_025_33', '', NULL, 'Y', '2024-01-25 15:01:23'),
(34, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_030_34', '', NULL, 'Y', '2024-01-30 12:59:12'),
(35, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_030_35', '', NULL, 'Y', '2024-01-30 13:05:51'),
(36, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_030_36', '', NULL, 'Y', '2024-01-30 13:07:09'),
(37, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_030_37', '', NULL, 'N', '2024-01-30 13:25:13'),
(38, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_030_38', '', NULL, 'Y', '2024-01-30 13:26:44'),
(39, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_030_39', '', NULL, 'Y', '2024-01-30 13:59:32'),
(40, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_030_40', '', NULL, 'Y', '2024-01-30 14:02:37'),
(41, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_030_41', '', NULL, 'L', '2024-01-30 14:21:31'),
(42, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_42', '', NULL, 'Y', '2024-01-31 05:39:37'),
(43, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_43', '', NULL, 'Y', '2024-01-31 05:47:13'),
(44, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_44', '', NULL, 'L', '2024-01-31 06:00:00'),
(45, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_45', '', NULL, 'L', '2024-01-31 06:30:00'),
(46, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_46', '', NULL, 'L', '2024-01-31 06:58:00'),
(47, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_47', '', NULL, 'L', '2024-01-31 07:15:53'),
(48, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_48', '', NULL, 'L', '2024-01-31 07:50:00'),
(49, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_49', '', NULL, 'L', '2024-01-31 07:48:00'),
(50, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_50', '', NULL, 'L', '2024-01-31 08:00:03'),
(51, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_51', '', NULL, 'L', '2024-01-31 07:59:03'),
(52, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_52', '', NULL, 'L', '2024-01-31 09:15:08'),
(53, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_53', '', NULL, 'L', '2024-01-31 09:16:35'),
(54, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_54', '', NULL, 'L', '2024-01-31 09:14:11'),
(55, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_55', '', NULL, 'Y', '2024-01-31 09:23:40'),
(56, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_56', '', NULL, 'L', '2024-01-31 09:26:04'),
(57, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_57', '', NULL, 'L', '2024-01-31 09:38:00'),
(58, 1, 1, 1, '2', 'TEXT', 'ca_TESTING_031_58', '', NULL, 'L', '2024-01-31 11:28:29'),
(59, 1, 1, 1, '2', 'TEXT', 'ca_TESTING_031_59', '', NULL, 'L', '2024-01-31 10:45:38'),
(60, 1, 1, 1, '2', 'TEXT', 'ca_TESTING_031_60', '', NULL, 'L', '2024-01-31 09:55:00'),
(61, 1, 1, 1, '2', 'TEXT', 'ca_TESTING_031_61', '', NULL, 'L', '2024-01-31 09:51:51'),
(62, 1, 1, 1, '2', 'TEXT', 'ca_TESTING_031_62', '', NULL, 'L', '2024-01-31 10:11:07'),
(63, 1, 1, 1, '2', 'TEXT', 'ca_TESTING_031_63', '', NULL, 'L', '2024-01-31 10:23:04'),
(64, 1, 1, 1, '2', 'TEXT', 'ca_TESTING_031_64', '', NULL, 'L', '2024-01-31 10:28:10'),
(65, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_65', '', NULL, 'L', '2024-01-31 10:30:00'),
(66, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_66', '', NULL, 'L', '2024-01-31 10:29:09'),
(67, 1, 1, 1, '2', 'TEXT', 'ca_TESTING_031_67', '', NULL, 'L', '2024-01-31 10:39:32'),
(68, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_68', '', NULL, 'L', '2024-01-31 10:50:16'),
(69, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_69', '', NULL, 'L', '2024-01-31 10:48:05'),
(70, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_70', '', NULL, 'L', '2024-01-31 10:55:47'),
(71, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_71', '', NULL, 'L', '2024-01-31 11:27:17'),
(72, 1, 1, 1, '2', 'TEXT', 'ca_TESTING_031_72', 'Y', '2024-01-31 11:50:00', 'Y', '2024-01-31 11:49:10'),
(73, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_031_73', 'Y', '2024-01-31 12:03:36', 'N', '2024-01-31 11:58:06'),
(74, 1, 1, 1, '2', 'TEXT', 'ca_TESTING_031_74', 'Y', '2024-01-31 12:00:09', 'N', '2024-01-31 11:58:26'),
(75, 1, 1, 1, '2', 'TEXT', 'ca_TESTING_032_75', 'N', NULL, 'N', '2024-02-01 04:13:02'),
(76, 1, 1, 1, '2', 'TEXT', 'ca_TESTING_032_76', 'N', NULL, 'Y', '2024-02-01 04:17:42'),
(77, 1, 1, 1, '2', 'TEXT', 'ca_TESTING_032_77', 'Y', '2024-02-01 04:50:09', 'Y', '2024-02-01 04:44:35'),
(78, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_032_78', 'Y', '2024-02-01 05:07:06', 'F', '2024-02-01 05:05:25'),
(79, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_032_79', 'N', NULL, 'Y', '2024-02-01 05:17:48'),
(80, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_032_80', 'N', NULL, 'Y', '2024-02-01 05:25:24'),
(81, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_032_81', 'N', NULL, 'Y', '2024-02-01 05:32:59'),
(82, 1, 1, 2, '1', 'TEXT', 'ca_Demo_032_82', 'N', NULL, 'Y', '2024-02-01 07:03:38'),
(83, 1, 1, 2, '2', 'TEXT', 'ca_Demo_032_83', 'N', NULL, 'Y', '2024-02-01 07:10:25'),
(84, 1, 1, 2, '6', 'TEXT', 'ca_Demo_032_84', 'N', NULL, 'Y', '2024-02-01 07:12:36'),
(85, 1, 1, 2, '2', 'TEXT', 'ca_Demo_032_85', 'N', NULL, 'Y', '2024-02-01 07:14:44'),
(86, 1, 1, 2, '1', 'TEXT', 'ca_Demo_032_86', 'Y', '2024-02-01 07:20:27', 'Y', '2024-02-01 07:16:07'),
(87, 1, 1, 2, '6', 'TEXT', 'ca_Demo_032_87', 'Y', '2024-02-01 07:18:29', 'Y', '2024-02-01 07:16:48'),
(88, 1, 1, 2, '1', 'TEXT', 'ca_Demo_032_88', 'Y', '2024-02-01 07:35:23', 'N', '2024-02-01 07:30:40'),
(89, 1, 1, 2, '2', 'TEXT', 'ca_Demo_032_89', 'Y', '2024-02-01 08:00:57', 'N', '2024-02-01 07:31:25'),
(90, 1, 1, 2, '6', 'TEXT', 'ca_Demo_032_90', 'Y', '2024-02-01 07:40:38', 'N', '2024-02-01 07:31:57'),
(91, 1, 1, 1, '7', 'TEXT', 'ca_TESTING_032_91', 'Y', '2024-02-01 07:45:06', 'Y', '2024-02-01 07:32:32'),
(92, 1, 1, 1, '2', 'TEXT', 'ca_TESTING_032_92', 'Y', '2024-02-01 07:47:57', 'N', '2024-02-01 07:34:51'),
(93, 1, 1, 2, '1', 'TEXT', 'ca_Demo_032_93', 'Y', '2024-02-01 08:02:10', 'Y', '2024-02-01 08:00:25'),
(94, 1, 1, 1, '2', 'TEXT', 'ca_TESTING_032_94', 'Y', '2024-02-01 08:05:39', 'N', '2024-02-01 08:00:52'),
(95, 1, 1, 2, '1', 'TEXT', 'ca_Demo_032_95', 'Y', '2024-02-01 08:03:03', 'N', '2024-02-01 08:01:22'),
(96, 1, 1, 2, '2', 'TEXT', 'ca_Demo_032_96', 'Y', '2024-02-01 08:09:02', 'N', '2024-02-01 08:07:19'),
(97, 1, 1, 2, '2', 'TEXT', 'ca_Demo_032_97', 'Y', '2024-02-01 08:08:51', 'N', '2024-02-01 08:08:05'),
(98, 1, 1, 2, '1', 'TEXT', 'ca_Demo_032_98', 'Y', '2024-02-01 08:15:55', 'Y', '2024-02-01 08:12:01'),
(99, 1, 1, 2, '1', 'TEXT', 'ca_Demo_032_99', 'Y', '2024-02-01 08:30:05', 'Y', '2024-02-01 08:16:41'),
(100, 1, 1, 2, '1', 'TEXT', 'ca_Demo_032_100', 'Y', '2024-02-01 08:20:44', 'Y', '2024-02-01 08:16:56'),
(101, 1, 1, 2, '1', 'TEXT', 'ca_Demo_032_101', 'Y', '2024-02-01 08:25:01', 'Y', '2024-02-01 08:17:22'),
(102, 1, 1, 2, '2', 'TEXT', 'ca_Demo_032_102', 'Y', '2024-02-01 09:00:24', 'Y', '2024-02-01 08:57:41'),
(103, 1, 1, 2, '2', 'TEXT', 'ca_Demo_032_103', 'Y', '2024-02-01 09:00:44', 'F', '2024-02-01 08:58:01'),
(104, 1, 1, 2, '1', 'TEXT', 'ca_Demo_032_104', 'N', NULL, 'Y', '2024-02-01 10:25:21'),
(105, 1, 1, 2, '1', 'TEXT', 'ca_Demo_032_105', 'Y', '2024-02-01 10:28:27', 'Y', '2024-02-01 10:25:43'),
(106, 1, 1, 2, '2', 'TEXT', 'ca_Demo_032_106', 'Y', '2024-02-01 10:30:12', 'N', '2024-02-01 10:28:02'),
(107, 1, 1, 2, '2', 'TEXT', 'ca_Demo_032_107', 'Y', '2024-02-01 11:00:14', 'N', '2024-02-01 10:28:41'),
(108, 1, 1, 1, '1', 'TEXT', 'ca_TESTING_032_108', 'Y', '2024-02-01 10:40:10', 'N', '2024-02-01 10:29:27'),
(109, 1, 1, 1, '7', 'TEXT', 'ca_TESTING_032_109', 'Y', '2024-02-01 10:45:00', 'N', '2024-02-01 10:30:33'),
(110, 1, 1, 2, '1', 'TEXT', 'ca_Demo_032_110', 'Y', '2024-02-01 10:48:51', 'Y', '2024-02-01 10:47:03'),
(111, 1, 1, 2, '6', 'TEXT', 'ca_Demo_032_111', 'Y', '2024-02-01 10:53:15', 'Y', '2024-02-01 10:52:33'),
(112, 1, 1, 2, '2', 'TEXT', 'ca_Demo_032_112', 'Y', '2024-02-01 10:55:38', 'F', '2024-02-01 10:53:11'),
(113, 1, 1, 1, '2', 'TEXT', 'ca_TESTING_032_113', 'Y', '2024-02-01 11:04:25', 'Y', '2024-02-01 11:02:39'),
(114, 1, 1, 2, '2', 'TEXT', 'ca_Demo_032_114', 'Y', '2024-02-01 11:42:01', 'Y', '2024-02-01 11:39:19'),
(115, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_115', 'N', NULL, 'F', '2024-02-02 06:32:03'),
(116, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_116', 'N', NULL, 'F', '2024-02-02 06:34:40'),
(117, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_117', 'N', NULL, 'F', '2024-02-02 06:43:46'),
(118, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_118', 'N', NULL, 'Y', '2024-02-02 06:44:52'),
(119, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_119', 'N', NULL, 'F', '2024-02-02 06:53:43'),
(120, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_120', 'N', NULL, 'F', '2024-02-02 07:11:25'),
(121, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_121', 'N', NULL, 'F', '2024-02-02 07:12:16'),
(122, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_122', 'N', NULL, 'F', '2024-02-02 07:13:55'),
(123, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_123', 'N', NULL, 'F', '2024-02-02 07:15:56'),
(124, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_124', 'N', NULL, 'Y', '2024-02-02 07:17:59'),
(125, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_125', 'N', NULL, 'Y', '2024-02-02 07:38:50'),
(126, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_126', 'N', NULL, 'Y', '2024-02-02 07:41:55'),
(127, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_127', 'N', NULL, 'Y', '2024-02-02 07:58:41'),
(128, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_128', 'N', NULL, 'Y', '2024-02-02 08:01:03'),
(129, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_129', 'N', NULL, 'Y', '2024-02-02 08:03:30'),
(130, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_130', 'N', NULL, 'Y', '2024-02-02 08:04:46'),
(131, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_131', 'N', NULL, 'Y', '2024-02-02 08:06:10'),
(132, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_132', 'N', NULL, 'Y', '2024-02-02 08:48:07'),
(133, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_133', 'N', NULL, 'Y', '2024-02-02 08:49:13'),
(134, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_134', 'N', NULL, 'Y', '2024-02-02 08:50:28'),
(135, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_135', 'N', NULL, 'Y', '2024-02-02 08:53:25'),
(136, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_136', 'N', NULL, 'Y', '2024-02-02 08:55:33'),
(137, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_137', 'N', NULL, 'Y', '2024-02-02 09:00:54'),
(138, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_138', 'N', NULL, 'Y', '2024-02-02 09:08:53'),
(139, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_139', 'N', NULL, 'F', '2024-02-02 09:31:07'),
(140, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_140', 'N', NULL, 'Y', '2024-02-02 09:34:02'),
(141, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_141', 'N', NULL, 'Y', '2024-02-02 09:40:41'),
(142, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_142', 'N', NULL, 'Y', '2024-02-02 09:43:39'),
(143, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_143', 'N', NULL, 'Y', '2024-02-02 09:45:29'),
(144, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_144', 'N', NULL, 'F', '2024-02-02 09:53:06'),
(145, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_145', 'N', NULL, 'Y', '2024-02-02 09:56:31'),
(146, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_146', 'N', NULL, 'Y', '2024-02-02 09:58:30'),
(147, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_147', 'N', NULL, 'Y', '2024-02-02 10:00:39'),
(148, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_148', 'N', NULL, 'Y', '2024-02-02 10:03:15'),
(149, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_149', 'N', NULL, 'F', '2024-02-02 10:06:01'),
(150, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_150', 'N', NULL, 'Y', '2024-02-02 10:07:13'),
(151, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_151', 'N', NULL, 'Y', '2024-02-02 10:09:08'),
(152, 1, 1, 2, '-', 'TEXT', 'ca_Demo_033_152', 'N', NULL, 'Y', '2024-02-02 10:15:55'),
(153, 1, 1, 2, '2', 'TEXT', 'ca_Demo_033_153', 'N', NULL, 'F', '2024-02-02 10:49:35'),
(154, 1, 1, 2, 'undefined', 'TEXT', 'ca_Demo_033_154', 'N', NULL, 'F', '2024-02-02 10:56:14'),
(155, 1, 1, 2, 'undefined', 'TEXT', 'ca_Demo_033_155', 'N', NULL, 'F', '2024-02-02 11:00:36'),
(156, 1, 1, 2, 'undefined', 'TEXT', 'ca_Demo_033_156', 'N', NULL, 'Y', '2024-02-02 12:24:18');

-- --------------------------------------------------------

--
-- Table structure for table `compose_msg_media_1`
--

CREATE TABLE `compose_msg_media_1` (
  `compose_msg_media_id` int(11) NOT NULL,
  `compose_message_id` int(11) NOT NULL,
  `text_title` varchar(2000) DEFAULT NULL,
  `text_reply` varchar(50) DEFAULT NULL,
  `text_number` varchar(15) DEFAULT NULL,
  `text_url` varchar(100) DEFAULT NULL,
  `text_address` varchar(100) DEFAULT NULL,
  `media_url` varchar(100) DEFAULT NULL,
  `media_type` varchar(10) DEFAULT NULL,
  `failed_reason` varchar(100) DEFAULT NULL,
  `cmm_status` char(1) NOT NULL,
  `cmm_entry_date` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci ROW_FORMAT=COMPACT;

--
-- Dumping data for table `compose_msg_media_1`
--

INSERT INTO `compose_msg_media_1` (`compose_msg_media_id`, `compose_message_id`, `text_title`, `text_reply`, `text_number`, `text_url`, `text_address`, `media_url`, `media_type`, `failed_reason`, `cmm_status`, `cmm_entry_date`) VALUES
(1, 1, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-23 12:53:12'),
(2, 2, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-23 13:24:25'),
(3, 3, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-23 13:35:39'),
(4, 4, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-24 09:09:50'),
(5, 5, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-24 09:22:35'),
(6, 6, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-24 09:44:08'),
(7, 7, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-24 09:58:54'),
(8, 8, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-24 10:02:32'),
(9, 9, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-24 11:03:35'),
(10, 10, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-24 11:40:35'),
(11, 11, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-24 11:48:37'),
(12, 12, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-24 11:53:47'),
(13, 13, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-24 11:58:36'),
(14, 14, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-24 12:51:40'),
(15, 15, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-24 13:20:01'),
(16, 16, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-25 07:10:56'),
(17, 17, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-25 07:40:29'),
(18, 18, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-25 07:42:17'),
(19, 19, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-25 07:47:32'),
(20, 20, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-25 07:49:49'),
(21, 21, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-25 07:55:30'),
(22, 22, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-25 08:56:26'),
(23, 24, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-25 09:03:30'),
(24, 25, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-25 09:10:10'),
(25, 26, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-25 09:15:05'),
(26, 27, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-25 09:16:32'),
(27, 28, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-25 09:28:55'),
(28, 29, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-25 09:52:31'),
(29, 30, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-25 10:34:52'),
(30, 31, 'HI.. Welcome', NULL, NULL, NULL, NULL, NULL, NULL, '', 'N', '2024-01-25 13:20:53'),
(31, 32, 'Server send message testing', NULL, NULL, NULL, NULL, NULL, NULL, '', 'Y', '2024-01-25 14:55:29'),
(32, 33, 'Server send message testing', NULL, NULL, NULL, NULL, NULL, NULL, '', 'Y', '2024-01-25 15:01:23'),
(33, 34, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'Y', '2024-01-30 12:59:12'),
(34, 35, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'Y', '2024-01-30 13:05:51'),
(35, 36, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'Y', '2024-01-30 13:07:09'),
(36, 38, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'Y', '2024-01-30 13:26:45'),
(37, 39, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'Y', '2024-01-30 13:59:32'),
(38, 40, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'Y', '2024-01-30 14:02:37'),
(39, 41, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-30 14:21:31'),
(40, 42, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'Y', '2024-01-31 05:39:37'),
(41, 43, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'Y', '2024-01-31 05:47:13'),
(42, 44, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 06:00:00'),
(43, 45, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 06:30:00'),
(44, 46, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 06:58:00'),
(45, 47, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 07:15:53'),
(46, 48, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 07:50:00'),
(47, 49, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 07:48:00'),
(48, 50, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 08:00:03'),
(49, 51, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 07:59:03'),
(50, 52, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 09:15:08'),
(51, 53, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 09:16:35'),
(52, 54, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 09:14:11'),
(53, 55, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'Y', '2024-01-31 09:23:40'),
(54, 56, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 09:26:04'),
(55, 57, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 09:38:00'),
(56, 58, 'JavaScript is the world most popular programming language.', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 11:28:29'),
(57, 59, 'JavaScript is the world most popular programming language.', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 10:45:38'),
(58, 60, 'JavaScript is the world most popular programming language.', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 09:55:00'),
(59, 61, 'JavaScript is the world most popular programming language.', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 09:51:51'),
(60, 62, 'JavaScript is the world most popular programming language.', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 10:11:07'),
(61, 63, 'JavaScript is the world most popular programming language.', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 10:23:04'),
(62, 64, 'JavaScript is the world most popular programming language.', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 10:28:10'),
(63, 65, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 10:30:00'),
(64, 66, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 10:29:09'),
(65, 67, 'JavaScript is the world most popular programming language.', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 10:39:32'),
(66, 68, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 10:50:16'),
(67, 69, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 10:48:05'),
(68, 70, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 10:55:47'),
(69, 71, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 11:27:17'),
(70, 72, 'JavaScript is the world most popular programming language.', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 11:50:00'),
(71, 73, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 12:03:36'),
(72, 74, 'JavaScript is the world most popular programming language.', NULL, NULL, NULL, NULL, NULL, NULL, '', 'L', '2024-01-31 12:00:09'),
(73, 75, 'JavaScript is the world most popular programming language.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'N', '2024-02-01 04:14:13'),
(74, 76, 'JavaScript is the world most popular programming language.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 04:17:42'),
(75, 77, 'JavaScript is the world most popular programming language.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 04:44:35'),
(76, 78, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, 'Sender ID unlinked', 'F', '2024-02-01 05:05:25'),
(77, 79, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 05:17:48'),
(78, 80, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 05:25:24'),
(79, 81, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 05:32:59'),
(80, 82, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 07:03:38'),
(81, 83, '<b>TEST Message</b>', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 07:10:25'),
(82, 84, 'sjdnkf', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 07:12:36'),
(83, 85, '<b>TEST Message</b>', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 07:14:44'),
(84, 86, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 07:16:07'),
(85, 87, 'sjdnkf', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 07:16:48'),
(86, 88, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'N', '2024-02-01 07:30:40'),
(87, 89, '<b>TEST Message</b>', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'N', '2024-02-01 07:31:25'),
(88, 90, 'sjdnkf', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'N', '2024-02-01 07:31:57'),
(89, 91, 'jnsjd', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 07:32:32'),
(90, 92, '<b>TEST Message</b>', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'N', '2024-02-01 07:34:51'),
(91, 93, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 08:00:25'),
(92, 94, '<b>TEST Message</b>', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'N', '2024-02-01 08:00:52'),
(93, 95, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'N', '2024-02-01 08:01:22'),
(94, 96, '<b>TEST Message</b>', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'N', '2024-02-01 08:07:19'),
(95, 97, '<b>TEST Message</b>', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'N', '2024-02-01 08:08:05'),
(96, 98, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 08:12:01'),
(97, 99, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 08:16:41'),
(98, 100, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 08:16:56'),
(99, 101, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 08:17:22'),
(100, 102, '<b>TEST Message</b>', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 08:57:41'),
(101, 103, '<b>TEST Message</b>', NULL, NULL, NULL, NULL, NULL, NULL, 'Sender ID unlinked', 'F', '2024-02-01 08:58:01'),
(102, 104, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 10:25:21'),
(103, 105, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 10:25:43'),
(104, 106, '<b>TEST Message</b>', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'N', '2024-02-01 10:28:02'),
(105, 107, '<b>TEST Message</b>', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'N', '2024-02-01 10:28:41'),
(106, 108, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'N', '2024-02-01 10:29:27'),
(107, 109, 'jnsjd', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'N', '2024-02-01 10:30:33'),
(108, 110, 'TESTING', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 10:47:03'),
(109, 111, 'sjdnkf', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 10:52:33'),
(110, 112, '<b>TEST Message</b>', NULL, NULL, NULL, NULL, NULL, NULL, 'Sender ID unlinked', 'F', '2024-02-01 10:53:11'),
(111, 113, '<b>TEST Message</b>', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 11:02:39'),
(112, 114, '<b>TEST Message</b>', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-01 11:39:19'),
(113, 115, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'F', '2024-02-02 06:32:03'),
(114, 116, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'F', '2024-02-02 06:34:40'),
(115, 117, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'F', '2024-02-02 06:43:46'),
(116, 118, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 06:44:52'),
(117, 119, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'F', '2024-02-02 06:53:43'),
(118, 120, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'F', '2024-02-02 07:11:25'),
(119, 121, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'F', '2024-02-02 07:12:16'),
(120, 122, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'F', '2024-02-02 07:13:55'),
(121, 123, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'F', '2024-02-02 07:15:56'),
(122, 124, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 07:17:59'),
(123, 125, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 07:38:50'),
(124, 126, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 07:41:55'),
(125, 127, 'hello world', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 07:58:42'),
(126, 128, 'hello world', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 08:01:03'),
(127, 129, 'hello world', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 08:03:30'),
(128, 130, 'hello world', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 08:04:46'),
(129, 131, 'hello world', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 08:06:10'),
(130, 132, 'hello world. This is a text message', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 08:48:07'),
(131, 133, 'hello world. This is a text message', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 08:49:13'),
(132, 134, 'Although he barks at strangers, he never bites them. He loves eating vegetables and I sometimes offer him meat and fish to eat. I bathe him once every few days and play with him in the garden to ensure he is exposed to sunlight and fresh air every day', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 08:50:28'),
(133, 135, 'Although he barks at strangers, he never bites them. He loves eating vegetables and I sometimes offer him meat and fish to eat. I bathe him once every few days and play with him in the garden to ensure he is exposed to sunlight and fresh air every day', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 08:53:25'),
(134, 136, 'Although he barks at strangers, he never bites them. He loves eating vegetables and I sometimes offer him meat and fish to eat. I bathe him once every few days and play with him in the garden to ensure he is exposed to sunlight and fresh air every day', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 08:55:33'),
(135, 137, 'Although he barks at strangers, he never bites them. He loves eating vegetables and I sometimes offer him meat and fish to eat. I bathe him once every few days and play with him in the garden to ensure he is exposed to sunlight and fresh air every day', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 09:00:54'),
(136, 138, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 09:08:53'),
(137, 139, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'F', '2024-02-02 09:31:07'),
(138, 140, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 09:34:02'),
(139, 141, 'Although he barks at strangers, he never bites them. He loves eating vegetables and I sometimes offer him meat and fish to eat. I bathe him once every few days and play with him in the garden to ensure he is exposed to sunlight and fresh air every day', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 09:40:41'),
(140, 142, 'Although he barks at strangers, he never bites them. He loves eating vegetables and I sometimes offer him meat and fish to eat. I bathe him once every few days and play with him in the garden to ensure he is exposed to sunlight and fresh air every day', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 09:43:39'),
(141, 143, 'Although he barks at strangers, he never bites them. He loves eating vegetables and I sometimes offer him meat and fish to eat. I bathe him once every few days and play with him in the garden to ensure he is exposed to sunlight and fresh air every day', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 09:45:29'),
(142, 144, 'Although he barks at strangers, he never bites them. He loves eating vegetables and I sometimes offer him meat and fish to eat. I bathe him once every few days and play with him in the garden to ensure he is exposed to sunlight and fresh air every day', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'F', '2024-02-02 09:53:06'),
(143, 145, 'Although he barks at strangers, he never bites them. He loves eating vegetables and I sometimes offer him meat and fish to eat. I bathe him once every few days and play with him in the garden to ensure he is exposed to sunlight and fresh air every day', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 09:56:31'),
(144, 146, 'Although he barks at strangers, he never bites them. He loves eating vegetables and I sometimes offer him meat and fish to eat. I bathe him once every few days and play with him in the garden to ensure he is exposed to sunlight and fresh air every day', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 09:58:30'),
(145, 147, 'Sometimes your client may need to download and process media files that have been attached to messages it receives. This library includes some useful functions to download these files in base64 format.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 10:00:39'),
(146, 148, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 10:03:15'),
(147, 149, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'F', '2024-02-02 10:06:01'),
(148, 150, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 10:07:13'),
(149, 151, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 10:09:08'),
(150, 152, 'Tamil Nadu, state of India, located in the extreme south of the subcontinent. It is bounded by the Indian Ocean to the east and south and by the states of Kerala to the west, Karnataka (formerly Mysore) to the northwest, and Andhra Pradesh to the north. Enclosed by Tamil Nadu along the north-central coast are the enclaves of Puducherry and Karaikal, both of which are part of Puducherry union territory. The capital is Chennai (Madras), on the coast in the northeastern portion of the state.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 10:15:55'),
(151, 153, '<b>TEST Message</b>', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'F', '2024-02-02 10:49:35'),
(152, 154, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'F', '2024-02-02 10:56:14'),
(153, 155, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'F', '2024-02-02 11:00:36'),
(154, 156, 'undefined', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Y', '2024-02-02 12:24:18');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `compose_message_1`
--
ALTER TABLE `compose_message_1`
  ADD PRIMARY KEY (`compose_message_id`),
  ADD KEY `compose_message_id` (`compose_message_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `sender_master_id` (`sender_master_id`),
  ADD KEY `group_master_id` (`group_master_id`);

--
-- Indexes for table `compose_msg_media_1`
--
ALTER TABLE `compose_msg_media_1`
  ADD PRIMARY KEY (`compose_msg_media_id`),
  ADD KEY `compose_message_id` (`compose_message_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `compose_message_1`
--
ALTER TABLE `compose_message_1`
  MODIFY `compose_message_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=157;

--
-- AUTO_INCREMENT for table `compose_msg_media_1`
--
ALTER TABLE `compose_msg_media_1`
  MODIFY `compose_msg_media_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=155;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
