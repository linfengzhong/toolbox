<?php
// Allow specifying main window URL for permalinks, etc.
$url = 'main.php';

if ("no" == "yes" && isset($_GET['corewindow'])) {

	// The default window url may have been overridden with a permalink...
	// Parse the URL and remove permalink option from base.
	$a = parse_url($_GET['corewindow']);

	// Build the base url.
	$url = htmlentities($a['path']).'?';
	$url = (isset($a['host'])) ? $a['scheme'].'://'.$a['host'].$url : '/'.$url;

	$query = isset($a['query']) ? $a['query'] : '';
	$pairs = explode('&', $query);
	foreach ($pairs as $pair) {
		$v = explode('=', $pair);
		if (is_array($v)) {
			$key = urlencode($v[0]);
			$val = urlencode(isset($v[1]) ? $v[1] : '');
			$url .= "&$key=$val";
		}
	}
	if (preg_match("/^http:\/\/|^https:\/\/|^\//", $url) != 1)
		$url = "main.php";
}

$this_year = date("Y");
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html>
<head>
	<meta name="ROBOTS" content="NOINDEX, NOFOLLOW">
	<title>Nagios: <?php echo $_SERVER['SERVER_NAME']; ?></title>
	<link rel="shortcut icon" href="images/favicon.ico" type="image/ico">
	<link rel='stylesheet' type='text/css' href='/nagios/stylesheets/common.css'>

	<script LANGUAGE="javascript">
		var n = Math.round(Math.random() * 10000000000);
		document.cookie = "NagFormId=" + n.toString(16);
	</script>
<style>

::-webkit-scrollbar { display: none; }
html {
	scrollbar-width: none;
}

body { 
	margin: 0; 
	overflow: auto;
}

#container {
	position: absolute;
	display: inline-block;
	width: 100%;
	height: 100%;
}
div.column { 
	display: flex; 
	height: 100%;
	min-height: -webkit-fill-available;
	min-height: -moz-available;
	overflow: auto;
}
div.left {
	float: left;
	min-width: 200px;
	overflow: hidden;
	border-right: 1px solid var(--color-background-darker);
}
div.right {
	width: 100%
	max-width: -webkit-fill-available;
	max-width: -moz-available;
}

iframe { 
	border: none; 
	min-height: 100%;
	height: -webkit-fill-available;
	height: -moz-available;
}
div.right iframe {
	width: -webkit-fill-available;
	width: -moz-available;
}

</style>
</head>
<body>
  <div id="container" class="">
    <div class="column left" >
      <iframe src="side.php" name="side"></iframe>
    </div>
    <div class="column right" >
      <iframe src="<?php echo $url; ?>" name="main"></iframe>
    </div>
  </div>

</body>
</html>

