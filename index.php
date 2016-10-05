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

	$strCommand = __DIR__ . '/script.sh -v -c ' . $strCommitHash;

	$curl = curl_init();

//	echo json_encode($strPostInfoArray);

	// Set some options - we are passing in a useragent too here
	curl_setopt_array($curl, array(
//		CURLOPT_RETURNTRANSFER => 1,
		CURLOPT_URL => 'https://api.github.com/repos/vaibhav-kaushal/ActozenQC3/statuses/' . $strCommitHash,
		CURLOPT_POST => 1,
		CURLOPT_POSTFIELDS => json_encode([
			"state" => "pending",
			"target_url" => "https://ci.health-zen.com/" . $strCommitHash,
			"description" => "About to run the tasks",
			"context" => "ci/script/pending"
		]),
		CURLOPT_HTTPHEADER => array("Authorization: token f0dc853b8d9e2eab46edeb2e3a3d65e288678b4e")
	));

	// Send the request & save response to $resp
	$resp = curl_exec($curl);

	// Close request to clear up some resources
	curl_close($curl);

	echo "about to run " . $strCommand . "\n";

	$strOutput = shell_exec($strCommand);

	echo "test was run. \n" ;

	echo $strOutput;