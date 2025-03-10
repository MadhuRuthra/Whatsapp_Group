<?php
session_start();
error_reporting(0);

header("Pragma: no-cache");
header("Cache-Control: no-cache");
header("Expires: 0");

// Include configuration.php
include_once('../api/configuration.php');
// Paytm Operation - Start
require_once("../PaytmKit/lib/config_paytm.php");
require_once("../PaytmKit/lib/encdec_paytm.php"); 
extract($_REQUEST);

$current_date = date("Y-m-d H:i:s");
$milliseconds = round(microtime(true) * 1000);

// echo "==".$_SERVER['REQUEST_METHOD']."==";
// print_r($_REQUEST);

// user_management Page paytm_payment - Start
if($_SERVER['REQUEST_METHOD'] == "GET" and $action_process == "paytm_payment") {
	// $qur_cda = $conn->query("SELECT usrsmscrd_id, raise_sms_credits, sms_amount 
	// 														FROM user_sms_credit_raise 
	// 														where user_id = '".$_SESSION['yjtsms_user_id']."' 
	// 														order by usrsmscrd_id desc limit 1");
	$curl = curl_init();
curl_setopt_array($curl, array(
  CURLOPT_URL => $api_url.'/select_query',
  CURLOPT_RETURNTRANSFER => true,
  CURLOPT_ENCODING => '',
  CURLOPT_MAXREDIRS => 10,
  CURLOPT_TIMEOUT => 0,
  CURLOPT_FOLLOWLOCATION => true,
  CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
  CURLOPT_CUSTOMREQUEST => 'POST',
  CURLOPT_POSTFIELDS =>'{
"query":"SELECT usrsmscrd_id, raise_sms_credits, sms_amountFROM user_sms_credit_raise where user_id = \''.$_SESSION['yjtsms_user_id'].'\'order by usrsmscrd_id desc limit 1"
}',
  CURLOPT_HTTPHEADER => array(
    'Content-Type: application/json'
  ),
));
$response = curl_exec($curl);
curl_close($curl);
// echo $response;
$obj = json_decode( $response);
for($indicator = 0; $indicator < $obj->num_of_rows; $indicator++){ 
	
	// while ($row_cda = $qur_cda->fetch_object()) {
		$cda = $obj->result[$indicator]->usrsmscrd_id;
	}

	if($cda != '') {
		$_SESSION['user_cda'] = $cda;
		// $qur_usc = $conn->query("SELECT usrsmscrd_id, raise_sms_credits, sms_amount 
		// 													FROM user_sms_credit_raise 
		// 													where usrsmscrd_id = '$cda'");
		$curl = curl_init();
		curl_setopt_array($curl, array(
			CURLOPT_URL => $api_url.'/select_query',
			CURLOPT_RETURNTRANSFER => true,
			CURLOPT_ENCODING => '',
			CURLOPT_MAXREDIRS => 10,
			CURLOPT_TIMEOUT => 0,
			CURLOPT_FOLLOWLOCATION => true,
			CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
			CURLOPT_CUSTOMREQUEST => 'POST',
			CURLOPT_POSTFIELDS =>'{
		"query":"SELECT usrsmscrd_id, raise_sms_credits, sms_amount FROM user_sms_credit_raise where usrsmscrd_id = '.$cda.'"
		}',
			CURLOPT_HTTPHEADER => array(
				'Content-Type: application/json'
			),
		));
		$response = curl_exec($curl);
		curl_close($curl);
		// echo $response;
		$obj = json_decode( $response);
		if ($obj->num_of_rows > 0) {
			// while ($row_usc = $qur_usc->fetch_object()) {		
				for($indicator = 0; $indicator < $obj->num_of_rows; $indicator++){ 

				$orderId 		= time();
				$txnAmount 	= $obj->result[$indicator]->sms_amount;
				$custId 		= "cust".$_SESSION['yjtsms_user_id'];
				$mobileNo 	= $_SESSION['yjtsms_user_mobile'];
				$email 			= $_SESSION['yjtsms_user_email'];

				$paytmParams = array();
				$paytmParams["ORDER_ID"] 	        = $orderId;
				$paytmParams["CUST_ID"] 	        = $custId;
				$paytmParams["MOBILE_NO"] 	      = $mobileNo;
				$paytmParams["EMAIL"] 		        = $email;
				$paytmParams["TXN_AMOUNT"] 	      = $txnAmount;
				$paytmParams["MID"] 		        	= PAYTM_MERCHANT_MID;
				$paytmParams["CHANNEL_ID"] 	      = PAYTM_CHANNEL_ID;
				$paytmParams["WEBSITE"] 	        = PAYTM_MERCHANT_WEBSITE;
				$paytmParams["INDUSTRY_TYPE_ID"]  = PAYTM_INDUSTRY_TYPE_ID;
				$paytmParams["CALLBACK_URL"]      = PAYTM_CALLBACK_URL."&cda=".$cda;
				$paytmChecksum                    = getChecksumFromArray($paytmParams, PAYTM_MERCHANT_KEY);
				$transactionURL                   = PAYTM_TXN_URL;

				// $transactionURL                = "https://securegw-stage.paytm.in/theia/processTransaction";
				// $transactionURL                = "https://securegw.paytm.in/theia/processTransaction"; // for production
				?>
				<html>
						<head>
								<title>Merchant Checkout Page</title>
						</head>
						<body>
								<center><h1>Please do not refresh this page...</h1></center>
								<form method='post' action='<?php echo $transactionURL; ?>' name='f1' id='f1'>
										<?php
											foreach($paytmParams as $name => $value) {
													echo '<input type="hidden" name="' . $name .'" value="' . $value . '">';
											}
										?>
										<input type="hidden" name="CHECKSUMHASH" value="<?php echo $paytmChecksum ?>">
										<span style="display: none;"><input type="submit" name="submit" value="submit" /></span>
								</form>
								<script type="text/javascript">
										document.getElementById("f1").submit.click();
								</script>
						</body>
				</html>
				<?
				// Paytm Operation - End
			}

		}
	}
} 
// user_management Page paytm_payment - End

// user_management Page paytm_payment from Paytm - Start
if($_SERVER['REQUEST_METHOD'] == "POST" and $action_process == "paytm_payment") {
	// echo "==".$_SESSION['user_cda']."==".$cda."==";
	$_SESSION['user_cda'] = $cda;
		// $qur_usc = $conn->query("SELECT usrsmscrd_id, user_id, raise_sms_credits, sms_amount 
		// 													FROM user_sms_credit_raise 
		// 													where usrsmscrd_id = '".$_SESSION['user_cda']."'");
		$curl = curl_init();
		curl_setopt_array($curl, array(
			CURLOPT_URL => $api_url.'/select_query',
			CURLOPT_RETURNTRANSFER => true,
			CURLOPT_ENCODING => '',
			CURLOPT_MAXREDIRS => 10,
			CURLOPT_TIMEOUT => 0,
			CURLOPT_FOLLOWLOCATION => true,
			CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
			CURLOPT_CUSTOMREQUEST => 'POST',
			CURLOPT_POSTFIELDS =>'{
		"query":"SELECT usrsmscrd_id, user_id, raise_sms_credits, sms_amount FROM user_sms_credit_raise where usrsmscrd_id = '.$_SESSION['user_cda'].'"
		}',
			CURLOPT_HTTPHEADER => array(
				'Content-Type: application/json'
			),
		));
		$response = curl_exec($curl);
		curl_close($curl);
		// echo $response;
		$obj = json_decode( $response);
		if ($obj->num_of_rows > 0) {
			// while ($row_usc = $qur_usc->fetch_object()) {		
				for($indicator = 0; $indicator < $obj->num_of_rows; $indicator++){ 

		// if ($qur_usc->num_rows > 0) {
		// 	while ($row_usc = $qur_usc->fetch_object()) {
				
				$paytmChecksum = "";
				$paramList = array();
				$isValidChecksum = "FALSE";
				$usrid = $obj->result[$indicator]->user_id;

				$paramList = $_POST;
				$paytmChecksum = isset($_POST["CHECKSUMHASH"]) ? $_POST["CHECKSUMHASH"] : ""; //Sent by Paytm pg

				//Verify all parameters received from Paytm pg to your application. Like MID received from paytm pg is same as your application’s MID, TXN_AMOUNT and ORDER_ID are same as what was sent by you to Paytm PG for initiating transaction etc.
				$isValidChecksum = verifychecksum_e($paramList, PAYTM_MERCHANT_KEY, $paytmChecksum); //will return TRUE or FALSE string.

				if($isValidChecksum == "TRUE") {
					// echo "<b>Checksum matched and following are the transaction details:</b>" . "<br/>";
					
					// echo "<pre>";
					// print_r($_POST);
					// echo "<pre>";
					$resp_status = "STATUS:".$_POST["STATUS"]."! ORDERID:".$_POST["ORDERID"]."! MID:".$_POST["MID"]."! TXNID:".$_POST["TXNID"]."! TXNAMOUNT:".$_POST["TXNAMOUNT"]."! RESPCODE:".$_POST["RESPCODE"]."! RESPMSG:".$_POST["RESPMSG"]."! BANKTXNID:".$_POST["BANKTXNID"]."! GATEWAYNAME:".$_POST["GATEWAYNAME"]."! BANKNAME:".$_POST["BANKNAME"];

					if ($_POST["STATUS"] == "TXN_SUCCESS") {
						// echo "<b>Transaction status is success</b>" . "<br/>";
						//Process your transaction here as success transaction.
						//Verify amount & order id received from Payment gateway with your application's order id and amount.
						// echo "UPDATE user_sms_credit_raise SET usrsmscrd_status = 'A', usrsmscrd_status_cmnts = '".$resp_status."' WHERE usrsmscrd_id = ".$_SESSION['user_cda'];
						$curl = curl_init();

curl_setopt_array($curl, array(
  CURLOPT_URL => $api_url.'/update_query',
  CURLOPT_RETURNTRANSFER => true,
  CURLOPT_ENCODING => '',
  CURLOPT_MAXREDIRS => 10,
  CURLOPT_TIMEOUT => 0,
  CURLOPT_FOLLOWLOCATION => true,
  CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
  CURLOPT_CUSTOMREQUEST => 'PUT',
  CURLOPT_POSTFIELDS =>'{
	"table_name" : "user_sms_credit_raise",
	"values" : "usrsmscrd_status = \'A\', usrsmscrd_status_cmnts = \''.$resp_status.'\' ",
	"where_condition" : "usrsmscrd_id = '.$_SESSION['user_cda'].'"
}',
  CURLOPT_HTTPHEADER => array(
    'Content-Type: application/json'
  ),
));

$response = curl_exec($curl);

curl_close($curl);
// echo $response;
	$obj = json_decode( $response);
						/*$sql_updt_usc = $conn->query("UPDATE user_sms_credit_raise 
																							SET usrsmscrd_status = 'A', usrsmscrd_status_cmnts = '".$resp_status."' 
																						WHERE usrsmscrd_id = ".$_SESSION['user_cda']);*/
				
					}
					else {
						// echo "<b>Transaction status is failure</b>" . "<br/>";
						// echo "UPDATE user_sms_credit_raise SET usrsmscrd_status = 'F', usrsmscrd_status_cmnts = '".$_POST["RESPMSG"]."' WHERE usrsmscrd_id = ".$_SESSION['user_cda'];
						$curl = curl_init();

						curl_setopt_array($curl, array(
							CURLOPT_URL => $api_url.'/update_query',
							CURLOPT_RETURNTRANSFER => true,
							CURLOPT_ENCODING => '',
							CURLOPT_MAXREDIRS => 10,
							CURLOPT_TIMEOUT => 0,
							CURLOPT_FOLLOWLOCATION => true,
							CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
							CURLOPT_CUSTOMREQUEST => 'PUT',
							CURLOPT_POSTFIELDS =>'{
							"table_name" : "user_sms_credit_raise",
							"values" : "usrsmscrd_status = \'F\', usrsmscrd_status_cmnts = \''.$_POST["RESPMSG"].'\' ",
							"where_condition" : "usrsmscrd_id = '.$_SESSION['user_cda'].'"
						}',
							CURLOPT_HTTPHEADER => array(
								'Content-Type: application/json'
							),
						));
						
						$response = curl_exec($curl);
						
						curl_close($curl);
						// echo $response;
							$obj = json_decode( $response);
				 /*		$sql_updt_usc = $conn->query("UPDATE user_sms_credit_raise 
																							SET usrsmscrd_status = 'F', usrsmscrd_status_cmnts = '".$_POST["RESPMSG"]."'
																						WHERE usrsmscrd_id = ".$_SESSION['user_cda']); */
																						
					}

					/* if (isset($_POST) && count($_POST)>0 )
					{ 
						foreach($_POST as $paramName => $paramValue) {
								echo "<br/>" . $paramName . " = " . $paramValue;
						}
					} */
				}
				else {
					echo "<b>Checksum mismatched.</b>";
					//Process transaction as suspicious.
				}
			}
		}
		$curl = curl_init();
		curl_setopt_array($curl, array(
			CURLOPT_URL => $api_url.'/select_query',
			CURLOPT_RETURNTRANSFER => true,
			CURLOPT_ENCODING => '',
			CURLOPT_MAXREDIRS => 10,
			CURLOPT_TIMEOUT => 0,
			CURLOPT_FOLLOWLOCATION => true,
			CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
			CURLOPT_CUSTOMREQUEST => 'POST',
			CURLOPT_POSTFIELDS =>'{
		"query":"SELECT * FROM user_management where user_id = \''.$usrid.'\'"
		}',
			CURLOPT_HTTPHEADER => array(
				'Content-Type: application/json'
			),
		));
		$response = curl_exec($curl);
		curl_close($curl);
		// echo $response;
		$obj = json_decode( $response);
		// $sql = "SELECT * FROM user_management where user_id = '$usrid'";
		// $qur = $conn->query($sql);

		if ($obj->num_of_rows > 0) {
			for($indicator = 0; $indicator < $obj->num_of_rows; $indicator++){ 
				
			// while($row = $qur->fetch_assoc()) {
			// 	extract($row);
				$_SESSION['yjtsms_parent_id'] 		= $obj->result[$indicator]->parent_id;
				$_SESSION['yjtsms_user_id'] 			= $obj->result[$indicator]->user_id;
				$_SESSION['yjtsms_user_master_id']= $obj->result[$indicator]->user_master_id;
				$_SESSION['yjtsms_user_name'] 		= $obj->result[$indicator]->user_name;
				$_SESSION['yjtsms_api_key'] 			= $obj->result[$indicator]->api_key;

				$_SESSION['yjtsms_login_id'] 			= $obj->result[$indicator]->login_id;
				$_SESSION['yjtsms_user_email'] 		= $obj->result[$indicator]->user_email;
				$_SESSION['yjtsms_user_mobile'] 	= $obj->result[$indicator]->user_mobile;
				$_SESSION['yjtsms_price_per_sms'] = $obj->result[$indicator]->price_per_sms;
				$_SESSION['yjtsms_netoptid'] 			= $obj->result[$indicator]->network_operators_id;
			}
		}
} 
// user_management Page paytm_payment from Paytm - End

// Finally Close all Opened Mysql DB Connection
$conn->close();
// exit;
?>
<script>window.location = "../sms_credit_list";</script>