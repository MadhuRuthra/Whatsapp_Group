<!--<script src="assets/js/jquery-3.4.0.min.js"></script>-->
<!---<script src="assets/js/jToast.js"></script>-->

<link rel="stylesheet" href="assets/modules/izitoast/css/iziToast.min.css">
<!-- JS Libraies -->
<script src="assets/modules/izitoast/js/iziToast.min.js"></script>
<!-- Page Specific JS File -->
<script src="assets/js/page/modules-toastr.js"></script>

<div id="scrolltop"><a class="top-button" href="#top"><img src="assets/img/up_arrow.png"
      style="width: 18px; height: 18px; text-align: center; margin-bottom: 5px;"></a></div>

<footer class="main-footer">
  <div class="footer-left">
    Copyright &copy;
    <?= date("Y") ?>
    <div class="bullet"></div> <a href="https://www.yeejai.com/" target="_blank">YeeJai Technologies</a>
  </div>
  <div class="footer-right">
    <a href="faq">FAQ</a> | <a href="#!">Privacy Policy</a>
  </div>
</footer>

<script>
  $(document).ready(function () {
    // find_waiting_approval();
    // find_blocked_senderid();
  });

  /* function find_waiting_approval() { -- DONT use
    $.ajax({
      type: 'post',
      url: "ajax/message_call_functions.php?tmpl_call_function=count_whatsappno",
      dataType: 'json',
      success: function(response) {
        if (response.status == 1) {
          showToast(
            '<div class="text-center" style="font-size: 20px; text-decoration: underline"><b>Notification</b></div><img src="assets/img/cm-logo.png" style="height:100px"><br>'+response.msg+' Sender ID Approvals are waiting.<br><a href="approve_whatsapp_no_api" class="cls_call" style="font-weight: bold">Click to Approve!!</a><br>',
            {
              duration: 3000, // The time interval after notification disappear - 10 seconds
              background: '#00d665a6', // Background color for toast notification 
              color: '#000', // Text color 
              borderRadius: '10px' //Border Radius 
            }
          );
        }
      },
      error: function(response, status, error) {}
    });
  }
  // setInterval(find_waiting_approval, 600000); // Every min it will call */

  function find_blocked_senderid() {
    $.ajax({
      type: 'post',
      url: "ajax/message_call_functions.php?tmpl_call_function=find_blocked_senderid",
      dataType: 'json',
      success: function (response) {
        if (response.status == 1) {
          /* showToast(
            '<div class="text-center" style="font-size: 20px; text-decoration: underline"><b>Notification</b></div>Hi, Following Sender ID has going to expired<br>'+response.msg+'<br>',
            {
              duration: 3000, // The time interval after notification disappear - 10 seconds
              background: '#00d665a6', // Background color for toast notification 
              color: '#000', // Text color 
              borderRadius: '10px' //Border Radius 
            }
          ); */

          iziToast.error({
            title: '',
            message: '<div class="text-center" style="font-size: 20px; text-decoration: underline; padding-bottom: 10px;"><b>Notification</b></div>Hi, Following Sender ID has Blocked<br>' + response.msg + '<br>',
            // position: 'topCenter' 
            position: 'bottomRight'
          });
        }
      },
      error: function (response, status, error) { }
    });
  }
  // setInterval(find_blocked_senderid, 600000); // Every min it will call
</script>
