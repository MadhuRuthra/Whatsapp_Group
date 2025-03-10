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
site_log_generate("Details Report Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"));
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta http-equiv="refresh" content="60">
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Details Report :: <?= $site_title ?></title>
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
            <h1>Details Report</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item">Details Report</div>
            </div>
          </div>

          <div class="section-body">
            <div class="row">
              <div class="col-12">
                <div class="card">
                  <div class="card-body">
                    <div class="table-responsive">
                      <table class="table table-striped" id="table-1">
                        <thead>
                          <tr>
                            <th>#</th>
                            <th>User</th>
                            <th>Campaign</th>
                            <th>Message Content</th>
                            <th>Count</th>
                            <th>Mobile No</th>
                            <th>Status</th>
                          </tr>
                        </thead>
                        <tbody>
                          <?
                          $sql_dashboard1 = "SELECT user_id FROM user_management 
                                              where (user_id = '" . $_SESSION['yjwatsp_user_id'] . "' or 
                                                parent_id = '" . $_SESSION['yjwatsp_user_id'] . "')";
                          $qur_dashboard1 = $conn->query($sql_dashboard1);
                          $dashboard_user = '';
                          $sql_sntsms = '';
                          if ($qur_dashboard1->num_rows > 0) {
                            while ($row_dashboard1 = $qur_dashboard1->fetch_assoc()) {
                              $list_user_id = $row_dashboard1["user_id"];

                              $sql_sntsms .= "SELECT wht.compose_whatsapp_id, wht.user_id, usr.user_name, wht.campaign_name, wht.whatsapp_content, wht.message_type, wht.total_mobileno_count, wht.content_char_count, wht.content_message_count, stt.country_code, stt.mobile_no, stt.comments sender, stt.comwtap_entry_date, stt.response_status, stt.response_message, stt.response_id, stt.response_date, stt.delivery_status, stt.read_status FROM whatsapp_messenger_" . $list_user_id . ".compose_whatsapp_" . $list_user_id . " wht left join whatsapp_messenger_" . $list_user_id . ".compose_whatsapp_status_" . $list_user_id . " stt on wht.compose_whatsapp_id = stt.compose_whatsapp_id left join whatsapp_messenger.user_management usr on wht.user_id = usr.user_id where (wht.user_id = '" . $list_user_id . "' or usr.parent_id = '" . $list_user_id . "') UNION ";
                            }
                          }
                          $sql_sntsms = rtrim($sql_sntsms, " UNION ");
                          $sql_sntsms = $sql_sntsms . " order by comwtap_entry_date desc";
                          $qur_sntsms = $conn->query($sql_sntsms);
                          site_log_generate("Details Report Page : User : " . $_SESSION['yjtsms_user_name'] . " executed the Query ($sql_sntsms) on " . date("Y-m-d H:i:s"));

                          $increment = 0;
                          if ($qur_sntsms->num_rows > 0) {
                            while ($row_sntsms = $qur_sntsms->fetch_assoc()) {
                              extract($row_sntsms);
                              $increment++;

                              $compose_whatsapp_id = $row_sntsms["compose_whatsapp_id"];
                              $user_id = $row_sntsms["user_id"];
                              $user_name = $row_sntsms["user_name"];
                              $campaign_name = $row_sntsms["campaign_name"];
                              $whatsapp_content = $row_sntsms["whatsapp_content"];

                              $message_type = $row_sntsms["message_type"];
                              $total_mobileno_count = $row_sntsms["total_mobileno_count"];
                              $content_char_count = $row_sntsms["content_char_count"];
                              $content_message_count = $row_sntsms["content_message_count"];
                              $mobile_no = $row_sntsms["country_code"] . $row_sntsms["mobile_no"];

                              $sender = $row_sntsms["sender"];
                              $send_date = date('d-m-Y h:i:s A', strtotime($row_sntsms["comwtap_entry_date"]));
                              if ($row_sntsms["response_date"] != '') {
                                $response_date = date('d-m-Y h:i:s A', strtotime($row_sntsms["response_date"]));
                              } else {
                                $response_date = '';
                              }
                              $response_status = $row_sntsms["response_status"];
                              $response_message = $row_sntsms["response_message"];

                              $response_id = $row_sntsms["response_id"];
                              $delivery_status = $row_sntsms["delivery_status"];
                              $read_status = $row_sntsms["read_status"];

                              $disp_stat = '';
                              switch ($response_status) {
                                case 'S':
                                  $disp_stat = '<div class="badge badge-success">SENT</div>';
                                  break;
                                case 'F':
                                  $disp_stat = '<div class="badge badge-danger">FAILED</div>';
                                  break;
                                case 'I':
                                  $disp_stat = '<div class="badge badge-warning">INVALID</div>';
                                  break;

                                default:
                                  $disp_stat = '<div class="badge badge-info">YET TO SENT</div>';
                                  break;
                              }
                              ?>
                              <tr>
                                <td>
                                  <?= $increment ?>
                                </td>
                                <td>
                                  <?= $user_name ?>
                                </td>
                                <td>
                                  <?= $campaign_name ?>
                                </td>
                                <td>
                                  <?= $message_type ?> :
                                  <?= $whatsapp_content ?>
                                </td>
                                <td>Total Mobile No :
                                  <?= $total_mobileno_count ?><br>Total Messages :
                                  <?= $content_message_count ?>
                                </td>
                                <td>Sender : <a href="#!" class="btn btn-outline-primary btn-disabled">
                                    <?= $sender ?>
                                  </a><br>Receiver : <a href="#!" class="btn btn-outline-success btn-disabled">
                                    <?= $mobile_no ?>
                                  </a></td>
                                <td>
                                  <?= $response_date . "<br>" . $disp_stat ?>
                                </td>
                              </tr>
                            <?
                            }
                          }
                          ?>
                        </tbody>
                      </table>
                    </div>
                  </div>
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