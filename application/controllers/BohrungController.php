<?php

class BohrungController extends Zend_Controller_Action {

    public function init() {

        $this->view->messages = $this->_helper->FlashMessenger->getMessages();
    }

    public function editAction() {

        $bohrung_id = (int)$this->_request->getParam('bohrung_id');

        if (empty($this->view->messages)) {
            $bohrungModel = new BohrungModel();
            $row = $bohrungModel->fetchRow(array('bohrung_id = ?' => $bohrung_id));
            $this->view->bohrung = $row->toArray();
        } else {
            $formSession = new Zend_Session_Namespace('bodo.form');
            $this->view->bohrung = $formSession->data;
            $this->view->bohrung['bohrung_id'] = $bohrung_id;
        }

        $this->addCodesToView();
    }

    public function newAction() {

        $standort_id = (int)$this->_request->getParam('standort_id');

        $this->addCodesToView();
        $this->view->standort_id = $standort_id;

        if (!empty($this->view->messages)) {
            $formSession = new Zend_Session_Namespace('bodo.form');
            $this->view->bohrung = $formSession->data;
        }
    }

    public function insertAction() {

        $bohrungModel = new BohrungModel();
        $data = $this->getData();

        try {

            $bohrungModel->insertBohrung($data);

        } catch (Geops_Database_Exception $exc) {

            $this->_helper->FlashMessenger(array(
                'type' => 'error',
                'text' => $exc->getMessage(),
            ));

            $formSession = new Zend_Session_Namespace('bodo.form');
            $formSession->data = $data;

            $this->_redirect(ROOT_DIR . 'bohrung/new?standort_id=' . $data['standort_id']);
        }

        $this->_helper->FlashMessenger(array(
            'type' => 'success',
            'text' => 'Bohrung erstellt.',
        ));

        $this->_redirect(ROOT_DIR . 'standort/view?standort_id=' . $data['standort_id']);
    }

    public function updateAction() {

        $bohrung_id = (int)$this->_request->getParam('bohrung_id');
        $data = $this->getData();
        $bohrungModel = new BohrungModel();

        try {

            $bohrungModel->updateBohrung($bohrung_id, $data);

        } catch (Geops_Database_Exception $exc) {

            $formSession = new Zend_Session_Namespace('bodo.form');
            $formSession->data = $data;

            $this->_helper->FlashMessenger(array(
                'type' => 'error',
                'text' => $exc->getMessage(),
            ));
            $this->_redirect(ROOT_DIR . 'bohrung/edit?bohrung_id=' . $bohrung_id);
        }

        $this->_helper->FlashMessenger(array(
            'type' => 'success',
            'text' => 'Bohrung aktualisiert.',
        ));
        $this->_redirect(ROOT_DIR . 'standort/view?standort_id=' . $data['standort_id']);
    }

    public function removeAction() {
        $bohrung_id = (int)$this->_request->getParam('bohrung_id');
        $this->view->bohrung_id = $bohrung_id;
    }

    public function deleteAction() {

        $bohrung_id = (int)$this->_request->getParam('bohrung_id');
        $bohrungModel = new BohrungModel();

        $standort_id = $bohrungModel->getStandortId($bohrung_id);

        if (!$standort_id) {
            $this->_helper->FlashMessenger(array(
                'type' => 'error',
                'text' => 'Bohrung nicht gefunden.',
            ));
            $this->_redirect(ROOT_DIR . 'standort/list');
        }

        try {

            $bohrungModel->delete(array('bohrung_id = ?' => $bohrung_id));

        } catch (Geops_Database_Exception $exc) {

            $this->_helper->FlashMessenger(array(
                'type' => 'error',
                'text' => $exc->getMessage(),
            ));
            $this->_redirect(ROOT_DIR . 'standort/view?standort_id=' . $standort_id);
        }

        $this->_helper->FlashMessenger(array(
            'type' => 'success',
            'text' => 'Bohrung gelöscht.',
        ));
        $this->_redirect(ROOT_DIR . 'standort/view?standort_id=' . $standort_id);
    }

    private function addCodesToView() {
        $codeModel = new CodeModel();
        $this->view->qualiOptions     = $codeModel->getCodes('bohrung', 'quali');
        $this->view->bohrartOptions   = $codeModel->getCodes('bohrung', 'bohrart');
        $this->view->bohrzweckOptions = $codeModel->getCodes('bohrung', 'bohrzweck');
        $this->view->ablenkungOptions = $codeModel->getCodes('bohrung', 'ablenkung');
    }

    private function getData() {

        return array(
            'standort_id'         => $this->_request->getParam('standort_id'),
            'bezeichnung'         => $this->_request->getParam('bezeichnung'),
            'bemerkung'           => $this->_request->getParam('bemerkung'),
            'datum'               => $this->_request->getParam('datum'),
            'besitzer'            => $this->_request->getParam('besitzer'),
            'durchmesserbohrloch' => $this->_request->getParam('durchmesserbohrloch'),
            'bohrart'             => $this->_request->getParam('bohrart'),
            'bohrzweck'           => $this->_request->getParam('bohrzweck'),
            'ablenkung'           => $this->_request->getParam('ablenkung'),
            'ablenkungbem'        => $this->_request->getParam('ablenkungbem'),
            'quali'               => $this->_request->getParam('quali'),
            'qualibem'            => $this->_request->getParam('qualibem'),
            'quelleref'           => $this->_request->getParam('quelleref'),
            'hotlinka'            => $this->_request->getParam('hotlinka'),
            'hotlinkf'            => $this->_request->getParam('hotlinkf'),
        );
    }
}
