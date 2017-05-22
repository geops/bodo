<?php

class CodeModel extends Zend_Db_Table_Abstract {

    public function getCodes($table, $row) {

        $codes = array('' => '-');
        $rows = $this->_db->fetchAll(
            "select code_id, kurztext from bohrung.code where codetyp_id = (
                select column_default::int from information_schema.columns
                where table_schema = 'bohrung' and table_name = '$table' and column_name = 'h_$row'
            ) order by sort"
        );

        foreach ($rows as $row) {
            $codes[$row['code_id']] = $row['kurztext'];
        }

        return $codes;
    }

    public function getSchichten() {

        return $this->_db->fetchPairs('select codeschicht_id, text from bohrung.codeschicht order by sort');
    }

}
