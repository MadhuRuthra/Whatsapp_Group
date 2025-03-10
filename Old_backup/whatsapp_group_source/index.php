<?
/*
This page is used to authendicate the user.
Every valid user can login here to access their
role based services.

Version : 1.0
Author : Arun Rama Balan.G (YJ0005)
Date : 06-Jul-2023
*/

session_start(); // To start session
error_reporting(0); // The error reporting function

// Include configuration.php
include_once('api/configuration.php');

// To find what is the previous page link and redirect to that link
$newPageName = substr($_SERVER["HTTP_REFERER"], strrpos($_SERVER["HTTP_REFERER"], "/") + 1);
if ($_SERVER['HTTP_REFERER'] == '' or $newPageName == 'index' or $newPageName == 'logout' or $newPageName == 'dashboard') {
  $server_http_referer = $site_url . "dashboard";
} elseif ($_SERVER['HTTP_REFERER'] == $site_url or $newPageName == 'index.php') {
  $server_http_referer = $site_url . "dashboard";
} else {
  $server_http_referer = $_SERVER['HTTP_REFERER'];
}

// If Session available user try to access this page, then it will redirect to Logout page
if ($_SESSION['yjtsms_user_id'] != "") { ?>
  <script>
    window.location = "logout";
  </script>
<?php exit();
}
site_log_generate("Index Page : Unknown User : '" . $_SESSION['yjtsms_user_id'] . "' access this page on " . date("Y-m-d H:i:s")); // Log file
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Login - <?= $site_title ?></title>
  <link rel="icon" href="assets/img/favicon.ico" type="image/x-icon">

  <!-- General CSS Files -->
  <link rel="stylesheet" href="assets/modules/bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="assets/modules/fontawesome/css/all.min.css">

  <!-- CSS Libraries -->
  <link rel="stylesheet" href="assets/modules/bootstrap-social/bootstrap-social.css">
  
  <!-- Template CSS -->
  <link rel="stylesheet" href="assets/css/style.css">
  <link rel="stylesheet" href="assets/css/components.css">
  <style>
    .progress {
      height: 0.3rem !important;
    }
    .row { margin: 5px 0 !important; }
  </style>

<body>
  <div id="app">
    <section class="section">
      <div class="container mt-5">
        <div class="row">
          <div class="col-sm-12 offset-sm-0 col-md-6 offset-md-3">
            <div class="login-brand">
              <img src="assets/img/yeejai-logo.png" alt="logo" style="width: 100%"> <!-- Logo -->
            </div>

            <div class="card-header text-center" style="display: block; border: 1px solid #e0e0e0;"><h3><?=$site_title?></h3></div>
            <div class="card card-success">
              <!-- Signin -->
              <div class="card-body" id="tab_signin" style="display: block;">
                <form class="md-float-material form-material" action="#" name="frm_login" id='frm_login' method="post">
                  <div>
                    <div class="row m-b-20">
                      <div class="col-md-12">
                        <h3 class="text-center"><i class="icofont icofont-sign-in"></i> Sign In</h3>
                      </div>
                    </div>
                    <div class="row">
                      <div class="col-4">
                        Email / Mobile No<label style="color:#FF0000">*</label>
                      </div>
                      <div class="col-8">
                        <input type="text" name="txt_username" id="txt_username" class="form-control" value="" maxlength="100" tabindex="1" autofocus="" required="" data-toggle="tooltip" data-placement="top" title="" data-original-title="Email / Mobile No" placeholder="Email / Mobile No"> <!-- Email/Mobile No -->
                      </div>
                    </div>

                    <div class="row mt-2">
                      <div class="col-4">
                        Login Password<label style="color:#FF0000">*</label>
                      </div>
                      <div class="col-8">
                        <div class="input-group" title="Visible Password">
                          <input type="password" name="txt_password" id='txt_password' class="form-control" value="" maxlength="100" tabindex="2" required="" data-toggle="tooltip" data-placement="top" title="" data-original-title="Login Password" placeholder="Login Password"> <!-- Password -->
                        </div>
                      </div>
                    </div>


                    <div class="row m-t-30">
                      <div class="col-md-12 text-center">
                        <span class="error_display" id='id_error_display_signin'></span> <!-- Error Display -->
                      </div>
                      <div class="col-md-4"></div>
                    </div>

                    <div class="row  mt-4">
                      <div class="col-md-4"></div>
                      <div class="col-md-4">
                        <input type="hidden" class="form-control" name='call_function' id='call_function' value='signin' /> <!-- Process Name -->
                        <input type="hidden" class="form-control" name='hid_sendurl' id='hid_sendurl' value='<?= $server_http_referer ?>' /> <!-- Redirect Link -->
                        <input type="submit" name="submit" id="submit" tabindex="3" value="Sign in" class="btn btn-success btn-md btn-block waves-effect waves-light text-center m-b-20"> <!-- Submit Button -->
                      </div>
                      <div class="col-md-4"></div>
                    </div>

                    <div class="row m-t-1">
                      <div class="col-md-6 text-left"><a class="nav-link" data-toggle="tab" href="#tab_signup" onclick="func_open_tab('signup')" role="tab">Sign Up</a></div>
                      <div class="col-md-6 text-right"><a class="nav-link" data-toggle="tab" href="#tab_forgotpwd" onclick="func_open_tab('forgotpwd')" role="tab">Forgot Password?</a></div>
                    </div>

                  </div>
                </form>
              </div>
              <!-- Signin -->

              <!-- Sign Up -->
              <div class="card-body" id="tab_signup" style="position: relative; display: none;">
                <form class="md-float-material form-material" action="#" name="frm_signup" id='frm_signup' method="post">

                  <div>
                    <div class="row m-b-20">
                      <div class="col-md-12">
                        <h3 class="text-center txt-primary"><i class="icofont icofont-ui-user "></i> Sign up</h3>
                      </div>
                    </div>
                    <div class="row">
                      <div class="col-4">
                        Name<label style="color:#FF0000">*</label>
                      </div>
                      <div class="col-8">
                        <input type="text" name="txt_user_name" id="txt_user_name" class="form-control" maxlength="30" value="" tabindex="2" autofocus="" required="" data-toggle="tooltip" data-placement="top" title="" onblur="func_display_loginid()" style="text-transform:uppercase" data-original-title="Name" pattern="[a-zA-Z0-9 -_]+" onkeypress="return clsAlphaNoOnly(event)" onpaste="return false;" placeholder="Name">
                        <span class="form-bar"></span>
                      </div>
                    </div>
                    <div class="row">
                      <div class="col-4">
                        Email ID<label style="color:#FF0000">*</label>
                      </div>
                      <div class="col-8">
                        <input type="email" name="txt_user_email" id='txt_user_email' class="form-control" maxlength="50" value="" tabindex="3" required="" data-toggle="tooltip" data-placement="top" title="" data-original-title="Email ID" placeholder="Email ID">
                        <span class="form-bar"></span>
                      </div>
                    </div>
                    <div class="row">
                      <div class="col-4">
                        Mobile No<label style="color:#FF0000">*</label>
                      </div>
                      <div class="col-8">
                        <input type="text" name="txt_user_mobile" id='txt_user_mobile' class="form-control" onkeypress="return (event.charCode !=8 && event.charCode ==0 || ( event.charCode == 46 || (event.charCode >= 48 && event.charCode <= 57)))" onkeyup="return call_validate_mobileno()" maxlength="10" value="" tabindex="4" required="" data-toggle="tooltip" data-placement="top" title="" data-original-title="Mobile No" placeholder="Mobile No">
                        <span class="form-bar"></span>
                      </div>
                    </div>
                    
                    <div class="row" id="id_otp">
                      <div class="col-4">
                        Enter the OTP<label style="color:#FF0000">*</label>
                      </div>
                      <div class="col-8">
                        <input type="text" name="txt_mobile_otp" id='txt_mobile_otp' class="form-control" onkeypress="return (event.charCode !=8 && event.charCode ==0 || ( event.charCode == 46 || (event.charCode >= 48 && event.charCode <= 57)))" onkeyup="return call_validate_mobileno()" maxlength="6" value="" tabindex="4" required="" data-toggle="tooltip" data-placement="top" title="" data-original-title="Enter the OTP" placeholder="Enter the OTP"  onblur="return validate_otp()">
                        <span class="form-bar"></span>
                      </div>
                    </div>

                    <div class="row" id="id_pwd" style="display: none">
                      <div class="col-4">
                        Login Password<label style="color:#FF0000">*</label>
                      </div>
                      <div class="col-8">

                        <div class="input-group" title="Visible Signup Password">
                          <input type="password" name="txt_user_password" id='txt_user_password' class="form-control" maxlength="100" value="" tabindex="10" required="" data-toggle="tooltip" data-placement="top" title="" data-original-title="Login Password -  [Atleast 8 characters and Must Contains Numeric, Capital Letters and Special characters]" placeholder="Login Password -  [Atleast 8 characters and Must Contains Numeric, Capital Letters and Special characters]" onblur="return checkPasswordStrength()">
                          <span class="form-bar"></span>
                          <span class="input-group-addon" onclick="password_visible1()" id='id_signup_display_visiblitity'><i class="icofont icofont-eye-blocked"></i></span>
                        </div>

                      </div>
                    </div>

                    <div class="row" id="id_confirm_pwd" style="display: none">
                      <div class="col-4">
                        Confirm Password<label style="color:#FF0000">*</label>
                      </div>
                      <div class="col-8">

                        <div class="input-group" title="Visible Signup Password">
                          <input type="password" name="txt_confirm_password" id='txt_confirm_password' class="form-control" maxlength="100" value="" tabindex="11" required="" data-toggle="tooltip" data-placement="top" title="" data-original-title="Confirm Password" placeholder="Confirm Password">
                          <span class="form-bar"></span>
                          <span class="input-group-addon" onclick="password_visible2()" id='id_signupc_display_visiblitity'><i class="icofont icofont-eye-blocked"></i></span>
                        </div>

                      </div>
                    </div>

                    <div class="row m-t-10 text-left">
                      <div class="col-md-12">
                        <div class="progress">
                          <div class="progress-bar" role="progressbar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100" style="width:0%" data-toggle="tooltip" data-placement="top" title="" data-original-title="Password Strength Meter" placeholder="Password Strength Meter">
                          </div>
                        </div>
                      </div>
                    </div>

                    <div class="row m-t-25 text-left">
                      <div class="col-md-12">
                        <div class="checkbox-fade fade-in-primary">
                          <label>
                            <input type="checkbox" name="chk_terms" id="chk_terms" value="" tabindex="12">
                            <span class="cr"><i class="cr-icon icofont icofont-ui-check txt-primary"></i></span>
                            <span class="text-inverse" style="color:#FF0000 !important">I read and accept <a href="#" style="color:#FF0000 !important" data-toggle="tooltip" data-placement="top" title="" data-original-title="Terms & Conditions." class="alert-ajax btn-outline-info">Terms &amp; Conditions.</a></span>
                          </label>
                        </div>
                      </div>
                    </div>
                    <div class="row m-t-30">
                      <div class="col-md-12">
                        <span class="error_display" id='id_error_display_signup'></span>
                      </div>
                    </div>

                    <div class="row m-t-10">
                      <div class="col-md-4"></div>
                      <div class="col-md-4">
                        <input type="hidden" class="form-control" name='call_function' id='call_function' value='signup' />
                        <input type="hidden" class="form-control" name='hid_sendurl' id='hid_sendurl' value='<?= $server_http_referer ?>' />
                        <input type="submit" name="submit_signup" id="submit_signup" tabindex="13" value="Sign Up Now" class="btn btn-success btn-md btn-block waves-effect text-center m-b-20">
                      </div>
                      <div class="col-md-4"></div>
                    </div>

                    <div class="row m-t-1">
                      <div class="col-md-6 text-left"><a class="nav-link" data-toggle="tab" href="#tab_signin" onclick="func_open_tab('signin')" role="tab">Sign In</a></div>
                      <div class="col-md-6 text-right"><a class="nav-link" data-toggle="tab" href="#tab_forgotpwd" onclick="func_open_tab('forgotpwd')" role="tab">Forgot Password?</a></div>
                    </div>

                  </div>
                </form>
              </div>
              <!-- Sign Up -->


              <!-- Forgot Password -->
              <div class="card-body" id="tab_forgotpwd" style="position: relative; display: none;">
                <form class="md-float-material form-material" action="#" name="frm_resetpwd" id='frm_resetpwd' method="post">
                  <div>
                    <div class="row m-b-20">
                      <div class="col-md-12">
                        <h3 class="text-center"><i class="icofont icofont-ui-unlock"></i> Recover Password</h3>
                      </div>
                    </div>
                    <div class="row">
                      <div class="col-4">
                        Mobile No<label style="color:#FF0000">*</label>
                      </div>
                      <div class="col-8">
                        <input type="text" name="txtfp_user_mobile" id='txtfp_user_mobile' class="form-control" onkeypress="return (event.charCode !=8 && event.charCode ==0 || ( event.charCode == 46 || (event.charCode >= 48 && event.charCode <= 57)))" onkeyup="return call_validate_mobileno()" maxlength="10" value="" tabindex="4" required="" data-toggle="tooltip" data-placement="top" title="" data-original-title="Mobile No" placeholder="Mobile No">
                        <span class="form-bar"></span>
                      </div>
                    </div>

                    <div class="row">
                      <div class="col-4">
                        Enter the OTP<label style="color:#FF0000">*</label>
                      </div>
                      <div class="col-8">
                        <input type="text" name="txtfp_mobile_otp" id='txtfp_mobile_otp' class="form-control" onkeypress="return (event.charCode !=8 && event.charCode ==0 || ( event.charCode == 46 || (event.charCode >= 48 && event.charCode <= 57)))" onkeyup="return call_validate_mobileno()" maxlength="6" value="" tabindex="4" required="" data-toggle="tooltip" data-placement="top" title="" data-original-title="Enter the OTP" placeholder="Enter the OTP"  onblur="return validate_otp()">
                        <span class="form-bar"></span>
                      </div>
                    </div>

                    <div class="row m-t-30">
                      <div class="col-md-4"></div>
                      <div class="col-md-4">
                        <span class="error_display" id='id_error_display_resetpwd'></span>
                        <input type="hidden" class="form-control" name='call_function' id='call_function' value='resetpwd' />
                        <input type="submit" name="submit_resetpwd" id="submit_resetpwd" tabindex="2" value="Reset Password" class="btn btn-success btn-md btn-block waves-effect text-center m-b-20">
                      </div>
                      <div class="col-md-4"></div>
                    </div>

                    <div class="row m-t-1">
                      <div class="col-md-6 text-left"><a class="nav-link" data-toggle="tab" href="#tab_signup" onclick="func_open_tab('signup')" role="tab">Sign Up</a></div>
                      <div class="col-md-6 text-right"><a class="nav-link" data-toggle="tab" href="#tab_signin" onclick="func_open_tab('signin')" role="tab">Sign In</a></div>
                    </div>

                  </div>
                </form>
              </div>
              <!-- Forgot Password -->

            </div>

            <!-- Footer Panel -->
            <div class="simple-footer">
              Copyright &copy;
              <?= $site_title ?> -
              <?= date("Y") ?>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>

  <!-- Modal content-->
  <div class="modal fade" id="default-Modal" tabindex="-1" role="dialog">
      <div class="modal-dialog" role="document">
          <div class="modal-content">
              <div class="modal-header">
                  <h4 class="modal-title">Terms & Conditions</h4>
                  <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                      <span aria-hidden="true">&times;</span>
                  </button>
              </div>
              <div class="modal-body" id="id_modal_display">
                  <h5>Welcome</h5>
                  <p>Waiting for load Data..</p>
              </div>
              <div class="modal-footer">
                  <button type="button" class="btn btn-primary waves-effect " data-dismiss="modal">Close</button>
              </div>
          </div>
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

  <script>
    $(".alert-ajax").click(function(){
				$("#id_modal_display").load("uploads/imports/terms.htm",function(){
						$('#default-Modal').modal({show:true});
				});
		});

    function func_open_tab(newtab) {
      if (newtab == 'signup') {
        $("#tab_signin").css("display", "none");
        $("#tab_forgotpwd").css("display", "none");
        $("#tab_signup").css("display", "block");
        $("#txt_user_name").focus();
      }
      if (newtab == 'signin') {
        $("#tab_forgotpwd").css("display", "none");
        $("#tab_signup").css("display", "none");
        $("#tab_signin").css("display", "block");
        $("#txt_username").focus();
      }
      if (newtab == 'forgotpwd') {
        $("#tab_signin").css("display", "none");
        $("#tab_signup").css("display", "none");
        $("#tab_forgotpwd").css("display", "block");
        $("#txt_user_email_fp").focus();
      }
    }

    function password_visible1() {
			var x = document.getElementById("txt_user_password");
			if (x.type === "password") {
				x.type = "text";
				$('#id_signup_display_visiblitity').html('<i class="icofont icofont-eye"></i>');
			} else {
				x.type = "password";
				$('#id_signup_display_visiblitity').html('<i class="icofont icofont-eye-blocked"></i>');
			}
		}

		function password_visible2() {
			var x = document.getElementById("txt_confirm_password");
			if (x.type === "password") {
				x.type = "text";
				$('#id_signupc_display_visiblitity').html('<i class="icofont icofont-eye"></i>');
			} else {
				x.type = "password";
				$('#id_signupc_display_visiblitity').html('<i class="icofont icofont-eye-blocked"></i>');
			}
		}

    function validate_otp() {
      var otp = 1;

      if(otp == 1) {
        $("#id_otp").css("display", "none");
        $("#id_pwd").css("display", "block");
        $("#id_confirm_pwd").css("display", "block");
      } else {
        $("#id_otp").css("display", "block");
        $("#id_pwd").css("display", "none");
        $("#id_confirm_pwd").css("display", "none");
      }
    }

    // To Submit the Form
    $("#submit").click(function(e) {
      $("#id_error_display_signin").html("");
      var uname = $('#txt_username').val();
      var password = $('#txt_password').val();
      var flag = true;
      /********validate all our form fields***********/
      /* Name field validation  */
      if (uname == "") {
        $('#txt_username').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }
      /* password field validation  */
      if (password == "") {
        $('#txt_password').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      } else {}
      /********Validation end here ****/

      /* If all are ok then we send ajax request to process_connect.php *******/
      if (flag) {
        var data_serialize = $("#frm_login").serialize();
        $.ajax({
          type: 'post',
          url: "ajax/call_functions.php",
          dataType: 'json',
          data: data_serialize,
          beforeSend: function() { // Before Send to Ajax
            $('#submit').attr('disabled', true);
            $('#load_page').show();
          },
          complete: function() { // After complete the Ajax
            $('#submit').attr('disabled', false);
            $('#load_page').hide();
          },
          success: function(response) { // Success
            if (response.status == '0') { // Failure Response
              $('#txt_password').val('');
              $('#submit').attr('disabled', false);
              $("#id_error_display_signin").html(response.msg);
            } else if (response.status == 1) { // Success Response
              $('#submit').attr('disabled', false);
              var hid_sendurl = $("#hid_sendurl").val();
              window.location = hid_sendurl; // Redirect the URL
            }
          },
          error: function(response, status, error) { // Error
            $('#txt_password').val('');
            $('#submit').attr('disabled', false);
            $("#id_error_display_signin").html(response.msg);
          }
        });
      }
    });
  </script>
</body>

</html>
