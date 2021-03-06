common.php                                                                                          0000644 0001750 0001750 00000005310 11241376724 011531  0                                                                                                    ustar   alex                            alex                                                                                                                                                                                                                   <?php

$dbname = "net";
$low_speed = 400;

require ("DB.php");

session_start ();

$cols = array ("name", "ip", "port", "switch");


class sw {
	var $ip, $conn;
}


$switches = array ();

$sw = new sw;
$sw->ip = "192.168.50.2";
$switches[1] = $sw;

function h2($s) {
  $s = htmlentities ($s);
  $len = strlen ($s);
  $ret = "";

  for ($i = 0; $i < $len; $i++) {
    $ret .= $s[$i];
    $ret .= " ";
  }
  return ($ret);
}

function ckerr ($str, $obj, $aux = "")
{
  global $dbname;

  $ret = "";
  if (DB::isError ($obj)) {
    $ret = sprintf ("<p>DBERR %s %s: %s<br />\n",
		    h($dbname),
		    h($str),
		    h($obj->getMessage ()),
		    "");

    /* these fields might have db connect passwords */
    $ret .= h($obj->userinfo);
    if ($aux != "")
      $ret .= sprintf ("<p>aux info: %s</p>\n",
		       h($aux));
    $ret .= "</p>";
    echo ($ret);
    echo ("domain_name " . htmlentities ($_SERVER['HTTP_HOST']) . "<br/>");
    echo ("request " . htmlentities ($_SERVER['REQUEST_URI']) . "<br/>");
    var_dump ($_SERVER);
    error ();
    exit ();
  }
}

function query ($stmt, $arr = NULL) {
  global $login_id, $_SERVER;
  global $db;

  if (is_string ($stmt) == 0) {
    echo ("wrong type first arg to query");
    error ();
    exit ();
  }

  $q = $db->query ($stmt, $arr);
  ckerr ($stmt, $q);

  return ($q);
}

function fetch ($q) {
	return ($q->fetchRow (DB_FETCHMODE_OBJECT));
}

$db1 = new DB;
$db = $db1->connect ("pgsql://apache@/$dbname");
ckerr ("connect/local can't connect to database", $db);

query ("begin transaction");


function h($val) {
	return (htmlentities ($val, ENT_QUOTES, 'UTF-8'));
}

function do_commit () {
	query ("end transaction");
}

function redirect ($t) {
	ob_clean ();
	do_commit ();
	header ("Location: $t");
	exit ();
}

function pstart () {
	ob_start ();
	echo ("<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN'"
	      ." 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>\n"
	      ."<html xmlns='http://www.w3.org/1999/xhtml'>\n"
	      ."<head>\n"
	      ."<meta http-equiv='Content-Type' content='text/html;"
	      ." charset=utf-8' />\n");
	echo ("<title>Switch</title>\n");
	echo ("<link rel='stylesheet' type='text/css' href='style.css' />\n");
	echo ("</head>\n");
	echo ("<body>\n");
	if ($_SESSION['flash'] != "") {
		echo ($_SESSION['flash']);
		$_SESSION['flash'] = "";
	}
}


function pfinish () {
	echo ("</body>\n");
	echo ("</html>\n");
	do_commit ();
	exit ();
}

function mklink ($text, $target) {
	if (trim ($text) == "")
		return ("&nbsp;");
	if (trim ($target) == "")
		return (h($text));
	return (sprintf ("<a href='%s'>%s</a>",
			 h($target), h($text)));
}

function odd_even ($x) {
	if ($x & 1)
		return ("class='odd'");
	return ("class='even'");
}

?>
                                                                                                                                                                                                                                                                                                                        curconfig.php                                                                                       0000644 0001750 0001750 00000001271 11241376724 012222  0                                                                                                    ustar   alex                            alex                                                                                                                                                                                                                   <?php

require ("common.php");
require ("/var/switch-interface/password.php");

pstart ();

$str = "";

foreach ($switches as $id => $sw) {
	$str .= sprintf ("<h1>Switch %d</h1><br />", $id);

	$str .= "<pre>";
	$sw->conn = ftp_connect ($sw->ip);
	$login_result = ftp_login ($sw->conn, "admin", $password);
	if (!$login_result) {
		echo ("ftp connection failed\n");
		pfinish ();
	}

	$t = sprintf ("/tmp/curswitchconfig%d", $id);
	$config = fopen ($t, "w");

	$download_result = ftp_fget ($sw->conn, $config, "config", FTP_ASCII);
	if (!$download_result) {
		echo ("ftp download failed\n");
		pfinish ();
	}

	$str .= file_get_contents ($t);

	$str .= "</pre>";
}

echo ($str);
	
pfinish ();

?>
                                                                                                                                                                                                                                                                                                                                       details.php                                                                                         0000644 0001750 0001750 00000003322 11241376724 011667  0                                                                                                    ustar   alex                            alex                                                                                                                                                                                                                   <?php

require ("common.php");

pstart ();

$id = 0 + @$_REQUEST['id'];
$bandwidth = @$_REQUEST['bandwidth'];

if ($bandwidth && $id) {
	$stmt = sprintf ("update comps set bandwidth='%s' where id=%d",
			 $bandwidth, $id);

	query ($stmt);
	
	do_commit ();
	
	$t = sprintf ("details.php?id=%d", $id);

	redirect ($t);
}

echo ("<div style='padding-top:1em'></div>\n");

if ($id) {
	$stmt = sprintf ("select name, ip, port, switch, bandwidth, id"
			 ." from comps where id=%d", $id);
	$q = query ($stmt);

	
	if (($r = fetch ($q)) == NULL) {
		echo ("can't find");
		pfinish ();
	}

	echo (sprintf ("<a href='index.php'>Back to list</a> | ", h($t)));
	$t = sprintf ("edit.php?id=%d", $id);
	echo (sprintf ("<a href='%s'>Edit</a> | ", h($t)));
	$t = sprintf ("edit.php?id=%d&delete=1", $id);
	echo (sprintf ("<a href='%s'>Delete</a>", h($t)));
	echo ("<div style='padding:.5em'></div>\n");

	$rows = "";

	foreach ($cols as $col) {
		$val = $r->$col;
		$rows .= "<tr>\n";
		$rows .= "<th>$col</th><td>$val</td>\n";
		$rows .= "</tr>\n";
	}

	$rows .= "<tr>";
	$rows .= "<th>bandwidth</th>";
	$rows .= "<td>";
	if ($r->bandwidth == "high") {
		$rows .= sprintf ("<a href='details.php?bandwidth=high&amp;id=%d'"
				  ." class='selected'>High</a> | ", $id);
		$rows .= sprintf ("<a href='details.php?bandwidth=low&amp;id=%d'>"
				  ."Low</a>", $id);
	} else {
		$rows .= sprintf ("<a href='details.php?bandwidth=high&amp;id=%d'>"
				  ."High</a> | ", $id);
		$rows .= sprintf ("<a href='details.php?bandwidth=low&amp;id=%d'"
				  ." class='selected'>Low</a>", $id);
	}
	$rows .= "</td>";
	$rows .= "</tr>";

} else {
	echo ("can't find\n");
	pfinish ();
}

echo ("<table class='twocol'>\n");

echo ($rows);

echo ("</table>\n");

pfinish ();

?>
                                                                                                                                                                                                                                                                                                              edit.php                                                                                            0000644 0001750 0001750 00000006723 11241376724 011177  0                                                                                                    ustar   alex                            alex                                                                                                                                                                                                                   <?php

require ("common.php");

pstart ();

$id = 0 + @$_REQUEST['id'];
$edit = 0 + @$_REQUEST['edit'];
$delete = 0 + @$_REQUEST['delete'];
$bandwidth = @$_REQUEST['bandwidth'];

function mkrow ($varname, $val) {
	return (sprintf ("<input type='text' size='40'"
			 ."name='%s' value='%s' />\n",
			 h($varname), h($val)));
}

$arg = array ();

foreach ($cols as $col) {
	$arg[$col] = @$_REQUEST[$col];
}

echo ("<div style='padding-top:1em'></div>\n");

if ($id && $delete != 1 && $delete != 2) {
	$stmt = sprintf ("select name, ip, port, switch"
			 ." from comps where id=%d", $id);
	$q = query ($stmt);

	if (($r = fetch ($q)) == NULL) {
		echo ("can't find\n");
		pfinish ();
	}

	echo (sprintf ("<a href='index.php'>Back to list</a> | "));
	echo (sprintf ("<a href='details.php?id=%d'>Details</a> | ", $id));
	echo (sprintf ("<a href='edit.php?id=%d&amp;delete=1'>Delete</a>", $id));
	echo ("<div style='padding:.5em'></div>\n");

	echo ("<form action='edit.php'>\n");
	echo (sprintf ("<input type='hidden' name='id' value='%d' />\n",
		       $id));
	echo ("<input type='hidden' name='edit' value='2' />\n");
	echo (sprintf ("<input type='hidden' name='display' value='%d' />\n",
		       $display));

	$rows = "";

	foreach ($cols as $col) {
		$val = $r->$col;
		$rows .= "<tr>\n";
		$t = sprintf ("<th>%s</th><td>%s</td>\n",
			      $col, mkrow ($col, $val));
		$rows .= $t;
		$rows .= "</tr>\n";
	}
} else if ($delete != 1 && $delete != 2) {
	echo (sprintf ("<a href='index.php'>Back to list</a>"));
	echo ("<div style='padding:.5em'></div>\n");

	echo ("<form action='edit.php'>\n");
	echo (sprintf ("<input type='hidden' name='id' value='%d' />\n",
		       $id));
	echo ("<input type='hidden' name='edit' value='2' />\n");

	$rows = "";
	$val = "";

	foreach ($cols as $col) {
		$rows .= "<tr>\n";
		$t = sprintf ("<th>%s</th><td>%s</td>\n",
			      $col, mkrow ($col, $val));
		$rows .= $t;
		$rows .= "</tr>\n";
	}	
}

if ($delete == 1) {
	$stmt = sprintf ("select name, ip, port, switch"
			 ." from comps where id=%d", $id);
	$q = query ($stmt);

	if (($r = fetch ($q)) == NULL) {
		echo ("can't find\n");
		pfinish ();
	}

	echo ("<form action='edit.php'>\n");
	echo ("<input type='hidden' name='delete' value='2' />\n");
	echo (sprintf ("<input type='hidden' name='id' value='%d' />\n", $id));
	echo (sprintf ("Are you sure you want to delete '%s'?"
		       ." <input type='submit' value='delete' />\n",
		       h($r->name)));

	echo ("</form>\n"); 
	pfinish ();
}

if ($delete == 2) {
	$stmt = sprintf ("select name from comps where id=%d", $id);
	$q = query ($stmt);

	if (($r = fetch ($q)) == NULL) {
		echo ("can't find\n");
		pfinish ();
	}

	query ("delete from comps where id = ?", $id);
	redirect ("index.php");
}

if ($edit == 2) {
	if ($id == 0) {
		$q = query ("select nextval('seq') as seq");
		$r = fetch ($q);
		$id = 0 + $r->seq;

		$stmt = sprintf ("insert into comps (id) values (%d)", $id);
		query ($stmt);
	}

	$t = array ();

	foreach ($cols as $col) {
		if ($arg[$col] == null) {
			$t[] = sprintf ("%s = null", $col);
		} else {
			$t[] = sprintf ("%s = '%s'", $col, h($arg[$col]));
		}
	}

	$t[] = sprintf ("bandwidth = 'high'");

	$stmt = sprintf ("update comps set %s where id = %d",
			 join (",", $t), $id);

	query ($stmt);

	$t = sprintf ("edit.php?id=%d", $id);

	do_commit ();

	redirect ($t);
}

echo ("<table class='twocol'>\n");

echo ($rows);

echo ("<tr><th></th><td><input type='submit' value='Save' /></td></tr>\n");

echo ("</table>\n");

echo ("</form>\n");

pfinish ();

?>
                                             index.php                                                                                           0000644 0001750 0001750 00000010121 11241376724 011344  0                                                                                                    ustar   alex                            alex                                                                                                                                                                                                                   <?php

require ("common.php");
require ("/var/switch-interface/password.php");

pstart ();

$id = @$_REQUEST['id'];
$bandwidth = @$_REQUEST['bandwidth'];
$update = @$_REQUEST['update'];

if ($bandwidth && $id) {
	$stmt = sprintf ("update comps set bandwidth='%s' where id=%d",
			 $bandwidth, $id);
	query ($stmt);

	do_commit ();

	redirect ("index.php");
}

if ($update) {
	update_router ();
	redirect ("index.php");
}

function notblank ($val) {
	if (trim($val) == "") {
		return ("&nbsp;");
	} else {
		return ($val);
	}
}

function update_router () {
	global $password;

	$stmt = "select name, switch, port, bandwidth from comps order by port";
	$q = query ($stmt);
	
	global $switches;

	foreach ($switches as $id => $sw) {
		$sw->conn = ftp_connect ($sw->ip);
		$login_result = ftp_login ($sw->conn, "admin", $password);
		if (!$login_result) {
			echo ("ftp connection failed\n");
			pfinish ();
		}

		$t = sprintf ("/tmp/switchconfig%d", $id);
		
		$sw->fp = fopen ($t, "w");

		$sw->config = "";

		$sw->fp= fopen ($t, "w");
		$sw->config = "";
		$sw->config .= "vlan 1\n"
			."  name 1\n"
			."  normal \"\"\n"
			."  fixed 1-8\n"
			."  forbidden \"\"\n"
			."  untagged 1-8\n"
			."  ip address default-management";
		$sw->config .= sprintf (" %s 255.255.255.0\n",
					$sw->ip);
		$sw->config .= "exit\n";
	}

	global $low_speed;
	while (($r = fetch ($q)) != NULL) {
	        $switches[$r->switch]->config
			.= sprintf ("interface port-channel %d\n", $r->port);
		$switches[$r->switch]->config .= sprintf ("  name %s\n",
							  $r->name);
		if ($r->bandwidth == "high") {
			$switches[$r->switch]->config
				.= sprintf ("  no bandwidth-limit ingress\n"
					    ."  no bandwidth-limit egress\n");
		} else {
			$switches[$r->switch]->config
				.= sprintf ("  bandwidth-limit ingress\n"
					    ."  bandwidth-limit ingress %d\n"
					    ."  bandwidth-limit egress\n"
					    ."  bandwidth-limit egress %d\n",
					    $low_speed, $low_speed);
		}
		$switches[$r->switch]->config .= sprintf ("exit\n");
	}

	foreach ($switches as $id => $sw) {
		$sw->config .= "bandwidth-control\n";
		
		fwrite ($sw->fp, $sw->config);
		fclose ($sw->fp);
		
		if ($id == 1) {
			$t = sprintf ("/tmp/switchconfig%d", $id);
			$upload = ftp_put ($sw->conn, "config", $t,
					   FTP_ASCII);
			
			if (!$upload) {
				echo ("ftp upload failed");
				pfinish ();
			}
			
			ftp_close ($sw->conn);
		}
	}
	
	$_SESSION['flash'] = sprintf ("router update in progress, please"
				      ." wait at least 20 seconds before"
				      ." updating again.<br />");
}

$stmt = sprintf ("select name, ip, port, switch, bandwidth, id from comps"
		 ." order by switch, port");
$q = query ($stmt);
$rows = "";
$rownum = 0;

while (($r = fetch ($q)) != NULL) {
	$rownum++;
	$o = odd_even ($rownum);
	$rows .= "<tr $o>";
	foreach ($cols as $col) {
		$val = $r->$col;
		$rows .= sprintf ("<td>%s</td>", $val);
	}

	$rows .= "<td>";
	if ($r->bandwidth == "high") {
		$rows .= sprintf ("<a href='index.php"
				  ."?bandwidth=high&amp;id=%d'"
				  ." class='selected'>High</a> | ", $r->id);
		$rows .= sprintf ("<a href='index.php"
				  ."?bandwidth=low&amp;id=%d'>"
				  ."Low</a>", $r->id);
	} else {	
		$rows .= sprintf ("<a href='index.php"
				  ."?bandwidth=high&amp;id=%d'>"
				  ."High</a> | ", $r->id);
		$rows .= sprintf ("<a href='index.php"
				  ."?bandwidth=low&amp;id=%d'"
				  ." class='selected'>Low</a>", $r->id);	
	}
	$rows .= "</td>";

	$rows .= sprintf ("<td><a href='details.php?id=%d'>Details</a></td>",
			  $r->id);
	$rows .= "</tr>";
}

echo ("<a href='edit.php'>Create new</a> | ");
echo ("<a href='curconfig.php'>Current Switch Config</a>\n");

echo ("<div style='padding-top:1em'></div>\n");
echo ("<table class='boxed'>\n");
echo ("<tr>\n");
foreach ($cols as $col) {
	echo (sprintf ("<th>%s</th>\n", h($col)));
}
echo ("<th>bandwidth</th>");
echo ("<th>op</th>");
echo ("</tr>\n");

echo ($rows);

echo ("</table>\n");

echo ("<form action='index.php'>");
echo ("<input type='hidden' name='update' value='1' />");
echo ("<input type='submit' value='Update Router' />");
echo ("</form>");

echo ("<div style='padding-top:1em'></div>\n");

pfinish ();

?>
                                                                                                                                                                                                                                                                                                                                                                                                                                               Makefile                                                                                            0000644 0001750 0001750 00000000413 11241376724 011167  0                                                                                                    ustar   alex                            alex                                                                                                                                                                                                                   WWW_FILES = common.php curconfig.php details.php edit.php index.php \
	style.css

AUX_FILES = password.php

all:

install:
	for f in $(WWW_FILES); do ln -sf `pwd`/$$f /var/www/html/net/.; done
	for f in $(AUX_FILES); do ln -sf `pwd`/$$f /var/switch-interface/.; done
                                                                                                                                                                                                                                                     README                                                                                              0000644 0001750 0001750 00000000000 11241376724 010377  0                                                                                                    ustar   alex                            alex                                                                                                                                                                                                                   style.css                                                                                           0000644 0001750 0001750 00000004323 11241376724 011405  0                                                                                                    ustar   alex                            alex                                                                                                                                                                                                                   /*Eric Myer Reset*/
html, body, div, span, applet, object, iframe,
h1, h2, h3, h4, h5, h6, p, blockquote, pre,
a, abbr, acronym, address, big, cite, code,
del, dfn, em, font, img, ins, kbd, q, s, samp,
small, strike, strong, sub, sup, tt, var,
dl, dt, dd, ol, ul, li,
fieldset, form, label, legend,
table, caption, tbody, tfoot, thead, tr, th, td {
	margin: 0;
	padding: 0;
	border: 0;
	outline: 0;
	font-weight: inherit;
	font-style: inherit;
	font-size: 100%;
	font-family: inherit;
	vertical-align: baseline;
}
/* remember to define focus styles! */
:focus {
	outline: 0;
}
body {
	line-height: 1;
	color: black;
	background: white;
}
ol, ul {
	list-style: none;
}
/* tables still need 'cellspacing="0"' in the markup */
table {
	border-collapse: separate;
	border-spacing: 0;
}
caption, th, td {
	text-align: left;
	font-weight: normal;
}
blockquote:before, blockquote:after,
q:before, q:after {
	content: "";
}
blockquote, q {
	quotes: "" "";
}

/*================================================================*/

body {
    padding: .5em;
    font-family: sans-serif;
    font-size: 1em;
    line-height: 1.1;
}

a {
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
}

h1 {
    font-weight: bold;
}

.boxed {
    border-bottom: 1px solid #888;
    border-left: 1px solid #888;
}

.boxed th {
    padding-left: 1em;
    padding-right: 1em;
    padding-top: .1em;
    padding-bottom: .3em;
    font-weight: bold;
    border-right: 1px solid #888;
    background: #bbb;
}

.boxed td {
    padding-left: 1em;
    padding-right: 1em;
    padding-bottom: .1em;
    border-right: 1px solid #aaa;
}

.boxed td .selected {
    color: white;
    background: #282;
}


.boxed .even {
    background: #ddd;
}

.twocol {
    border-left: 1px solid #aaa;
    border-top: 1px solid #aaa;
}

.twocol th {
    padding: .5em;
    font-weight: bold;
    border-right: 1px solid #aaa;
    border-bottom: 1px solid #aaa;
}

.twocol td {
    border-right: 1px solid #aaa;
    border-bottom: 1px solid #aaa;
    padding-left: .5em;
    padding-right: .5em;
}

.twocol td .selected {
    color: white;
    background: #282;
}    

.clear td {
    padding-left: 0em;
    padding-right: .1em;
    padding-bottom: 0em;
    border-right: 0px solid #fff;
}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             