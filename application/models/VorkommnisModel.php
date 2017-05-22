<?php

class VorkommnisModel extends Zend_Db_Table_Abstract {

    protected $_name = 'bohrung.vorkommnis';

    public function updateVorkommnis($vorkommnis_id, $data) {

        $where = array('vorkommnis_id = ?' => $vorkommnis_id);
        $data = $this->prepareData($data);
        $this->_db->update('bohrung.vorkommnis', $data, $where);
    }

    public function insertVorkommnis($data) {

        $data = $this->prepareData($data);
        return $this->_db->insert('bohrung.vorkommnis', $data);
    }

    public function deleteVorkommnis($vorkommnis_id) {

        $where = array('vorkommnis_id = ?' => $vorkommnis_id);
        return $this->_db->delete('bohrung.vorkommnis', $where);
    }

    public function saveVorkommnisse($vorkommnisse, $bohrprofil_id) {

        foreach ($vorkommnisse as $vorkommnis) {
            $vorkommnis['bohrprofil_id'] = $bohrprofil_id;

            if (empty($vorkommnis['vorkommnis_id']) && !$vorkommnis['delete']) {
                $this->insertVorkommnis($vorkommnis);

            } else if (!empty($vorkommnis['vorkommnis_id'])) {
                if ($vorkommnis['delete']) {
                    $this->deleteVorkommnis($vorkommnis['vorkommnis_id']);
                } else {
                    $this->updateVorkommnis($vorkommnis['vorkommnis_id'], $vorkommnis);
                }
            }
        }
    }


    private function prepareData($data) {

        $data['tiefe']  = is_numeric($data['tiefe']) ? (float)$data['tiefe'] : NULL;
        $data['typ']    = empty($data['typ'])    ? NULL : (int)$data['typ'];
        $data['subtyp'] = empty($data['subtyp']) ? NULL : (int)$data['subtyp'];
        $data['quali']  = empty($data['quali'])  ? NULL : (int)$data['quali'];

        unset($data['delete']);
        unset($data['vorkommnis_id']);

        return $data;
    }
}