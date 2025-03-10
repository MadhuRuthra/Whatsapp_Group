<div class="main-sidebar sidebar-style-2">
  <aside id="sidebar-wrapper">
    <div class="sidebar-brand">
      <a href="dashboard"><img src="assets/img/yeejai-logo.png" style="height:100%" /></a>
    </div>
    <div class="sidebar-brand sidebar-brand-sm">
      <a href="dashboard"><img src="assets/img/yj.png" style="height:100%" /></a>
    </div>
    <ul class="sidebar-menu">
      <li <? if ($site_page_name == 'dashboard') { ?>class="dropdown active" <? } else { ?>class="dropdown" <? } ?>>
        <a href="dashboard" class="nav-link"><i class="fas fa-home"></i><span>Dashboard</span></a>
      </li>

      <li <? if ($site_page_name == 'approve_whatsapp_no' or $site_page_name == 'manage_senderid_list' or $site_page_name == 'add_senderid') { ?>class="dropdown active" <? } else { ?>class="dropdown" <? } ?>>
        <a href="#" class="nav-link has-dropdown" data-toggle="dropdown"><i class="fab fa-whatsapp"></i>
          <span>Sender ID</span></a>
        <ul class="dropdown-menu">
            <li <? if ($site_page_name == 'add_senderid') { ?>class="active" <? } ?>><a class="nav-link" href="add_senderid">Add Sender ID</a></li>
            <li <? if ($site_page_name == 'manage_senderid_list') { ?>class="active" <? } ?>><a class="nav-link" href="manage_senderid_list">Sender ID List</a></li>
        </ul>
      </li>

      <li <? if ($site_page_name == 'contacts') { ?>class="dropdown active" <? } else { ?>class="dropdown" <? } ?>>
        <a href="contacts" class="nav-link"><i class="fas fa-user"></i><span>Contacts</span></a>
      </li>

      <li <? if ($site_page_name == 'add_group' or $site_page_name == 'group_list' or $site_page_name == 'add_group' or $site_page_name == 'add_contact_group') { ?>class="dropdown active" <? } else { ?>class="dropdown" <? } ?>>
        <a href="#" class="nav-link has-dropdown"><i class="fas fa-user-plus"></i> <span>Groups</span></a>
        <ul class="dropdown-menu">
            <? /* <li <? if ($site_page_name == 'add_group') { ?>class="active" <? } ?>><a class="nav-link" href="add_group">Add Group</a></li> */ ?>
            <li <? if ($site_page_name == 'add_contact_group') { ?>class="active" <? } ?>><a class="nav-link" href="add_contact_group">Add Group Contact</a></li>
            <li <? if ($site_page_name == 'group_list') { ?>class="active" <? } ?>><a class="nav-link" href="group_list">Group List</a></li>
        </ul>
      </li>

      <li <? if ($site_page_name == 'summary_report' or $site_page_name == 'campaign_report' or $site_page_name == 'details_report') { ?>class="dropdown active" <? } else { ?>class="dropdown" <? } ?>>
        <a href="#" class="nav-link has-dropdown"><i class="fas fa-chart-bar"></i> <span>MIS Reports</span></a>
        <ul class="dropdown-menu">
            <li <? if ($site_page_name == 'campaign_report') { ?>class="active" <? } ?>><a class="nav-link" href="campaign_report">Campaign Report</a></li>
            <? /* <li <? if ($site_page_name == 'details_report') { ?>class="active" <? } ?>><a class="nav-link" href="details_report">Details Report</a></li> */ ?>
        </ul>
      </li>
    </ul>

  </aside>
</div>
