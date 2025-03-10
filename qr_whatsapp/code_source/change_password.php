<?php
session_start();
error_reporting(0);
include_once('api/configuration.php');
extract($_REQUEST);

if ($_SESSION['yjwatsp_user_id'] == "") { ?>
  <script>window.location = "index";</script>
  <?php exit();
}

$site_page_name = pathinfo($_SERVER['PHP_SELF'], PATHINFO_FILENAME);
site_log_generate("Change Password Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"));
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Change Password ::
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
</head>

<body>
  <div id="app">
    <div class="main-wrapper main-wrapper-1">
      <div class="navbar-bg"></div>

      <? include("libraries/site_header.php"); ?>

      <? include("libraries/site_menu.php"); ?>

      <!-- Main Content -->
      <div class="main-content">
        <section class="section">
          <div class="section-header">
            <h1>Change Password</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item">Change Password</div>
            </div>
          </div>

          <div class="section-body">
            <div class="row">

              <div class="col-12 col-md-8 col-lg-8 offset-2">
                <div class="card">
                  <form class="needs-validation" novalidate="" id="frmid_change_pwd" name="frmid_change_pwd" action="#"
                    method="post" enctype="multipart/form-data">
                    <div class="card-body">

                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Existing Password</label>
                        <div class="col-sm-9">
                          <div class="input-group" title="" data-toggle="tooltip" data-placement="top" title=""
                            data-original-title="Existing Password">
                            <span class="input-group-addon"><i class="icofont icofont-lock"></i></span>
                            <input type="password" name="txt_ex_password" id='txt_ex_password' class="form-control"
                              maxlength="100" value="" tabindex="1" autofocus required=""
                              placeholder="Existing Password">
                            <div class="input-group-prepend">
                              <div class="input-group-text" onclick="password_visible()"
                                id="id_signup_display_visiblitity"><i class="fas fa-eye-slash"></i>
                              </div>
                            </div>

                          </div>
                        </div>
                      </div>

                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">New Password</label>
                        <div class="col-sm-9">
                          <div class="input-group" title="" data-toggle="tooltip" data-placement="top" title=""
                            data-original-title="New Password : [Atleast 8 characters and Must Contains Numeric, Capital Letters and Special characters]">
                            <span class="input-group-addon"><i class="icofont icofont-ui-lock"></i></span>
                            <input type="password" name="txt_new_password" id='txt_new_password' class="form-control"
                              maxlength="100" value="" tabindex="2" required=""
                              placeholder="New Password : [Atleast 8 characters and Must Contains Numeric, Capital Letters and Special characters]"
                              onblur="return checkPasswordStrength()">
                            <div class="input-group-prepend">
                              <div class="input-group-text" onclick="password_visible1()" id="display_visiblitity"><i
                                  class="fas fa-eye-slash"></i>
                              </div>
                            </div>

                          </div>
                          <div id='idtxt_new_password' class='text-danger'></div>

                          <div class="progress" style="margin-top: 3px; height: 3px;">
                            <div class="progress-bar" role="progressbar" aria-valuenow="0" aria-valuemin="0"
                              aria-valuemax="100" style="width:0%" data-toggle="tooltip" data-placement="top" title=""
                              data-original-title="Password Strength Meter" placeholder="Password Strength Meter">
                            </div>
                          </div>
                        </div>
                      </div>

                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Confirm Password</label>
                        <div class="col-sm-9">
                          <div class="input-group" title="" data-toggle="tooltip" data-placement="top" title=""
                            data-original-title="Confirm Password : [Atleast 8 characters and Must Contains Numeric, Capital Letters and Special characters]">
                            <span class="input-group-addon"><i class="icofont icofont-sand-clock"></i></span>
                            <input type="password" name="txt_confirm_password" id='txt_confirm_password'
                              class="form-control" maxlength="100" value="" tabindex="3" required=""
                              placeholder="Your Confirm Password">
                            <div class="input-group-prepend">
                              <div class="input-group-text" onclick="password_visible2()" id="display_visiblitity_1"><i
                                  class="fas fa-eye-slash"></i>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>

                      <div class="card-footer text-center">
                        <span class="error_display" id='pwd_id_error_display'></span><br>
                        <input type="hidden" class="form-control" name='pwd_call_function' id='pwd_call_function'
                          value='change_pwd' />
                        <input type="submit" name="pwd_submit" id="pwd_submit" tabindex="4" value="Change Password"
                          class="btn btn-success">
                      </div>
                  </form>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>

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
    function checkPasswordStrength() {
      var number = /([0-9])/;
      var alphabets = /([a-zA-Z])/;
      var special_characters = /([~,!,@,#,$,%,^,&,*,-,_,+,=,?,>,<])/;
      var new_pass = $('#txt_new_password').val();
      if (new_pass.length < 8 && new_pass != '') {
        $('#idtxt_new_password').html("Weak (should be atleast 8 characters.)");
        $('#txt_new_password').css('border-color', 'red');
        return false;
      } else {
        if ($('#txt_new_password').val().match(number) && $('#txt_new_password').val().match(alphabets) && $('#txt_new_password').val().match(special_characters)) {
          $('#idtxt_new_password').html("");
          $('#txt_new_password').css('border-color', '#a0a0a0');
          return true;
        } else {
          if (new_pass != '') {
            $('#idtxt_new_password').html("Medium (should include alphabets, numbers and special characters.)");
            $('#txt_new_password').css('border-color', 'red');
            return false;
          }
        }
      }
    }

    function password_visible1() {
      var x = document.getElementById("txt_new_password");
      if (x.type === "password") {
        x.type = "text";
        $('#display_visiblitity').html('<i class="fas fa-eye"></i>');
      } else {
        x.type = "password";
        $('#display_visiblitity').html('<i class="fas fa-eye-slash"></i>');
      }
    }

    function password_visible2() {
      var x = document.getElementById("txt_confirm_password");
      if (x.type === "password") {
        x.type = "text";
        $('#display_visiblitity_1').html('<i class="fas fa-eye"></i>');
      } else {
        x.type = "password";
        $('#display_visiblitity_1').html('<i class="fas fa-eye-slash"></i>');
      }
    }

    function password_visible() {
      var x = document.getElementById("txt_ex_password");
      if (x.type === "password") {
        x.type = "text";
        $('#id_signup_display_visiblitity').html('<i class="fas fa-eye"></i>');
      } else {
        x.type = "password";
        $('#id_signup_display_visiblitity').html('<i class="fas fa-eye-slash"></i>');
      }
    }

    $("#pwd_submit").click(function (e) {
      $("#pwd_id_error_display").html("");

      //get input field values
      var ex_password = $('#txt_ex_password').val();
      var new_password = $('#txt_new_password').val();
      var confirm_password = $('#txt_confirm_password').val();

      var flag = true;
      /********validate all our form fields***********/
      /* password field validation  */
      if (ex_password == "") {
        $('#txt_ex_password').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }
      if (new_password == "") {
        $('#txt_new_password').css('border-color', 'red');
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

      /* ex password, new password, confirm_password field validation  */
      if (new_password == ex_password && (new_password != '') && (ex_password != '')) {
        $('#txt_new_password').css('border-color', 'red');
        $("#pwd_id_error_display").html("New Password cannot same with Existing Password");
        flag = false;
        e.preventDefault();
      }

      if (confirm_password != "" && new_password != "" && confirm_password != new_password) {
        $('#txt_confirm_password').css('border-color', 'red');
        $("#pwd_id_error_display").html("Confirm Password mismatch with New Password");
        flag = false;
        e.preventDefault();
      }
      /********Validation end here ****/

      /* If all are ok then we send ajax request to ajax/call_functions.php *******/
      if (flag) {
        $('#txt_confirm_password').css('border-color', '');
        $('#txt_ex_password').css('border-color', '');
        var data_serialize = $("#frmid_change_pwd").serialize();
        $.ajax({
          type: 'post',
          url: "ajax/call_functions.php",
          dataType: 'json',
          data: data_serialize,
          beforeSend: function () {
            $('#pwd_submit').attr('disabled', true);
            $('#load_page').show();
          },
          complete: function () {
            $('#pwd_submit').attr('disabled', false);
            $('#load_page').hide();
          },
          success: function (response) {
            if (response.status == '0') {
              $('#txt_ex_password').val('');
              $('#txt_new_password').val('');
              $('#txt_confirm_password').val('');
              $('#pwd_submit').attr('disabled', false);
              $("#pwd_id_error_display").html(response.msg);
            } else if (response.status == 1) {
              $('#pwd_submit').attr('disabled', false);
              $("#pwd_id_error_display").html("Password Changed..Kindly Login The New Password!");
              setInterval(function () {
                window.location = 'index';
              }, 2000);
            }
            $('#load_page').hide();
          },
          error: function (response, status, error) {
            $('#txt_ex_password').val('');
            $('#txt_new_password').val('');
            $('#txt_confirm_password').val('');
            $('#pwd_submit').attr('disabled', false);
            $("#pwd_id_error_display").html(response.msg);
          }
        });
      }
    });

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
      // and update percentage variable as needed.

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
      if (percentage > 80) {
        $("#strength_display").html("");
      } else {
        $("#strength_display").html(strn_disp);
      }
    }
    // Update progress bar as per the input
    $(document).ready(function () {
      // Whenever the key is pressed, apply condition checks.
      $("#txt_new_password").keyup(function () {
        var m = $(this).val();
        var n = m.length;

        // Function for checking
        check(n, m);
      });
    });
  </script>
</body>

</html>
