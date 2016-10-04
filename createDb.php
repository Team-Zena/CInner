<?php

$objDb = new SQLite3("buildStatus.db");

$objDb->query("CREATE TABLE IF NOT EXISTS events (id TEXT, data TEXT);");

$strId = md5('');
$strValue = "Test Successful";
$objDb->query("INSERT INTO events (id, data) VALUES ('$strId', '$strValue')");

echo "Success!!";
