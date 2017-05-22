<?php

class IndexController extends Zend_Controller_Action
{

    public function init() {
        
        $this->view->messages = $this->_helper->FlashMessenger->getMessages();
    }

    public function indexAction() {

        $standortModel = new StandortModel();
        $this->view->standorte = $standortModel->listStandorte();
    }


}

