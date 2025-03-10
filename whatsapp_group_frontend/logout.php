<?php
/*
This page is used to Logout the user.
Every valid user can logout here and 
clear & Destroy the session.
Version : 1.0
Author : Arun Rama Balan.G (YJ0005)
Date : 06-Jul-2023
*/

include_once('api/configuration.php'); // Include Configuration File
header('Cache-Control: no cache'); //no cache // This is for avoid failure in submit form  pagination form details page
session_cache_limiter('private_no_expire, must-revalidate'); // works // This is for avoid failure in submit form  pagination form details page

session_start(); // Start the Session
site_log_generate("Logout Page : User : '" . $_SESSION['yjwatsp_user_name'] . "' logged out successfully on " . date("Y-m-d H:i:s")); // Log File

// Update data into data base
$bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
$request_id = $_SESSION['yjwatsp_user_id'] . "_" . date("Y") . "" . date('z', strtotime(date("d-m-Y"))) . "" . date("His") . "_" . rand(1000, 9999);
$replace_txt = '{
	"request_id":"' . $request_id . '"
  }';


$curl = curl_init();
curl_setopt_array($curl, array(
	CURLOPT_URL => $api_url . '/logout',
	CURLOPT_RETURNTRANSFER => true,
	CURLOPT_ENCODING => '',
	CURLOPT_MAXREDIRS => 10,
	CURLOPT_TIMEOUT => 0,
	CURLOPT_FOLLOWLOCATION => true,
	CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
	CURLOPT_SSL_VERIFYPEER => 0,
	CURLOPT_CUSTOMREQUEST => 'POST',
	CURLOPT_POSTFIELDS => $replace_txt,
	CURLOPT_HTTPHEADER => array(
		$bearer_token,
		'Content-Type: application/json'
	),
)
);

// Send the data into API and execute 
site_log_generate("Logout Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
$response = curl_exec($curl);
curl_close($curl);

// After got response decode the JSON result
$header = json_decode($response, false);
site_log_generate("Logout Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

// Clear the Session
$_SESSION['yjwatsp_parent_id'] = '';
$_SESSION['yjwatsp_user_id'] = '';
$_SESSION['yjwatsp_user_master_id'] = '';
$_SESSION['yjwatsp_user_name'] = '';
$_SESSION['yjwatsp_bearer_token'] = '';

// Clear the Session
$_SESSION = array();
// If it's desired to kill the session, also delete the session cookie.
// Note: This will destroy the session, and not just the session data!
if (ini_get("session.use_cookies")) {
	$params = session_get_cookie_params();
	setcookie(
		session_name(),
		'', time() - 42000,
		$params["path"], $params["domain"],
		$params["secure"], $params["httponly"]
	);
}

// Set the Session details
ini_set('session.gc_max_lifetime', 0);
ini_set('session.gc_probability', 1);
ini_set('session.gc_divisor', 1);

// Destory the Session
session_write_close();
session_unset();
session_destroy();
site_log_generate("Logout Page : All sessions destroyed successfully on " . date("Y-m-d H:i:s")); // Log File
?>
<script>window.location = "index";</script> <!-- Redirect to Index page -->