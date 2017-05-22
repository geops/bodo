<?php

class SchichtModel extends Zend_Db_Table_Abstract {

    protected $_name = 'bohrung.schicht';

    public function updateSchicht($schicht_id, $data) {

        $where = array('schicht_id = ?' => $schicht_id);
        $data = $this->prepareData($data);
        $this->_db->update('bohrung.schicht', $data, $where);
    }

    public function insertSchicht($data) {

        $data = $this->prepareData($data);
        return $this->_db->insert('bohrung.schicht', $data);
    }

    public function deleteSchicht($schicht_id) {

        $where = array('schicht_id = ?' => $schicht_id);
        return $this->_db->delete('bohrung.schicht', $where);
    }

    public function saveSchichten($schichten, $bohrprofil_id) {

        foreach ($schichten as $schicht) {
            $schicht['bohrprofil_id'] = $bohrprofil_id;

            if (empty($schicht['schicht_id']) && !$schicht['delete']) {
                $this->insertSchicht($schicht);

            } else if (!empty($schicht['schicht_id'])) {
                if ($schicht['delete']) {
                    $this->deleteSchicht($schicht['schicht_id']);
                } else {
                    $this->updateSchicht($schicht['schicht_id'], $schicht);
                }
            }
        }
    }


    private function prepareData($data) {

        $data['tiefe']        = is_numeric($data['tiefe'])   ? (float)$data['tiefe'] : NULL;
        $data['schichten_id'] = empty($data['schichten_id']) ? NULL : (int)$data['schichten_id'];
        $data['quali']        = empty($data['quali'])        ? NULL : (int)$data['quali'];

        unset($data['delete']);
        unset($data['schicht_id']);

        return $data;
    }
}