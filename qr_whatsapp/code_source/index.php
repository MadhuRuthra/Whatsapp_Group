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
  <title>Login -
    <?= $site_title ?>
  </title>
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

    .row {
      margin: 5px 0 !important;
    }

    .theme-loader {
      display: block;
      position: fixed;
      top: 0;
      left: 0;
      z-index: 100;
      width: 100%;
      height: 100%;
      background-color: rgba(192, 192, 192, 0.5);
      background-image: url("assets/img/loader.gif");
      background-repeat: no-repeat;
      background-position: center;

    }
  </style>

<body>
  <div class="theme-loader" style="display:none;"> </div>
  <div id="app">
    <section class="section">
      <div class="container mt-5">
        <div class="row">
          <div class="col-sm-12 offset-sm-0 col-md-6 offset-md-3">
            <div class="login-brand">
              <img src="assets/img/cm-logo.png" alt="logo" style="width: 100%"> <!-- Logo -->
            </div>

            <div class="card-header text-center" style="display: block; border: 1px solid #e0e0e0;">
              <h3>
                <?= $site_title ?>
              </h3>
            </div>
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
                        <input type="text" name="txt_username" id="txt_username" class="form-control" value=""
                          maxlength="100" tabindex="1" autofocus="" required="" data-toggle="tooltip"
                          data-placement="top" title="" data-original-title="Email / Mobile No"
                          placeholder="Email / Mobile No"> <!-- Email/Mobile No -->
                      </div>
                    </div>
                    <!-- Password -->
                    <div class="row mt-2">
                      <div class="col-4">
                        Login Password<label style="color:#FF0000">*</label>
                      </div>
                      <div class="col-8">
                        <div class="input-group" title="Visible Password">
                          <input type="password" name="txt_password" id='txt_password' class="form-control" value=""
                            maxlength="100" tabindex="2" required="" data-toggle="tooltip" data-placement="top" title=""
                            data-original-title="Login Password" placeholder="Login Password">
                          <span class="input-group-prepend"></span>
                          <span class="input-group-text" onclick="password_visible()"
                            id='id_signupc_display_visiblitity'><i class="fas fa-eye-slash"></i></span>
                        </div>
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
                      <input type="hidden" class="form-control" name='call_function' id='call_function'
                        value='signin' /> <!-- Process Name -->
                      <input type="hidden" class="form-control" name='hid_sendurl' id='hid_sendurl'
                        value='<?= $server_http_referer ?>' /> <!-- Redirect Link -->
                      <input type="submit" name="submit" id="submit" tabindex="3" value="Sign in"
                        class="btn btn-success btn-md btn-block waves-effect waves-light text-center m-b-20">
                      <!-- Submit Button -->
                    </div>
                    <div class="col-md-4"></div>
                  </div>

                  <div class="row m-t-1">
                    <!-- <div class="col-md-6 text-left"><a class="nav-link" data-toggle="tab" href="#tab_signup"
                        onclick="func_open_tab('signup')" role="tab">Sign Up</a></div>
                    <div class="col-md-6 text-right"><a class="nav-link" data-toggle="tab" href="#tab_forgotpwd"
                        onclick="func_open_tab('forgotpwd')" role="tab">Forgot Password?</a></div> -->
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
                      <input type="text" name="txt_user_name" id="txt_user_name" class="form-control" maxlength="30"
                        value="" tabindex="2" autofocus="" required="" data-toggle="tooltip" data-placement="top"
                        title="" onblur="" style="text-transform:uppercase" data-original-title="Name"
                        pattern="[a-zA-Z0-9 -_]+" onkeypress="return clsAlphaNoOnly(event)" onpaste="return false;"
                        placeholder="Name">
                      <span class="form-bar"></span>
                    </div>
                  </div>
                  <div class="row">
                    <div class="col-4">
                      Email ID<label style="color:#FF0000">*</label>
                    </div>
                    <div class="col-8">
                      <input type="email" name="txt_user_email" id='txt_user_email' class="form-control" maxlength="50"
                        value="" tabindex="3" required="" data-toggle="tooltip" data-placement="top" title=""
                        data-original-title="Email ID" placeholder="Email ID">
                      <span class="form-bar"></span>
                    </div>
                  </div>
                  <div class="row">
                    <div class="col-4">
                      Mobile No<label style="color:#FF0000">*</label>
                    </div>
                    <div class="col-8">
                      <input type="text" name="txt_user_mobile" id='txt_user_mobile' class="form-control"
                        onkeypress="return (event.charCode !=8 && event.charCode ==0 || ( event.charCode == 46 || (event.charCode >= 48 && event.charCode <= 57)))"
                        onblur="return call_validate_mobileno()" maxlength="10" value="" tabindex="4" required=""
                        data-toggle="tooltip" data-placement="top" title="" data-original-title="Mobile No"
                        placeholder="Mobile No">
                      <span class="form-bar"></span>
                    </div>
                  </div>

                  <div class="row" id="id_otp">
                    <div class="col-4">
                      Enter the OTP<label style="color:#FF0000">*</label>
                    </div>
                    <div class="col-8">
                      <input type="text" name="txt_mobile_otp" id='txt_mobile_otp' class="form-control"
                        onkeypress="return (event.charCode !=8 && event.charCode ==0 || ( event.charCode == 46 || (event.charCode >= 48 && event.charCode <= 57)))"
                        onkeyup="return call_validate_mobileno()" maxlength="6" value="" tabindex="4" required=""
                        data-toggle="tooltip" data-placement="top" title="" data-original-title="Enter the OTP"
                        placeholder="Enter the OTP" onblur="return validate_otp()">
                      <span class="form-bar"></span>
                    </div>
                  </div>

                  <div class="row" id="id_pwd" style="display: none">
                    <div class="col-4">
                      Login Password<label style="color:#FF0000">*</label>
                    </div>
                    <div class="col-8">
                      <div class="input-group " title="Visible Signup Password">
                        <input type="password" name="txt_user_password" id='txt_user_password' class="form-control"
                          maxlength="100" value="" tabindex="10" required="" data-toggle="tooltip" data-placement="top"
                          title=""
                          data-original-title="Login Password -  [Atleast 8 characters and Must Contains Numeric, Capital Letters and Special characters]"
                          placeholder="Login Password -  [Atleast 8 characters and Must Contains Numeric, Capital Letters and Special characters]"
                          onblur="return checkPasswordStrength()">
                        <span class="input-group-prepend"></span>
                        <span class="input-group-text" onclick="password_visible1()"
                          id='id_signup_display_visiblitity'><i class="fas fa-eye-slash"></i></span>
                      </div>

                    </div>
                  </div>

                  <div class="row" id="id_confirm_pwd" style="display: none">
                    <div class="col-4">
                      Confirm Password<label style="color:#FF0000">*</label>
                    </div>
                    <div class="col-8">

                      <div class="input-group" title="Visible Signup Password">
                        <input type="password" name="txt_confirm_password" id='txt_confirm_password'
                          class="form-control" maxlength="100" value="" tabindex="11" required="" data-toggle="tooltip"
                          data-placement="top" title="" data-original-title="Confirm Password"
                          placeholder="Confirm Password">
                        <span class="input-group-prepend"></span>
                        <span class="input-group-text" onclick="password_visible2()"
                          id='id_signup_display_visiblitity_2'><i class="fas fa-eye-slash"></i></span>
                      </div>

                    </div>
                  </div>

                  <div class="row m-t-10 text-left" style="margin-top: 10px !important;">
                    <div class="col-md-12">
                      <div class="progress">
                        <div class="progress-bar" role="progressbar" aria-valuenow="0" aria-valuemin="0"
                          aria-valuemax="100" style="width:0%" data-toggle="tooltip" data-placement="top" title=""
                          data-original-title="Password Strength Meter" placeholder="Password Strength Meter">
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
                          <span class="text-inverse" style="color:#FF0000 !important">I read and accept <a href="#"
                              style="color:#FF0000 !important" data-toggle="tooltip" data-placement="top" title=""
                              data-original-title="Terms & Conditions." class="alert-ajax btn-outline-info">Terms
                              &amp; Conditions.</a></span>
                        </label>
                      </div>
                    </div>
                  </div>
                  <div class="row m-t-30">
                    <div class="col-md-12 text-center">
                      <span class="error_display" id='id_error_display_signup'></span>
                    </div>
                  </div>

                  <div class="row m-t-10">
                    <div class="col-md-4"></div>
                    <div class="col-md-4">
                      <input type="hidden" class="form-control" name='call_function' id='call_function'
                        value='signup' />
                      <input type="hidden" class="form-control" name='hid_sendurl' id='hid_sendurl'
                        value='<?= $server_http_referer ?>' />
                      <input type="submit" name="submit_signup" id="submit_signup" tabindex="13" value="Sign Up Now"
                        class="btn btn-success btn-md btn-block waves-effect text-center m-b-20">
                    </div>
                    <div class="col-md-4"></div>
                  </div>

                  <div class="row m-t-1">
                    <div class="col-md-6 text-left"><a class="nav-link" data-toggle="tab" href="#tab_signin"
                        onclick="func_open_tab('signin')" role="tab">Sign In</a></div>
                    <div class="col-md-6 text-right"><a class="nav-link" data-toggle="tab" href="#tab_forgotpwd"
                        onclick="func_open_tab('forgotpwd')" role="tab">Forgot Password?</a></div>
                  </div>

                </div>
              </form>
            </div>
            <!-- Sign Up -->


            <!-- Forgot Password -->
            <div class="card-body" id="tab_forgotpwd" style="position: relative; display: none;">
              <form class="md-float-material form-material" action="#" name="frm_resetpwd" id='frm_resetpwd'
                method="post">
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
                      <input type="text" name="txtfp_user_mobile" id='txtfp_user_mobile' class="form-control"
                        onkeypress="return (event.charCode !=8 && event.charCode ==0 || ( event.charCode == 46 || (event.charCode >= 48 && event.charCode <= 57)))"
                        onkeyup="return call_validate_mobileno()" maxlength="10" value="" tabindex="4" required=""
                        data-toggle="tooltip" data-placement="top" title="" data-original-title="Mobile No"
                        placeholder="Mobile No">
                      <span class="form-bar"></span>
                    </div>
                  </div>

                  <div class="row" id="id_otp_rc">
                    <div class="col-4">
                      Enter the OTP<label style="color:#FF0000">*</label>
                    </div>
                    <div class="col-8">
                      <input type="text" name="txtfp_mobile_otp_rc" id='txtfp_mobile_otp_rc' class="form-control"
                        onkeypress="return (event.charCode !=8 && event.charCode ==0 || ( event.charCode == 46 || (event.charCode >= 48 && event.charCode <= 57)))"
                        onkeyup="return call_validate_mobileno()" maxlength="6" value="" tabindex="4" required=""
                        data-toggle="tooltip" data-placement="top" title="" data-original-title="Enter the OTP"
                        placeholder="Enter the OTP" onblur="return validate_otp_rc()">
                      <span class="form-bar"></span>
                    </div>
                  </div>

                  <div class="row" id="id_pwd_rc" style="display: none">
                    <div class="col-4">
                      Recover Password<label style="color:#FF0000">*</label>
                    </div>
                    <div class="col-8">
                      <div class="input-group " title="Visible Signup Password">
                        <input type="password" name="txt_user_password_rc" id='txt_user_password_rc'
                          class="form-control" maxlength="100" value="" tabindex="10" required="" data-toggle="tooltip"
                          data-placement="top" title=""
                          data-original-title="Recover Password -  [Atleast 8 characters and Must Contains Numeric, Capital Letters and Special characters]"
                          placeholder="Recover Password -  [Atleast 8 characters and Must Contains Numeric, Capital Letters and Special characters]"
                          onblur="return checkPasswordStrength_rc()">
                        <span class="input-group-prepend"></span>
                        <span class="input-group-text" onclick="password_visible_rc1()"
                          id='id_rc_display_visiblitity'><i class="fas fa-eye-slash"></i></span>
                      </div>

                    </div>
                  </div>

                  <div class="row" id="id_confirm_pwd_rc" style="display: none">
                    <div class="col-4">
                      Confirm Password<label style="color:#FF0000">*</label>
                    </div>
                    <div class="col-8">

                      <div class="input-group" title="Visible Signup Password">
                        <input type="password" name="txt_confirm_password_rc" id='txt_confirm_password_rc'
                          class="form-control" maxlength="100" value="" tabindex="11" required="" data-toggle="tooltip"
                          data-placement="top" title="" data-original-title="Confirm Password"
                          placeholder="Confirm Password">
                        <span class="input-group-prepend"></span>
                        <span class="input-group-text" onclick="password_visible_rc2()"
                          id='id_rc_display_visiblitity_2'><i class="fas fa-eye-slash"></i></span>
                      </div>

                    </div>
                  </div>

                  <div class="row m-t-10 text-left" style="margin-top: 10px !important;">
                    <div class="col-md-12">
                      <div class="progress">
                        <div class="progress-bar" role="progressbar" aria-valuenow="0" aria-valuemin="0"
                          aria-valuemax="100" style="width:0%" data-toggle="tooltip" data-placement="top" title=""
                          data-original-title="Password Strength Meter" placeholder="Password Strength Meter">
                        </div>
                      </div>
                    </div>
                  </div>

                  <div class="row m-t-30">
                    <div class="col-md-12 text-center">
                      <span class="error_display" id='id_error_display_resetpwd'></span>
                    </div>
                    <div class="col-md-4"></div>
                    <div class="col-md-4">
                      <input type="hidden" class="form-control" name='call_function' id='call_function'
                        value='resetpwd' />
                      <input type="submit" name="submit_resetpwd" id="submit_resetpwd" tabindex="2"
                        value="Reset Password" class="btn btn-success btn-md btn-block waves-effect text-center m-b-20">
                    </div>
                    <div class="col-md-4"></div>
                  </div>

                  <div class="row m-t-1">
                    <div class="col-md-6 text-left"><a class="nav-link" data-toggle="tab" href="#tab_signup"
                        onclick="func_open_tab('signup')" role="tab">Sign Up</a></div>
                    <div class="col-md-6 text-right"><a class="nav-link" data-toggle="tab" href="#tab_signin"
                        onclick="func_open_tab('signin')" role="tab">Sign In</a></div>
                  </div>

                </div>
              </form>
            </div>
            <!-- Forgot Password -->

          </div>
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
  <!-- <script src="assets/js/jquery-3.4.0.min.js"></script> -->
  <!-- JS Libraies -->
  <!-- Page Specific JS File -->
  <!-- Template JS File -->
  <script src="assets/js/scripts.js"></script>
  <script src="assets/js/custom.js"></script>
  <script>

    document.body.addEventListener("click", function (evt) {
      //note evt.target can be a nested element, not the body element, resulting in misfires
      $("#id_error_display_signin").html("");
    });
    // Terms and conditions columns

    $(".alert-ajax").click(function () {
      $("#id_modal_display").load("uploads/imports/terms.htm", function () {
        $('#default-Modal').modal({ show: true });
      });
    });

    function func_open_tab(newtab) {
      if (newtab == 'signup') {
        $('#txt_username').css("border-color", "");
        $('#txt_password').css("border-color", "");
        $('#txtfp_user_mobile').css("border-color", "");
        $('#txt_user_password_rc').css("border-color", "");
        $('#txt_confirm_password_rc').css("border-color", "");
        $('#txtfp_mobile_otp_rc').css("border-color", "");
        $(".progress-bar").removeAttr('style');
        $("#id_error_display_resetpwd").html("");
        $("#id_error_display_signin").html("");
        $('#txt_username').val('');
        $('#txt_password').val('');
        $('#txtfp_user_mobile').val('');
        $('#txt_user_password_rc').val('');
        $('#txt_confirm_password_rc').val('');
        $('#txtfp_mobile_otp_rc').val('');
        $("#id_otp_rc").removeAttr('style');
        $('#id_pwd_rc').css("display", "none");
        $('#id_confirm_pwd_rc').css("display", "none");
        $("#tab_signin").css("display", "none");
        $("#tab_forgotpwd").css("display", "none");
        $("#tab_signup").css("display", "block");
        $("#txt_user_name").focus();
      }
      if (newtab == 'signin') {
        $('#txtfp_user_mobile').css("border-color", "");
        $('#txt_user_password_rc').css("border-color", "");
        $('#txt_confirm_password_rc').css("border-color", "");
        $('#txt_user_name').css("border-color", "");
        $('#txt_user_email').css("border-color", "");
        $('#txt_user_mobile').css("border-color", "");
        $('#txt_mobile_otp').css("border-color", "");
        $('#txt_user_password').css("border-color", "");
        $('#txt_confirm_password').css("border-color", "");
        $('#txtfp_mobile_otp_rc').css("border-color", "");
        $(".progress-bar").removeAttr('style');
        $("#id_error_display_resetpwd").html("");
        $("#id_error_display_signup").html("");
        $('#txtfp_user_mobile').val('');
        $('#txt_user_password_rc').val('');
        $('#txt_confirm_password_rc').val('');
        $('#txt_user_name').val('');
        $('#txt_user_email').val('');
        $('#txt_user_mobile').val('');
        $('#txt_mobile_otp').val('');
        $('#txt_user_password').val('');
        $('#txt_confirm_password').val('');
        $('#txtfp_mobile_otp_rc').val('');
        $("#id_otp").removeAttr('style');
        $('#id_pwd').css("display", "none");
        $('#id_confirm_pwd').css("display", "none");
        $("#id_otp_rc").removeAttr('style');
        $('#id_pwd_rc').css("display", "none");
        $('#id_confirm_pwd_rc').css("display", "none");
        $("#tab_forgotpwd").css("display", "none");
        $("#tab_signup").css("display", "none");
        $("#tab_signin").css("display", "block");
        $("#txt_username").focus();
      }
      if (newtab == 'forgotpwd') {
        $('#txt_username').css("border-color", "");
        $('#txt_password').css("border-color", "");
        $('#txt_user_name').css("border-color", "");
        $('#txt_user_email').css("border-color", "");
        $('#txt_user_mobile').css("border-color", "");
        $('#txt_mobile_otp').css("border-color", "");
        $('#txt_user_password').css("border-color", "");
        $('#txt_confirm_password').css("border-color", "");
        $(".progress-bar").removeAttr('style');
        $("#id_error_display_signin").html("");
        $("#id_error_display_signup").html("");
        $('#txt_username').val('');
        $('#txt_password').val('');
        $('#txt_user_name').val('');
        $('#txt_user_email').val('');
        $('#txt_user_mobile').val('');
        $('#txt_mobile_otp').val('');
        $('#txt_user_password').val('');
        $('#txt_confirm_password').val('');
        $("#id_otp").removeAttr('style');
        $('#id_pwd').css("display", "none");
        $('#id_confirm_pwd').css("display", "none");
        $("#tab_signin").css("display", "none");
        $("#tab_signup").css("display", "none");
        $("#tab_forgotpwd").css("display", "block");
        $("#txt_user_email_fp").focus();
      }
    }

    function password_visible() {
      var x = document.getElementById("txt_password");
      if (x.type === "password") {
        x.type = "text";
        $('#id_signupc_display_visiblitity').html('<i class="fas fa-eye"></i>');
      } else {
        x.type = "password";
        $('#id_signupc_display_visiblitity').html('<i class="fas fa-eye-slash"></i>');
      }
    }
    // SIGN IN To Submit the Form
    $("#submit").click(function (e) {
      $("#id_error_display_signin").html("");
      var uname = $('#txt_username').val();
      var password = $('#txt_password').val();
      var flag = true;
      /********validate all our form fields***********/
      /* password field validation  */
      if (password == "") {
        $('#txt_password').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }

      /* Name field validation  */
      if (uname == "") {
        $('#txt_username').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      } else {
        const txt_username = document.getElementById("txt_username");
        const inputValue = txt_username.value.trim();
        // Regular expressions for mobile number and email validation
        const mobilePattern = /^[0-9]{10}$/; // Assumes a 10-digit mobile number
        const emailPattern = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i;

        if (mobilePattern.test(inputValue)) {
          var stt = -1;
          // Validate Mobile NO
          if (txt_user_mobile.length < 10 && txt_user_mobile != '') {
            $('#txt_username').css('border-color', '#red');
            $("#id_error_display_signin").html("Mobile Number must contain 10 digits");
          }
          // If Mobile NO > 5
          if (inputValue.length > 5) {
            var letter = inputValue.charAt(0);
            if (letter == 0 || letter == 1 || letter == 2 || letter == 3 || letter == 4 || letter == 5) { // First Character is in 0 to 5 then INVALID
              stt = 0;
            } else { // Else VALID
              stt = 1;
            }
            if (stt == 0) { // Send Invalid Response
              $('#txt_username').css('border-color', 'red');
              $("#id_error_display_signin").html("Invalid Mobile Number");
            }
            else
              $('#txt_username').css('border-color', '#ccc'); // Success Response
          }
          if (inputValue.length >= 10) { // Mobile 10 Digits then
            var flag = true;
          }
        }
        else if (emailPattern.test(inputValue)) {
          // Valid email address
          // flag = true;
          // You can submit the form or take further action here
        }
        else {
          // Invalid input
          $("#id_error_display_signin").html("Invalid input. Please enter a valid mobile number or email address.");
          flag = false;
          e.preventDefault();
        }
      }
      /********Validation end here ****/

      /* If all are ok then we send ajax request to process_connect.php *******/
      if (flag) {
        e.preventDefault();
        var data_serialize = $("#frm_login").serialize();
        $.ajax({
          type: 'post',
          url: "ajax/call_functions.php",
          dataType: 'json',
          data: data_serialize,
          beforeSend: function () { // Before Send to Ajax
            $('#submit').attr('disabled', true);
            $('.theme-loader').css("display", "block");
            $('.theme-loader').show();
          },
          complete: function () { // After complete the Ajax
            $('#submit').attr('disabled', false);
            $('.theme-loader').css("display", "none");
            $('.theme-loader').hide();
          },
          success: function (response) { // Success
            if (response.status == '0') { // Failure Response
              $('#txt_password').val('');
              $('#submit').attr('disabled', false);
              $("#id_error_display_signin").html(response.msg);
              if (response.msg == null || response.msg == '') {
                $("#id_error_display_signin").html('Service not running, Kindly check the service!!');
              }
            } else if (response.status == 1) { // Success Response
              $('#submit').attr('disabled', false);
              var hid_sendurl = $("#hid_sendurl").val();
              window.location = hid_sendurl; // Redirect the URL
            }
          },
          error: function (response, status, error) { // Error
            $('#txt_password').val('');
            $('#submit').attr('disabled', false);
            $("#id_error_display_signin").html(response.msg);
          }
        });
      }
    });

    /* SIGN UP TAB  */
    var percentage = 0;

    function check(n, m) {
      var strn_disp = "Very Weak Password";
      if (n < 6) {
        percentage = 0;
        $(".progress-bar").css("background", "#FF0000");
        strn_disp = "Very Weak Password";
      } else if (n < 7) {
        percentage = 20;
        $(".progress-bar").css("background", "#758fce");
        strn_disp = "Weak Password";
      } else if (n < 8) {
        percentage = 40;
        $(".progress-bar").css("background", "#ff9800");
        strn_disp = "Medium Password";
      } else if (n < 10) {
        percentage = 60;
        $(".progress-bar").css("background", "#A5FF33");
        strn_disp = "Strong Password";
      } else {
        percentage = 80;
        $(".progress-bar").css("background", "#129632");
        strn_disp = "Very Strong Password";
      }

      //Lowercase Words only
      if ((m.match(/[a-z]/) != null)) {
        percentage += 5;
      }

      //Uppercase Words only
      if ((m.match(/[A-Z]/) != null)) {
        percentage += 5;
      }

      //Digits only
      if ((m.match(/0|1|2|3|4|5|6|7|8|9/) != null)) {
        percentage += 5;
      }

      //Special characters
      if ((m.match(/\W/) != null) && (m.match(/\D/) != null)) {
        percentage += 5;
      }

      // Update the width of the progress bar
      $(".progress-bar").css("width", percentage + "%");
      $("#strength_display").html(strn_disp);
    }

    // Update progress bar as per the input
    $(document).ready(function () {
      // Whenever the key is pressed, apply condition checks.
      $("#txt_user_password").keyup(function () {
        var m = $(this).val();
        var n = m.length;
        // Function for checking
        check(n, m);
      });
    });

    // Update progress bar as per the input
    $(document).ready(function () {
      // Whenever the key is pressed, apply condition checks.
      $("#txt_user_password_rc").keyup(function () {
        var m = $(this).val();
        var n = m.length;
        // Function for checking
        check(n, m);
      });
    });


    function password_visible1() {
      var x = document.getElementById("txt_user_password");
      if (x.type === "password") {
        x.type = "text";
        $('#id_signup_display_visiblitity').html('<i class="fas fa-eye"></i>');
      } else {
        x.type = "password";
        $('#id_signup_display_visiblitity').html('<i class="fas fa-eye-slash"></i>');
      }
    }

    function password_visible2() {
      var x = document.getElementById("txt_confirm_password");
      if (x.type === "password") {
        x.type = "text";
        $('#id_signup_display_visiblitity_2').html('<i class="fas fa-eye"></i>');
      } else {
        x.type = "password";
        $('#id_signup_display_visiblitity_2').html('<i class="fas fa-eye-slash"></i>');
      }
    }

    /* txt_mobile_otp field validation  */
    function validate_otp() {
      var txt_mobile_otp = $('#txt_mobile_otp').val();
      $("#id_error_display_signup").html("");
      if (txt_mobile_otp.length == 6) {
        var data_serialize = $("#txt_user_otp");
        $.ajax({
          type: 'post',
          url: "ajax/call_functions.php?otp_check_call_function=mobile_check_otp",
          dataType: 'json',
          data: data_serialize,
          beforeSend: function () {
          },
          complete: function () {
            $("#id_error_display_submit").html("");
          },
          error: function () {
            $("#id_error_display_submit").html("Enter a correct otp");
          },
        })
        $('#txt_mobile_otp').prop("required", false);
        $("#id_otp").css("display", "none");
        $('#id_pwd').removeAttr('style');
        $('#id_confirm_pwd').removeAttr('style');
      } else {
        $("#id_error_display_signup").html("Enter a valid OTP");
        $("#id_pwd").css("display", "none");
        $("#id_confirm_pwd").css("display", "none");
      }
    }

    function call_validate_mobileno() {
      var txt_user_mobile = $("#txt_user_mobile").val();
      var stt = -1;
      if (txt_user_mobile.length > 9) {
        var letter = txt_user_mobile.charAt(0);
        if (letter == 0 || letter == 1 || letter == 2 || letter == 3 || letter == 4 || letter == 5) {
          stt = 0;
        } else {
          stt = 1;
        }
        if (stt == 0)
          $('#txt_user_mobile').css('border-color', 'red');
        else
          $('#txt_user_mobile').css('border-color', '#ccc');
      }
      if (txt_user_mobile.length == '10') {
        var data_serialize = $("#txt_user_mobile").serialize();
        $.ajax({
          type: 'post',
          url: "ajax/call_functions.php?otp_call_function=mobile_otp",
          dataType: 'json',
          data: data_serialize,
          beforeSend: function () {

          },
          complete: function () {

          },
        })
      }
      return stt;
    }

    // SIGN UP To submit_signup the Form
    $("#submit_signup").click(function (e) {
      var flag = true;
      $("#id_error_display_signup").html("");
      var txt_user_name = $('#txt_user_name').val();
      var txt_user_email = $('#txt_user_email').val();
      var txt_user_mobile = $('#txt_user_mobile').val();
      var txt_mobile_otp = $('#txt_mobile_otp').val();
      var txt_user_password = $('#txt_user_password').val();
      var txt_confirm_password = $('#txt_confirm_password').val();

      /********validate all our form fields***********/
      /* Name field validation  */
      if (txt_user_name == "") {
        $('#txt_user_name').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }
      /* txt_user_password validation  */
      if (txt_user_password == "") {
        $('#txt_user_password').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }
      /* txt_user_mobile validation  */
      if (txt_user_mobile == "") {
        $('#txt_user_mobile').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }
      /* txt_mobile_otp validation  */
      if (txt_mobile_otp == "") {
        $('#txt_mobile_otp').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }

      /* txt_confirm_password validation  */
      if (txt_confirm_password == "") {
        $('#txt_confirm_password').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }

      /* txt_user_email field validation  */
      if (txt_user_email == "") {
        $('#txt_user_email').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }
      const user_email = document.getElementById("txt_user_email");
      const inputValue = user_email.value.trim();
      // Regular expressions for email validation
      const emailPattern = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i;
      if (emailPattern.test(inputValue)) {
        // Valid email address
        // flag = true;
        // You can submit_signup the form or take further action here
      } else {
        // Invalid input
        $("#id_error_display_signup").html("Invalid Email Address.");
        flag = false;
        e.preventDefault();
      }

      /* txt_user_mobile field validation  */
      var stt = -1;

      // Validate Mobile NO
      if (txt_user_mobile.length < 10 && txt_user_mobile != '') {
        $('#txt_user_mobile').css('border-color', '#red');
        $("#id_error_display_signup").html("Mobile Number must contain 10 digits");
      }

      // If Mobile NO > 5
      if (txt_user_mobile.length > 5) {
        var letter = txt_user_mobile.charAt(0);
        if (letter == 0 || letter == 1 || letter == 2 || letter == 3 || letter == 4 || letter == 5) { // First Character is in 0 to 5 then INVALID
          stt = 0;
        } else { // Else VALID
          stt = 1;
        }
        if (stt == 0) { // Send Invalid Response
          $('#txt_user_mobile').css('border-color', 'red');
          $("#id_error_display_signup").html("Invalid Mobile Number");
        }
        else
          $('#txt_user_mobile').css('border-color', '#ccc'); // Success Response
      }
      if (txt_user_mobile.length <= 10) { // Mobile Number 10 Digits.
        // var flag = true;
      }

      /* txt_user_password field validation  */
      if (txt_user_password == "") {
        $('#txt_user_password').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      } else {
        if (checkPasswordStrength() == false) {
          flag = false;
          e.preventDefault();
        }
      }

      /* txt_confirm_password field validation  */
      if (txt_confirm_password == "") {
        $('#txt_confirm_password').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }

      /* txt_user_password, txt_confirm_password field validation  */
      if ((txt_confirm_password != "" && txt_user_password != "") && (txt_confirm_password != txt_user_password)) {
        $('#txt_confirm_password').css('border-color', 'red');
        $("#id_error_display_signup").html("Confirm Password mismatch with Password");
        flag = false;
        e.preventDefault();
      }

      if ($("#chk_terms").prop('checked') == false) {
        $('#chk_terms').css('border-color', 'red');
        $("#id_error_display_signup").html("Must read the Terms and Select!");
        flag = false;
        e.preventDefault();
      }
      /********Validation end here ****/
      /* If all are ok then we send ajax request to process_connect.php *******/
      if (flag) {
        var data_serialize = $("#frm_signup").serialize();
        $.ajax({
          type: 'post',
          url: "ajax/call_functions.php",
          dataType: 'json',
          data: data_serialize,
          beforeSend: function () { // Before Send to Ajax
            $('#submit_signup').attr('disabled', true);
            $('.theme-loader').css("display", "block");
            $('.theme-loader').show();
          },
          complete: function () { // After complete the Ajax
            $('#submit_signup').attr('disabled', false);
            $('.theme-loader').css("display", "none");
            $('.theme-loader').hide();
          },
          success: function (response) { // Success
            if (response.status == '0') { // Failure Response
              $('#txt_password').val('');
              $('#submit_signup').attr('disabled', false);
              $("#id_error_display_signup").html(response.msg);
              if (response.msg === null || response.msg === '') {
                $("#id_error_display_signup").html('Service not running, Kindly check the service!!');
              }
            } else if (response.status == 1) { // Success Response
              $('#submit_signup').attr('disabled', false);
              var hid_sendurl = $("#hid_sendurl").val();
              $("#id_error_display_signup").html(response.msg);
              setInterval(function () {
                window.location = hid_sendurl; // Redirect the URL
              }, 1000);

            }
          },
          error: function (response, status, error) { // Error
            $('#txt_password').val('');
            $('#submit_signup').attr('disabled', false);
            $("#id_error_display_signup").html(response.msg);
          }
        });
      }
    });


    /* RECOVERY PASSWORD TAB */
    function password_visible_rc1() {
      var x = document.getElementById("txt_user_password_rc");
      if (x.type === "password") {
        x.type = "text";
        $('#id_rc_display_visiblitity').html('<i class="fas fa-eye"></i>');
      } else {
        x.type = "password";
        $('#id_rc_display_visiblitity').html('<i class="fas fa-eye-slash"></i>');
      }
    }

    function password_visible_rc2() {
      var x = document.getElementById("txt_confirm_password_rc");
      if (x.type === "password") {
        x.type = "text";
        $('#id_rc_display_visiblitity_2').html('<i class="fas fa-eye"></i>');
      } else {
        x.type = "password";
        $('#id_rc_display_visiblitity_2').html('<i class="fas fa-eye-slash"></i>');
      }
    }

    /* txt_mobile_otp field validation  */
    function validate_otp_rc() {
      var txt_mobile_otp = $('#txtfp_mobile_otp_rc').val();
      $("#id_error_display_resetpwd").html("");
      if (txt_mobile_otp.length == 6) {
        $('#txtfp_mobile_otp_rc').prop("required", false);
        $("#id_otp_rc").css("display", "none");
        $('#id_pwd_rc').removeAttr('style');
        $('#id_confirm_pwd_rc').removeAttr('style');
      } else {
        $("#id_error_display_resetpwd").html("Enter a valid OTP");
        $("#id_pwd_rc").css("display", "none");
        $("#id_confirm_pwd_rc").css("display", "none");
      }
    }

    // RECOVERY PASSWORD To submit_resetpwd the Form
    $("#submit_resetpwd").click(function (e) {
      $("#id_error_display_resetpwd").html("");
      var txtfp_user_mobile = $('#txtfp_user_mobile').val();
      var txtfp_mobile_otp_rc = $('#txtfp_mobile_otp_rc').val();
      var txt_user_password_rc = $('#txt_user_password_rc').val();
      var txt_confirm_password_rc = $('#txt_confirm_password_rc').val();
      var flag = true;
      /********validate all our form fields***********/
      /* txtfp_user_mobile validation  */
      if (txtfp_user_mobile == "") {
        $('#txtfp_user_mobile').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }
      /* txtfp_mobile_otp_rc validation  */
      if (txtfp_mobile_otp_rc == "") {
        $('#txtfp_mobile_otp_rc').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }
      /* txtfp_user_mobile field validation  */
      var stt = -1;

      // Validate Mobile NO
      if (txtfp_user_mobile.length < 10 && txtfp_user_mobile != '') {
        $('#txtfp_user_mobile').css('border-color', '#red');
        $("#id_error_display_resetpwd").html("Mobile Number must contain 10 digits");
      }

      // If Mobile NO > 5
      if (txtfp_user_mobile.length > 5) {
        var letter = txtfp_user_mobile.charAt(0);
        if (letter == 0 || letter == 1 || letter == 2 || letter == 3 || letter == 4 || letter == 5) { // First Character is in 0 to 5 then INVALID
          stt = 0;
        } else { // Else VALID
          stt = 1;
        }
        if (stt == 0) { // Send Invalid Response
          $('#txtfp_user_mobile').css('border-color', 'red');
          $("#id_error_display_resetpwd").html("Invalid Mobile Number");
        }
        else
          $('#txtfp_user_mobile').css('border-color', '#ccc'); // Success Response
      }
      if (txtfp_user_mobile.length <= 10) { // Mobile Number 10 Digits.
        // var flag = true;
      }

      /* txt_user_password field validation  */
      if (txt_user_password_rc == "") {
        $('#txt_user_password_rc').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      } else {
        if (checkPasswordStrength_rc() == false) {
          flag = false;
          e.preventDefault();
        }
      }

      /* txt_confirm_password field validation  */
      if (txt_confirm_password_rc == "") {
        $('#txt_confirm_password_rc').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }

      /* txt_user_password, txt_confirm_password field validation  */
      if (txt_confirm_password_rc != "" && txt_user_password_rc != "" && txt_confirm_password_rc != txt_user_password_rc) {
        $('#txt_confirm_password_rc').css('border-color', 'red');
        $("#id_error_display_resetpwd").html("Confirm Password mismatch with Password");
        flag = false;
        e.preventDefault();
      }

      /********Validation end here ****/

      /* If all are ok then we send ajax request to process_connect.php *******/
      if (flag) {
        e.preventDefault();
        var data_serialize = $("#frm_resetpwd").serialize();
        $.ajax({
          type: 'post',
          url: "ajax/call_functions.php",
          dataType: 'json',
          data: data_serialize,
          beforeSend: function () { // Before Send to Ajax
            $('#submit_resetpwd').attr('disabled', true);
            $('.theme-loader').css("display", "block");
            $('.theme-loader').show();
          },
          complete: function () { // After complete the Ajax
            $('#submit_resetpwd').attr('disabled', false);
            $('.theme-loader').css("display", "none");
            $('.theme-loader').hide();
          },
          success: function (response) { // Success
            if (response.status == '0') { // Failure Response
              $('#submit_resetpwd').attr('disabled', false);
              $("#id_error_display_resetpwd").html(response.msg);
              if (response.msg === null || response.msg === '') {
                $("#id_error_display_resetpwd").html('Service not running, Kindly check the service!!');
              }
            } else if (response.status == 1) { // Success Response
              $('#submit_resetpwd').attr('disabled', false);
              var hid_sendurl = $("#hid_sendurl").val();
              $("#id_error_display_resetpwd").html(response.msg);
              setInterval(function () {
                window.location = hid_sendurl; // Redirect the URL
              }, 1000);
            }
          },
          error: function (response, status, error) { // Error
            var txtfp_user_mobile = $('#txtfp_user_mobile').val();
            $('#txtfp_mobile_otp_rc').val("");
            $('#txt_user_password_rc').val('');
            $('#txt_confirm_password_rc').val("");
            $('#submit_resetpwd').attr('disabled', false);
            $("#id_error_display_resetpwd").html(response.msg);
          }
        });
      }
    });

  </script>
</body>

</html>
