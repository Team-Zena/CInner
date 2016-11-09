<!DOCTYPE html>
<html>
<head>
	<title>Build is pending</title>
</head>
<body>
<?php
	/**
	 * Created by PhpStorm.
	 * User: vaibhav
	 * Date: 06/10/16
	 * Time: 1:16 PM
	 */

	$strCommitHash = 'N/A';
	if(isset($_GET['hash'])) {
		$strCommitHash = $_GET['hash'];
	}

	$intTimeDiff = null;
	if(isset($_GET['time'])) {
		$intStartTime = $_GET['time'];
		$intTimeNow = time();
		$intTimeDiff = $intTimeNow - $intStartTime;
	}

	echo "The build for <strong>" . $strCommitHash . "</strong> is pending since $intTimeDiff seconds.";
?>
</body>
</html>
