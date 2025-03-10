<?php
/*
Authendicated users only allow to view this Add Sender ID page.
This page is used to view the Add a New Sender ID.
It will send the form to API service and Save to Whatsapp Facebook
and get the response from them and store into our DB.

Version : 1.0
Author : Madhubala (YJ0009)
Date : 27-Jul-2023
*/

session_start(); // start session
error_reporting(0); // The error reporting function

include_once('api/configuration.php'); // Include configuration.php
extract($_REQUEST); // Extract the request

// If the Session is not available redirect to index page
if ($_SESSION['yjwatsp_user_id'] == "") { ?>
	<script>
	window.location = "index";
	</script>
	<?php exit();
}

/*if($_SESSION['yjwatsp_user_master_id'] != 1 and $_SESSION['yjwatsp_user_master_id'] != 2) { ?>
<script>
window.location = "dashboard";
</script>
<?php exit();
}*/

$site_page_name = pathinfo($_SERVER['PHP_SELF'], PATHINFO_FILENAME); // Collect the Current page name
site_log_generate("On Boarding Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"));

// To Send the request  API
$replace_txt = '{
  "user_id" : "' . $_SESSION["yjwatsp_user_id"] . '"
}';

// Add bearer token
$bearer_token = "Authorization: " . $_SESSION["yjwatsp_bearer_token"] . "";

// It will call "p_login" API to verify, can we allow to login the already existing user for access the details
$curl = curl_init();
curl_setopt_array(
	$curl,
	array(
		CURLOPT_URL => $api_url . '/user/view_user_list',
		CURLOPT_RETURNTRANSFER => true,
		CURLOPT_ENCODING => '',
		CURLOPT_MAXREDIRS => 10,
		CURLOPT_TIMEOUT => 0,
		CURLOPT_FOLLOWLOCATION => true,
		CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
		CURLOPT_CUSTOMREQUEST => 'GET',
		CURLOPT_POSTFIELDS => $replace_txt,
		CURLOPT_HTTPHEADER => array(
			$bearer_token,
			'Content-Type: application/json'
		),
	)
);

// Send the data into API and execute
// Log file generate
site_log_generate("On Boarding Page : " . $uname . " Execute the service [$replace_txt, $bearer_token] on " . date("Y-m-d H:i:s"), "../");

$response = curl_exec($curl);
// echo $response;
curl_close($curl);
// After got response decode the JSON result
$state1 = json_decode($response, false);

// Log file generate
site_log_generate("On Boarding Page : " . $uname . " get the Service response [$response] on " . date("Y-m-d H:i:s"), "../");

// To get the API response one by one data and assign to Session
if ($state1->response_status == 200) {
	// Looping the indicator is less than the count of response_result.if the condition is true to continue the process.if the condition are false to stop the process
	for ($indicator = 0; $indicator < count($state1->user_list); $indicator++) {
		$user_name = $state1->user_list[$indicator]->user_name;
		$user_email = $state1->user_list[$indicator]->user_email;
		$user_mobile = $state1->user_list[$indicator]->user_mobile;

		$user_type = $state1->user_list[$indicator]->user_type;
		$user_details = $state1->user_list[$indicator]->user_details;
		$user_status = $state1->user_list[$indicator]->usr_mgt_statuss;
		$login_id = $state1->user_list[$indicator]->login_id;
	}
}
?>
<!DOCTYPE html>
<html lang="en">

<head>
				<meta charset="UTF-8">
				<link rel="icon" href="assets/img/favicon.ico" type="image/x-icon">
				<meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
				<title>On Boarding ::
								<?= $site_title ?>
				</title>

				<!-- General CSS Files -->
				<link rel="stylesheet" href="assets/modules/bootstrap/css/bootstrap.min.css">
				<link rel="stylesheet" href="assets/modules/fontawesome/css/all.min.css">

				<!-- CSS Libraries -->

				<!-- Template CSS -->
				<link rel="stylesheet" href="assets/css/style.css">
				<link rel="stylesheet" href="assets/css/components.css">

				<!-- style include in css -->
				<style>
				.loader {
								width: 50;
								background-color: #ffffffcf;
				}

				.loader img {}

				.grid_clr_green {
								background-color: #c1e5cf1f;
								margin-right: -10px;
								margin-left: -10px;
				}

				.grid_clr_white {
								margin-right: -10px;
								margin-left: -10px;
				}
				</style>
</head>

<body>
				<div id="app">
								<div class="main-wrapper main-wrapper-1">
												<div class="navbar-bg"></div>

												<!-- include header function adding -->
												<? include("libraries/site_header.php"); ?>

												<!-- include sitemenu function adding -->
												<? include("libraries/site_menu.php"); ?>

												<!-- Main Content -->
												<div class="main-content">
																<section class="section">
																				<!-- Title and Breadcrumbs -->
																				<div class="section-header">
																								<h1>On Boarding</h1>
																								<div class="section-header-breadcrumb">
																												<div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
																												<div class="breadcrumb-item">On Boarding</div>
																								</div>
																				</div>

																				<!-- Form Entry Panel -->
																				<div class="section-body">
																								<div class="row">

																												<div class="col-8 col-md-8 col-lg-8 offset-md-2">
																																<div class="card" style="padding: 10px;">
																																				<form class="md-float-material form-material" action="#" name="frm_edit_onboarding"
																																								id='frm_edit_onboarding' class="needs-validation" novalidate=""
																																								enctype="multipart/form-data" method="post">
																																								<div>
																																												<div class="row m-b-20">
																																																<div class="col-md-12">
																																																				<h5 class="text-center"><i class="icofont icofont-sign-in"></i>Basic
																																																								Information </h5>
																																																</div>
																																																<button type="button" style="margin-left:93%"
																																																				class="btn btn-sm btn-primary waves-effect waves-light f-right"
																																																				data-toggle="tooltip" data-placement="top" title=""
																																																				data-original-title="Edit Personal Information">
																																																				<i class="fa fa-edit edit-btn"></i>
																																																</button>
																																												</div>
																																												<div class="row mt-2 grid_clr_green">
																																																<div class="col-6 label">
																																																				Client Name<label style="color:#FF0000">*</label>
																																																</div>
																																																<div class="col-6">

																																																				<input type="text" name="clientname_txt" id="clientname_txt"
																																																								class="form-control" value="<?= $user_name ?>" readonly
																																																								maxlength="50" tabindex="1" autofocus="" required=""
																																																								data-toggle="tooltip" data-placement="top" title=""
																																																								data-original-title="User Name" placeholder="User Name"
																																																								pattern="[a-zA-Z0-9 -_]+"
																																																								onkeypress="return clsAlphaNoOnly(event)"
																																																								onpaste="return false;">
																																																</div>
																																												</div>
																																												<div class="row mt-2 grid_clr_white">
																																																<div class="col-6 label">
																																																				User Mobile<label style="color:#FF0000">*</label>
																																																</div>
																																																<div class="col-6">

																																																				<input type="text" name="mobile_no_txt" id="mobile_no_txt"
																																																								class="form-control" value="<?= $user_mobile ?>" maxlength="10"
																																																								readonly tabindex="4" autofocus="" required=""
																																																								data-toggle="tooltip" data-placement="top" title=""
																																																								data-original-title="User Mobile" placeholder="User Mobile"
																																																								onkeypress="return (event.charCode !=8 && event.charCode ==0 ||  (event.charCode >= 48 && event.charCode <= 57))">
																																																</div>
																																												</div>
																																												<div class="row mt-2 grid_clr_green">
																																																<div class="col-6 label">
																																																				User Email ID<label style="color:#FF0000">*</label>
																																																</div>
																																																<div class="col-6">

																																																				<input type="text" name="email_id_contact" id="email_id_contact"
																																																								class="form-control" value="<?= $user_email ?>" maxlength="100"
																																																								readonly tabindex="5" autofocus="" required=""
																																																								data-toggle="tooltip" data-placement="top" title=""
																																																								data-original-title="User Email ID" placeholder="User Email ID">
																																																</div>
																																												</div>
																																												<div class="row mt-2 grid_clr_white">
																																																<div class="col-6 label">
																																																				User Type<label style="color:#FF0000">*</label>
																																																</div>
																																																<div class="col-6">

																																																				<input type="text" name="login_id_txt" id="login_id_txt"
																																																								class="form-control" value="User" maxlength="50" readonly
																																																								tabindex="1" autofocus="" required="" data-toggle="tooltip"
																																																								data-placement="top" title="" data-original-title="Login ID"
																																																								placeholder="Login ID" pattern="[a-zA-Z0-9 -_]+"
																																																								onkeypress="return clsAlphaNoOnly(event)"
																																																								onpaste="return false;">
																																																</div>
																																												</div>


																																												<? if ($rejected_comments != '') { ?>
																																													<div class="row mt-2 grid_clr_green">
																																																	<div class="col-6 label">
																																																					Remarks
																																																	</div>
																																																	<div class="col-6 error_display text-left">
																																																					<b>
																																																									<?= $rejected_comments ?>
																																																					</b>
																																																	</div>
																																													</div>
																																												<? } ?>
																																								</div>
																																								<? if ($user_status != 'Y') { ?>
																																									<div class="row m-t-30">
																																													<div class="col-md-12" style="text-align:center;">
																																																	<span class="error_display text-center"
																																																					id='id_error_display_onboarding'></span>&nbsp;
																																													</div>
																																									</div>

																																									<div class="row  m-t-30">
																																													<div class="col-md-12" style="text-align:center">
																																																	<input type="hidden" class="form-control" name='call_function'
																																																					id='call_function' value='edit_onboarding' />
																																																	<input type="submit" name="submit_onboarding" id="submit_onboarding"
																																																					style="width:150px;margin-left:auto;margin-right:auto" tabindex="30"
																																																					value="Submit"
																																																					class="btn btn-success btn-md btn-block waves-effect waves-light text-center ">
																																													</div>
																																									</div>
																																								<? } ?>
																																								<div class="row m-t-30">
																																												<div class="col-md-12" style="text-align:center;">&nbsp;</div>
																																								</div>

																																</div>
																																</form>
																												</div>
																								</div>
																				</div>
												</div>
												</section>
								</div>
								<!-- include site footer -->
								<? include("libraries/site_footer.php"); ?>
				</div>
				</div>

				<!-- General JS Scripts -->
				<script src="assets/modules/jquery.min.js"></script>
				<script src="assets/modules/popper.js"></script>
				<script src="assets/modules/tooltip.js"></script>
				<script src="assets/modules/bootstrap/js/bootstrap.min.js"></script>
				<script src="assets/modules/nicescroll/jquery.nicescroll.min.js"></script>
				<script src="assets/modules/moment.min.js"></script>
				<script src="assets/js/stisla.js"></script>

				<!-- JS Libraies -->

				<!-- Page Specific JS File -->

				<!-- Template JS File -->
				<script src="assets/js/scripts.js"></script>
				<script src="assets/js/custom.js"></script>

				<!--Remove dublicates numbers -->
				<script>
				// start function document
				$(function() {
								$('#id_qrcode').fadeOut("slow");
				});

				$('.edit-btn').click(function() {
								if ($('.form-control').is('[readonly]')) { //checks if it is already on readonly mode
												$('.form-control').prop('readonly', false); //turns the readonly off
								} else { //else we do other things
												$('.form-control').prop('readonly', true);
								}
				});

				document.body.addEventListener("click", function(evt) {
								$("#id_error_display_onboarding").html("");
				})

				// Sign up submit Button function Start
				$(document).on("submit", "form#frm_edit_onboarding", function(e) {
								e.preventDefault();
								$("#id_error_display_onboarding").html("");
								//get input field values 
								var clientname_txt = $('#clientname_txt').val();
								var login_id_txt = $('#login_id_txt').val();
								var mobile_no_txt = $('#mobile_no_txt').val();
								var email_id_contact = $('#email_id_contact').val();
								var flag = true;
								/********validate all our form fields***********/
								if (clientname_txt == "") {
												$('#clientname_txt').css('border-color', 'red');
												flag = false;
								}
								if (login_id_txt == "") {
												$('#login_id_txt').css('border-color', 'red');
												flag = false;
								}
								if (email_id_contact == "") {
												$('#email_id_contact').css('border-color', 'red');
												flag = false;
								}

								if (mobile_no_txt == "") {
												$('#mobile_no_txt').css('border-color', 'red');
												flag = false;
								}
								var mobile_no_txt = document.getElementById('mobile_no_txt').value;
								if (mobile_no_txt.length != 10) {
												$("#id_error_display_onboarding").html("Please enter a valid mobile number");
												flag = false;
								}
								if (!(mobile_no_txt.charAt(0) == "9" || mobile_no_txt.charAt(0) == "8" || mobile_no_txt.charAt(0) ==
																"6" || mobile_no_txt.charAt(0) == "7")) {
												$("#id_error_display_onboarding").html("Please enter a valid mobile number");
												document.getElementById('mobile_no_txt').focus();
												flag = false;
								}
								/************************************/

								var email_id_contact = $('#email_id_contact').val();
								/* Email field validation  */
								var filter = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i
								if (filter.test(email_id_contact)) {
												// flag = true;
								} else {
												$("#id_error_display_onboarding").html("Email is invalid");
												document.getElementById('email_id_contact').focus();
												flag = false;
												e.preventDefault();
								}
								/********Validation end here ****/

								// alert("FLAG=="+flag+"==");
								$('#submit_onboarding').attr('disabled', false);
								/* If all are ok then we send ajax request to call_functions.php *******/
								if (flag) {
												var fd = new FormData(this);
												$.ajax({
																type: 'post',
																url: "ajax/call_functions.php",
																dataType: 'json',
																data: fd,
																contentType: false,
																processData: false,
																beforeSend: function() { // Before Send to Ajax
																				$('#submit_onboarding').attr('disabled', true);
																				$('#load_page').show();
																},
																complete: function() { // After complete the Ajax
																				$('#submit_onboarding').attr('disabled', false);
																				$('#load_page').hide();
																},
																success: function(response) { // Success
																				// exit();
																				if (response.status == 2 || response.status == 0) { // Failure Response
																								$('#submit_onboarding').attr('disabled', false);
																								$("#id_error_display_onboarding").html(response.msg);
																				} else if (response.status == 1) { // Success Response
																								$('#submit_onboarding').attr('disabled', false);
																								$("#id_error_display_onboarding").html(response.msg);
																								setInterval(function() {
																												window.location = 'dashboard';
																								}, 2000);
																				}
																},
																error: function(response, status, error) { // If any error occurs
																				// die();
																				$('#submit_onboarding').attr('disabled', false);
																				$("#id_error_display_onboarding").html(response.msg);
																}
												});
								}
				});

				function clsAlphaNoOnly(e) { // Accept only alpha numerics, no special characters 
								var key = e.keyCode;
								if ((key >= 65 && key <= 90) || (key >= 97 && key <= 122) || (key >= 48 && key <= 57) || (key == 32) || (key ==
																95)) {
												return true;
								}
								return false;
				}

				// TEMplate Name - Space
				$(function() {
								$('#clientname_txt').on('keypress', function(e) {
												if (e.which == 32) {
																console.log('Space Detected');
																return false;
												}
								});
				});
				$(function() {
								$('#contact_person_txt').on('keypress', function(e) {
												if (e.which == 32) {
																console.log('Space Detected');
																return false;
												}
								});
				});
				</script>
</body>

</html>
