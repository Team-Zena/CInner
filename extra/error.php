
<!DOCTYPE html>
<html>
<head>
	<title>An Error occurred when building</title>
</head>
<body>
<?php
	$strHash = '<no commit hash>';
	if(isset($_GET['hash'])) {
		$strHash = $_GET['hash'];
	}

	if(isset($_GET['reason'])) {
		switch ($_GET['reason']) {
			case 'noLogFile':
				default:
				echo "No log file was generated for commit: " . $strHash;
				break;
		}
	}
?>
</body>
</html>

