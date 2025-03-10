<?
session_start();
error_reporting(E_ALL);
// Include configuration.php
include_once('../api/configuration.php');

$fn = $_SESSION['url_loc'];

$url = $fn;  
$file_name = basename($url); 

if ($fn) {
  //Perform security checks
  //.....check user session/role/whatever
  $result = $full_pathurl.''.$fn;
  if (file_exists($result)) {
    header('Content-Description: File Transfer');
    // header('Content-Type: application/force-download');
    header('Content-Type: application/csv');
    header('Content-Disposition: attachment; filename='.basename($result));
    header('Content-Transfer-Encoding: binary');
    header('Expires: 0');
    header('Cache-Control: must-revalidate, post-check=0, pre-check=0');
    header('Pragma: public');
    header('Content-Length: ' . filesize($result));
    ob_clean();
    flush();
    readfile($result);
    // file_put_contents( $filename, 
            // file_get_contents($furl));
    // @unlink($result);
  }
}
exit;
?>
