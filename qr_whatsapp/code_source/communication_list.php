<?php
session_start(); // start session
error_reporting(0); // The error reporting function

include_once('api/configuration.php'); // Include configuration.php
extract($_REQUEST); // Extract the request

// If the Session is not available redirect to index page
if ($_SESSION['yjwatsp_user_id'] == "") { ?>
  <script>window.location = "index";</script>
  <?php exit();
}

$site_page_name = pathinfo($_SERVER['PHP_SELF'], PATHINFO_FILENAME); // Collect the Current page name
site_log_generate("Whatsapp List Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"));
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Whatsapp List ::
    <?= $site_title ?>
  </title>
  <link rel="icon" href="assets/img/favicon.ico" type="image/x-icon">

  <!-- General CSS Files -->
  <link rel="stylesheet" href="assets/modules/bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="assets/modules/fontawesome/css/all.min.css">

  <!-- CSS Libraries -->
  <link rel="stylesheet" href="assets/css/jquery.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/searchPanes.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/select.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/colReorder.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/buttons.dataTables.min.css">

  <!-- Template CSS -->
  <link rel="stylesheet" href="assets/css/style.css">
  <link rel="stylesheet" href="assets/css/components.css">
 <link rel="stylesheet" href="assets/css/loader.css">
</head>

<style>
  #id_template_whatsapp_list {
    height: 600px;
  }

  .dataTables_filter label,
  .previous,
  .next {
    font-weight: bolder;
  }
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
          <!-- Title and Breadcrumbs -->
          <div class="section-header">
            <h1>Communication List</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item active"><a href="communication">Communication</a></div>
              <div class="breadcrumb-item">Communication List</div>
            </div>
          </div>

          <!-- Communication Button Panel -->
          <div class="row">
            <div class="col-12">
              <h4 class="text-right"><a href="communication" class="btn btn-success"><i
                    class="fas fa-plus"></i>Communication</a></h4>
            </div>
          </div>

          <!-- List Panel -->
          <div class="section-body">
            <div class="row">
              <div class="col-12">
                <div class="card">
                  <div class="card-body">
                    <div class="table-responsive" id="id_template_whatsapp_list">
                      Loading..
                    </div>
                  </div>
                </div>
              </div>
            </div>

          </div>
        </section>
      </div>

      <div class="modal" tabindex="-1" role="dialog" id="message_view">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
      <div class="modal-header">
          <h4 class="modal-title">Message</h4>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <center><img id="img_url" src="" width="300" height="300" style="display:none"/></center>
        <center>
        <video id="video_url" width="300" height="300" style="display:none" controls>
    <source src="" type="video/mp4">
    Your browser does not support the video tag.
</video>
      </center>

        <div class="modal-body" id="id_modal_display" style="white-space: pre-line; word-wrap: break-word; word-break: break-word;">
          
        </div>

        <div class="modal-footer" >
        </div>
      </div>
    </div>
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

  <script src="assets/js/jquery.dataTables.min.js"></script>
  <script src="assets/js/dataTables.buttons.min.js"></script>
  <script src="assets/js/dataTables.searchPanes.min.js"></script>
  <script src="assets/js/dataTables.select.min.js"></script>
  <script src="assets/js/jszip.min.js"></script>
  <script src="assets/js/pdfmake.min.js"></script>
  <script src="assets/js/vfs_fonts.js"></script>
  <script src="assets/js/buttons.html5.min.js"></script>
  <script src="assets/js/buttons.colVis.min.js"></script>

  <script>
    // On loading the page, this function will call
    $(document).ready(function () {
      find_template_whatsapp_list();
    });

    
    function message_view(message, media_type, media_url) {
      var img = document.getElementById('img_url');
        var video = document.getElementById('video_url');
        img.src = "";
        video.src = "";
        $('#img_url').css('display', 'none');
        $('#video_url').css('display', 'none');

      console.log(message, media_type, media_url)
      $('#message_view').modal({ show: true });

      var divElement = document.getElementById('id_modal_display');

      // Assign the value to the innerHTML property of the div element
      divElement.innerHTML = message;

      if(media_type.toLowerCase() == 'image'){
      $('#img_url').css('display', 'block');
        img.src = media_url;
      }
      else if(media_type.toLowerCase() == 'video'){
      $('#video_url').css('display', 'block');
        video.src = media_url;
      }
    
    }
    // To list the Whatsapp messages from API
    function find_template_whatsapp_list() {
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?call_function=template_whatsapp_list",
        dataType: 'html',
        success: function (response) {
          $("#id_template_whatsapp_list").html(response);
        },
        error: function (response, status, error) { }
      });
    }
    setInterval(find_template_whatsapp_list, 60000); // Every 1 min (60000), it will call

    // To Show Datatable with Export, search panes and Column visible 
    $('#table-1').DataTable({
      dom: 'Bfrtip',
      colReorder: true,
      buttons: [{
        extend: 'copyHtml5',
        exportOptions: {
          columns: [0, ':visible']
        }
      }, {
        extend: 'csvHtml5',
        exportOptions: {
          columns: ':visible'
        }
      }, {
        extend: 'pdfHtml5',
        exportOptions: {
          columns: ':visible'
        }
      }, {
        extend: 'searchPanes',
        config: {
          cascadePanes: true
        }
      }, 'colvis'],
      columnDefs: [{
        searchPanes: {
          show: false
        },
        targets: [0]
      }]
    });
  </script>
</body>

</html>
