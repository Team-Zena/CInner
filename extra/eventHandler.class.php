<?php
/**
 * Created by PhpStorm.
 * User: vaibhav
 * Date: 29/9/16
 * Time: 1:20 AM
 */

class DbHandler {

    const DbName = 'buildStatus.db';

    /** @var SQLite3 */
    private $objDb;

    public function __construct() {
        if(!file_exists(self::DbName)) {
            $this->CreateDb();
        }
    }

    public function CreateDb() {
        $this->objDb = new SQLite3("buildStatus.db");

        $this->objDb->query("CREATE TABLE IF NOT EXISTS test_status
(
    commit_id TEXT PRIMARY KEY NOT NULL,
    status INTEGER DEFAULT 0 NOT NULL,
    test_request_time INTEGER NOT NULL
);
CREATE UNIQUE INDEX test_status_index ON test_status (status);");

        $strId = md5('');
        $strValue = "DB Created";
//        $this->objDb->query("INSERT INTO events (id, data) VALUES ('$strId', '$strValue')");
    }

    /**
     * @param $strData
     * @return bool
     */
    public function CreateNewTestStatus($strData) {
        // Ensure that the Data is an array
        if(!is_array($strData)) {
            return false;
        }

        $strId = md5(microtime() . rand(10, 1000000));
        $strValue = SQLite3::escapeString(json_encode($strData));

        $this->objDb->query("INSERT INTO events (id, data) VALUES ('$strId', '$strValue')");
    }
}