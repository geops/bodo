<?php

class StandortController extends Zend_Controller_Action {

    public function init() {

        $this->view->messages = $this->_helper->FlashMessenger->getMessages();
    }

    public function listAction() {

        $standort_id = (int)$this->_request->getParam('standort_id');
        $bezeichnung = $this->_request->getParam('bezeichnung');

        $standortModel = new StandortModel();
        $this->view->standorte = $standortModel->listStandorte($standort_id, $bezeichnung);
        $this->_helper->layout->disableLayout();
    }

    public function viewAction() {

        $standort_id = (int)$this->_request->getParam('standort_id');

        $standortModel = new StandortModel();
        $standort = $standortModel->getStandort($standort_id);

        if ($standort) {

            $bohrungModel = new BohrungModel();

            $this->view->bohrungen = $bohrungModel->getBohrungen($standort_id);
            $this->view->standort = $standort;

        } else {

            $this->_helper->FlashMessenger(array(
                'type' => 'error',
                'text' => "Standort mit der ID $standort_id nicht gefunden.",
            ));
            $this->_redirect(ROOT_DIR);
        }
    }

    public function editAction() {

        $standort_id = (int)$this->_request->getParam('standort_id');

        $standortModel = new StandortModel();
        $standort = $standortModel->getStandort($standort_id);

        if ($standort) {

            $codeModel = new CodeModel();

            $this->view->standort = $standort;
            $this->view->qualiOptions = $codeModel->getCodes('standort', 'quali');

        } else {

            $this->_helper->FlashMessenger(array(
                'type' => 'error',
                'text' => 'Standort nicht gefunden.',
            ));
            $this->_redirect(ROOT_DIR);
        }
    }

    public function newAction() {

        $codeModel = new CodeModel();
        $this->view->qualiOptions = $codeModel->getCodes('standort', 'quali');

        if (!empty($this->view->messages)) {
            $formSession = new Zend_Session_Namespace('bodo.form');
            $this->view->standort = $formSession->data;
        }
    }

    public function insertAction() {

        $standortModel = new StandortModel();
        $data = $this->getData();

        try {

            $data = $standortModel->prepareData($data);
            $standort_id = $standortModel->insert($data);

        } catch (Geops_Database_Exception $exc) {

            $this->_helper->FlashMessenger(array(
                'type' => 'error',
                'text' => $exc->getMessage(),
            ));

            $formSession = new Zend_Session_Namespace('bodo.form');
            $formSession->data = $data;

            $this->_redirect(ROOT_DIR . 'standort/new');
        }

        $this->_helper->FlashMessenger(array(
            'type' => 'success',
            'text' => 'Standort erstellt.',
        ));

        $this->_redirect(ROOT_DIR . 'standort/view?standort_id=' . $standort_id);

    }

    public function updateAction() {

        $standort_id = (int)$this->_request->getParam('standort_id');
        $data = $this->getData();
        $standortModel = new StandortModel();

        try {

            $standortModel->updateStandort($standort_id, $data);

        } catch (Geops_Database_Exception $exc) {

            // Save form date from getting lost.
            $formSession = new Zend_Session_Namespace('bodo.form');
            $formSession->data = $data;

            $this->_helper->FlashMessenger(array(
                'type' => 'error',
                'text' => $exc->getMessage(),
            ));
            $this->_redirect(ROOT_DIR . 'standort/edit?standort_id=' . $standort_id);
        }

        $this->_helper->FlashMessenger(array(
            'type' => 'success',
            'text' => 'Standort aktualisiert.',
        ));
        $this->_redirect(ROOT_DIR . 'standort/view?standort_id=' . $standort_id);
    }

    public function removeAction() {
        $standort_id = (int)$this->_request->getParam('standort_id');
        $this->view->standort_id = $standort_id;
    }

    public function deleteAction() {

        $standort_id = (int)$this->_request->getParam('standort_id');
        $standortModel = new StandortModel();

        try {

            $standortModel->delete(array('standort_id = ?' => $standort_id));

        } catch (Geops_Database_Exception $exc) {

            $this->_helper->FlashMessenger(array(
                'type' => 'error',
                'text' => $exc->getMessage(),
            ));
            $this->_redirect(ROOT_DIR . 'standort/view?standort_id=' . $standort_id);
        }

        $this->_helper->FlashMessenger(array(
            'type' => 'success',
            'text' => 'Standort gelöscht.',
        ));
        $this->_redirect(ROOT_DIR);
    }

    private function getData() {

        return array(
            'bezeichnung'  => $this->_request->getParam('bezeichnung'),
            'bemerkung'    => $this->_request->getParam('bemerkung'),
            'anzbohrloch'  => $this->_request->getParam('anzbohrloch'),
            'gembfs'       => $this->_request->getParam('gembfs'),
            'gbnummer'     => $this->_request->getParam('gbnummer'),
            'gaso_nr'      => $this->_request->getParam('gaso_nr'),
            'quali'        => $this->_request->getParam('quali'),
            'qualibem'     => $this->_request->getParam('qualibem'),
            'x_koordinate' => $this->_request->getParam('x_koordinate'),
            'y_koordinate' => $this->_request->getParam('y_koordinate'),
        );
    }
}

