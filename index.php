<?php
	// Make sure that the post data contains payload key
	if (!array_key_exists('payload', $_POST)) {
		echo "Request did not contain the 'payload' key";
		exit(1);
	}

	// If we are here then we got the pyaload key and it must have a JSON string
	$strPayloadArray = json_decode($_POST['payload'], true);

	if ($strPayloadArray === null) {
		// decoding failed
		echo "Invalid payload";
		exit(2);
	}

	// There has to be an 'after' key in the payload contianing the commit hash
	if (!array_key_exists('after', $strPayloadArray)) {
		echo "There was no 'after' key in the Payload!";
		exit(3);
	}
	$strCommitHash = $strPayloadArray['after'];

	// The commit has will be 40 characters alphanumeric string
	if (!ctype_alnum($strCommitHash) || strlen($strCommitHash) != 40) {
		echo "Commit hash was not alphanumeric or was not of 40 characters.";
		exit(4);
	}



	$strCommand = __DIR__ . '/script.sh -c ' . $strCommitHash;
	$strOutput = shell_exec($strCommand);

	echo "test was run.";