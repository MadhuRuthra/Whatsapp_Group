<?php
/*
Primary Admin user only allow to this Manage Users page.
This page is used to manage the users.
It will send the form to API service 
and get the response from them and store into our DB.

Version : 1.0
Author : Madhubala (YJ0009)
Date : 03-Jul-2023
*/

session_start(); // start session
error_reporting(0); // The error reporting function

include_once 'api/configuration.php'; // Include configuration.php
extract($_REQUEST); // Extract the request

// If the Session is not available redirect to index page
if ($_SESSION['yjwatsp_user_id'] == "") { ?>
  <script>
    window.location = "index";
  </script>
  <?php exit();
}

// If the logged in user is not Primary admin, it will redirect to Dashboard page
if ($_SESSION['yjwatsp_user_master_id'] != 1) { ?>
  <script>
    window.location = "dashboard";
  </script>
  <? exit();
}

$site_page_name = pathinfo($_SERVER['PHP_SELF'], PATHINFO_FILENAME); // Collect the Current page name
site_log_generate("Manage Users Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"));
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Manage Users ::
    <?= $site_title ?>
  </title>
  <link rel="icon" href="assets/img/favicon.ico" type="image/x-icon">

  <!-- General CSS Files -->
  <link rel="stylesheet" href="assets/modules/bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="assets/modules/fontawesome/css/all.min.css">

  <!-- CSS Libraries -->
  <!-- Template CSS -->
  <link rel="stylesheet" href="assets/css/style.css">
  <link rel="stylesheet" href="assets/css/components.css">
  <!-- style include in css -->
  <style>
    .progress {
      height: 0.2rem;
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
            <h1>Manage Users</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item active"><a href="manage_users_list">Manage Users List</a></div>
              <div class="breadcrumb-item">Manage Users</div>
            </div>
          </div>

          <!-- User Creation Form panel -->
          <div class="section-body">
            <div class="row">

              <div class="col-12 col-md-8 col-lg-8 offset-2">
                <div class="card">
                  <form class="needs-validation" novalidate="" id="frm_users" name="frm_users" action="#" method="post"
                    enctype="multipart/form-data">
                    <div class="card-body">

                      <!-- To create the User Name -->
                      <div class="clear_both form-group mb-2 row">
                        <label class="col-sm-4 col-form-label">User Name <label style="color:#FF0000">*</label> <span
                            data-toggle="tooltip"
                            data-original-title="Username using only alphabets, numbers, and underscores.">[?]</span></label>
                        <div class="col-sm-8" style="float: right;">
                          <input type="input" name="user_name" id="user_name" class="form-control" value=""
                            maxlength="30" tabindex="1" required="" data-toggle="tooltip" data-placement="top"
                            title="User Name" data-original-title="User Name" placeholder="User Name"
                            pattern="[a-zA-Z0-9 -_]+" onkeypress="return clsAlphaNoOnly(event)" onpaste="return false;">
                        </div>
                      </div>
                      <!-- login password -->
                      <div class="form-group mb-2 row">
                        <label class="col-sm-4 col-form-label">Login Password <label style="color:#FF0000">*</label>
                          <span data-toggle="tooltip"
                            data-original-title="Login Password using only alphabets, numbers, and special characters.">[?]</span></label>
                        <div class="col-sm-8">
                          <div class="input-group " title="Visible Signup Password">
                            <input type="password" name="txt_user_password" id='txt_user_password' class="form-control"
                              value="" maxlength="50" tabindex="2" required="" data-toggle="tooltip"
                              data-placement="top" title="" data-original-title="Login Password"
                              placeholder="Login Password">
                            <span class="input-group-prepend"></span>
                            <span class="input-group-text" onclick="password_visible1()"
                              id='login_pwd_display_visiblitity'><i class="fas fa-eye-slash"></i></span>
                          </div>
                        </div>
                      </div>
                      <!-- confirm password -->
                      <div class="form-group mb-2 row">
                        <label class="col-sm-4 col-form-label">Confirm Password <label style="color:#FF0000">*</label>
                          <span data-toggle="tooltip"
                            data-original-title="Confirm Password using only alphabets, numbers, and special characters.">[?]</span></label>
                        <div class="col-sm-8">
                          <div class="input-group " title="Visible Signup Password">
                            <input type="password" name="txt_confirm_password" id='txt_confirm_password'
                              class="form-control" value="" maxlength="50" tabindex="3" required=""
                              data-toggle="tooltip" data-placement="top" title="" data-original-title="Confirm Password"
                              placeholder="Confirm Password">
                            <span class="input-group-prepend"></span>
                            <span class="input-group-text" onclick="password_visible2()"
                              id='conform_pwd_display_visiblitity'><i class="fas fa-eye-slash"></i></span>
                          </div>
                        </div>
                      </div>
                      <!-- progressbar field -->
                      <div class="form-group mb-2 row">
                        <div class="col-sm-12">
                          <div class="progress">
                            <div class="progress-bar" role="progressbar" aria-valuenow="0" aria-valuemin="0"
                              aria-valuemax="100" style="width:0%" data-toggle="tooltip" data-placement="top" title=""
                              data-original-title="Password Strength Meter" placeholder="Password Strength Meter">
                            </div>
                          </div>
                        </div>
                      </div>
                      <!-- Email text field -->
                      <div class="form-group mb-2 row">
                        <label class="col-sm-4 col-form-label">Email <label style="color:#FF0000">*</label> <span
                            data-toggle="tooltip"
                            data-original-title="Email using only alphabets, numbers, and special characters.">[?]</span></label>
                        <div class="col-sm-8">
                          <input type="email" name="txt_user_email" pattern="[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$"
                            id='txt_user_email' class="form-control" required="" maxlength="50" minlength="1" value=""
                            tabindex="4" required="" data-toggle="tooltip" data-placement="top" title=""
                            data-original-title="Email" placeholder="Email">
                        </div>
                      </div>

                      <!-- Mobile number Test -->
                      <div class="form-group mb-2 row">
                        <label class="col-sm-4 col-form-label">Mobile No <label style="color:#FF0000">*</label> <span
                            data-toggle="tooltip"
                            data-original-title="Mobile nos using only numbers.">[?]</span></label>
                        <div class="col-sm-8">
                          <input type="text" name="txt_user_mobile" id='txt_user_mobile' class="form-control"
                            onkeypress="return (event.charCode !=8 && event.charCode ==0 ||  (event.charCode >= 48 && event.charCode <= 57))"
                            onkeyup="return call_validate_mobileno()" maxlength="10" value="" tabindex="5" required=""
                            data-toggle="tooltip" data-placement="top" title="" data-original-title="Mobile No"
                            placeholder="Mobile No">
                        </div>
                      </div>

                      <!-- OTP Test -->
                      <div class="form-group mb-2 row">
                        <label class="col-sm-4 col-form-label">OTP <label style="color:#FF0000">*</label> <span
                            data-toggle="tooltip" data-original-title="Otp using only numbers.">[?]</span></label>
                        <div class="col-sm-8">
                          <input type="text" name="otp" id='otp' class="form-control"
                            onkeypress="return (event.charCode !=8 && event.charCode ==0 || ( event.charCode == 46 || (event.charCode >= 48 && event.charCode <= 57)))"
                            onblur="return validate_otp()" maxlength="6" value="" tabindex="6" required=""
                            data-toggle="tooltip" data-placement="top" title="" data-original-title="OTP"
                            placeholder="OTP" disabled>
                        </div>
                      </div>
                      <!--OTP Test -->

                      <!-- Assign Plan Admin -->
                      <div class="clear_both form-group mb-2 row">
                        <label class="col-sm-4 col-form-label">Assign Plan <label style="color:#FF0000">*</label> <span
                            data-toggle="tooltip" data-original-title="Users select any plans.">[?]</span></label>
                        <div class="col-sm-8" style="float: right;">
                          <select name="assign_plan" id='assign_plan' class="form-control mb-2" data-toggle="tooltip"
                            data-placement="top" title="" tabindex="7" data-original-title="Assign Plans">
                            <? // To display the Department Admin
                            $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . ''; // Add Bearer Token
                            $curl = curl_init();
                            curl_setopt_array(
                              $curl,
                              array(
                                CURLOPT_URL => $api_url . '/plan/plan_details',
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
                            site_log_generate("Manage Users Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
                            $response = curl_exec($curl);
                            curl_close($curl);

                            // After got response decode the JSON result
                            $header = json_decode($response, false);
                            if ($response == '') { ?>
                              <script>
                                window.location = "index"
                              </script>
                              <? } else if ($header->response_status == 403) { ?>
                                <script>
                                window.location = "index"
                                </script>
                              <? }
                            site_log_generate("Manage Users Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');
                            if ($response == '') {
                              header('Location: index');
                              exit;
                            } else if ($header->response_status == 403) {
                              header('Location: index');
                              exit;
                            } else {
                              // To display the response data into option button
                              for ($indicator = 0; $indicator < $header->num_of_rows; $indicator++) {
                                // Looping while the indicator is less than the num_of_rows. If the condition is true, continue the process to get the details. If the conditions are false, stop the process.
                                echo '<option value="' . $header->plan_details[$indicator]->annual_monthly . '~~' . $header->plan_details[$indicator]->plan_master_id . '~~' . $header->plan_details[$indicator]->group_no_max_count . '~~' . $header->plan_details[$indicator]->whatsapp_no_max_count . '~~' . $header->plan_details[$indicator]->plan_price . '~~' . $header->plan_details[$indicator]->message_limit . '">' . $header->plan_details[$indicator]->plan_title . " [ " . $header->plan_details[$indicator]->plan_price . " ] [ " . $header->plan_details[$indicator]->annual_monthly . " ] </option>";
                              }
                            }
                            ?>
                          </select>
                        </div>
                      </div>
                      <!-- Error Display & Submit button -->
                      <div class="error_display" id='id_error_display_signup'></div>
                      <div class="card-footer text-center">
                        <input type="hidden" class="form-control" name='call_function' id='call_function'
                          value='manage_users' />
                        <input type="submit" name="submit_signup" id="submit_signup" tabindex="8" value="Submit"
                          class="btn btn-success">
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

  <script>

    document.body.addEventListener("click", function (evt) {
      //note evt.target can be a nested element, not the body element, resulting in misfires
      $("#id_error_display_signup").html("");
    });

    // If Sign up submit button clicks
    $("#submit_signup").click(function (e) {
      $("#id_error_display_signup").html("");
      //get input field values
      var user_name = $('#user_name').val();
      var password = $('#txt_user_password').val();
      var confirm_password = $('#txt_confirm_password').val();
      var email = $('#txt_user_email').val();
      var user_mobile = $('#txt_user_mobile').val();
      var otp = $('#otp').val();
      var assign_plan = $('#assign_plan').val();
      var flag = true;
      /********validate all our form fields***********/
      /* Login ID field validation  */
      if (user_name == "") {
        $('#user_name').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }
      /* Login Short Name field validation  */
      if (otp == "") {
        $('#otp').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }

      /* password field validation  */
      if (password == "") {
        $('#txt_user_password').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      } else {
        if (checkPasswordStrength() == false) {
          flag = false;
          e.preventDefault();
        }
      }

      /* confirm_password field validation  */
      if (confirm_password == "") {
        $('#txt_confirm_password').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }

      /* password, confirm_password field validation  */
      if (confirm_password != "" && password != "" && confirm_password != password) {
        $('#txt_confirm_password').css('border-color', 'red');
        $("#id_error_display_signup").html("Confirm Password mismatch with Password");
        flag = false;
        e.preventDefault();
      }

      /* Email field validation  */
      if (email == "") {
        $('#txt_user_email').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }

      /* Mobile field validation  */
      if (user_mobile == "") {
        $('#txt_user_mobile').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }
      if (user_mobile.length != 10) {
        $('#txt_user_mobile').css('border-color', 'red');
        $("#id_error_display_signup").html("Please enter a valid mobile number");
        console.log("##");
        flag = false;
        e.preventDefault();
      }
      if (!(user_mobile.charAt(0) == "9" || user_mobile.charAt(0) == "8" || user_mobile.charAt(0) == "6" ||
        user_mobile.charAt(0) == "7")) {
        $('#txt_user_mobile').css('border-color', 'red');
        $("#id_error_display_signup").html("Please enter a valid mobile number");
        document.getElementById('txt_user_mobile').focus();
        flag = false;
        e.preventDefault();
      } else {

      }
      /* Email field validation  */
      var filter = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i
      if (filter.test(email)) {
        // flag = true;
      } else {
        $("#id_error_display_signup").html("Email is invalid");
        flag = false;
        e.preventDefault();
      }
      /********Validation end here ****/

      /* If all are ok then we send ajax request to ajax/call_functions.php *******/
      if (flag) {
        e.preventDefault();
        var data_serialize = $("#frm_users").serialize();
        $.ajax({
          type: 'post',
          url: "ajax/call_functions.php",
          dataType: 'json',
          data: data_serialize,
          beforeSend: function () { // Before send to Ajax
            $('#submit_signup').attr('disabled', true);
            $('#load_page').show();
          },
          complete: function () { // After complete Ajax
            $('#submit_signup').attr('disabled', false);
            $('#load_page').hide();
          },
          success: function (response) { // Success
            if (response.status == 0) { // Failure response
              $('#submit_signup').attr('disabled', true);
              $("#id_error_display_signup").html(response.msg);
            } else if (response.status == 1) { // Success Reponse
              $('#submit_signup').attr('disabled', true);
              $("#id_error_display_signup").html(response.msg);
              setInterval(function () {
                window.location = 'manage_users_list';
              }, 2000);
            }
            if (response.status == 2) { // Failure response
              e.preventDefault();
              $('#submit_signup').attr('disabled', true);
              $("#id_error_display_signup").html(response.msg);
            }

          },
          error: function (response, status, error) { // Error
            $('#otp').val('');
            $('#txt_user_email').val('');
            $('#txt_user_mobile').val('');
            $('#user_name').val('');
            $('#txt_user_password').val('');
            $('#txt_confirm_password').val('');
            $('#submit_signup').attr('disabled', false);
            $("#id_error_display_signup").html(response.msg);
          }
        });
      }
    });

    function password_visible1() {
      var x = document.getElementById("txt_user_password");
      if (x.type === "password") {
        x.type = "text";
        $('#login_pwd_display_visiblitity').html('<i class="fas fa-eye"></i>');
      } else {
        x.type = "password";
        $('#login_pwd_display_visiblitity').html('<i class="fas fa-eye-slash"></i>');
      }
    }

    function password_visible2() {
      var x = document.getElementById("txt_confirm_password");
      if (x.type === "password") {
        x.type = "text";
        $('#conform_pwd_display_visiblitity').html('<i class="fas fa-eye"></i>');
      } else {
        x.type = "password";
        $('#conform_pwd_display_visiblitity').html('<i class="fas fa-eye-slash"></i>');
      }
    }

    // To Update progress bar as per the input
    $(document).ready(function () {
      // Whenever the key is pressed, apply condition checks.
      $("#txt_user_password").keyup(function () {
        var m = $(this).val();
        var n = m.length;
        // Function for checking
        check(n, m);
      });
    });

    // To check the strength of a password
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

      // Check for the character-set constraints
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

    document.body.addEventListener("click", function (evt) {
      $("#id_error_display_signup").html("");
    })

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
        else {
          $('#txt_user_mobile').css('border-color', '#ccc');
          $('#otp').prop('disabled', false);
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
      }
      return stt;
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
          beforeSend: function () { },
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
  </script>
</body>

</html>
