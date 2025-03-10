<?php 
header('Cache-Control: no cache'); //no cache // This is for avoid failure in submit form  pagination form details page
session_cache_limiter('private_no_expire, must-revalidate'); // works // This is for avoid failure in submit form  pagination form details page

session_start();
$_SESSION['tcs_username'] = '';
$_SESSION['tcs_userid'] = '';
$_SESSION['tcs_user'] = '';
$_SESSION['tcs_userid1'] = '';
$_SESSION['tcs_mainmenu_access'] = '';
$_SESSION['tcs_submenu_access'] = '';
$_SESSION['tcs_menuid'] = '';

$_SESSION['tcs_empsrno'] = '';
$_SESSION['tcs_brncode'] = '';
$_SESSION['tcs_empname'] = '';
$_SESSION['tcs_esecode'] = '';
$_SESSION['tcs_descode'] = '';
$_SESSION['tcs_section'] = '';
$_SESSION['tcs_partsup'] = '';
$_SESSION['tcs_supemp'] = '';
$_SESSION['tcs_section_rights'] = '';
$_SESSION['lastid'] = '';
$_SESSION['tcs_userip'] = '';

$_SESSION['security_pwds'] = '';
$_SESSION['security_url'] = '';
$_SESSION['outside'] = '';



$_SESSION = array();
// If it's desired to kill the session, also delete the session cookie.
// Note: This will destroy the session, and not just the session data!
if (ini_get("session.use_cookies")) {
    $params = session_get_cookie_params();
    setcookie(session_name(), '', time() - 42000,
        $params["path"], $params["domain"],
        $params["secure"], $params["httponly"]
    );
}

// Use this too
ini_set('session.gc_max_lifetime', 0);
ini_set('session.gc_probability', 1);
ini_set('session.gc_divisor', 1);


session_write_close();
session_unset(); 
session_destroy();
?>
<script>window.location="index.php";</script>