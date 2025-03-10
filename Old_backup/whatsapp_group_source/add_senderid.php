<?
/*
Authendicated users only allow to view this Add Sender ID page.
This page is used to Add a New Sender ID by scanning the QR Code.
It will send the form to API service and Save to Whatsapp Facebook
and get the response from them and store into our DB.

Version : 1.0
Author : Arun Rama Balan.G (YJ0005)
Date : 07-Jul-2023
*/

session_start(); // To start session
error_reporting(0); // The error reporting function

include_once('api/configuration.php'); //  Include configuration.php
extract($_REQUEST); // Extract the request

// If the Session is not available redirect to index page
if ($_SESSION['yjwatsp_user_id'] == "") { ?>
  <script>window.location = "index";</script>
  <?php exit();
}

$site_page_name = pathinfo($_SERVER['PHP_SELF'], PATHINFO_FILENAME); // Collect the Current page name
site_log_generate("Add Sender ID Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s")); // Log File
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Add Sender ID ::
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

<style>
  .loader {
    width: 50;
    background-color: #ffffffcf;
  }
  .loader img {}
</style>

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
            <!-- Title & Breadcrumb Panel -->
          <div class="section-header">
            <h1>Add Sender ID</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item active"><a href="manage_senderid_list">Manage Sender ID List</a></div>
              <div class="breadcrumb-item">Add Sender ID</div>
            </div>
          </div>

          <!-- Entry Panel -->
          <div class="section-body">
            <div class="row">

              <div class="col-12 col-md-8 col-lg-8 offset-2">
                <div class="card">
                  <form class="needs-validation" novalidate="" id="frm_store" name="frm_store" action="#" method="post"
                    enctype="multipart/form-data">
                    <div class="card-body">

                      <!-- Mobile No -->
                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Mobile Number</label>
                        <div class="col-sm-9">
                          <select id="txt_country_code" name="txt_country_code" class="form-control" tabindex="1" style="width: 20%; float: left;">
                            <?
                            site_log_generate("Add Sender ID Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [country list] on " . date("Y-m-d H:i:s"));
                            $bearer_token = 'Authorization: '.$_SESSION['yjwatsp_bearer_token'].''; 
                            $curl = curl_init();
                            curl_setopt_array(
                              $curl,
                              array(
                                CURLOPT_URL => $api_url . '/list/country_list',
                                CURLOPT_RETURNTRANSFER => true,
                                CURLOPT_ENCODING => '',
                                CURLOPT_MAXREDIRS => 10,
                                CURLOPT_TIMEOUT => 0,
                                CURLOPT_FOLLOWLOCATION => true,
                                CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
                                CURLOPT_SSL_VERIFYPEER => 0,
                                CURLOPT_CUSTOMREQUEST => 'GET',
                                CURLOPT_HTTPHEADER => array(
                                  $bearer_token,
                                  'Content-Type: application/json'
                                ),
                              )
                            );
                            $response = curl_exec($curl);
                            curl_close($curl);

                            $state1 = json_decode($response, false);
                            site_log_generate("Add Sender ID Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"));
                            // print_r($state1);

                            if ($state1->response_status == 403) { ?>
                              <script>window.location="logout"</script>
                            <? } 

                            if ($state1->response_status == 200) {
                              for ($indicator = 0; $indicator < count($state1->country_list); $indicator++) {
                                $shortname = $state1->country_list[$indicator]->shortname;
                                $phonecode = $state1->country_list[$indicator]->phonecode;
                                $countryid = $state1->country_list[$indicator]->id;
                                ?>
                                <option value="<?= $countryid ?>||<?= $phonecode ?>" <? if ($shortname == 'IN') {
                                      echo "selected";
                                    } ?>><?=
                                       $shortname . " +" . $phonecode ?></option>
                              <?php }
                            }
                            ?>
                          </select>

                          <input type="text" name="mobile_number" id='mobile_number' class="form-control"
                            value="<?= $_REQUEST['mob'] ?>" tabindex="2" autofocus required="" maxlength="13"
                            placeholder="Mobile Number" data-toggle="tooltip" data-placement="top" title=""
                            data-original-title="Mobile Number" style="width:75%; float:left; margin-left:2%;"
                            onkeypress="return (event.charCode !=8 && event.charCode ==0 || ( event.charCode == 46 || (event.charCode >= 48 && event.charCode <= 57)))"
                            onblur="return call_validate_mobileqrno()" <? if ($_REQUEST['mob'] != '') { ?> readonly <? } ?>>
                        </div>
                      </div>

                      <div class="card-footer text-center">
                        <span class="error_display" id='id_error_display'></span><br> <!-- Error Display -->
                        <input type="hidden" class="form-control" name='store_call_function' id='store_call_function'
                          value='qrcode' /> <!-- Process Name -->
                        <a href="#!" name="submit" id="submit" tabindex="3" value="Submit"
                          class="btn btn-success">Click</a> <!-- Submit Button -->

                        <div class="container">
                          <span class="error_display" style='font-size: 12px;' id='qrcode_display'></span><Br>
                          <img src='./assets/img/loader.gif' id="id_qrcode" alt='QR Code'> <!-- QR Code display Panel -->
                        </div>
                      </div>


                  </form>

                </div>
              </div>
            </div>

            <!-- Instruction Panel -->
            <div class="text-left">
              <span class="error_display1"><b>Note :</b> <br>1) Mobile Numbers for India - 10 digits allowed <br>2)
                Mobile Numbers for Foreign country - 5 to 13 digits allowed <br>3) It should be a whatsapp
                account</span>
            </div>
          </div>
        </section>
      </div>

      <!-- Footer Panel -->
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

  <!--Remove duplicates numbers -->
  <script>
    // On loading the page, this function will call
    $(function () {
      $('#id_qrcode').fadeOut("slow");
    });

    // If the Function get no response and timeout
    function show_timeout() {
      $('#id_qrcode').hide();
      $("#qrcode_display").html("Timed out, Waiting for new QR Code");
    }

    // To Submit the Mobile No and display the QR Code From API
    function call_validate_mobileqrno() {
      $('#id_qrcode').hide();
      $("#qrcode_display").html("");
      var mobile_number = $("#mobile_number").val();
      var stt = -1;

      // Validate Mobile NO
      if (mobile_number.length < 5 && mobile_number != '') {
        $('#mobile_number').css('border-color', '#red');
        $("#id_error_display").html("Mobile Number must contain 5 to 13 digits");
      }

      // If Mobile NO > 5
      if (mobile_number.length > 5) {

        var letter = mobile_number.charAt(0);
        if (letter == 0 || letter == 1 || letter == 2 || letter == 3 || letter == 4 || letter == 5) { // First Character is in 0 to 5 then INVALID
          stt = 0;
        } else { // Else VALID
          stt = 1;
        }
        if (stt == 0) { // Send Invalid Response
          $('#mobile_number').css('border-color', 'red');
          $("#id_error_display").html("Invalid Mobile Number");
        }
        else
          $('#mobile_number').css('border-color', '#ccc'); // Success Response
      }

      if (mobile_number.length >= 5 & mobile_number.length <= 13) { // Mobile between 5 to 13 Digits then
        var flag = true;
        var mobile_number = $("#mobile_number").serialize();
        var txt_country_code = $("#txt_country_code").val();

        $.ajax({
          type: 'post',
          url: "ajax/store_call_functions.php?store_call_function=mobile_qrcode&txt_country_code=" + txt_country_code + "",
          dataType: 'json',
          data: mobile_number,
          beforeSend: function () { // Before send to Ajax
            $('#id_qrcode').show();
            $('a').css("pointer-events", "none");
            $('#submit').addClass('btn-outline-light btn-disabled').removeClass('btn-success');
            $('#submit').css("pointer-events", "none");
          },
          complete: function () { // After complete the Ajax
            $('#id_qrcode').show();
          },
          success: function (response) { // Success
            $('a').css("pointer-events", "block");
            if (response.status == '1') { // Success Response
              $('#id_qrcode').show();
              $("#id_qrcode").attr("src", response.qrcode);
              $("#qrcode_display").html('Please wait, automatically it will redirect after link!!');
              if (response.msg == 'QRCODE Already Scanned!') {
                window.location = "manage_senderid_list";
              }
            } else if (response.status == '2') { // Loading
              $('#id_qrcode').hide();
              $("#qrcode_display").html(response.msg);
            } else if (response.status == '0') { // Failure Response
              $('#id_qrcode').hide();
              $("#qrcode_display").html(response.msg);
              $('#submit').addClass('btn-success').removeClass('btn-outline-light btn-disabled');
              $('#submit').css("pointer-events", "block");
            }

            setInterval(show_timeout, 50000); // After 50 seconds show timeout msg
          },
          error: function (response, status, error) { // Error
            $('a').css("pointer-events", "block");
            $('#mobile_number').val('');
            $('#id_qrcode').show();
            $("#id_error_display").html(response.msg);
          }
        })
      }
      return stt;

    }
    setInterval(call_validate_mobileqrno, 60000); // Every min it will call
  </script>
</body>

</html>
