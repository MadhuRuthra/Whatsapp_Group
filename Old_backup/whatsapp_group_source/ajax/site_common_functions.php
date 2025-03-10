<?
function displayDates($format = 'D, d M Y')
{
  $date2 = date("Y-m-d");
  $date1 = date('Y-m-d', strtotime($date2 . ' - 9 days'));

  // $dates = array();
  $current = strtotime($date1);
  $date2 = strtotime($date2);
  $stepVal = '+1 day';
  while ($current <= $date2) {
    $dates_display .= '"' . date($format, $current) . '", ';
    // $dates[] = date($format, $current);
    $current = strtotime($stepVal, $current);
  }
  $dates_display = rtrim($dates_display, ', ');
  return $dates_display;
}

function indian_money_format($number)
{

  return $num = preg_replace("/(\d+?)(?=(\d\d)+(\d)(?!\d))(\.\d+)?/i", "$1,", $number);
}

function is_base64($s)
{
  return (bool) preg_match('/^[a-zA-Z0-9\/\r\n+]*={0,2}$/', $s);
}

// Find the Unread Mail count from Gmail
function CountUnreadMail($host, $login, $passwd)
{
  $mbox = imap_open($host, $login, $passwd);
  $count = 0;
  if (!$mbox) {
    echo "Error";
  } else {
    $headers = imap_headers($mbox);
    foreach ($headers as $mail) {
      $flags = substr($mail, 0, 4);
      $isunr = (strpos($flags, "U") !== false);
      if ($isunr)
        $count++;
    }
  }

  imap_close($mbox);
  return $count;
}

function validate_phone_number($phone)
{
  // Allow +, - and . in phone number
  $filtered_phone_number = filter_var($phone, FILTER_SANITIZE_NUMBER_INT);
  // Remove "-" from number
  $phone_to_check = str_replace("-", "", str_replace(" ", "", $filtered_phone_number));

  // Check the lenght of number
  // This can be customized if you want phone number from a specific country
  if (strlen($phone_to_check) < 5 || strlen($phone_to_check) > 13) {
    // if (strlen($phone_to_check) < 10 || strlen($phone_to_check) > 12) {
    return false;
  } else {
    // echo "**".$phone."**".preg_match('/^[6-9]\d{9}$/', $phone)."**";
    if (preg_match('/^[1-9]\d{4,12}$/', $phone)) { // Pregmatch for 5 to 13 mobile number digits allowed and It must starts between 1 to 9
      return true;
    } else {
      return false;
    }
  }
}
?>
