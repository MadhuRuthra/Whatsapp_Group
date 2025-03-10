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
site_log_generate("Add Group Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"));
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Add Group ::
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

      <? include("libraries/site_header.php"); ?>

      <? include("libraries/site_menu.php"); ?>

      <!-- Main Content -->
      <div class="main-content">
        <section class="section">
          <div class="section-header">
            <h1>Add Group</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item active"><a href="group_list">Group List</a></div>
              <div class="breadcrumb-item">Add Group</div>
            </div>
          </div>

          <div class="section-body">
            <div class="row">

              <div class="col-12 col-md-8 col-lg-8 offset-2">
                <div class="card">
                  <form class="needs-validation" novalidate="" id="frm_store" name="frm_store" action="#" method="post"
                    enctype="multipart/form-data">
                    <div class="card-body">

                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Group Name</label>
                        <div class="col-sm-9">
                          <input type="text" name="txt_group_name" id='txt_group_name' class="form-control"
                            value="<?= $_REQUEST['mob'] ?>" autofocus tabindex="1" required="" maxlength="250"
                            placeholder="Group Name" data-toggle="tooltip" data-placement="top" title=""
                            data-original-title="Group Name">
                        </div>
                      </div>

                      <div class="card-footer text-center">
                        <span class="error_display" id='id_error_display'></span><br>
                        <input type="hidden" class="form-control" name='store_call_function' id='store_call_function'
                          value='add_group_name' />
                        <a href="#!" name="submit" id="submit" tabindex="3" value="Submit"
                          class="btn btn-success">Submit</a>
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

  <!--Remove dublicates numbers -->
  <script>
    $(function () {
      $('#id_qrcode').fadeOut("slow");
    });

    function call_validate_mobileqrno() {
      $('#id_qrcode').hide();
      $("#qrcode_display").html("");
      var mobile_number = $("#mobile_number").val();
      var stt = -1;
      if (mobile_number.length < 5 && mobile_number != '') {
        $('#mobile_number').css('border-color', '#red');
        $("#id_error_display").html("Mobile Number must contain 5 to 13 digits");
      }

      if (mobile_number.length > 5) {

        var letter = mobile_number.charAt(0);
        if (letter == 0 || letter == 1 || letter == 2 || letter == 3 || letter == 4 || letter == 5) {
          stt = 0;
        } else {
          stt = 1;
        }
        if (stt == 0) {
          $('#mobile_number').css('border-color', 'red');
          $("#id_error_display").html("Invalid Mobile Number");
        }
        else
          $('#mobile_number').css('border-color', '#ccc');
      }

      if (mobile_number.length >= 5 & mobile_number.length <= 13) {
        var flag = true;
        var mobile_number = $("#mobile_number").serialize();
        var txt_country_code = $("#txt_country_code").val();

        $.ajax({
          type: 'post',
          url: "ajax/store_call_functions.php?store_call_function=mobile_qrcode&txt_country_code=" + txt_country_code + "",
          dataType: 'json',
          data: mobile_number,
          beforeSend: function () {
            $('#id_qrcode').show();
            $('a').css("pointer-events", "none");
            $('#submit').addClass('btn-outline-light btn-disabled').removeClass('btn-success');
            $('#submit').css("pointer-events", "none");
          },
          complete: function () {
            $('#id_qrcode').show();
          },
          success: function (response) {
            $('a').css("pointer-events", "block");
            if (response.status == '1') {
              $('#id_qrcode').show();
              $("#id_qrcode").attr("src", response.qrcode);
              $("#qrcode_display").html('Please wait, automatically it will redirect after link!!');
              if (response.msg == 'QRCODE Already Scanned!') {
                window.location = "manage_senderid_list";
              }
            } else if (response.status == '3') {
              $('#id_qrcode').hide();
              $("#qrcode_display").html(response.msg);
            } else if (response.status == 0) {
              $('#id_qrcode').hide();
              $("#qrcode_display").html(response.msg);
              $('#submit').addClass('btn-success').removeClass('btn-outline-light btn-disabled');
              $('#submit').css("pointer-events", "block");
            }
	
            setInterval(show_timeout, 50000); // After 50 seconds show timeout msg
          },
          error: function (response, status, error) {
            $('a').css("pointer-events", "block");
            $('#mobile_number').val('');
            $('#id_qrcode').show();
            $("#id_error_display").html(response.msg);
          }
        })
      }
      return stt;

    }
    setInterval(call_validate_mobileqrno, 60000);
  </script>
</body>

</html>
